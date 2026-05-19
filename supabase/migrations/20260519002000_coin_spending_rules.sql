create or replace function public._coin_economy_int(p_key text, p_default integer default 0)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_value jsonb;
  v_result integer;
begin
  select value
    into v_value
    from public.app_settings
   where key = 'coin_economy';

  if v_value is null then
    return p_default;
  end if;

  v_result := nullif(v_value ->> p_key, '')::integer;
  return greatest(coalesce(v_result, p_default), 0);
exception
  when others then
    return p_default;
end;
$$;

create or replace function public._spend_user_coins(
  p_user_id uuid,
  p_amount integer,
  p_transaction_type text,
  p_reference_table text default null,
  p_reference_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance integer;
begin
  if coalesce(p_amount, 0) <= 0 then
    return;
  end if;

  select coalesce(coin_balance, 0)
    into v_balance
    from public.users
   where id = p_user_id
   for update;

  if v_balance is null then
    raise exception 'User profile not found';
  end if;

  if v_balance < p_amount then
    raise exception 'Balans coins ou pa sifi';
  end if;

update public.users
     set coin_balance = v_balance - p_amount,
         total_coins_spent = coalesce(total_coins_spent, 0) + p_amount
   where id = p_user_id;

  insert into public.coin_transactions (
    from_user_id,
    amount,
    fee,
    transaction_type,
    status
  )
  values (
    p_user_id,
    p_amount,
    0,
    p_transaction_type,
    'completed'
  );
end;
$$;

create or replace function public.submit_vote_and_argument_with_coins(
  p_matchup_id uuid,
  p_option_id uuid,
  p_argument_body text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_vote_cost integer;
  v_argument_cost integer;
  v_existing_vote_id uuid;
  v_existing_argument_id uuid;
  v_argument_id uuid;
  v_body text;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
      from public.matchup_options
     where id = p_option_id
       and matchup_id = p_matchup_id
  ) then
    raise exception 'Invalid matchup option';
  end if;

  v_body := btrim(coalesce(p_argument_body, ''));
  if v_body = '' then
    raise exception 'Argument is required';
  end if;

  select id
    into v_existing_vote_id
    from public.votes
   where user_id = v_user_id
     and matchup_id = p_matchup_id
   limit 1;

  select id
    into v_existing_argument_id
    from public.arguments
   where user_id = v_user_id
     and matchup_id = p_matchup_id
     and status = 'active'
   limit 1;

  v_vote_cost := case
    when v_existing_vote_id is null then public._coin_economy_int('coinsPerVote', 0)
    else 0
  end;
  v_argument_cost := case
    when v_existing_argument_id is null then public._coin_economy_int('coinsPerArgument', 0)
    else 0
  end;

  perform public._spend_user_coins(
    v_user_id,
    v_vote_cost,
    'vote_spend',
    'matchups',
    p_matchup_id
  );

  perform public._spend_user_coins(
    v_user_id,
    v_argument_cost,
    'argument_post_spend',
    'matchups',
    p_matchup_id
  );

  insert into public.votes (
    user_id,
    matchup_id,
    option_id
  )
  values (
    v_user_id,
    p_matchup_id,
    p_option_id
  )
  on conflict (user_id, matchup_id) do update
    set option_id = excluded.option_id;

  if v_existing_argument_id is null then
    insert into public.arguments (
      user_id,
      matchup_id,
      option_id,
      body,
      status
    )
    values (
      v_user_id,
      p_matchup_id,
      p_option_id,
      v_body,
      'active'
    )
    returning id into v_argument_id;
  else
    v_argument_id := v_existing_argument_id;
  end if;

  return jsonb_build_object(
    'success', true,
    'vote_cost', v_vote_cost,
    'argument_cost', v_argument_cost,
    'argument_id', v_argument_id
  );
end;
$$;

create or replace function public.change_vote_with_coins(
  p_matchup_id uuid,
  p_option_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_existing_option_id uuid;
  v_vote_cost integer;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
      from public.matchup_options
     where id = p_option_id
       and matchup_id = p_matchup_id
  ) then
    raise exception 'Invalid matchup option';
  end if;

  select option_id
    into v_existing_option_id
    from public.votes
   where user_id = v_user_id
     and matchup_id = p_matchup_id
   limit 1;

  if v_existing_option_id = p_option_id then
    return jsonb_build_object('success', true, 'vote_cost', 0);
  end if;

  v_vote_cost := public._coin_economy_int('coinsPerVote', 0);

  perform public._spend_user_coins(
    v_user_id,
    v_vote_cost,
    'vote_change_spend',
    'matchups',
    p_matchup_id
  );

  insert into public.votes (
    user_id,
    matchup_id,
    option_id,
    vote_changed
  )
  values (
    v_user_id,
    p_matchup_id,
    p_option_id,
    true
  )
  on conflict (user_id, matchup_id) do update
    set option_id = excluded.option_id,
        vote_changed = true;

  return jsonb_build_object('success', true, 'vote_cost', v_vote_cost);
end;
$$;

grant execute on function public.submit_vote_and_argument_with_coins(
  uuid,
  uuid,
  text
) to authenticated;

grant execute on function public.change_vote_with_coins(
  uuid,
  uuid
) to authenticated;
