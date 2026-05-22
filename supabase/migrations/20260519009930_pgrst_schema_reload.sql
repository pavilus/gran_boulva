-- Force PostgREST to reload its schema cache so new RLS policies take effect.
NOTIFY pgrst, 'reload schema';
