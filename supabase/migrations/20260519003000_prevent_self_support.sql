create or replace function public.support_argument_checked(
  p_argument_id uuid,
  p_amount integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_owner_user_id uuid;
begin
  select id
    into v_user_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select user_id
    into v_owner_user_id
    from public.arguments
   where id = p_argument_id
   limit 1;

  if v_owner_user_id is null then
    raise exception 'Argument not found';
  end if;

  if v_owner_user_id = v_user_id then
    raise exception 'Ou pa ka sipòte pwòp agiman ou';
  end if;

  perform public.support_argument(p_argument_id, p_amount);

  return jsonb_build_object('success', true);
end;
$$;

grant execute on function public.support_argument_checked(
  uuid,
  integer
) to authenticated;
