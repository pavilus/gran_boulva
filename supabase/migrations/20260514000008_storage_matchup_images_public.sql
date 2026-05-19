-- Ensure matchup-images bucket exists and is public
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'matchup-images',
  'matchup-images',
  true,
  10485760,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set public = true;

-- Ensure avatars bucket exists and is public
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update set public = true;

-- Public read for matchup images
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public read matchup images'
  ) then
    create policy "Public read matchup images"
      on storage.objects for select to public
      using (bucket_id = 'matchup-images');
  end if;
end $$;

-- Service role can upload/update/delete matchup images
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Service role manage matchup images'
  ) then
    create policy "Service role manage matchup images"
      on storage.objects for all to service_role
      using (bucket_id = 'matchup-images')
      with check (bucket_id = 'matchup-images');
  end if;
end $$;

-- Public read for avatars
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public read avatars'
  ) then
    create policy "Public read avatars"
      on storage.objects for select to public
      using (bucket_id = 'avatars');
  end if;
end $$;

-- Authenticated users can manage their own avatars
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated manage avatars'
  ) then
    create policy "Authenticated manage avatars"
      on storage.objects for all to authenticated
      using (bucket_id = 'avatars')
      with check (bucket_id = 'avatars');
  end if;
end $$;
