-- Add terms consent tracking to creator_profiles.
-- Tier 1+ creators must accept the Creator Agreement before earning revenue.
ALTER TABLE public.creator_profiles
  ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ;

-- RPC for a signed-in creator to record acceptance of the Creator Agreement.
-- Only the owner can accept their own terms; only stamps once (idempotent re-calls are safe).
CREATE OR REPLACE FUNCTION public.accept_creator_terms()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  SELECT id INTO v_user_id FROM public.users WHERE auth_user_id = auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated';
  END IF;

  UPDATE public.creator_profiles
  SET terms_accepted_at = now()
  WHERE user_id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_creator_terms() TO authenticated;
