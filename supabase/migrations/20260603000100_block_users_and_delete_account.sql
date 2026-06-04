-- blocked_users: track user blocks for content filtering and developer notification
CREATE TABLE IF NOT EXISTS public.blocked_users (
  blocker_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id)
);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE public.blocked_users TO service_role;
GRANT SELECT, INSERT, DELETE ON TABLE public.blocked_users TO authenticated;

CREATE POLICY "Users can manage own blocks" ON public.blocked_users
  FOR ALL USING (
    blocker_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
  );

-- RPC for authenticated users to delete their own account
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
