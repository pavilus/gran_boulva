-- ─────────────────────────────────────────────────────────────────────────────
-- 20260522000600_streak_recovery_system
-- Adds streak_recoveries table, expands coin_transactions types,
-- seeds streak_recovery_settings, and creates recovery RPCs.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. streak_recoveries table ───────────────────────────────────────────────
create table if not exists public.streak_recoveries (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null references public.users(id) on delete cascade,
  streak_length_at_recovery integer not null,
  coins_spent              integer not null,
  recovered_at             timestamptz not null default now(),
  recovered_date           date not null
);

alter table public.streak_recoveries enable row level security;

create policy "Users see own recoveries"
  on public.streak_recoveries
  for select
  using (user_id = (select id from public.users where auth_user_id = auth.uid()));

create index if not exists streak_recoveries_user_id_idx
  on public.streak_recoveries(user_id);

grant select on public.streak_recoveries to authenticated;
grant all   on public.streak_recoveries to service_role;

-- ── 2. Expand coin_transactions transaction_type constraint ───────────────────
alter table public.coin_transactions
  drop constraint if exists coin_transactions_transaction_type_check;

alter table public.coin_transactions
  add constraint coin_transactions_transaction_type_check
  check (transaction_type = any(array[
    'purchase',
    'boost',
    'boost_spend',
    'argument_support',
    'referral_reward',
    'transfer',
    'admin_reward',
    'refund',
    'signup_bonus',
    'daily_claim',
    'vote_spend',
    'vote_change_spend',
    'argument_post_spend',
    'streak_recovery',
    'cosmetic_purchase'
  ]));

-- ── 3. App settings: streak recovery ─────────────────────────────────────────
insert into public.app_settings (key, value)
values (
  'streak_recovery_settings',
  '{"windowHours":24,"costs":{"min3":25,"min8":50,"min31":100,"min91":250}}'::jsonb
)
on conflict (key) do nothing;

-- ── 4. RPC: get_streak_recovery_status ───────────────────────────────────────
create or replace function public.get_streak_recovery_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id        uuid;
  v_streak         integer;
  v_longest        integer;
  v_last_claim     date;
  v_last_claim_at  timestamptz;
  v_eligible       boolean;
  v_cost           integer;
  v_already        boolean;
  v_settings       jsonb;
  v_costs          jsonb;
begin
  -- resolve user
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid();

  if v_user_id is null then
    return jsonb_build_object(
      'current_streak',       0,
      'longest_streak',       0,
      'last_claim_date',      null,
      'is_recovery_eligible', false,
      'recovery_cost',        0,
      'already_recovered',    false
    );
  end if;

  -- fetch streak data
  select streak_count, last_claim_date
  into v_streak, v_last_claim
  from public.user_daily_coin_claims
  where user_id = v_user_id;

  if v_streak is null then
    v_streak     := 0;
    v_last_claim := null;
  end if;

  -- longest streak: we track streak_count as current; use it as best proxy
  v_longest := v_streak;

  -- eligibility: missed exactly yesterday (last_claim_date = today - 2)
  -- AND streak >= 3 AND not already recovered today (for yesterday)
  v_eligible := false;
  v_cost      := 0;

  if v_streak >= 3 and v_last_claim = current_date - 2 then
    -- check not already recovered yesterday's date today
    select exists(
      select 1 from public.streak_recoveries
      where user_id      = v_user_id
        and recovered_date = current_date - 1
    ) into v_already;

    if not v_already then
      v_eligible := true;
      -- determine cost from settings
      select value into v_settings
      from public.app_settings
      where key = 'streak_recovery_settings';

      v_costs := coalesce(v_settings->'costs',
        '{"min3":25,"min8":50,"min31":100,"min91":250}'::jsonb);

      if    v_streak >= 91 then v_cost := (v_costs->>'min91')::integer;
      elsif v_streak >= 31 then v_cost := (v_costs->>'min31')::integer;
      elsif v_streak >= 8  then v_cost := (v_costs->>'min8')::integer;
      else                      v_cost := (v_costs->>'min3')::integer;
      end if;
    end if;
  else
    -- already_recovered is irrelevant when not eligible; default false
    select exists(
      select 1 from public.streak_recoveries
      where user_id      = v_user_id
        and recovered_date = current_date - 1
    ) into v_already;
  end if;

  return jsonb_build_object(
    'current_streak',       v_streak,
    'longest_streak',       v_longest,
    'last_claim_date',      v_last_claim,
    'is_recovery_eligible', v_eligible,
    'recovery_cost',        v_cost,
    'already_recovered',    coalesce(v_already, false)
  );
