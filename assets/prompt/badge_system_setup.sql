-- BadgeSystem setup
-- Run this in Supabase SQL Editor.
--
-- Creates:
-- - badges
-- - badge_levels
-- - user_badges
-- - badge_events
-- - record_badge_event RPC used by the Flutter app

create extension if not exists pgcrypto;

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name_ht text not null,
  name_en text not null,
  description_ht text not null default '',
  description_en text not null default '',
  icon_asset text not null default '',
  color_hex text not null default '#A855F7',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- If an older badges table already exists, bring it up to the BadgeSystem shape.
alter table public.badges
add column if not exists key text,
add column if not exists name_ht text not null default '',
add column if not exists name_en text not null default '',
add column if not exists description_ht text not null default '',
add column if not exists description_en text not null default '',
add column if not exists icon_asset text not null default '',
add column if not exists color_hex text not null default '#A855F7',
add column if not exists sort_order integer not null default 0,
add column if not exists is_active boolean not null default true,
add column if not exists created_at timestamptz not null default now();

update public.badges
set key = 'legacy_' || id::text
where key is null
   or key = '';

with ranked_badges as (
  select
    id,
    key,
    row_number() over (partition by key order by id) as duplicate_rank
  from public.badges
)
update public.badges b
set key = b.key || '_' || b.id::text
from ranked_badges rb
where rb.id = b.id
  and rb.duplicate_rank > 1;

alter table public.badges
alter column key set not null;

create unique index if not exists badges_key_unique
on public.badges (key);

-- Older BadgeSystem drafts used public.badges.code as a required field.
-- The current app uses key, so keep code compatible without blocking inserts.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'badges'
      and column_name = 'code'
  ) then
    update public.badges
    set code = coalesce(nullif(code, ''), key, 'legacy_' || id::text)
    where code is null
       or code = '';

    alter table public.badges
    alter column code drop not null;
  end if;
end $$;

create table if not exists public.badge_levels (
  id uuid primary key default gen_random_uuid(),
  badge_id uuid not null references public.badges(id) on delete cascade,
  level integer not null check (level between 1 and 10),
  required_xp integer not null check (required_xp >= 0),
  title_ht text not null,
  title_en text not null,
  influence_reward integer not null default 0,
  created_at timestamptz not null default now(),
  unique (badge_id, level)
);

alter table public.badge_levels
add column if not exists badge_id uuid references public.badges(id) on delete cascade,
add column if not exists level integer not null default 1,
add column if not exists required_xp integer not null default 0,
add column if not exists title_ht text not null default '',
add column if not exists title_en text not null default '',
add column if not exists influence_reward integer not null default 0,
add column if not exists created_at timestamptz not null default now();

create unique index if not exists badge_levels_badge_id_level_unique
on public.badge_levels (badge_id, level);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  current_xp integer not null default 0,
  current_level integer not null default 0 check (current_level between 0 and 10),
  is_featured boolean not null default false,
  earned_at timestamptz,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, badge_id)
);

alter table public.user_badges
add column if not exists user_id uuid references public.users(id) on delete cascade,
add column if not exists badge_id uuid references public.badges(id) on delete cascade,
add column if not exists current_xp integer not null default 0,
add column if not exists current_level integer not null default 0,
add column if not exists is_featured boolean not null default false,
add column if not exists earned_at timestamptz,
add column if not exists updated_at timestamptz not null default now(),
add column if not exists created_at timestamptz not null default now();

create unique index if not exists user_badges_user_id_badge_id_unique
on public.user_badges (user_id, badge_id);

create table if not exists public.badge_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  event_type text not null,
  xp_gained integer not null check (xp_gained > 0),
  reference_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.badge_events
add column if not exists user_id uuid references public.users(id) on delete cascade,
add column if not exists badge_id uuid references public.badges(id) on delete cascade,
add column if not exists event_type text not null default 'manual',
add column if not exists xp_gained integer not null default 1,
add column if not exists reference_id uuid,
add column if not exists metadata jsonb not null default '{}'::jsonb,
add column if not exists created_at timestamptz not null default now();

create unique index if not exists badge_events_once_per_reference
on public.badge_events (
  user_id,
  badge_id,
  event_type,
  coalesce(reference_id, '00000000-0000-0000-0000-000000000000'::uuid)
);

create or replace function public.current_app_user_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select u.id
  from public.users u
  where u.auth_user_id = auth.uid()
  limit 1
$$;

insert into public.badges
  (key, name_ht, name_en, description_ht, description_en, icon_asset, color_hex, sort_order)
values
  ('top_voter', 'Top Votè', 'Top Voter', 'Vote sou matchups pou monte nivo ou.', 'Vote on matchups to level up.', 'assets/images/topvotè.png', '#A855F7', 1),
  ('hot_streak', 'San Kanpe', 'Hot Streak', 'Kenbe aktivite ou vivan chak jou.', 'Keep your participation streak alive.', 'assets/images/sankanpe.png', '#F97316', 2),
  ('debater', 'Gran Debatè', 'Debater', 'Ekri agiman ki fè diskisyon an pi rich.', 'Post arguments that strengthen the debate.', 'assets/images/grandebatè.png', '#3B82F6', 3),
  ('consistent', 'Konsistan', 'Consistent', 'Patisipe regilyèman semèn apre semèn.', 'Participate reliably week after week.', 'assets/images/konsistan.png', '#22C55E', 4),
  ('community', 'Gran Sipòtè', 'Great Supporter', 'Sipòte lòt moun epi fè kominote a grandi.', 'Support others and help the community grow.', 'assets/images/sipote.png', '#D90C82', 5)
