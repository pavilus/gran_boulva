-- Badge System polish: updated names, icons, and per-badge level thresholds.

insert into public.badges
  (key, name_ht, name_en, description_ht, description_en, icon_asset, color_hex, sort_order, is_active)
values
  (
    'top_voter',
    'Top Votè',
    'Top Voter',
    'Vote sou matchups pou monte nivo ou.',
    'Vote on matchups to level up.',
    'assets/images/topvotè.png',
    '#A855F7',
    1,
    true
  ),
  (
    'hot_streak',
    'San Kanpe',
    'Hot Streak',
    'Kenbe aktivite ou vivan chak jou.',
    'Keep your participation streak alive.',
    'assets/images/sankanpe.png',
    '#F97316',
    2,
    true
  ),
  (
    'debater',
    'Gran Debatè',
    'Debater',
    'Ekri agiman ki fè diskisyon an pi rich.',
    'Post arguments that strengthen the debate.',
    'assets/images/grandebatè.png',
    '#3B82F6',
    3,
    true
  ),
  (
    'consistent',
    'Konsistan',
    'Consistent',
    'Patisipe regilyèman semèn apre semèn.',
    'Participate reliably week after week.',
    'assets/images/konsistan.png',
    '#22C55E',
    4,
    true
  ),
  (
    'community',
    'Gran Sipòtè',
    'Great Supporter',
    'Sipòte lòt moun epi fè kominote a grandi.',
    'Support others and help the community grow.',
    'assets/images/sipote.png',
    '#D90C82',
    5,
    true
  )
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
from thresholds t
join public.badges b on b.key = t.badge_key
on conflict (badge_id, level) do update
set required_xp = excluded.required_xp,
    title_ht = excluded.title_ht,
    title_en = excluded.title_en,
    influence_reward = excluded.influence_reward;

update public.user_badges ub
set current_level = computed.level,
    updated_at = now()
from (
  select
    ub2.id,
    coalesce(max(bl.level), 0) as level
  from public.user_badges ub2
  left join public.badge_levels bl
    on bl.badge_id = ub2.badge_id
   and bl.required_xp <= ub2.current_xp
  group by ub2.id
) computed
where computed.id = ub.id
  and ub.current_level is distinct from computed.level;
