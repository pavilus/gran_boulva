alter table public.votes
  add column if not exists vote_changed boolean not null default false;
