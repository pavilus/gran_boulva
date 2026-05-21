update public.app_settings
   set value = value
     || jsonb_build_object(
       'signupBonus', coalesce((value ->> 'signupBonus')::integer, 5),
       'dailyClaimBase', coalesce((value ->> 'dailyClaimBase')::integer, 2),
       'dailyStreakBonus', coalesce((value ->> 'dailyStreakBonus')::integer, 1),
       'dailyClaimMax', coalesce((value ->> 'dailyClaimMax')::integer, 10)
     ),
       updated_at = now()
 where key = 'coin_economy';

create table if not exists public.user_daily_coin_claims (
  user_id uuid primary key references public.users(id) on delete cascade,
  last_claim_date date,
  streak_count integer not null default 0,
  total_claimed integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.user_daily_coin_claims enable row level security;

drop policy if exists "Users can read their own daily coin claims" on public.user_daily_coin_claims;
create policy "Users can read their own daily coin claims"
  on public.user_daily_coin_claims
  for select
  to authenticated
  using (
    exists (
      select 1
        from public.users u
       where u.id = user_daily_coin_claims.user_id
         and u.auth_user_id = auth.uid()
    )
  );

drop policy if exists "Service role can manage daily coin claims" on public.user_daily_coin_claims;
create policy "Service role can manage daily coin claims"
  on public.user_daily_coin_claims
  for all
  to service_role
  using (true)
  with check (true);

create or replace function public.award_signup_coin_bonus()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bonus integer;
begin
  v_bonus := public._coin_economy_int('signupBonus', 5);

  if v_bonus <= 0 then
    return new;
  end if;

  update public.users
     set coin_balance = coalesce(coin_balance, 0) + v_bonus
   where id = new.id;

  insert into public.coin_transactions (
    to_user_id,
    amount,
    fee,
    transaction_type,
    status
  )
  values (
    new.id,
    v_bonus,
    0,
    'signup_bonus',
    'completed'
  );

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
    new.id,
    'coins',
    'Byenvini sou Gran Boulva',
    'Ou resevwa ' || v_bonus || ' Boulva Coins pou kòmanse.',
    'coin_transactions',
    new.id,
    false
  );

  return new;
end;
$$;

drop trigger if exists users_award_signup_coin_bonus on public.users;
create trigger users_award_signup_coin_bonus
after insert on public.users
for each row
execute function public.award_signup_coin_bonus();

create or replace function public.get_daily_coin_claim_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_claim public.user_daily_coin_claims%rowtype;
  v_today date := current_date;
  v_base integer := public._coin_economy_int('dailyClaimBase', 2);
  v_streak_bonus integer := public._coin_economy_int('dailyStreakBonus', 1);
  v_max integer := public._coin_economy_int('dailyClaimMax', 10);
  v_next_streak integer;
  v_amount integer;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select *
    into v_claim
    from public.user_daily_coin_claims
   where user_id = v_user_id;

  v_next_streak := case
    when v_claim.last_claim_date = v_today - 1 then coalesce(v_claim.streak_count, 0) + 1
    when v_claim.last_claim_date = v_today then coalesce(v_claim.streak_count, 0)
    else 1
  end;
  v_amount := least(v_max, v_base + greatest(v_next_streak - 1, 0) * v_streak_bonus);

  return jsonb_build_object(
    'can_claim', coalesce(v_claim.last_claim_date <> v_today, true),
    'today_amount', greatest(v_amount, 0),
    'streak_count', coalesce(v_claim.streak_count, 0),
    'next_streak_count', v_next_streak,
    'last_claim_date', v_claim.last_claim_date,
    'daily_claim_base', v_base,
    'daily_streak_bonus', v_streak_bonus,
    'daily_claim_max', v_max
  );
end;
$$;

create or replace function public.claim_daily_coin_reward()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_claim public.user_daily_coin_claims%rowtype;
  v_today date := current_date;
  v_base integer := public._coin_economy_int('dailyClaimBase', 2);
  v_streak_bonus integer := public._coin_economy_int('dailyStreakBonus', 1);
  v_max integer := public._coin_economy_int('dailyClaimMax', 10);
  v_streak integer;
  v_amount integer;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select *
    into v_claim
    from public.user_daily_coin_claims
   where user_id = v_user_id
   for update;

  if v_claim.last_claim_date = v_today then
    return public.get_daily_coin_claim_status()
      || jsonb_build_object('claimed', false, 'amount', 0);
  end if;

  v_streak := case
    when v_claim.last_claim_date = v_today - 1 then coalesce(v_claim.streak_count, 0) + 1
    else 1
  end;
  v_amount := greatest(least(v_max, v_base + greatest(v_streak - 1, 0) * v_streak_bonus), 0);

  if v_amount <= 0 then
    raise exception 'Daily reward is disabled';
  end if;

  update public.users
     set coin_balance = coalesce(coin_balance, 0) + v_amount
   where id = v_user_id;

  insert into public.user_daily_coin_claims (
    user_id,
    last_claim_date,
    streak_count,
    total_claimed,
    updated_at
  )
  values (
    v_user_id,
    v_today,
    v_streak,
    v_amount,
    now()
  )
  on conflict (user_id) do update
    set last_claim_date = excluded.last_claim_date,
        streak_count = excluded.streak_count,
        total_claimed = public.user_daily_coin_claims.total_claimed + excluded.total_claimed,
        updated_at = now();

  insert into public.coin_transactions (
    to_user_id,
    amount,
    fee,
    transaction_type,
    status
  )
  values (
    v_user_id,
    v_amount,
    0,
    'daily_claim',
    'completed'
  );

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
    'coins',
    'Rekonpans chak jou',
    'Ou reklame ' || v_amount || ' Boulva Coins. Streak ou: ' || v_streak || ' jou.',
    'coin_transactions',
    v_user_id,
    false
  );

  return jsonb_build_object(
    'claimed', true,
    'amount', v_amount,
    'can_claim', false,
    'today_amount', v_amount,
    'streak_count', v_streak,
    'next_streak_count', v_streak + 1,
    'last_claim_date', v_today
  );
end;
$$;

grant execute on function public.get_daily_coin_claim_status() to authenticated;
grant execute on function public.claim_daily_coin_reward() to authenticated;
