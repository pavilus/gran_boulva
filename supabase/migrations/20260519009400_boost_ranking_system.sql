-- Finish the boost ranking system:
-- boosted visibility is temporary, while organic engagement can outrank it.

alter table public.arguments
  add column if not exists boost_tier text,
  add column if not exists boost_started_at timestamptz,
  add column if not exists support_count integer not null default 0,
  add column if not exists support_coins integer not null default 0,
  add column if not exists share_count integer not null default 0,
  add column if not exists save_count integer not null default 0,
  add column if not exists view_count integer not null default 0,
  add column if not exists final_score numeric not null default 0,
  add column if not exists last_ranked_at timestamptz;

alter table public.coin_transactions
  add column if not exists reference_table text,
  add column if not exists reference_id uuid;

alter table public.users
  add column if not exists free_boost_credits integer not null default 0,
  add column if not exists total_boosts_used integer not null default 0,
  add column if not exists total_support_given integer not null default 0,
  add column if not exists total_support_received integer not null default 0,
  add column if not exists total_coins_spent integer not null default 0;

create or replace function public.current_app_user_id()
returns uuid
language sql
security definer
set search_path = public
as $$
  select id
  from public.users
  where auth_user_id = auth.uid()
  limit 1;
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
         total_coins_spent = coalesce(total_coins_spent, 0) + p_amount,
         updated_at = now()
   where id = p_user_id;

  insert into public.coin_transactions (
    from_user_id,
    amount,
    fee,
    transaction_type,
    reference_table,
    reference_id,
    status
  )
  values (
    p_user_id,
    p_amount,
    0,
    p_transaction_type,
    p_reference_table,
    p_reference_id,
    'completed'
  );
end;
$$;

create or replace function public.argument_boost_score(
  p_boost_tier text,
  p_boost_expires_at timestamptz
)
returns integer
language sql
stable
as $$
  select case
    when p_boost_expires_at is null or p_boost_expires_at <= now() then 0
    when p_boost_tier in ('1w', '7d', 'week') then 120
    when p_boost_tier in ('4d', '3d') then 60
    when p_boost_tier in ('24h', '1d', 'day') then 20
    else 60
  end;
$$;

