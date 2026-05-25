-- ============================================================
-- Partner Applications
-- Collected after a successful Founding Partner checkout ($499).
-- ============================================================

create table if not exists public.partner_applications (
  id                 uuid primary key default gen_random_uuid(),

  -- Identity
  name               text        not null,
  email              text        not null,
  phone_number       text,
  country            text,
  profession         text,

  -- Background
  business_background text,
  linkedin_url        text,
  why_interested      text,
  strategic_skills    text,

  -- Interests (checkbox array)
  -- values: 'partnership' | 'creator_support' | 'investment_discussion' | 'advisory_opportunities'
  interests           text[]      not null default '{}',

  -- Optional
  investment_range    text,
  industry_expertise  text,
  audience_size       text,

  -- Source
  stripe_session_id   text,

  created_at          timestamptz not null default now()
);

-- Prevent duplicate submissions for the same Stripe session
create unique index if not exists partner_applications_session_idx
  on public.partner_applications (stripe_session_id)
  where stripe_session_id is not null;

-- Only service_role can read/write (admin dashboard access)
alter table public.partner_applications enable row level security;

create policy "service_role full access"
  on public.partner_applications
  for all
  to service_role
  using (true)
  with check (true);

-- Anon insert only (for the form submission from the landing page)
create policy "anon insert"
  on public.partner_applications
  for insert
  to anon, authenticated
  with check (true);
