-- ============================================================
-- Creator Revenue Sharing System
-- Migration: 20260519008900_creator_revenue_system.sql
-- ============================================================
-- Tables:
--   creator_profiles        — one row per user: tier, score, revenue totals
--   creator_revenue_events  — every coin-earning event (support, tips, etc.)
--   creator_payouts         — payout requests + history
-- RPCs:
--   calculate_creator_score(p_user_id)   — returns 0-100 score
--   refresh_creator_tier(p_user_id)      — recalculates + auto-upgrades tier 0/1/2
--   get_creator_dashboard(p_user_id)     — stats for in-app dashboard
-- ============================================================

-- ───────────────────────────────────────────────────────────
-- 1. CREATOR TIERS reference (documentation, no table needed)
-- ───────────────────────────────────────────────────────────
-- Tier 0 — User         : default, no monetization
-- Tier 1 — Rising       : score >= 15 AND followers >= 10, no monetization yet
-- Tier 2 — Verified Creator : verification approved (trusted_creator or public_figure)
--                             AND score >= 35  →  70% revenue share
-- Tier 3 — Elite        : score >= 70, admin-confirmed  →  80% revenue share
-- Tier 4 — Cultural Icon: admin-only grant  →  custom revenue share (stored in profile)

-- ───────────────────────────────────────────────────────────
-- 2. creator_profiles
-- ───────────────────────────────────────────────────────────
create table if not exists public.creator_profiles (
  user_id                 uuid        primary key references public.users(id) on delete cascade,
  creator_tier            integer     not null default 0
                            check (creator_tier between 0 and 4),
  creator_score           integer     not null default 0
                            check (creator_score between 0 and 100),
  trust_score             integer     not null default 0
                            check (trust_score between 0 and 100),
  is_monetization_enabled boolean     not null default false,
  monetization_suspended  boolean     not null default false,
  suspension_reason       text,
  revenue_share_rate      numeric(3,2) not null default 0.00,
  -- lifetime revenue counters (in coins)
  total_earned_coins      bigint      not null default 0,
  pending_payout_coins    bigint      not null default 0,
  total_paid_out_coins    bigint      not null default 0,
  -- metadata
  score_updated_at        timestamptz,
  tier_updated_at         timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────
-- 3. creator_revenue_events
-- ───────────────────────────────────────────────────────────
create table if not exists public.creator_revenue_events (
  id                  uuid        primary key default gen_random_uuid(),
  creator_user_id     uuid        not null references public.users(id) on delete cascade,
  source_user_id      uuid        references public.users(id) on delete set null,
  -- event_type: 'argument_support' | 'boost_tip' | 'subscription' | 'admin_bonus'
  event_type          text        not null,
  gross_coins         bigint      not null check (gross_coins > 0),
  creator_share_rate  numeric(3,2) not null,
  creator_coins       bigint      not null,   -- floor(gross * rate)
  platform_coins      bigint      not null,   -- gross - creator_coins
  reference_table     text,
  reference_id        uuid,
  created_at          timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────
-- 4. creator_payouts
-- ───────────────────────────────────────────────────────────
create table if not exists public.creator_payouts (
  id                  uuid        primary key default gen_random_uuid(),
  creator_user_id     uuid        not null references public.users(id) on delete cascade,
  coins_amount        bigint      not null check (coins_amount > 0),
  usd_amount          numeric(10,2),
  -- status: 'pending' | 'processing' | 'completed' | 'failed'
  status              text        not null default 'pending',
  payout_method       text,       -- 'stripe' | 'moncash' | 'natcash' | 'manual'
  payout_reference    text,       -- external transaction ID
  admin_notes         text,
  requested_at        timestamptz not null default now(),
  processed_at        timestamptz,
  created_at          timestamptz not null default now()
);

-- ───────────────────────────────────────────────────────────
-- 5. Indexes
-- ───────────────────────────────────────────────────────────
create index if not exists creator_revenue_events_creator_idx
  on public.creator_revenue_events (creator_user_id, created_at desc);

create index if not exists creator_revenue_events_source_idx
  on public.creator_revenue_events (source_user_id);

create index if not exists creator_payouts_creator_idx
  on public.creator_payouts (creator_user_id, created_at desc);

create index if not exists creator_payouts_status_idx
  on public.creator_payouts (status);

-- ───────────────────────────────────────────────────────────
-- 6. calculate_creator_score(p_user_id)
--    Returns 0-100. Weights:
--      Badge Progression   30 pts (avg badge level / 10 * 30)
--      Engagement Quality  20 pts (participation + arguments, log-scaled)
--      Followers           20 pts (log-scaled, 1000 followers ~ 15 pts)
--      Consistency         15 pts (participation_count log-scaled)
--      Community Rep       10 pts (total_support_received log-scaled)
--      Debate Performance   5 pts (victory_count / max(participation,1) * 5)
-- ───────────────────────────────────────────────────────────
create or replace function public.calculate_creator_score(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_followers         integer := 0;
  v_participation     integer := 0;
  v_victories         integer := 0;
  v_support_received  integer := 0;
  v_avg_badge_level   numeric := 0;
  v_badge_pts         numeric := 0;
  v_engagement_pts    numeric := 0;
  v_followers_pts     numeric := 0;
  v_consistency_pts   numeric := 0;
  v_reputation_pts    numeric := 0;
  v_debate_pts        numeric := 0;
  v_total             integer := 0;
begin
  -- Pull user stats
  select
    coalesce(followers_count, 0),
    coalesce(participation_count, 0),
    coalesce(victory_count, 0),
    coalesce(total_support_received, 0)
  into v_followers, v_participation, v_victories, v_support_received
  from public.users
  where id = p_user_id;

  -- Badge progression: average current_level across all user_badges (max 10 each)
  select coalesce(avg(ub.current_level), 0)
  into v_avg_badge_level
  from public.user_badges ub
  where ub.user_id = p_user_id;

  -- Score components
  -- 1. Badge Progression (30 pts)
  v_badge_pts := least(30.0, (v_avg_badge_level / 10.0) * 30.0);

  -- 2. Engagement Quality (20 pts): participation log-scaled, cap at 500
  v_engagement_pts := least(20.0,
    case when v_participation > 0
    then (ln(least(v_participation, 500)::numeric + 1) / ln(501)) * 20.0
    else 0 end);

  -- 3. Followers (20 pts): log-scaled, 1000 followers ≈ 15 pts, 10000 ≈ 20 pts
  v_followers_pts := least(20.0,
    case when v_followers > 0
    then (ln(least(v_followers, 10000)::numeric + 1) / ln(10001)) * 20.0
    else 0 end);

  -- 4. Consistency (15 pts): participation log-scaled differently
  v_consistency_pts := least(15.0,
    case when v_participation > 0
    then (ln(least(v_participation, 200)::numeric + 1) / ln(201)) * 15.0
    else 0 end);

  -- 5. Community Reputation (10 pts): coins received, cap at 5000
  v_reputation_pts := least(10.0,
    case when v_support_received > 0
    then (ln(least(v_support_received, 5000)::numeric + 1) / ln(5001)) * 10.0
    else 0 end);

  -- 6. Debate Performance (5 pts): win rate
  v_debate_pts := least(5.0,
    (v_victories::numeric / greatest(v_participation, 1)) * 5.0);

  v_total := round(
    v_badge_pts + v_engagement_pts + v_followers_pts +
    v_consistency_pts + v_reputation_pts + v_debate_pts
  )::integer;

  return least(100, greatest(0, v_total));
end;
$$;

-- ───────────────────────────────────────────────────────────
-- 7. refresh_creator_tier(p_user_id)
--    Recalculates score and auto-upgrades tiers 0→1 and 1→2.
--    Tier 3 and 4 require admin confirmation.
--    Returns the new tier.
-- ───────────────────────────────────────────────────────────
create or replace function public.refresh_creator_tier(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_score           integer;
  v_new_tier        integer;
  v_current_tier    integer;
  v_followers       integer;
  v_verification    text;
  v_verif_status    text;
  v_share_rate      numeric(3,2);
  v_monetization    boolean;
begin
  -- Calculate fresh score
  v_score := public.calculate_creator_score(p_user_id);

  -- Get user data needed for tier rules
  select
    coalesce(followers_count, 0),
    coalesce(verification_type, ''),
    coalesce(verification_status, 'none')
  into v_followers, v_verification, v_verif_status
  from public.users
  where id = p_user_id;

  -- Get current tier (create profile row if missing)
  insert into public.creator_profiles (user_id, creator_tier, creator_score)
  values (p_user_id, 0, v_score)
  on conflict (user_id) do nothing;

  select creator_tier into v_current_tier
  from public.creator_profiles
  where user_id = p_user_id;

  -- Determine new tier (only ever auto-upgrade, never auto-downgrade)
  v_new_tier := v_current_tier;

  -- 0 → 1: score >= 15 AND (followers >= 10 OR participation >= 5)
  if v_current_tier = 0 and v_score >= 15 and v_followers >= 10 then
    v_new_tier := 1;
  end if;

  -- 1 → 2: verification approved (trusted_creator or public_figure or organization)
  --         AND score >= 35
  if v_current_tier <= 1
    and v_verif_status = 'approved'
    and v_verification in ('trusted_creator', 'public_figure', 'organization')
    and v_score >= 35
  then
    v_new_tier := 2;
  end if;

  -- Tiers 3 and 4 require admin — no auto-upgrade here

  -- Determine revenue share rate + monetization
  case v_new_tier
    when 2 then v_share_rate := 0.70; v_monetization := true;
    when 3 then v_share_rate := 0.80; v_monetization := true;
    when 4 then v_share_rate := null; v_monetization := true; -- custom kept as-is
    else         v_share_rate := 0.00; v_monetization := false;
  end case;

  -- Update the profile
  update public.creator_profiles
  set
    creator_score      = v_score,
    creator_tier       = v_new_tier,
    score_updated_at   = now(),
    tier_updated_at    = case when v_new_tier <> v_current_tier then now() else tier_updated_at end,
    revenue_share_rate = coalesce(
      case when v_new_tier = 4 then revenue_share_rate else v_share_rate end,
      v_share_rate
    ),
    is_monetization_enabled = coalesce(
      case when monetization_suspended then false else v_monetization end,
      false
    ),
    updated_at         = now()
  where user_id = p_user_id;

  -- Notify on tier upgrade
  if v_new_tier > v_current_tier then
    insert into public.notifications (user_id, type, title, body)
    values (
      p_user_id,
      'system',
      case v_new_tier
        when 1 then 'Ou tounen Kreyatè Monte!'
        when 2 then 'Ou tounen Kreyatè Verifye!'
        when 3 then 'Ou tounen Kreyatè Elit!'
        when 4 then 'Ou tounen Ikòn Kiltirèl!'
        else 'Nivo kreyatè ou chanje'
      end,
      case v_new_tier
        when 1 then 'Ou kounye a nan Nivo 1 — Kreyatè Monte. Kontinye grandi!'
        when 2 then 'Felisitasyon! Ou kounye a nan Nivo 2 — Kreyatè Verifye. Ou ka kòmanse touche revni.'
        when 3 then 'Ou rive nan somè a! Nivo 3 — Kreyatè Elit ak 80% revni.'
        when 4 then 'Ou se yon Ikòn Kiltirèl Gran Boulva. Mèsi pou enfliyans ou.'
        else ''
      end
    );
  end if;

  return v_new_tier;
end;
$$;

-- ───────────────────────────────────────────────────────────
-- 8. get_creator_dashboard(p_user_id)
--    Returns JSON with all creator stats for the in-app dashboard.
-- ───────────────────────────────────────────────────────────
create or replace function public.get_creator_dashboard(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile   record;
  v_user      record;
  v_revenue_30d bigint;
  v_revenue_7d  bigint;
  v_supporters  bigint;
begin
  -- Ensure profile exists
  insert into public.creator_profiles (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select * into v_profile from public.creator_profiles where user_id = p_user_id;
  select followers_count, participation_count, victory_count,
         total_support_received, influence_score
  into v_user
  from public.users where id = p_user_id;

  -- Revenue last 30 days
  select coalesce(sum(creator_coins), 0)
  into v_revenue_30d
  from public.creator_revenue_events
  where creator_user_id = p_user_id
    and created_at >= now() - interval '30 days';

  -- Revenue last 7 days
  select coalesce(sum(creator_coins), 0)
  into v_revenue_7d
  from public.creator_revenue_events
  where creator_user_id = p_user_id
    and created_at >= now() - interval '7 days';

  -- Unique supporters (last 30 days)
  select count(distinct source_user_id)
  into v_supporters
  from public.creator_revenue_events
  where creator_user_id = p_user_id
    and created_at >= now() - interval '30 days'
    and source_user_id is not null;

  return jsonb_build_object(
    'creator_tier',            v_profile.creator_tier,
    'creator_score',           v_profile.creator_score,
    'trust_score',             v_profile.trust_score,
    'is_monetization_enabled', v_profile.is_monetization_enabled,
    'revenue_share_rate',      v_profile.revenue_share_rate,
    'total_earned_coins',      v_profile.total_earned_coins,
    'pending_payout_coins',    v_profile.pending_payout_coins,
    'total_paid_out_coins',    v_profile.total_paid_out_coins,
    'revenue_last_7d',         v_revenue_7d,
    'revenue_last_30d',        v_revenue_30d,
    'unique_supporters_30d',   v_supporters,
    'followers_count',         coalesce(v_user.followers_count, 0),
    'participation_count',     coalesce(v_user.participation_count, 0),
    'victory_count',           coalesce(v_user.victory_count, 0),
    'total_support_received',  coalesce(v_user.total_support_received, 0),
    'influence_score',         coalesce(v_user.influence_score, 0)
  );
end;
$$;

-- ───────────────────────────────────────────────────────────
-- 9. record_creator_revenue(p_creator_id, p_source_id, p_event_type,
--                            p_gross_coins, p_reference_table, p_reference_id)
--    Called internally when a support/tip event fires.
--    Splits coins, logs event, updates profile totals.
-- ───────────────────────────────────────────────────────────
create or replace function public.record_creator_revenue(
  p_creator_id      uuid,
  p_source_id       uuid,
  p_event_type      text,
  p_gross_coins     bigint,
  p_reference_table text default null,
  p_reference_id    uuid  default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rate          numeric(3,2) := 0.00;
  v_enabled       boolean := false;
  v_creator_coins bigint;
  v_platform_coins bigint;
begin
  -- Get creator's current rate
  select revenue_share_rate, is_monetization_enabled
  into v_rate, v_enabled
  from public.creator_profiles
  where user_id = p_creator_id;

  -- Only log if monetization is active
  if not found or not v_enabled or v_rate = 0 then
    return;
  end if;

  v_creator_coins  := floor(p_gross_coins * v_rate)::bigint;
  v_platform_coins := p_gross_coins - v_creator_coins;

  -- Log event
  insert into public.creator_revenue_events (
    creator_user_id, source_user_id, event_type,
    gross_coins, creator_share_rate, creator_coins, platform_coins,
    reference_table, reference_id
  ) values (
    p_creator_id, p_source_id, p_event_type,
    p_gross_coins, v_rate, v_creator_coins, v_platform_coins,
    p_reference_table, p_reference_id
  );

  -- Update profile totals
  update public.creator_profiles
  set
    total_earned_coins   = total_earned_coins + v_creator_coins,
    pending_payout_coins = pending_payout_coins + v_creator_coins,
    updated_at           = now()
  where user_id = p_creator_id;
end;
$$;

-- ───────────────────────────────────────────────────────────
-- 10. Trigger: auto-log revenue when support_argument fires
--     We do this by watching coin_transactions for type='support'
-- ───────────────────────────────────────────────────────────
create or replace function public.trg_coin_support_revenue()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only handle support transactions that have a recipient
  if NEW.type = 'support' and NEW.recipient_user_id is not null then
    perform public.record_creator_revenue(
      NEW.recipient_user_id,
      NEW.user_id,
      'argument_support',
      NEW.amount::bigint,
      'coin_transactions',
      NEW.id
    );
  end if;
  return NEW;
end;
$$;

-- Drop trigger if exists, then recreate
drop trigger if exists trg_coin_support_revenue on public.coin_transactions;
create trigger trg_coin_support_revenue
  after insert on public.coin_transactions
  for each row
  execute function public.trg_coin_support_revenue();

-- ───────────────────────────────────────────────────────────
-- 11. RLS
-- ───────────────────────────────────────────────────────────
alter table public.creator_profiles enable row level security;
alter table public.creator_revenue_events enable row level security;
alter table public.creator_payouts enable row level security;

-- creator_profiles: public read, owners can read their own detail
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='creator_profiles'
      and policyname='Anyone can read creator profiles'
  ) then
    create policy "Anyone can read creator profiles"
    on public.creator_profiles for select using (true);
  end if;
end $$;

-- creator_revenue_events: owner only
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='creator_revenue_events'
      and policyname='Creators can read own revenue events'
  ) then
    create policy "Creators can read own revenue events"
    on public.creator_revenue_events for select
    using (creator_user_id = public.current_app_user_id());
  end if;
end $$;

-- creator_payouts: owner only
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='creator_payouts'
      and policyname='Creators can read own payouts'
  ) then
    create policy "Creators can read own payouts"
    on public.creator_payouts for select
    using (creator_user_id = public.current_app_user_id());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='creator_payouts'
      and policyname='Creators can request payouts'
  ) then
    create policy "Creators can request payouts"
    on public.creator_payouts for insert
    with check (creator_user_id = public.current_app_user_id());
  end if;
end $$;

-- ───────────────────────────────────────────────────────────
-- 12. Grants
-- ───────────────────────────────────────────────────────────
grant select on public.creator_profiles to authenticated, anon;
grant insert, update on public.creator_profiles to authenticated;

grant select on public.creator_revenue_events to authenticated;
grant insert on public.creator_revenue_events to authenticated;

grant select, insert on public.creator_payouts to authenticated;

grant select on public.creator_profiles to service_role;
grant all on public.creator_revenue_events to service_role;
grant all on public.creator_payouts to service_role;

grant execute on function public.calculate_creator_score(uuid) to authenticated, service_role;
grant execute on function public.refresh_creator_tier(uuid) to authenticated, service_role;
grant execute on function public.get_creator_dashboard(uuid) to authenticated, service_role;
grant execute on function public.record_creator_revenue(uuid, uuid, text, bigint, text, uuid) to service_role;
