create or replace function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with normalized as (
    select lower(trim(coalesce(p_username, ''))) as username
  )
  select normalized.username ~ '^[a-z0-9_]{3,}$'
     and not exists (
       select 1
         from public.users u
        where lower(u.username) = normalized.username
     )
    from normalized;
$$;

grant execute on function public.is_username_available(text) to anon;
grant execute on function public.is_username_available(text) to authenticated;
grant execute on function public.is_username_available(text) to service_role;
