create extension if not exists pgcrypto;

alter table public.users
  add column if not exists followers_count integer not null default 0,
  add column if not exists following_count integer not null default 0;

create table if not exists public.follows (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.users(id) on delete cascade,
  following_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint follows_no_self_follow check (follower_id <> following_id),
  constraint follows_unique_pair unique (follower_id, following_id)
);

create index if not exists follows_follower_id_idx
  on public.follows(follower_id);

create index if not exists follows_following_id_idx
  on public.follows(following_id);

alter table public.follows enable row level security;

grant select on table public.follows to authenticated;
grant all on table public.follows to service_role;

drop policy if exists "Authenticated users can read follows" on public.follows;
create policy "Authenticated users can read follows"
  on public.follows for select
  to authenticated
  using (true);

drop policy if exists "Service role can manage follows" on public.follows;
create policy "Service role can manage follows"
  on public.follows for all
  to service_role
  using (true)
  with check (true);

grant select, insert, update on table public.notifications to authenticated;
grant all on table public.notifications to service_role;

drop policy if exists "Users can read their notifications" on public.notifications;
create policy "Users can read their notifications"
  on public.notifications for select
  to authenticated
  using (
    exists (
      select 1
        from public.users u
       where u.id = notifications.user_id
         and u.auth_user_id = auth.uid()
    )
  );

drop policy if exists "Users can mark their notifications read" on public.notifications;
create policy "Users can mark their notifications read"
  on public.notifications for update
  to authenticated
  using (
    exists (
      select 1
        from public.users u
       where u.id = notifications.user_id
         and u.auth_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
        from public.users u
       where u.id = notifications.user_id
         and u.auth_user_id = auth.uid()
    )
  );

drop policy if exists "Authenticated users can send notifications" on public.notifications;
create policy "Authenticated users can send notifications"
  on public.notifications for insert
  to authenticated
  with check (true);

drop policy if exists "Service role can manage notifications" on public.notifications;
create policy "Service role can manage notifications"
  on public.notifications for all
  to service_role
  using (true)
  with check (true);

update public.users u
   set followers_count = coalesce(f.count, 0)
  from (
    select following_id, count(*)::integer as count
      from public.follows
     group by following_id
  ) f
 where u.id = f.following_id;

update public.users u
   set following_count = coalesce(f.count, 0)
  from (
    select follower_id, count(*)::integer as count
      from public.follows
     group by follower_id
  ) f
 where u.id = f.follower_id;

create or replace function public.follow_user(p_following_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_follower public.users%rowtype;
  v_following public.users%rowtype;
  v_inserted boolean := false;
begin
  select *
    into v_follower
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_follower.id is null then
    raise exception 'Not authenticated';
  end if;

  select *
    into v_following
    from public.users
   where id = p_following_id
   limit 1;

  if v_following.id is null then
    raise exception 'User not found';
  end if;

  if v_follower.id = v_following.id then
    raise exception 'You cannot follow yourself';
  end if;

  insert into public.follows (follower_id, following_id)
  values (v_follower.id, v_following.id)
  on conflict (follower_id, following_id) do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted then
    update public.users
       set following_count = greatest(coalesce(following_count, 0) + 1, 0)
     where id = v_follower.id;

    update public.users
       set followers_count = greatest(coalesce(followers_count, 0) + 1, 0)
     where id = v_following.id;

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
      v_following.id,
      'new_follower',
      'Nouvo moun ap swiv ou',
      '@' || v_follower.username || ' ap swiv ou sou Gran Boulva.',
      'users',
      v_follower.id,
      false
    );
  end if;

  return jsonb_build_object('success', true, 'following', true, 'created', v_inserted);
end;
$$;

create or replace function public.unfollow_user(p_following_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_follower_id uuid;
  v_deleted boolean := false;
begin
  select id
    into v_follower_id
    from public.users
   where auth_user_id = auth.uid()
   limit 1;

  if v_follower_id is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.follows
   where follower_id = v_follower_id
     and following_id = p_following_id;

  get diagnostics v_deleted = row_count;

  if v_deleted then
    update public.users
       set following_count = greatest(coalesce(following_count, 0) - 1, 0)
     where id = v_follower_id;

    update public.users
       set followers_count = greatest(coalesce(followers_count, 0) - 1, 0)
     where id = p_following_id;
  end if;

  return jsonb_build_object('success', true, 'following', false, 'deleted', v_deleted);
end;
$$;

grant execute on function public.follow_user(uuid) to authenticated;
grant execute on function public.unfollow_user(uuid) to authenticated;