end;
$$;

grant execute on function public.get_streak_recovery_status() to authenticated;

-- ── 5. RPC: recover_streak ───────────────────────────────────────────────────
create or replace function public.recover_streak()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id    uuid;
  v_streak     integer;
  v_last_claim date;
  v_balance    integer;
  v_cost       integer;
  v_settings   jsonb;
  v_costs      jsonb;
  v_eligible   boolean;
  v_already    boolean;
begin
  -- resolve user
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid();

  if v_user_id is null then
    return '{"ok":false,"error":"User not found"}'::jsonb;
  end if;

  -- fetch streak
  select streak_count, last_claim_date
  into v_streak, v_last_claim
  from public.user_daily_coin_claims
  where user_id = v_user_id;

  if v_streak is null then
    return '{"ok":false,"error":"No streak to recover"}'::jsonb;
  end if;

  -- eligibility check
  if v_streak < 3 then
    return '{"ok":false,"error":"Streak too short to recover"}'::jsonb;
  end if;

  if v_last_claim != current_date - 2 then
    return '{"ok":false,"error":"Not eligible for recovery"}'::jsonb;
  end if;

  -- check not already recovered
  select exists(
    select 1 from public.streak_recoveries
    where user_id      = v_user_id
      and recovered_date = current_date - 1
  ) into v_already;

  if v_already then
    return '{"ok":false,"error":"Already recovered today"}'::jsonb;
  end if;

  -- determine cost
  select value into v_settings
  from public.app_settings
  where key = 'streak_recovery_settings';

  v_costs := coalesce(v_settings->'costs',
    '{"min3":25,"min8":50,"min31":100,"min91":250}'::jsonb);

  if    v_streak >= 91 then v_cost := (v_costs->>'min91')::integer;
  elsif v_streak >= 31 then v_cost := (v_costs->>'min31')::integer;
  elsif v_streak >= 8  then v_cost := (v_costs->>'min8')::integer;
  else                      v_cost := (v_costs->>'min3')::integer;
  end if;

  -- check balance
  select coin_balance into v_balance
  from public.users
  where id = v_user_id;

  if v_balance < v_cost then
    return '{"ok":false,"error":"Insufficient coins"}'::jsonb;
  end if;

  -- deduct coins
  update public.users
  set coin_balance = coin_balance - v_cost
  where id = v_user_id;

  -- log transaction
  insert into public.coin_transactions
    (user_id, amount, transaction_type, description)
  values
    (v_user_id, -v_cost, 'streak_recovery', 'Streak recovery — day ' || v_streak);

  -- record recovery event
  insert into public.streak_recoveries
    (user_id, streak_length_at_recovery, coins_spent, recovered_date)
  values
    (v_user_id, v_streak, v_cost, current_date - 1);

  -- update claims: set last_claim_date to yesterday so next claim continues streak
  update public.user_daily_coin_claims
  set last_claim_date = current_date - 1
  where user_id = v_user_id;

  return jsonb_build_object(
    'ok',          true,
    'new_streak',  v_streak,
    'coins_spent', v_cost
  );
end;
$$;

grant execute on function public.recover_streak() to authenticated;
