-- Verified User System: manual request + admin approval foundation.

alter type public.notification_type add value if not exists 'system';

alter table public.users
  add column if not exists verification_type text,
  add column if not exists verification_badge_style text,
  add column if not exists verification_status text not null default 'none';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'users_verification_status_check'
  ) then
    alter table public.users add constraint users_verification_status_check
      check (verification_status in ('none', 'pending', 'approved', 'rejected', 'revoked', 'expired'));
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'users_verification_type_check'
  ) then
    alter table public.users add constraint users_verification_type_check
      check (
        verification_type is null or
        verification_type in ('standard', 'public_figure', 'organization', 'trusted_creator', 'admin')
      );
  end if;
end $$;

create table if not exists public.verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  verification_type text not null check (verification_type in ('standard', 'public_figure', 'organization', 'trusted_creator', 'admin')),
  status text not null default 'pending' check (status in ('pending', 'under_review', 'approved', 'rejected', 'revoked', 'expired')),
  display_name text,
  legal_name text,
  organization_name text,
  website text,
  organization_email text,
  social_links text,
  proof_notes text,
  admin_notes text,
  rejection_reason text,
  reviewed_by uuid references public.users(id) on delete set null,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists verification_requests_user_id_idx
  on public.verification_requests(user_id);
create index if not exists verification_requests_status_idx
  on public.verification_requests(status, submitted_at desc);

create table if not exists public.verification_documents (
  id uuid primary key default gen_random_uuid(),
  verification_request_id uuid not null references public.verification_requests(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  document_type text not null,
  document_url text not null,
  created_at timestamptz not null default now()
);

create index if not exists verification_documents_request_id_idx
  on public.verification_documents(verification_request_id);

create table if not exists public.user_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  verification_type text not null check (verification_type in ('standard', 'public_figure', 'organization', 'trusted_creator', 'admin')),
  badge_style text not null default 'standard',
  status text not null default 'approved' check (status in ('approved', 'revoked', 'expired')),
  granted_by uuid references public.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid references public.users(id) on delete set null,
  revocation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, verification_type)
);

create index if not exists user_verifications_user_id_idx
  on public.user_verifications(user_id);

insert into storage.buckets (id, name, public)
values ('verification-documents', 'verification-documents', false)
on conflict (id) do nothing;

alter table public.verification_requests enable row level security;
alter table public.verification_documents enable row level security;
alter table public.user_verifications enable row level security;

drop policy if exists "Users can read own verification requests" on public.verification_requests;
create policy "Users can read own verification requests"
on public.verification_requests for select
to authenticated
using (
  user_id in (select id from public.users where auth_user_id = auth.uid())
  or exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
);

drop policy if exists "Users can create own verification requests" on public.verification_requests;
create policy "Users can create own verification requests"
on public.verification_requests for insert
to authenticated
with check (user_id in (select id from public.users where auth_user_id = auth.uid()));

drop policy if exists "Admins can update verification requests" on public.verification_requests;
create policy "Admins can update verification requests"
on public.verification_requests for update
to authenticated
using (
  exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
)
with check (
  exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
);

drop policy if exists "Users can read own verification documents" on public.verification_documents;
create policy "Users can read own verification documents"
on public.verification_documents for select
to authenticated
using (
  user_id in (select id from public.users where auth_user_id = auth.uid())
  or exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
);

drop policy if exists "Users can create own verification documents" on public.verification_documents;
create policy "Users can create own verification documents"
on public.verification_documents for insert
to authenticated
with check (user_id in (select id from public.users where auth_user_id = auth.uid()));

drop policy if exists "Anyone can read approved user verifications" on public.user_verifications;
create policy "Anyone can read approved user verifications"
on public.user_verifications for select
to authenticated
using (
  status = 'approved'
  or user_id in (select id from public.users where auth_user_id = auth.uid())
  or exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
);

drop policy if exists "Admins manage user verifications" on public.user_verifications;
create policy "Admins manage user verifications"
on public.user_verifications for all
to authenticated
using (
  exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
)
with check (
  exists (
    select 1 from public.users
    where auth_user_id = auth.uid() and role in ('admin', 'moderator')
  )
);

drop policy if exists "Users upload own verification documents" on storage.objects;
create policy "Users upload own verification documents"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'verification-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users read own verification document objects" on storage.objects;
create policy "Users read own verification document objects"
on storage.objects for select
to authenticated
using (
  bucket_id = 'verification-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1 from public.users
      where auth_user_id = auth.uid() and role in ('admin', 'moderator')
    )
  )
);

grant select, insert, update on public.verification_requests to authenticated;
grant select, insert on public.verification_documents to authenticated;
grant select on public.user_verifications to authenticated;
grant all on public.verification_requests to service_role;
grant all on public.verification_documents to service_role;
grant all on public.user_verifications to service_role;
