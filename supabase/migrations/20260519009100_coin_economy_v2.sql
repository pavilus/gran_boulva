-- ============================================================
-- Boulva Coin Economy v2
-- Migration: 20260519009100_coin_economy_v2.sql
-- ============================================================
-- Changes:
--   1. Fix coinToUsdRate: 0.001 → 0.006 (100 coins = $0.60)
--   2. Fix coin packs to match spec (100/550/1200/2500/7000)
--   3. Fix support amounts → support level system
--   4. Tier 1 (Rising Creator) gets 60% revenue share
--   5. Min payout → $25 (≈ 4167 coins)
--   6. New table: coin_support_levels
--   7. New table: gifting_events
--   8. New table: fraud_events
--   9. Add wallet_usd_balance + risk_score to creator_profiles
--  10. Updated RPCs: record_creator_revenue, refresh_creator_tier
--  11. New RPCs: get_top_supporters, get_public_gifting_feed
-- ============================================================

-- ── 1. Fix payout_settings ────────────────────────────────────
update public.app_settings
set value = jsonb_build_object(
  'coinToUsdRate',      0.006,
  'minPayoutCoins',     4167,
  'minPayoutUsd',       25,
  'payoutMode',         coalesce(value->>'payoutMode', 'manual'),
  'moncashEnvironment', coalesce(value->>'moncashEnvironment', 'sandbox'),
  'moncashEnabled',     coalesce((value->>'moncashEnabled')::boolean, false)
),
updated_at = now()
where key = 'payout_settings';

-- ── 2. Fix coin_economy — packs + support amounts ─────────────
update public.app_settings
set value = value
  || jsonb_build_object(
    'supportAmounts', '[50, 250, 1000, 5000, 10000]'::jsonb,
    'coinPacks', '[
      {"coins": 100,  "price": 99,   "label": "$0.99",  "savings": "",          "popular": false, "bonus": 0},
      {"coins": 550,  "price": 499,  "label": "$4.99",  "savings": "9% ekonomi","popular": false, "bonus": 0},
      {"coins": 1200, "price": 999,  "label": "$9.99",  "savings": "16% ekonomi","popular": true,  "bonus": 0},
      {"coins": 2500, "price": 1999, "label": "$19.99", "savings": "19% ekonomi","popular": false, "bonus": 0},
      {"coins": 7000, "price": 4999, "label": "$49.99", "savings": "29% ekonomi","popular": false, "bonus": 0}
    ]'::jsonb
  ),
updated_at = now()
where key = 'coin_economy';

-- ── 3. coin_support_levels ─────────────────────────────────────
create table if not exists public.coin_support_levels (
  id              uuid    primary key default gen_random_uuid(),
  coins           integer not null unique,
  label_ht        text    not null,
  label_en        text    not null,
  emoji           text    not null default '💙',
  color_hex       text    not null default '#3B82F6',
  animation_intensity integer not null default 1 check (animation_intensity between 1 and 5),
  feed_message_ht text    not null default '',
  sort_order      integer not null default 0,
  is_active       boolean not null default true
);

insert into public.coin_support_levels
  (coins, label_ht, label_en, emoji, color_hex, animation_intensity, feed_message_ht, sort_order)
values
  (50,    'Sipò Rapid',     'Quick Support',      '💙', '#3B82F6', 1, 'voye yon sipò rapid',     1),
  (250,   'Sipò Solid',     'Strong Support',     '💜', '#A855F7', 2, 'voye yon sipò solid',     2),
  (1000,  'Gran Sipò',      'Major Support',      '💛', '#EAB308', 3, 'voye yon gran sipò',      3),
  (5000,  'Sipòtè Elit',    'Elite Supporter',    '🧡', '#F97316', 4, 'voye yon sipò elit',      4),
  (10000, 'Soutyen Legendè','Legendary Support',  '❤️', '#EF4444', 5, 'voye yon soutyen legendè',5)
on conflict (coins) do update
  set label_ht = excluded.label_ht,
      label_en = excluded.label_en,
      emoji    = excluded.emoji,
      color_hex = excluded.color_hex,
      animation_intensity = excluded.animation_intensity,
      feed_message_ht = excluded.feed_message_ht;

