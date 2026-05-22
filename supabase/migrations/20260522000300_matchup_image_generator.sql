-- Matchup Image Generator
-- Keeps card option art separate from branded poster/share assets.

alter table public.matchups
  add column if not exists poster_image_url text,
  add column if not exists share_image_url text;

create table if not exists public.matchup_image_sets (
  id uuid primary key default gen_random_uuid(),
  matchup_id uuid not null references public.matchups(id) on delete cascade,
  option_a_image_url text not null,
  option_b_image_url text not null,
  poster_image_url text not null,
  share_image_url text not null,
  prompt text,
  model text not null default 'gpt-image-1.5',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists matchup_image_sets_matchup_created_idx
  on public.matchup_image_sets (matchup_id, created_at desc);

create index if not exists matchup_image_sets_created_idx
  on public.matchup_image_sets (created_at desc);

alter table public.matchup_image_sets enable row level security;

grant all on table public.matchup_image_sets to service_role;
