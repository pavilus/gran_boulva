create table if not exists public.email_messages (
  id uuid primary key default gen_random_uuid(),
  direction text not null check (direction in ('inbound', 'outbound')),
  status text not null default 'queued',
  from_email text,
  to_email text,
  subject text,
  body_text text,
  body_html text,
  provider text,
  provider_id text,
  error text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.email_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  subject text not null,
  body_text text,
  body_html text,
  signature_html text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.email_settings (
  id boolean primary key default true,
  from_email text not null default 'support@granboulva.com',
  reply_to text not null default 'support@granboulva.com',
  default_signature_html text,
  updated_at timestamptz not null default now(),
  constraint email_settings_singleton check (id)
);

insert into public.email_settings (id)
values (true)
on conflict (id) do nothing;

grant all on table public.email_messages to service_role;
grant all on table public.email_templates to service_role;
grant all on table public.email_settings to service_role;
