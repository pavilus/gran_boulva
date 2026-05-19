create table if not exists public.user_interests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  category text,
  score numeric not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id, category_id)
);

create table if not exists public.user_behavior_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_type text not null,
  target_type text not null,
  target_id uuid not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.content_recommendation_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  content_type text not null,
  content_id uuid not null,
  recommendation_score numeric not null default 0,
  generated_at timestamptz not null default now(),
  unique (user_id, content_type, content_id)
);

create table if not exists public.trending_scores (
  id uuid primary key default gen_random_uuid(),
  content_type text not null,
  content_id uuid not null,
  trending_score numeric not null default 0,
  updated_at timestamptz not null default now(),
  unique (content_type, content_id)
);

alter table public.user_interests enable row level security;
alter table public.user_behavior_events enable row level security;
alter table public.content_recommendation_scores enable row level security;
alter table public.trending_scores enable row level security;

drop policy if exists "Users can read own interests" on public.user_interests;
create policy "Users can read own interests"
  on public.user_interests for select
  to authenticated
  using (exists (
    select 1 from public.users u
     where u.id = user_interests.user_id
       and u.auth_user_id = auth.uid()
  ));

drop policy if exists "Users can read own behavior events" on public.user_behavior_events;
create policy "Users can read own behavior events"
  on public.user_behavior_events for select
  to authenticated
  using (exists (
    select 1 from public.users u
     where u.id = user_behavior_events.user_id
       and u.auth_user_id = auth.uid()
  ));

drop policy if exists "Users can read own recommendation scores" on public.content_recommendation_scores;
create policy "Users can read own recommendation scores"
  on public.content_recommendation_scores for select
  to authenticated
  using (exists (
    select 1 from public.users u
     where u.id = content_recommendation_scores.user_id
       and u.auth_user_id = auth.uid()
  ));

drop policy if exists "Authenticated users can read trending scores" on public.trending_scores;
create policy "Authenticated users can read trending scores"
  on public.trending_scores for select
  to authenticated
  using (true);

drop policy if exists "Service role can manage user interests" on public.user_interests;
create policy "Service role can manage user interests"
  on public.user_interests for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "Service role can manage behavior events" on public.user_behavior_events;
create policy "Service role can manage behavior events"
  on public.user_behavior_events for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "Service role can manage recommendation scores" on public.content_recommendation_scores;
create policy "Service role can manage recommendation scores"
  on public.content_recommendation_scores for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "Service role can manage trending scores" on public.trending_scores;
create policy "Service role can manage trending scores"
  on public.trending_scores for all
  to service_role
  using (true)
  with check (true);

create index if not exists idx_user_interests_user_score
  on public.user_interests (user_id, score desc);
create index if not exists idx_behavior_events_user_created
  on public.user_behavior_events (user_id, created_at desc);
create index if not exists idx_behavior_events_target
  on public.user_behavior_events (target_type, target_id, created_at desc);
create index if not exists idx_trending_scores_content
  on public.trending_scores (content_type, content_id, trending_score desc);

insert into public.app_settings (key, value)
values (
  'recommendation_settings',
  '{
    "personalizedRatio": 70,
    "discoveryRatio": 20,
    "perspectiveRatio": 10,
    "freshnessDecayHours": 48,
    "trendingWeight": 1.2,
    "interestWeight": 2.0,
    "diversityWeight": 0.35
  }'::jsonb
)
on conflict (key) do nothing;

create or replace function public._recommendation_event_weight(p_event_type text)
returns numeric
language sql
immutable
as $$
  select case p_event_type
    when 'vote' then 4
    when 'argument_post' then 7
    when 'like' then 2
    when 'reply' then 5
    when 'save' then 6
    when 'share' then 7
    when 'follow' then 5
    when 'support' then 8
    when 'boost' then 6
    when 'profile_view' then 1
    when 'prediction_vote' then 5
    when 'matchup_view' then 1
    when 'notification_click' then 3
    else 1
  end::numeric;
$$;