create or replace function public.calculate_argument_final_score(
  p_argument_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_arg record;
  v_engagement_rate numeric := 0;
  v_recency_score integer := 0;
begin
  select
    coalesce(boost_tier, '') as boost_tier,
    boost_expires_at,
    coalesce(like_count, 0) as like_count,
    coalesce(reply_count, 0) as reply_count,
    coalesce(share_count, 0) as share_count,
    coalesce(save_count, 0) as save_count,
    coalesce(view_count, 0) as view_count,
    coalesce(support_coins, 0) as support_coins,
    created_at
  into v_arg
  from public.arguments
  where id = p_argument_id;

  if not found then
    return 0;
  end if;

  if v_arg.created_at >= now() - interval '2 hours' then
    v_recency_score := 15;
  elsif v_arg.created_at >= now() - interval '12 hours' then
    v_recency_score := 10;
  elsif v_arg.created_at >= now() - interval '24 hours' then
    v_recency_score := 5;
  end if;

  if v_arg.view_count > 0 then
    v_engagement_rate :=
      ((v_arg.like_count + v_arg.reply_count + v_arg.share_count + v_arg.save_count)::numeric
        / greatest(v_arg.view_count, 1)) * 100;
  end if;

  return
    public.argument_boost_score(v_arg.boost_tier, v_arg.boost_expires_at)
    + (v_arg.like_count * 2)
    + (v_arg.reply_count * 5)
    + (v_arg.share_count * 8)
    + (v_arg.save_count * 6)
    + (v_arg.support_coins * 0.3)
    + least(v_engagement_rate, 100)
    + v_recency_score;
end;
$$;

create or replace function public.refresh_argument_final_score(
  p_argument_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_score numeric;
begin
  v_score := public.calculate_argument_final_score(p_argument_id);

  update public.arguments
     set final_score = v_score,
         visibility_score = greatest(coalesce(visibility_score, 0), floor(v_score)::integer),
         last_ranked_at = now()
   where id = p_argument_id;

  return v_score;
end;
$$;

create or replace function public.refresh_matchup_argument_scores(
  p_matchup_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_argument_id uuid;
begin
  for v_argument_id in
    select id
    from public.arguments
    where matchup_id = p_matchup_id
      and status = 'active'
  loop
    perform public.refresh_argument_final_score(v_argument_id);
  end loop;
end;
$$;

create or replace function public.trg_refresh_argument_score()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_table_name = 'arguments' then
    perform public.refresh_argument_final_score(coalesce(new.id, old.id));
  else
    perform public.refresh_argument_final_score(coalesce(new.argument_id, old.argument_id));
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_refresh_argument_score_arguments on public.arguments;
create trigger trg_refresh_argument_score_arguments
after insert or update of
  boost_tier,
  boost_expires_at,
  like_count,
  reply_count,
  share_count,
  save_count,
  view_count,
  support_count,
  support_coins,
  status
on public.arguments
for each row
execute function public.trg_refresh_argument_score();

do $$
begin
  if to_regclass('public.argument_reactions') is not null then
    execute 'drop trigger if exists trg_refresh_argument_score_reactions on public.argument_reactions';
    execute 'create trigger trg_refresh_argument_score_reactions
      after insert or update or delete on public.argument_reactions
      for each row execute function public.trg_refresh_argument_score()';
  end if;

  if to_regclass('public.argument_replies') is not null then
    execute 'drop trigger if exists trg_refresh_argument_score_replies on public.argument_replies';
    execute 'create trigger trg_refresh_argument_score_replies
      after insert or update or delete on public.argument_replies
      for each row execute function public.trg_refresh_argument_score()';
  end if;
end;
$$;

create or replace function public.record_argument_view(
  p_argument_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_score numeric;
begin
  update public.arguments
     set view_count = coalesce(view_count, 0) + 1
   where id = p_argument_id;

  v_score := public.refresh_argument_final_score(p_argument_id);
  return v_score;
end;
$$;

create or replace function public.boost_argument(
  p_argument_id uuid,
  p_tier text,
  p_use_free_credit boolean default false,
  p_use_coins boolean default false,
  p_coin_cost integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_owner_id uuid;
  v_duration interval;
  v_default_cost integer;
  v_cost integer;
  v_expires_at timestamptz;
  v_score numeric;
begin
  v_user_id := public.current_app_user_id();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select user_id
    into v_owner_id
    from public.arguments
   where id = p_argument_id
     and status = 'active';

  if v_owner_id is null then
    raise exception 'Argument not found';
  end if;

  if v_owner_id <> v_user_id then
    raise exception 'Ou ka sèlman booste pwòp agiman ou';
  end if;

  v_duration := case
    when p_tier in ('1w', '7d', 'week') then interval '7 days'
    when p_tier in ('4d', '3d') then interval '4 days'
    else interval '24 hours'
  end;

  v_default_cost := case
    when p_tier in ('1w', '7d', 'week') then 550
    when p_tier in ('4d', '3d') then 350
    else 150
  end;
  v_cost := greatest(coalesce(p_coin_cost, v_default_cost), 0);

  if p_use_free_credit then
    update public.users
       set free_boost_credits = free_boost_credits - 1,
           total_boosts_used = coalesce(total_boosts_used, 0) + 1,
           updated_at = now()
     where id = v_user_id
       and coalesce(free_boost_credits, 0) > 0;

    if not found then
      raise exception 'Pa gen boost gratis disponib';
    end if;
  else
    if not p_use_coins then
      raise exception 'Boost mande coins';
    end if;

    perform public._spend_user_coins(
      v_user_id,
      v_cost,
      'boost_spend',
      'arguments',
      p_argument_id
    );

    update public.users
       set total_boosts_used = coalesce(total_boosts_used, 0) + 1,
           updated_at = now()
     where id = v_user_id;
  end if;

  v_expires_at := greatest(coalesce((
    select boost_expires_at from public.arguments where id = p_argument_id
  ), now()), now()) + v_duration;

  update public.arguments
     set boost_tier = p_tier,
         boost_started_at = now(),
         boost_expires_at = v_expires_at
   where id = p_argument_id;

  v_score := public.refresh_argument_final_score(p_argument_id);

  insert into public.notifications (user_id, type, title, body, related_table, related_id)
  values (
    v_user_id,
    'boost',
    'Boost aktive',
    'Agiman ou an gen plis vizibilite kounye a.',
    'arguments',
    p_argument_id
  );

  return jsonb_build_object(
    'success', true,
    'argument_id', p_argument_id,
    'tier', p_tier,
    'coin_cost', case when p_use_free_credit then 0 else v_cost end,
    'boost_expires_at', v_expires_at,
    'final_score', v_score
  );
end;
$$;

create or replace function public.support_argument(
  p_argument_id uuid,
  p_amount integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_supporter_id uuid;
  v_creator_id uuid;
  v_supporter_name text;
  v_score numeric;
begin
  v_supporter_id := public.current_app_user_id();
  if v_supporter_id is null then
    raise exception 'Not authenticated';
  end if;

  if coalesce(p_amount, 0) <= 0 then
    raise exception 'Montan sipò a pa valab';
  end if;

  select user_id
    into v_creator_id
    from public.arguments
   where id = p_argument_id
     and status = 'active';

  if v_creator_id is null then
    raise exception 'Argument not found';
  end if;

  if v_creator_id = v_supporter_id then
    raise exception 'Ou pa ka sipòte pwòp agiman ou';
  end if;

  perform public._spend_user_coins(
    v_supporter_id,
    p_amount,
    'argument_support',
    'arguments',
    p_argument_id
  );

  update public.arguments
     set support_count = coalesce(support_count, 0) + 1,
         support_coins = coalesce(support_coins, 0) + p_amount
   where id = p_argument_id;

  update public.users
     set influence_score = coalesce(influence_score, 0) + greatest(1, floor(p_amount / 10)),
         total_support_received = coalesce(total_support_received, 0) + p_amount,
         updated_at = now()
   where id = v_creator_id;

  update public.users
     set total_support_given = coalesce(total_support_given, 0) + p_amount,
         updated_at = now()
   where id = v_supporter_id;

  select username into v_supporter_name
  from public.users
  where id = v_supporter_id;

  insert into public.notifications (user_id, type, title, body, related_table, related_id)
  values (
    v_creator_id,
    'argument_support',
    'Nouvo sipò',
    coalesce(v_supporter_name, 'Yon moun') || ' sipòte agiman w la ak ' || p_amount || ' coins.',
    'arguments',
    p_argument_id
  );

  v_score := public.refresh_argument_final_score(p_argument_id);

  return jsonb_build_object(
    'success', true,
    'argument_id', p_argument_id,
    'amount', p_amount,
    'final_score', v_score
  );
end;
$$;

create or replace function public.get_matchup_arguments_for_voter(
  p_matchup_id uuid,
  p_sort text default 'popular',
  p_limit integer default 20,
  p_offset integer default 0,
  p_fetch_all boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_can_view boolean;
  v_result jsonb;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    return '[]'::jsonb;
  end if;

  select exists (
    select 1
      from public.votes
     where user_id = v_user_id
       and matchup_id = p_matchup_id
  )
    into v_can_view;

  if not v_can_view then
    return '[]'::jsonb;
  end if;

  perform public.refresh_matchup_argument_scores(p_matchup_id);

  with visible_arguments as (
    select
      a.*,
      public.argument_boost_score(a.boost_tier, a.boost_expires_at) as boost_score,
      (a.boost_expires_at is not null and a.boost_expires_at > now()) as is_boosted,
      jsonb_build_object(
        'username', u.username,
        'avatar_url', u.avatar_url,
        'gender', u.gender,
        'verification_type', u.verification_type,
        'verification_badge_style', u.verification_badge_style,
        'verification_status', u.verification_status,
        'influence_score', coalesce(u.influence_score, 0)
      ) as user_json,
      jsonb_build_object(
        'option_label', mo.option_label,
        'option_name', mo.option_name
      ) as option_json,
      ar.reaction_type as current_user_reaction
    from public.arguments a
    left join public.users u on u.id = a.user_id
    left join public.matchup_options mo on mo.id = a.option_id
    left join public.argument_reactions ar
      on ar.argument_id = a.id
     and ar.user_id = v_user_id
    where a.matchup_id = p_matchup_id
      and a.status = 'active'
    order by
      case when p_sort = 'recent' then a.created_at end desc,
      case when p_sort = 'boosted' then (a.boost_expires_at is not null and a.boost_expires_at > now()) end desc,
      case when p_sort <> 'recent' then coalesce(a.final_score, 0) end desc,
      a.created_at desc
    limit case when p_fetch_all then null else greatest(p_limit, 1) end
    offset case when p_fetch_all then 0 else greatest(p_offset, 0) end
  )
  select coalesce(
    jsonb_agg(
      to_jsonb(visible_arguments)
        - 'user_json'
        - 'option_json'
        - 'current_user_reaction'
        || jsonb_build_object(
          'user', user_json,
          'option', option_json,
          'my_reaction', current_user_reaction
        )
    ),
    '[]'::jsonb
  )
    into v_result
    from visible_arguments;

  return v_result;
end;
$$;

grant execute on function public.current_app_user_id() to authenticated;
grant execute on function public._spend_user_coins(uuid, integer, text, text, uuid) to authenticated;
grant execute on function public.argument_boost_score(text, timestamptz) to authenticated;
grant execute on function public.calculate_argument_final_score(uuid) to authenticated;
grant execute on function public.refresh_argument_final_score(uuid) to authenticated;
grant execute on function public.refresh_matchup_argument_scores(uuid) to authenticated;
grant execute on function public.record_argument_view(uuid) to authenticated;
grant execute on function public.boost_argument(uuid, text, boolean, boolean, integer) to authenticated;
grant execute on function public.support_argument(uuid, integer) to authenticated;
grant execute on function public.get_matchup_arguments_for_voter(uuid, text, integer, integer, boolean) to authenticated;

create index if not exists idx_arguments_matchup_final_score
  on public.arguments (matchup_id, status, final_score desc, created_at desc);

create index if not exists idx_arguments_active_boosts
  on public.arguments (boost_expires_at)
  where boost_expires_at is not null;

update public.arguments
   set final_score = public.calculate_argument_final_score(id),
       last_ranked_at = now()
 where status = 'active';
