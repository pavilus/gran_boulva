create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_full_name text;
  v_language text;
  v_referred_by uuid;
  v_referral_code text;
begin
  v_username := lower(trim(coalesce(new.raw_user_meta_data->>'username', '')));
  v_full_name := trim(coalesce(new.raw_user_meta_data->>'full_name', ''));
  v_language := coalesce(nullif(new.raw_user_meta_data->>'language', ''), 'ht');
  v_referral_code := nullif(trim(coalesce(new.raw_user_meta_data->>'referral_code', '')), '');

  if v_username = '' then
    v_username := lower(regexp_replace(split_part(new.email, '@', 1), '[^a-zA-Z0-9_]', '_', 'g'));
  end if;

  if v_username !~ '^[a-z0-9_]{3,}$' then
    raise exception 'USERNAME_INVALID';
  end if;

  if exists (select 1 from public.users u where lower(u.username) = v_username) then
    raise exception 'USERNAME_TAKEN';
  end if;

  if v_full_name = '' then
    v_full_name := v_username;
  end if;

  if v_referral_code is not null then
    select id
      into v_referred_by
      from public.users
     where referral_code = v_referral_code
     limit 1;
  end if;

  insert into public.users (
    auth_user_id,
    full_name,
    username,
    email,
    language,
    referred_by
  )
  values (
    new.id,
    v_full_name,
    v_username,
    coalesce(new.email, ''),
    v_language,
    v_referred_by
  )
  on conflict (auth_user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_public_profile on auth.users;
create trigger on_auth_user_created_create_public_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

grant execute on function public.handle_new_auth_user() to service_role;
