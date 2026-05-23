create table if not exists public.waitlist (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  email       text not null,
  is_creator  boolean not null default false,
  is_supporter boolean not null default false,
  tier        text,                      -- 'supporter' | 'ambassador' | 'founding_creator' | 'founding_partner'
  source      text default 'landing',
  created_at  timestamptz not null default now(),
  constraint waitlist_email_unique unique (email)
);

alter table public.waitlist enable row level security;
grant all on table public.waitlist to service_role;

-- Allow anon inserts (public waitlist form)
create policy "anon can insert waitlist" on public.waitlist
  for insert to anon, authenticated with check (true);

-- Only service_role can read
create policy "service_role can read waitlist" on public.waitlist
  for select to service_role using (true);
