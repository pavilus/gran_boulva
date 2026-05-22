-- ─────────────────────────────────────────────────────────────────────────────
-- Grant authenticated users access to predictions and prediction_votes.
-- Without these, the Flutter app (which uses the authenticated key)
-- cannot read predictions even when status = 'active'.
-- Also adds 'resolved' to the prediction_status enum if missing.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Extend enum to include 'resolved' if not already present ──────────────────
do $$
begin
  if not exists (
    select 1 from pg_enum
    where enumlabel = 'resolved'
      and enumtypid = (select oid from pg_type where typname = 'prediction_status')
  ) then
    alter type prediction_status add value 'resolved';
  end if;
end$$;

-- ── predictions ───────────────────────────────────────────────────────────────
grant select on table public.predictions to authenticated;
grant select on table public.predictions to anon;

alter table public.predictions enable row level security;

-- All active/closed/resolved predictions are publicly readable.
-- Use ::text cast to avoid enum literal comparison issues.
drop policy if exists "Predictions readable by all" on public.predictions;
create policy "Predictions readable by all"
  on public.predictions for select
  using (status::text in ('active', 'closed', 'resolved'));

-- ── prediction_votes ──────────────────────────────────────────────────────────
grant select, insert on table public.prediction_votes to authenticated;

alter table public.prediction_votes enable row level security;

-- Users can read their own votes
drop policy if exists "Users can read own prediction votes" on public.prediction_votes;
create policy "Users can read own prediction votes"
  on public.prediction_votes for select
  to authenticated
  using (
    user_id = (
      select id from public.users where auth_user_id = auth.uid() limit 1
    )
  );

-- Users can read all votes on predictions they have already voted on (for %)
drop policy if exists "Users can read all votes after voting" on public.prediction_votes;
create policy "Users can read all votes after voting"
  on public.prediction_votes for select
  to authenticated
  using (
    prediction_id in (
      select prediction_id from public.prediction_votes pv2
      where pv2.user_id = (
        select id from public.users where auth_user_id = auth.uid() limit 1
      )
    )
  );

-- Users can insert their own vote
drop policy if exists "Users can vote on predictions" on public.prediction_votes;
create policy "Users can vote on predictions"
  on public.prediction_votes for insert
  to authenticated
  with check (
    user_id = (
      select id from public.users where auth_user_id = auth.uid() limit 1
    )
  );
