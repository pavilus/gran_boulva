-- Public storage bucket for badge icon images uploaded from admin dashboard.
-- Flutter reads icon_asset: if it starts with 'http' it uses Image.network(),
-- otherwise falls back to Image.asset() (the existing local PNG assets).

insert into storage.buckets (id, name, public)
values ('badge-icons', 'badge-icons', true)
on conflict (id) do nothing;

-- Allow admin service role to upload / delete
create policy "badge_icons_admin_upload"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'badge-icons');

create policy "badge_icons_admin_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'badge-icons');

-- Public read
create policy "badge_icons_public_read"
  on storage.objects for select
  to public
  using (bucket_id = 'badge-icons');
