-- Fix: authenticated role needs insert + update on user_verifications
-- so admin approve/reject flows work via the regular Supabase client.
grant insert, update on public.user_verifications to authenticated;