-- ── 4. gifting_events ─────────────────────────────────────────
create table if not exists public.gifting_events (
  id                uuid        primary key default gen_random_uuid(),
  giver_user_id     uuid        not null references public.users(id) on delete cascade,
  receiver_user_id  uuid        not null references public.users(id) on delete cascade,
  coins_amount      integer     not null check (coins_amount > 0),
  support_level_id  uuid        references public.coin_support_levels(id),
  context_type      text        not null default 'creator',
  -- context_type: 'creator' | 'argument' | 'matchup' | 'prediction'
  context_id        uuid,
  is_public         boolean     not null default true,
  feed_message      text,
  created_at        timestamptz not null default now()
);

create index if not exists gifting_events_receiver_idx
  on public.gifting_events (receiver_user_id, created_at desc);
create index if not exists gifting_events_giver_idx
  on public.gifting_events (giver_user_id, created_at desc);
create index if not exists gifting_events_public_idx
  on public.gifting_events (created_at desc) where is_public = true;

-- ── 5. fraud_events ───────────────────────────────────────────
create table if not exists public.fraud_events (
  id            uuid        primary key default gen_random_uuid(),
  user_id       uuid        not null references public.users(id) on delete cascade,
  event_type    text        not null,
  -- event_type: 'self_gift_attempt' | 'rapid_gifting' | 'suspicious_ring'
  --             | 'chargeback' | 'bot_pattern' | 'high_velocity'
  severity      integer     not null default 1 check (severity between 1 and 5),
  details       jsonb       not null default '{}',
  resolved      boolean     not null default false,
  created_at    timestamptz not null default now()
);

create index if not exists fraud_events_user_idx
  on public.fraud_events (user_id, created_at desc);
create index if not exists fraud_events_unresolved_idx
  on public.fraud_events (created_at desc) where resolved = false;

-- ── 6. Enhance creator_profiles ───────────────────────────────
alter table public.creator_profiles
  add column if not exists wallet_usd_balance numeric(12,4) not null default 0,
  add column if not exists risk_score         integer       not null default 0
    check (risk_score between 0 and 100);

-- ── 7. Updated record_creator_revenue ─────────────────────────
-- Now reads coinToUsdRate from app_settings and stores USD wallet value.
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
  v_rate           numeric(3,2) := 0.00;
  v_enabled        boolean      := false;
  v_suspended      boolean      := true;
  v_creator_coins  bigint;
  v_platform_coins bigint;
  v_usd_rate       numeric      := 0.006;
  v_creator_usd    numeric;
begin
  -- Get creator's current rate and monetization status
  select revenue_share_rate, is_monetization_enabled, monetization_suspended
  into v_rate, v_enabled, v_suspended
  from public.creator_profiles
  where user_id = p_creator_id;

  if not found or not v_enabled or v_suspended then return; end if;
  if v_rate = 0 then return; end if;

  -- Read coinToUsdRate from settings
  select coalesce((value->>'coinToUsdRate')::numeric, 0.006)
  into v_usd_rate
  from public.app_settings
  where key = 'payout_settings';

  v_creator_coins  := floor(p_gross_coins * v_rate)::bigint;
  v_platform_coins := p_gross_coins - v_creator_coins;
  v_creator_usd    := v_creator_coins * v_usd_rate;

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

  -- Update profile totals (coins + USD wallet)
  update public.creator_profiles
  set
    total_earned_coins   = total_earned_coins + v_creator_coins,
    pending_payout_coins = pending_payout_coins + v_creator_coins,
    wallet_usd_balance   = wallet_usd_balance + v_creator_usd,
    updated_at           = now()
  where user_id = p_creator_id;
end;
$$;

