-- deadline_at on predictions should be nullable.
-- A prediction with no deadline is active indefinitely (closed manually).
-- The Flutter app and recommendation RPC already handle NULL deadline_at
-- gracefully, so this is purely a constraint relaxation.
alter table public.predictions
  alter column deadline_at drop not null;
