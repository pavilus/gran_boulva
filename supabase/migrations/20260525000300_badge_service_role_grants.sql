-- Grant service_role access to badge tables.
-- These tables were created manually in Supabase dashboard so they never got
-- explicit service_role grants. The admin dashboard uses service_role and was
-- getting "permission denied" errors.

grant select, insert, update, delete on public.badges        to service_role;
grant select, insert, update, delete on public.badge_levels  to service_role;
grant select, insert, update, delete on public.badge_events  to service_role;
grant select, insert, update, delete on public.user_badges   to service_role;
