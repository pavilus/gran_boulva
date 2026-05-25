-- ============================================================
-- Reward System Complete Fix
-- Migration: 20260525000400_reward_system_complete_fix.sql
-- ============================================================
-- Changes:
--   1. record_badge_event_v2: awards influence_score on level-up
--      (fetches influence_reward from badge_levels for the new level)
--   2. Per-badge influence gains on every inserted event:
--        top_voter  → +1 influence per vote event
--        debater    → +2 influence per argument event
--        community  → +1 influence per support/reaction event
--   3. Recreate record_badge_event (original wrapper) to route
--      through v2 so all fixes apply uniformly.
--   4. The existing floor(coins/10) influence from support_argument
--      is left intact in that function.
-- ============================================================

create or replace function public.record_badge_event_v2(
  p_badge_key text,
  p_event_type text,
  p_xp_gained integer,
  p_reference_id uuid default null,
  p_reference_key text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id          uuid;
  v_badge_id         uuid;
  v_badge_name       text;
  v_event_id         uuid;
  v_old_xp           integer := 0;
  v_old_level        integer := 0;
  v_new_xp           integer := 0;
  v_new_level        integer := 0;
  v_influence_reward integer := 0;
  v_extra_influence  integer := 0;
begin
  -- ── 1. Identify the calling user ──────────────────────────────
  v_user_id := public.current_app_user_id();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- ── 2. Look up the badge ──────────────────────────────────────
  select id, name_ht into v_badge_id, v_badge_name
  from public.badges
  where key = p_badge_key
    and is_active = true;

  if v_badge_id is null then
    raise exception 'Unknown badge key: %', p_badge_key;
  end if;

  -- ── 3. Ensure user_badges row exists ─────────────────────────
  insert into public.user_badges (user_id, badge_id)
  values (v_user_id, v_badge_id)
  on conflict (user_id, badge_id) do nothing;

  -- ── 4. Snapshot current XP / level ───────────────────────────
  select current_xp, current_level into v_old_xp, v_old_level
  from public.user_badges
  where user_id = v_user_id
    and badge_id = v_badge_id;

  -- ── 5. Insert event (idempotent via unique index) ─────────────
  insert into public.badge_events (
    user_id,
    badge_id,
    event_type,
    xp_gained,
    reference_id,
    reference_key,
    metadata
  )
  values (
    v_user_id,
    v_badge_id,
    p_event_type,
    p_xp_gained,
    p_reference_id,
    nullif(p_reference_key, ''),
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict do nothing
  returning id into v_event_id;

  -- ── 6. If the event was actually inserted, add XP ────────────
  if v_event_id is not null then
    update public.user_badges
    set current_xp = current_xp + p_xp_gained,
        updated_at = now()
    where user_id = v_user_id
      and badge_id = v_badge_id
    returning current_xp into v_new_xp;
  else
    v_new_xp := v_old_xp;
  end if;

  -- ── 7. Recalculate badge level ────────────────────────────────
  select coalesce(max(level), 0) into v_new_level
  from public.badge_levels
  where badge_id = v_badge_id
    and required_xp <= coalesce(v_new_xp, 0);

  update public.user_badges
  set current_level = v_new_level,
      earned_at = case
        when earned_at is null and v_new_level > 0 then now()
        else earned_at
      end,
      updated_at = now()
  where user_id = v_user_id
    and badge_id = v_badge_id;

  -- ── 8. Award influence on level-up ───────────────────────────
  if v_event_id is not null and v_new_level > v_old_level then
    -- Fetch the influence_reward for the newly reached level
    select coalesce(influence_reward, 0) into v_influence_reward
    from public.badge_levels
    where badge_id = v_badge_id
      and level = v_new_level;

    if v_influence_reward > 0 then
      update public.users
      set influence_score = coalesce(influence_score, 0) + v_influence_reward,
          updated_at = now()
      where id = v_user_id;
    end if;

    -- Notify user of level-up
    insert into public.notifications (
      user_id,
      type,
      title,
      body,
      related_table,
      related_id,
      is_read
    )
    values (
      v_user_id,
      'badge_level_up',
      'Nouvo nivo badj',
      'Ou rive ' || coalesce(v_badge_name, p_badge_key) || ' Nivo ' || v_new_level || '!',
      'badges',
      v_badge_id,
      false
    );
  end if;

  -- ── 9. Per-action influence bonuses (per-event, not per level) ─
  -- Only apply when the event was actually inserted (not a duplicate).
  if v_event_id is not null then
    v_extra_influence := case p_badge_key
      when 'top_voter'  then 1   -- +1 per vote cast
      when 'debater'    then 2   -- +2 per argument posted
      when 'community'  then 1   -- +1 per support/reaction/reply action
      else 0
    end;

    if v_extra_influence > 0 then
      update public.users
      set influence_score = coalesce(influence_score, 0) + v_extra_influence,
          updated_at = now()
      where id = v_user_id;
    end if;
  end if;

  -- ── 10. Return result ─────────────────────────────────────────
  return jsonb_build_object(
    'success',        true,
    'badge_key',      p_badge_key,
    'badge_name',     v_badge_name,
    'xp',             coalesce(v_new_xp, 0),
    'old_level',      coalesce(v_old_level, 0),
    'level',          v_new_level,
    'leveled_up',     v_event_id is not null and v_new_level > v_old_level,
    'inserted_event', v_event_id is not null
  );
end;
$$;

grant execute on function public.record_badge_event_v2(
  text, text, integer, uuid, text, jsonb
) to authenticated;

-- ============================================================
-- Recreate record_badge_event (original wrapper) so that it
-- routes through record_badge_event_v2 and inherits all fixes.
-- ============================================================
create or replace function public.record_badge_event(
  p_badge_key text,
  p_event_type text,
  p_xp_gained integer,
  p_reference_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select public.record_badge_event_v2(
    p_badge_key    => p_badge_key,
    p_event_type   => p_event_type,
    p_xp_gained    => p_xp_gained,
    p_reference_id => p_reference_id,
    p_reference_key => null,
    p_metadata     => p_metadata
  );
$$;

grant execute on function public.record_badge_event(text, text, integer, uuid, jsonb) to authenticated;
