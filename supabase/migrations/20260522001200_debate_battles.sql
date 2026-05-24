-- ============================================================
-- Debate Battle Feature — Foundation Tables
-- Migration: 20260522001200_debate_battles.sql
-- ============================================================
-- Tables:
--   debate_battles          — one row per battle: mode, status, Agora tokens, recording
--   battle_round_log        — per-speaker round turns (Full Debate mode only)
--   battle_audience_votes   — final winner vote (UNIQUE per voter per battle)
--   battle_extension_votes  — mid-battle "continue?" vote (UNIQUE per voter per battle)
--
-- Modes:  'rapid_fire' (5 min, Tier 1+)  |  'full_debate' (10 min, Tier 2+)
-- Status: pending → accepted → lobby → live → voting → completed | cancelled
-- Timer authority: round_ends_at is the server-side source of truth.
--   Clients count down locally and sync on rejoin.
-- Round advancement (Full Debate): pg_cron job inside Edge Function; not here.
-- ============================================================


-- ───────────────────────────────────────────────────────────
-- 1. debate_battles
-- ───────────────────────────────────────────────────────────
create table if not exists public.debate_battles (
  id                       uuid        primary key default gen_random_uuid(),

  -- Participants
  challenger_id            uuid        not null references public.users(id) on delete cascade,
  opponent_id              uuid        not null references public.users(id) on delete cascade,
  winner_id                uuid        references public.users(id) on delete set null,

  -- Battle config
  mode                     text        not null
                             check (mode in ('rapid_fire', 'full_debate')),
  topic                    text        not null,
  entry_fee_coins          bigint      not null default 0
                             check (entry_fee_coins >= 0),
  prize_pool_coins         bigint      not null default 0
                             check (prize_pool_coins >= 0),

  -- Status lifecycle: pending → accepted → lobby → live → voting → completed | cancelled
  status                   text        not null default 'pending'
                             check (status in (
                               'pending', 'accepted', 'lobby', 'live',
                               'voting', 'completed', 'cancelled'
                             )),
  cancelled_reason         text,

  -- Agora RTC
  agora_channel            text        unique,           -- e.g. "battle-<id>"
  agora_challenger_token   text,
  agora_opponent_token     text,

  -- Round / timer (used for both modes; Full Debate tracks current_round)
  current_round            integer     not null default 0
                             check (current_round between 0 and 4),
  round_ends_at            timestamptz,                  -- server-side timer authority

  -- Extension vote state (max 1 per battle)
  extension_used           boolean     not null default false,
  extension_vote_open      boolean     not null default false,
  extension_approved       boolean,                      -- null until vote closes

  -- Final audience vote state
  audience_vote_open       boolean     not null default false,

  -- Recording (HLS via Agora Cloud Recording → S3)
  recording_url            text,
  recording_expires_at     timestamptz,                  -- 24 h after battle ends

  -- Timestamps
  created_at               timestamptz not null default now(),
  started_at               timestamptz,
  ended_at                 timestamptz
);

-- Indexes
create index if not exists debate_battles_challenger_idx  on public.debate_battles (challenger_id);
create index if not exists debate_battles_opponent_idx    on public.debate_battles (opponent_id);
create index if not exists debate_battles_status_idx      on public.debate_battles (status);
create index if not exists debate_battles_created_at_idx  on public.debate_battles (created_at desc);

-- RLS
alter table public.debate_battles enable row level security;

-- All roles — only service_role writes (Edge Functions own the lifecycle)
grant all   on table public.debate_battles to service_role;
grant select on table public.debate_battles to authenticated;

-- Authenticated users can read all battles (public feed, replays, etc.)
create policy "authenticated can read battles"
  on public.debate_battles for select
  to authenticated
  using (true);

-- Only service_role can insert / update / delete (via Edge Functions)
create policy "service_role full access battles"
  on public.debate_battles for all
  to service_role
  using (true)
  with check (true);


-- ───────────────────────────────────────────────────────────
-- 2. battle_round_log  (Full Debate only)
-- ───────────────────────────────────────────────────────────
-- One row per speaker turn in a Full Debate.
-- Round schedule:
--   Round 1 — Opening   (Ouvertura)  : A 45s → B 45s
--   Round 2 — Argument  (Agiman)     : A 90s → B 90s
--   Round 3 — Rebuttal  (Repons)     : B 60s → A 60s  ← reversed
--   Round 4 — Closing   (Klotin)     : A 45s → B 45s
-- Extension adds Round 5 (bonus): A 60s → B 60s
create table if not exists public.battle_round_log (
  id               uuid        primary key default gen_random_uuid(),
  battle_id        uuid        not null references public.debate_battles(id) on delete cascade,

  round_number     integer     not null check (round_number between 1 and 5),
  -- speaker: 'challenger' | 'opponent'
  speaker          text        not null check (speaker in ('challenger', 'opponent')),
  duration_seconds integer     not null check (duration_seconds > 0),

  starts_at        timestamptz not null,
  ends_at          timestamptz not null,

  created_at       timestamptz not null default now(),

  -- Enforce logical ordering: one row per round + speaker combination
  constraint battle_round_log_unique unique (battle_id, round_number, speaker)
);