-- ── 8. Updated refresh_creator_tier — Tier 1 now at 60% ───────
create or replace function public.refresh_creator_tier(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_score         integer;
  v_new_tier      integer;
  v_current_tier  integer;
  v_followers     integer;
  v_verification  text;
  v_verif_status  text;
  v_share_rate    numeric(3,2);
  v_monetization  boolean;
begin
  v_score := public.calculate_creator_score(p_user_id);

  select
    coalesce(followers_count, 0),
    coalesce(verification_type, ''),
    coalesce(verification_status, 'none')
  into v_followers, v_verification, v_verif_status
  from public.users where id = p_user_id;

  insert into public.creator_profiles (user_id, creator_tier, creator_score)
  values (p_user_id, 0, v_score)
  on conflict (user_id) do nothing;

  select creator_tier into v_current_tier
  from public.creator_profiles where user_id = p_user_id;

  v_new_tier := v_current_tier;

  -- 0 → 1 Rising: score >= 15 AND followers >= 10
  if v_current_tier = 0 and v_score >= 15 and v_followers >= 10 then
    v_new_tier := 1;
  end if;

  -- 1 → 2 Verified Creator: approved verification + score >= 35
  if v_current_tier <= 1
    and v_verif_status = 'approved'
    and v_verification in ('trusted_creator', 'public_figure', 'organization')
    and v_score >= 35
  then
    v_new_tier := 2;
  end if;

  -- Tiers 3 and 4 require admin confirmation

  -- Revenue share rates (spec-aligned)
  case v_new_tier
    when 1 then v_share_rate := 0.60; v_monetization := true;   -- Rising: 60%
    when 2 then v_share_rate := 0.70; v_monetization := true;   -- Verified: 70%
    when 3 then v_share_rate := 0.80; v_monetization := true;   -- Elite: 80%
    when 4 then v_share_rate := null; v_monetization := true;   -- Icon: custom
    else         v_share_rate := 0.00; v_monetization := false;
  end case;

  update public.creator_profiles
  set
    creator_score      = v_score,
    creator_tier       = v_new_tier,
    score_updated_at   = now(),
    tier_updated_at    = case when v_new_tier <> v_current_tier then now() else tier_updated_at end,
    revenue_share_rate = case
      when v_new_tier = 4 then revenue_share_rate  -- keep custom
      else coalesce(v_share_rate, 0.00)
    end,
    is_monetization_enabled = case
      when monetization_suspended then false
      else v_monetization
    end,
    updated_at = now()
  where user_id = p_user_id;

  -- Notify on tier upgrade
  if v_new_tier > v_current_tier then
    insert into public.notifications (user_id, type, title, body)
    values (
      p_user_id,
      'system',
      case v_new_tier
        when 1 then '🌱 Ou tounen Kreyatè Monte!'
        when 2 then '✅ Ou tounen Kreyatè Verifye!'
        when 3 then '⚡ Ou tounen Kreyatè Elit!'
        when 4 then '👑 Ou tounen Ikòn Kiltirèl!'
        else 'Nivo kreyatè ou chanje'
      end,
      case v_new_tier
        when 1 then 'Felisitasyon! Ou kounye a nan Nivo 1 — Kreyatè Monte. Ou ka touche 60% nan revni ou yo.'
        when 2 then 'Felisitasyon! Ou kounye a nan Nivo 2 — Kreyatè Verifye ak 70% revni.'
        when 3 then 'Ou rive nan somè a! Nivo 3 — Kreyatè Elit ak 80% revni.'
        when 4 then 'Ou se yon Ikòn Kiltirèl Gran Boulva. Mèsi pou enfliyans ou.'
        else ''
      end
    );
  end if;

  return v_new_tier;
end;
$$;

-- ── 9. Updated get_creator_dashboard — add USD wallet ─────────
create or replace function public.get_creator_dashboard(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile      record;
  v_user         record;
  v_revenue_30d  bigint;
  v_revenue_7d   bigint;
  v_supporters   bigint;
  v_usd_7d       numeric;
  v_usd_30d      numeric;
  v_usd_rate     numeric := 0.006;
begin
  insert into public.creator_profiles (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select * into v_profile from public.creator_profiles where user_id = p_user_id;
  select followers_count, participation_count, victory_count,
         total_support_received, influence_score
  into v_user from public.users where id = p_user_id;

  -- Read current USD rate
  select coalesce((value->>'coinToUsdRate')::numeric, 0.006)
  into v_usd_rate
  from public.app_settings where key = 'payout_settings';

  select coalesce(sum(creator_coins), 0)
  into v_revenue_30d
  from public.creator_revenue_events
  where creator_user_id = p_user_id
    and created_at >= now() - interval '30 days';

  select coalesce(sum(creator_coins), 0)
  into v_revenue_7d
  from public.creator_revenue_events
  where creator_user_id = p_user_id
    and created_at >= now() - interval '7 days';

  v_usd_7d  := v_revenue_7d  * v_usd_rate;
  v_usd_30d := v_revenue_30d * v_usd_rate;

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
    'risk_score',              v_profile.risk_score,
    'is_monetization_enabled', v_profile.is_monetization_enabled,
    'revenue_share_rate',      v_profile.revenue_share_rate,
    'total_earned_coins',      v_profile.total_earned_coins,
    'pending_payout_coins',    v_profile.pending_payout_coins,
    'total_paid_out_coins',    v_profile.total_paid_out_coins,
    'wallet_usd_balance',      v_profile.wallet_usd_balance,
    'revenue_last_7d',         v_revenue_7d,
    'revenue_last_30d',        v_revenue_30d,
    'usd_last_7d',             v_usd_7d,
    'usd_last_30d',            v_usd_30d,
    'unique_supporters_30d',   v_supporters,
    'followers_count',         coalesce(v_user.followers_count, 0),
    'participation_count',     coalesce(v_user.participation_count, 0),
    'victory_count',           coalesce(v_user.victory_count, 0),
    'total_support_received',  coalesce(v_user.total_support_received, 0),
    'influence_score',         coalesce(v_user.influence_score, 0),
    'coin_to_usd_rate',        v_usd_rate
  );
end;
$$;

-- ── 10. get_top_supporters(creator_id, limit) ─────────────────
create or replace function public.get_top_supporters(
  p_creator_id uuid,
  p_limit      integer default 5
)
returns table (
  giver_user_id uuid,
  username      text,
  avatar_url    text,
  total_coins   bigint,
  gift_count    bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    ge.giver_user_id,
    u.username,
    u.avatar_url,
    sum(ge.coins_amount)::bigint as total_coins,
    count(*)::bigint             as gift_count
  from public.gifting_events ge
  join public.users u on u.id = ge.giver_user_id
  where ge.receiver_user_id = p_creator_id
    and ge.created_at >= now() - interval '30 days'
  group by ge.giver_user_id, u.username, u.avatar_url
  order by sum(ge.coins_amount) desc
  limit p_limit;
end;
$$;

-- ── 11. get_public_gifting_feed(limit) ────────────────────────
create or replace function public.get_public_gifting_feed(
  p_limit integer default 20
)
returns table (
  id               uuid,
  giver_username   text,
  giver_avatar     text,
  receiver_username text,
  coins_amount     integer,
  feed_message     text,
  emoji            text,
  color_hex        text,
  created_at       timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    ge.id,
    ug.username   as giver_username,
    ug.avatar_url as giver_avatar,
    ur.username   as receiver_username,
    ge.coins_amount,
    ge.feed_message,
    coalesce(sl.emoji, '💙')    as emoji,
    coalesce(sl.color_hex, '#3B82F6') as color_hex,
    ge.created_at
  from public.gifting_events ge
  join public.users ug on ug.id = ge.giver_user_id
  join public.users ur on ur.id = ge.receiver_user_id
  left join public.coin_support_levels sl on sl.id = ge.support_level_id
  where ge.is_public = true
  order by ge.created_at desc
  limit p_limit;
end;
$$;

-- ── 12. gift_coins RPC ────────────────────────────────────────
-- Central gifting function called by the app. Deducts coins from giver,
-- triggers revenue split, logs gifting_event, sends notifications.
create or replace function public.gift_coins(
  p_receiver_id    uuid,
  p_coins          integer,
  p_context_type   text    default 'creator',
  p_context_id     uuid    default null,
  p_is_public      boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_giver_id     uuid;
  v_giver_coins  integer;
  v_level        record;
  v_event_id     uuid;
  v_feed_msg     text;
begin
  v_giver_id := public.current_app_user_id();
  if v_giver_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Block self-gifting
  if v_giver_id = p_receiver_id then
    raise exception 'Ou pa ka voye coins bay tèt ou';
  end if;

  -- Check balance
  select coin_balance into v_giver_coins
  from public.users where id = v_giver_id;

  if v_giver_coins < p_coins then
    raise exception 'Balans pa sifi';
  end if;

  -- Deduct from giver
  update public.users
  set coin_balance = coin_balance - p_coins, updated_at = now()
  where id = v_giver_id;

  -- Credit receiver
  update public.users
  set coin_balance          = coin_balance + p_coins,
      total_support_received = total_support_received + p_coins,
      updated_at             = now()
  where id = p_receiver_id;

  -- Log coin_transaction (triggers revenue split via existing trigger)
  insert into public.coin_transactions (
    user_id, recipient_user_id, type, amount, description
  ) values (
    v_giver_id, p_receiver_id, 'support', p_coins, 'gift_coins'
  );

  -- Find matching support level
  select * into v_level
  from public.coin_support_levels
  where coins <= p_coins and is_active = true
  order by coins desc
  limit 1;

  -- Build feed message
  select u.username into v_feed_msg from public.users u where u.id = v_giver_id;
  v_feed_msg := '@' || v_feed_msg || ' ' || coalesce(v_level.feed_message_ht, 'voye yon sipò');

  -- Log gifting event
  insert into public.gifting_events (
    giver_user_id, receiver_user_id, coins_amount,
    support_level_id, context_type, context_id,
    is_public, feed_message
  ) values (
    v_giver_id, p_receiver_id, p_coins,
    v_level.id, p_context_type, p_context_id,
    p_is_public, v_feed_msg
  ) returning id into v_event_id;

  -- Notify receiver
  insert into public.notifications (user_id, type, title, body, related_table, related_id)
  values (
    p_receiver_id,
    'coin_gift',
    coalesce(v_level.emoji, '💙') || ' ' || coalesce(v_level.label_ht, 'Sipò'),
    v_feed_msg || ' — ' || p_coins || ' Boulva Coins',
    'gifting_events',
    v_event_id
  );

  return jsonb_build_object(
    'ok', true,
    'event_id', v_event_id,
    'level_label', coalesce(v_level.label_ht, ''),
    'level_emoji', coalesce(v_level.emoji, '💙'),
    'animation_intensity', coalesce(v_level.animation_intensity, 1)
  );
end;
$$;

-- ── 13. RLS ───────────────────────────────────────────────────
alter table public.coin_support_levels enable row level security;
alter table public.gifting_events enable row level security;
alter table public.fraud_events enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where tablename='coin_support_levels'
    and policyname='Anyone can read support levels') then
    create policy "Anyone can read support levels"
    on public.coin_support_levels for select using (is_active = true);
  end if;

  if not exists (select 1 from pg_policies where tablename='gifting_events'
    and policyname='Anyone can read public gifting events') then
    create policy "Anyone can read public gifting events"
    on public.gifting_events for select using (is_public = true);
  end if;

  if not exists (select 1 from pg_policies where tablename='gifting_events'
    and policyname='Users can read own gifting events') then
    create policy "Users can read own gifting events"
    on public.gifting_events for select
    using (giver_user_id = public.current_app_user_id()
        or receiver_user_id = public.current_app_user_id());
  end if;
end $$;

-- ── 14. Grants ────────────────────────────────────────────────
grant select on public.coin_support_levels to authenticated, anon;
grant select on public.gifting_events to authenticated, anon;
grant all on public.coin_support_levels to service_role;
grant all on public.gifting_events to service_role;
grant all on public.fraud_events to service_role;

grant execute on function public.gift_coins(uuid,integer,text,uuid,boolean)  to authenticated;
grant execute on function public.get_top_supporters(uuid,integer)            to authenticated, anon;
grant execute on function public.get_public_gifting_feed(integer)            to authenticated, anon;
grant execute on function public.get_creator_dashboard(uuid)                 to authenticated, service_role;
grant execute on function public.record_creator_revenue(uuid,uuid,text,bigint,text,uuid) to service_role;
