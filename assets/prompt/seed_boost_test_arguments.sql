-- BoostSystem test seed
-- Run this in Supabase SQL Editor.
--
-- What it does:
-- 1. Picks the first 3 published matchups.
-- 2. Gives every user a vote in each selected matchup.
-- 3. Creates one fake active argument per user per selected matchup.
-- 4. Grants test Boulva Coins so users can test boosts/support.
-- 5. Recalculates visible vote/argument counters.
--
-- Safe to rerun: it will not duplicate the same user's fake argument
-- for the same matchup.

alter table public.users
add column if not exists coin_balance integer not null default 0,
add column if not exists total_coins_received integer not null default 0,
add column if not exists total_coins_spent integer not null default 0,
add column if not exists total_boosts_used integer not null default 0,
add column if not exists total_support_given integer not null default 0,
add column if not exists total_support_received integer not null default 0;

alter table public.arguments
add column if not exists support_count integer not null default 0,
add column if not exists support_coins integer not null default 0,
add column if not exists share_count integer not null default 0,
add column if not exists save_count integer not null default 0,
add column if not exists view_count integer not null default 0,
add column if not exists final_score numeric not null default 0;

alter table public.matchups
add column if not exists argument_count integer not null default 0;

-- Give all existing users enough test coins to boost/support.
update public.users
set coin_balance = greatest(coin_balance, 1000),
    total_coins_received = greatest(total_coins_received, 1000);

with target_matchups as (
  select id
  from public.matchups
  where status = 'published'
  order by coalesce(published_at, created_at) desc
  limit 3
),
users_to_seed as (
  select id, username
  from public.users
),
matchup_choices as (
  select
    tm.id as matchup_id,
    u.id as user_id,
    u.username,
    (
      select mo.id
      from public.matchup_options mo
      where mo.matchup_id = tm.id
      order by md5(u.id::text || tm.id::text || mo.id::text)
      limit 1
    ) as option_id,
    row_number() over (partition by tm.id order by u.username nulls last, u.id) as matchup_user_rank
  from target_matchups tm
  cross join users_to_seed u
),
seeded_votes as (
  insert into public.votes (user_id, matchup_id, option_id)
  select user_id, matchup_id, option_id
  from matchup_choices
  where option_id is not null
  on conflict (user_id, matchup_id)
  do update set option_id = excluded.option_id
  returning user_id, matchup_id, option_id
)
insert into public.arguments (
  user_id,
  matchup_id,
  option_id,
  body,
  like_count,
  dislike_count,
  reply_count,
  visibility_score,
  support_count,
  support_coins,
  view_count,
  status,
  created_at
)
select
  mc.user_id,
  mc.matchup_id,
  mc.option_id,
  case (mc.matchup_user_rank % 6)
    when 0 then 'Mwen kanpe sou pozisyon sa paske li gen plis lojik, plis prèv, epi li pi bon pou kominote a.'
    when 1 then 'Pou mwen, chwa sa pi solid. Lè ou gade enpak li sou moun yo, li klè li merite plis sipò.'
    when 2 then 'Mwen pa dakò ak lòt bò a. Agiman sa gen plis pwa paske li baze sou eksperyans reyèl.'
    when 3 then 'Sa se opinyon mwen: si nou vle bon rezilta, nou dwe chwazi bò ki bay plis valè alontèm.'
    when 4 then 'Mwen vote konsa paske li pi jis, pi pratik, epi li pi fasil pou moun konprann.'
    else 'Mwen panse agiman sa merite monte pi wo paske anpil moun ka aprann nan diskisyon sa.'
  end,
  2 + (mc.matchup_user_rank % 17),
  mc.matchup_user_rank % 4,
  1 + (mc.matchup_user_rank % 9),
  20 + (mc.matchup_user_rank * 3),
  mc.matchup_user_rank % 5,
  (mc.matchup_user_rank % 5) * 25,
  40 + (mc.matchup_user_rank * 11),
  'active',
  now() - ((mc.matchup_user_rank % 30)::integer * interval '1 hour')
from matchup_choices mc
where mc.option_id is not null
  and not exists (
    select 1
    from public.arguments a
    where a.user_id = mc.user_id
      and a.matchup_id = mc.matchup_id
  )
on conflict on constraint arguments_user_id_matchup_id_key do nothing;

-- Refresh matchup option vote counts.
update public.matchup_options mo
set vote_count = counts.vote_count
from (
  select option_id, count(*)::integer as vote_count
  from public.votes
  group by option_id
) counts
where mo.id = counts.option_id;

-- Reset options with no votes.
update public.matchup_options mo
set vote_count = 0
where not exists (
  select 1
  from public.votes v
  where v.option_id = mo.id
);

-- Refresh matchup totals and engagement counters.
update public.matchups m
set total_votes = coalesce(v.vote_count, 0),
    argument_count = coalesce(a.argument_count, 0),
    engagement_score =
      coalesce(v.vote_count, 0)
      + (coalesce(a.argument_count, 0) * 5)
from (
  select matchup_id, count(*)::integer as vote_count
  from public.votes
  group by matchup_id
) v
full join (
  select matchup_id, count(*)::integer as argument_count
  from public.arguments
  where status = 'active'
  group by matchup_id
) a on a.matchup_id = v.matchup_id
where m.id = coalesce(v.matchup_id, a.matchup_id);

-- Recalculate final_score for seeded/active arguments.
update public.arguments a
set final_score =
  case
    when a.boost_expires_at is not null and a.boost_expires_at > now() then 60
    else 0
  end
  + (coalesce(a.like_count, 0) * 2)
  + (coalesce(a.reply_count, 0) * 5)
  + (coalesce(a.share_count, 0) * 8)
  + (coalesce(a.save_count, 0) * 6)
  + (coalesce(a.support_coins, 0) * 0.3)
  + case
      when a.created_at >= now() - interval '2 hours' then 15
      when a.created_at >= now() - interval '12 hours' then 10
      when a.created_at >= now() - interval '24 hours' then 5
      else 0
    end,
    visibility_score = greatest(
      coalesce(a.visibility_score, 0),
      (
        (coalesce(a.like_count, 0) * 2)
        + (coalesce(a.reply_count, 0) * 5)
        + (coalesce(a.support_coins, 0) * 0.3)
      )::integer
    )
where a.status = 'active';

-- Quick verification.
select
  m.id,
  m.title_ht,
  m.total_votes,
  m.argument_count
from public.matchups m
where m.id in (
  select id
  from public.matchups
  where status = 'published'
  order by coalesce(published_at, created_at) desc
  limit 3
)
order by coalesce(m.published_at, m.created_at) desc;
