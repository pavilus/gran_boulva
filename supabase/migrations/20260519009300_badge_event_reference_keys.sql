-- Badge events need non-UUID reference keys for daily/weekly progress.

alter table public.badge_events
  add column if not exists reference_key text;

drop index if exists public.badge_events_once_per_reference;

create unique index if not exists badge_events_once_per_reference
on public.badge_events (
  user_id,
  badge_id,
  event_type,
  coalesce(reference_key, reference_id::text, 'none')
);

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
  v_user_id uuid;
  v_badge_id uuid;
  v_badge_name text;
  v_event_id uuid;
  v_old_xp integer := 0;
  v_old_level integer := 0;
  v_new_xp integer := 0;
  v_new_level integer := 0;
begin
  v_user_id := public.current_app_user_id();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id, name_ht into v_badge_id, v_badge_name
  from public.badges
  where key = p_badge_key
    and is_active = true;

  if v_badge_id is null then
    raise exception 'Unknown badge key: %', p_badge_key;
  end if;

  insert into public.user_badges (user_id, badge_id)
  values (v_user_id, v_badge_id)
  on conflict (user_id, badge_id) do nothing;

  select current_xp, current_level into v_old_xp, v_old_level
  from public.user_badges
  where user_id = v_user_id
    and badge_id = v_badge_id;

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

  if v_event_id is not null and v_new_level > v_old_level then
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

  return jsonb_build_object(
    'success', true,
    'badge_key', p_badge_key,
    'badge_name', v_badge_name,
    'xp', coalesce(v_new_xp, 0),
    'old_level', coalesce(v_old_level, 0),
    'level', v_new_level,
    'leveled_up', v_event_id is not null and v_new_level > v_old_level,
    'inserted_event', v_event_id is not null
  );
end;
$$;

grant execute on function public.record_badge_event_v2(
  text,
  text,
  integer,
  uuid,
  text,
  jsonb
) to authenticated;
