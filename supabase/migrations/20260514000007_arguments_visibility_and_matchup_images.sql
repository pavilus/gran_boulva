alter table public.matchup_options
  add column if not exists image_url text;

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

  with visible_arguments as (
    select
      a.*,
      jsonb_build_object(
        'username', u.username,
        'avatar_url', u.avatar_url,
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
      case when p_sort <> 'recent' then coalesce(a.visibility_score, 0) end desc,
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

grant execute on function public.get_matchup_arguments_for_voter(
  uuid,
  text,
  integer,
  integer,
  boolean
) to authenticated;

do $$
begin
  if not exists (
    select 1
      from pg_policies
     where schemaname = 'public'
       and tablename = 'arguments'
       and policyname = 'Users can read their own arguments'
  ) then
    create policy "Users can read their own arguments"
      on public.arguments
      for select
      to authenticated
      using (
        exists (
          select 1
            from public.users u
           where u.auth_user_id = auth.uid()
             and u.id = arguments.user_id
        )
      );
  end if;

  if not exists (
    select 1
      from pg_policies
     where schemaname = 'public'
       and tablename = 'arguments'
       and policyname = 'Authenticated users can read active arguments'
  ) then
    create policy "Authenticated users can read active arguments"
      on public.arguments
      for select
      to authenticated
      using (
        status = 'active'
      );
  end if;
end;
$$;