on conflict (key) do update
set name_ht = excluded.name_ht,
    name_en = excluded.name_en,
    description_ht = excluded.description_ht,
    description_en = excluded.description_en,
    icon_asset = excluded.icon_asset,
    color_hex = excluded.color_hex,
    sort_order = excluded.sort_order,
    is_active = true;

with thresholds(badge_key, level, required_xp) as (
  values
    ('top_voter', 1, 10),
    ('top_voter', 2, 50),
    ('top_voter', 3, 100),
    ('top_voter', 4, 250),
    ('top_voter', 5, 500),
    ('top_voter', 6, 1000),
    ('top_voter', 7, 2500),
    ('top_voter', 8, 5000),
    ('top_voter', 9, 10000),
    ('top_voter', 10, 25000),
    ('hot_streak', 1, 3),
    ('hot_streak', 2, 7),
    ('hot_streak', 3, 14),
    ('hot_streak', 4, 21),
    ('hot_streak', 5, 30),
    ('hot_streak', 6, 45),
    ('hot_streak', 7, 60),
    ('hot_streak', 8, 90),
    ('hot_streak', 9, 180),
    ('hot_streak', 10, 365),
    ('debater', 1, 5),
    ('debater', 2, 25),
    ('debater', 3, 50),
    ('debater', 4, 100),
    ('debater', 5, 250),
    ('debater', 6, 500),
    ('debater', 7, 1000),
    ('debater', 8, 2500),
    ('debater', 9, 5000),
    ('debater', 10, 10000),
    ('consistent', 1, 1),
    ('consistent', 2, 2),
    ('consistent', 3, 4),
    ('consistent', 4, 8),
    ('consistent', 5, 12),
    ('consistent', 6, 24),
    ('consistent', 7, 36),
    ('consistent', 8, 52),
    ('consistent', 9, 104),
    ('consistent', 10, 156),
    ('community', 1, 10),
    ('community', 2, 50),
    ('community', 3, 100),
    ('community', 4, 250),
    ('community', 5, 500),
    ('community', 6, 1000),
    ('community', 7, 2500),
    ('community', 8, 5000),
    ('community', 9, 10000),
    ('community', 10, 25000)
)
insert into public.badge_levels
  (badge_id, level, required_xp, title_ht, title_en, influence_reward)
select
  b.id,
  t.level,
  t.required_xp,
  'Nivo ' || t.level,
  'Level ' || t.level,
  t.level * 5
from public.badges b
join thresholds t on t.badge_key = b.key
on conflict (badge_id, level) do update
set required_xp = excluded.required_xp,
    title_ht = excluded.title_ht,
    title_en = excluded.title_en,
    influence_reward = excluded.influence_reward;

create or replace function public.record_badge_event(
  p_badge_key text,
  p_event_type text,
  p_xp_gained integer,
  p_reference_id uuid default null,
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
  v_event_id uuid;
  v_new_xp integer;
  v_new_level integer;
begin
  v_user_id := public.current_app_user_id();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id into v_badge_id
  from public.badges
  where key = p_badge_key
    and is_active = true;

  if v_badge_id is null then
    raise exception 'Unknown badge key: %', p_badge_key;
  end if;

  insert into public.badge_events (
    user_id,
    badge_id,
    event_type,
    xp_gained,
    reference_id,
    metadata
  )
  values (
    v_user_id,
    v_badge_id,
    p_event_type,
    p_xp_gained,
    p_reference_id,
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict do nothing
  returning id into v_event_id;

  insert into public.user_badges (user_id, badge_id)
  values (v_user_id, v_badge_id)
  on conflict (user_id, badge_id) do nothing;

  if v_event_id is not null then
    update public.user_badges
    set current_xp = current_xp + p_xp_gained,
        updated_at = now()
    where user_id = v_user_id
      and badge_id = v_badge_id
    returning current_xp into v_new_xp;
  else
    select current_xp into v_new_xp
    from public.user_badges
    where user_id = v_user_id
      and badge_id = v_badge_id;
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

  return jsonb_build_object(
    'success', true,
    'badge_key', p_badge_key,
    'xp', coalesce(v_new_xp, 0),
    'level', v_new_level,
    'inserted_event', v_event_id is not null
  );
end;
$$;

alter table public.badges enable row level security;
alter table public.badge_levels enable row level security;
alter table public.user_badges enable row level security;
alter table public.badge_events enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'badges'
      and policyname = 'Anyone can read active badges'
  ) then
    create policy "Anyone can read active badges"
    on public.badges for select
    using (is_active = true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'badge_levels'
      and policyname = 'Anyone can read badge levels'
  ) then
    create policy "Anyone can read badge levels"
    on public.badge_levels for select
    using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_badges'
      and policyname = 'Users can read visible badge progress'
  ) then
    create policy "Users can read visible badge progress"
    on public.user_badges for select
    using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'badge_events'
      and policyname = 'Users can read own badge events'
  ) then
    create policy "Users can read own badge events"
    on public.badge_events for select
    using (user_id = public.current_app_user_id());
  end if;
end $$;

grant execute on function public.record_badge_event(text, text, integer, uuid, jsonb) to authenticated;
grant execute on function public.current_app_user_id() to authenticated;

-- Quick verification.
select
  b.key,
  b.name_ht,
  count(bl.id) as levels
from public.badges b
left join public.badge_levels bl on bl.badge_id = b.id
group by b.id
order by b.sort_order;