create index if not exists battle_round_log_battle_idx on public.battle_round_log (battle_id);

alter table public.battle_round_log enable row level security;

grant all    on table public.battle_round_log to service_role;
grant select on table public.battle_round_log to authenticated;

create policy "authenticated can read round log"
  on public.battle_round_log for select
  to authenticated
  using (true);

create policy "service_role full access round log"
  on public.battle_round_log for all
  to service_role
  using (true)
  with check (true);


-- ───────────────────────────────────────────────────────────
-- 3. battle_audience_votes  (final winner vote)
-- ───────────────────────────────────────────────────────────
-- Open for 30 seconds after battle ends.
-- One vote per viewer per battle — enforced by UNIQUE constraint.
create table if not exists public.battle_audience_votes (
  id          uuid        primary key default gen_random_uuid(),
  battle_id   uuid        not null references public.debate_battles(id) on delete cascade,
  voter_id    uuid        not null references public.users(id) on delete cascade,

  -- 'challenger' | 'opponent'
  vote_for    text        not null check (vote_for in ('challenger', 'opponent')),

  created_at  timestamptz not null default now(),

  constraint battle_audience_votes_unique unique (battle_id, voter_id)
);

create index if not exists battle_audience_votes_battle_idx on public.battle_audience_votes (battle_id);
create index if not exists battle_audience_votes_voter_idx  on public.battle_audience_votes (voter_id);

alter table public.battle_audience_votes enable row level security;

grant all    on table public.battle_audience_votes to service_role;
grant select on table public.battle_audience_votes to authenticated;
grant insert on table public.battle_audience_votes to authenticated;

-- Audience can read all votes for a battle (for live tally display)
create policy "authenticated can read audience votes"
  on public.battle_audience_votes for select
  to authenticated
  using (true);

-- Authenticated users can cast exactly one vote per battle (UNIQUE handles duplicate prevention)
create policy "authenticated can insert own audience vote"
  on public.battle_audience_votes for insert
  to authenticated
  with check (voter_id = (select id from public.users where auth_user_id = auth.uid() limit 1));

-- No updates or deletes — votes are final
create policy "service_role full access audience votes"
  on public.battle_audience_votes for all
  to service_role
  using (true)
  with check (true);


-- ───────────────────────────────────────────────────────────
-- 4. battle_extension_votes  (mid-battle "continue?" vote)
-- ───────────────────────────────────────────────────────────
-- Triggered at 4:30 (Rapid Fire) or 9:30 (Full Debate).
-- 10-second window. Threshold: ≥60% Yes AND min viewer count met.
-- Min viewers: 200 (Rapid Fire) | 500 (Full Debate).
-- Max 1 extension per battle — enforced via debate_battles.extension_used.
-- One vote per viewer per battle — enforced by UNIQUE constraint.
create table if not exists public.battle_extension_votes (
  id          uuid        primary key default gen_random_uuid(),
  battle_id   uuid        not null references public.debate_battles(id) on delete cascade,
  voter_id    uuid        not null references public.users(id) on delete cascade,

  -- true = Yes (extend) | false = No (end on time)
  vote        boolean     not null,

  created_at  timestamptz not null default now(),

  constraint battle_extension_votes_unique unique (battle_id, voter_id)
);

create index if not exists battle_extension_votes_battle_idx on public.battle_extension_votes (battle_id);
create index if not exists battle_extension_votes_voter_idx  on public.battle_extension_votes (voter_id);

alter table public.battle_extension_votes enable row level security;

grant all    on table public.battle_extension_votes to service_role;
grant select on table public.battle_extension_votes to authenticated;
grant insert on table public.battle_extension_votes to authenticated;

-- Audience can see vote counts (for live "60% want to continue" bar)
create policy "authenticated can read extension votes"
  on public.battle_extension_votes for select
  to authenticated
  using (true);

-- Authenticated users can cast exactly one extension vote per battle
create policy "authenticated can insert own extension vote"
  on public.battle_extension_votes for insert
  to authenticated
  with check (voter_id = (select id from public.users where auth_user_id = auth.uid() limit 1));

-- No updates or deletes
create policy "service_role full access extension votes"
  on public.battle_extension_votes for all
  to service_role
  using (true)
  with check (true);
