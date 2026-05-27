-- Allow media-only arguments (voice or video without text body).
-- The previous RPC rejected empty bodies with 'Argument is required'.
-- Now that media attachments are supported, the body may be empty/whitespace
-- when the user submits a voice or video argument with no text.
-- We store v_body as-is (trimmed); the Flutter UI guards display with
--   body.trim().isNotEmpty && body.trim() != ' '
-- so an empty DB body is never shown as a blank card.

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

  -- Allow empty body — voice/video arguments have no required text.
  -- We trim for storage but do NOT reject empty bodies anymore.
  v_body := btrim(coalesce(p_argument_body, ''));

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
