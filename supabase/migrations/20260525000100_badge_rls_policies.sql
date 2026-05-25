-- Fix badge read access.
-- user_badges, badge_events, badges, badge_levels were created in the Supabase
-- dashboard without SELECT policies. RPCs (security definer) can write fine, but
-- direct Flutter queries get 0 rows back, so the badge counter always shows 0.

-- ── user_badges ──────────────────────────────────────────────────────────────
alter table public.user_badges enable row level security;

drop policy if exists "user_badges_select_own"  on public.user_badges;
drop policy if exists "user_badges_select_public" on public.user_badges;

-- Users can read their own badge progress; public profiles can see others too
create policy "user_badges_select_own"
  on public.user_badges for select
  to authenticated
  using (user_id = public.current_app_user_id());

-- Allow reading any user's badge progress (for public profile display)
create policy "user_badges_select_public"
  on public.user_badges for select
  to authenticated
  using (true);

-- ── badge_events ─────────────────────────────────────────────────────────────
alter table public.badge_events enable row level security;

drop policy if exists "badge_events_select_own" on public.badge_events;

create policy "badge_events_select_own"
  on public.badge_events for select
  to authenticated
  using (user_id = public.current_app_user_id());

-- ── badges (reference table — public read) ───────────────────────────────────
alter table public.badges enable row level security;

drop policy if exists "badges_select_all" on public.badges;

create policy "badges_select_all"
  on public.badges for select
  to authenticated
  using (true);

-- ── badge_levels (reference table — public read) ─────────────────────────────
alter table public.badge_levels enable row level security;

drop policy if exists "badge_levels_select_all" on public.badge_levels;

create policy "badge_levels_select_all"
  on public.badge_levels for select
  to authenticated
  using (true);

-- ── grants ────────────────────────────────────────────────────────────────────
grant select on public.user_badges   to authenticated;
grant select on public.badge_events  to authenticated;
grant select on public.badges        to authenticated;
grant select on public.badge_levels  to authenticated;