create or replace function public.record_behavior_event(
  p_event_type text,
  p_target_type text,
  p_target_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_weight numeric := public._recommendation_event_weight(p_event_type);
  v_category_id uuid;
  v_category_name text;
  v_trending_type text := p_target_type;
  v_trending_id uuid := p_target_id;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.user_behavior_events (
    user_id,
    event_type,
    target_type,
    target_id,
    metadata
  )
  values (
    v_user_id,
    p_event_type,
    p_target_type,
    p_target_id,
    coalesce(p_metadata, '{}'::jsonb)
  );

  if p_target_type = 'matchup' then
    select m.category_id, c.name_ht
      into v_category_id, v_category_name
      from public.matchups m
      left join public.categories c on c.id = m.category_id
     where m.id = p_target_id;
  elsif p_target_type = 'argument' then
    select m.category_id, c.name_ht, m.id
      into v_category_id, v_category_name, v_trending_id
      from public.arguments a
      join public.matchups m on m.id = a.matchup_id
      left join public.categories c on c.id = m.category_id
     where a.id = p_target_id;
    v_trending_type := 'matchup';
  elsif p_target_type = 'prediction' then
    select p.category_id, c.name_ht
      into v_category_id, v_category_name
      from public.predictions p
      left join public.categories c on c.id = p.category_id
     where p.id = p_target_id;
  end if;

  if v_category_id is not null then
    insert into public.user_interests (
      user_id,
      category_id,
      category,
      score,
      updated_at
    )
    values (
      v_user_id,
      v_category_id,
      v_category_name,
      v_weight,
      now()
    )
    on conflict (user_id, category_id) do update
      set score = least(100, public.user_interests.score * 0.98 + excluded.score),
          category = coalesce(excluded.category, public.user_interests.category),
          updated_at = now();
  end if;

  if v_trending_id is not null and p_event_type <> 'matchup_view' then
    insert into public.trending_scores (
      content_type,
      content_id,
      trending_score,
      updated_at
    )
    values (
      v_trending_type,
      v_trending_id,
      v_weight,
      now()
    )
    on conflict (content_type, content_id) do update
      set trending_score = public.trending_scores.trending_score * 0.92 + excluded.trending_score,
          updated_at = now();
  end if;

  return jsonb_build_object('success', true);
end;
$$;

create or replace function public.get_recommended_home_feed(
  p_category_id uuid default null,
  p_limit integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_settings jsonb;
  v_interest_weight numeric;
  v_trending_weight numeric;
  v_diversity_weight numeric;
  v_freshness_hours numeric;
  v_result jsonb;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  select value
    into v_settings
    from public.app_settings
   where key = 'recommendation_settings';

  v_interest_weight := coalesce((v_settings ->> 'interestWeight')::numeric, 2.0);
  v_trending_weight := coalesce((v_settings ->> 'trendingWeight')::numeric, 1.2);
  v_diversity_weight := coalesce((v_settings ->> 'diversityWeight')::numeric, 0.35);
  v_freshness_hours := greatest(coalesce((v_settings ->> 'freshnessDecayHours')::numeric, 48), 1);

  with scored as (
    select
      m.*,
      c.id as category_json_id,
      c.name_ht as category_name_ht,
      c.name_en as category_name_en,
      c.icon as category_icon,
      coalesce(ui.score, 0) as interest_score,
      coalesce(ts.trending_score, 0) as trending_score,
      greatest(
        0,
        40 - (extract(epoch from (now() - coalesce(m.published_at, m.created_at))) / 3600 / v_freshness_hours * 40)
      ) as freshness_score,
      case when ui.id is null then 12 else 0 end as diversity_score,
      (
        coalesce(ui.score, 0) * v_interest_weight
        + coalesce(ts.trending_score, 0) * v_trending_weight
        + coalesce(m.engagement_score, 0) * 0.05
        + greatest(
            0,
            40 - (extract(epoch from (now() - coalesce(m.published_at, m.created_at))) / 3600 / v_freshness_hours * 40)
          )
        + case when ui.id is null then 12 * v_diversity_weight else 0 end
        + random() * 4
      ) as recommendation_score,
      (
        select v.option_id
          from public.votes v
         where v.user_id = v_user_id
           and v.matchup_id = m.id
         limit 1
      ) as my_vote_option_id,
      exists (
        select 1
          from public.saved_items si
         where si.user_id = v_user_id
           and si.item_type = 'matchup'
           and si.item_id = m.id
      ) as is_saved
    from public.matchups m
    left join public.categories c on c.id = m.category_id
    left join public.user_interests ui
      on ui.user_id = v_user_id
     and ui.category_id = m.category_id
    left join public.trending_scores ts
      on ts.content_type = 'matchup'
     and ts.content_id = m.id
    where m.status = 'published'
      and (p_category_id is null or m.category_id = p_category_id)
  ),
  limited as (
    select *
      from scored
     order by recommendation_score desc, published_at desc nulls last, created_at desc
     limit greatest(p_limit, 1)
  )
  select coalesce(
    jsonb_agg(
      to_jsonb(limited)
        - 'category_json_id'
        - 'category_name_ht'
        - 'category_name_en'
        - 'category_icon'
        - 'recommendation_score'
        - 'interest_score'
        - 'trending_score'
        - 'freshness_score'
        - 'diversity_score'
        || jsonb_build_object(
          'category', jsonb_build_object(
            'id', category_json_id,
            'name_ht', category_name_ht,
            'name_en', category_name_en,
            'icon', category_icon
          ),
          'options', coalesce((
            select jsonb_agg(to_jsonb(mo) order by mo.option_label)
              from public.matchup_options mo
             where mo.matchup_id = limited.id
          ), '[]'::jsonb),
          'my_vote_option_id', my_vote_option_id,
          'is_saved', is_saved
        )
    ),
    '[]'::jsonb
  )
    into v_result
    from limited;

  return v_result;
end;
$$;

grant execute on function public.record_behavior_event(
  text,
  text,
  uuid,
  jsonb
) to authenticated;

grant execute on function public.get_recommended_home_feed(
  uuid,
  integer
) to authenticated;
