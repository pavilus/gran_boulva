-- Keep one home-feed RPC signature for PostgREST and fix popular sorting.
drop function if exists public.get_recommended_home_feed(uuid, integer);

create or replace function public.get_recommended_home_feed(
  p_category_id uuid default null,
  p_limit integer default 30,
  p_popular boolean default false
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
    select distinct on (m.id)
      m.*,
      c.id as category_json_id,
      c.name_ht as category_name_ht,
      c.name_en as category_name_en,
      c.icon as category_icon,
      coalesce(ui.score, 0) as interest_score,
      coalesce(ts.trending_score, 0) as trending_score,
      greatest(
        0,
        40 - (
          extract(epoch from (now() - coalesce(m.published_at, m.created_at)))
          / 3600 / v_freshness_hours * 40
        )
      ) as freshness_score,
      case when ui.id is null then 12 else 0 end as diversity_score,
      (
        coalesce(ui.score, 0) * v_interest_weight
        + coalesce(ts.trending_score, 0) * v_trending_weight
        + coalesce(m.engagement_score, 0) * 0.05
        + greatest(
            0,
            40 - (
              extract(epoch from (now() - coalesce(m.published_at, m.created_at)))
              / 3600 / v_freshness_hours * 40
            )
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
     and (not p_popular or m.total_votes > 0)
  ),
  limited as (
    select *
      from scored
     order by
       case
         when p_popular then total_votes::numeric
         else recommendation_score
       end desc,
       engagement_score desc,
       published_at desc nulls last,
       created_at desc
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

grant execute on function public.get_recommended_home_feed(
  uuid,
  integer,
  boolean
) to authenticated;
