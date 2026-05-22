-- ─────────────────────────────────────────────────────────────────────────────
-- Fix infinite recursion in prediction_votes RLS (correct policy name).
-- Migration 009800 dropped the wrong policy name. The actual culprit is
-- "Users can read all votes after voting" which does:
--   prediction_id IN (SELECT prediction_id FROM prediction_votes pv2 ...)
-- That self-reference inside a SELECT policy causes infinite recursion (42P17).
-- ─────────────────────────────────────────────────────────────────────────────

-- Drop both the old recursive policy AND the one from 009800 (different name,
-- same intent) so we end up with exactly one clean policy.
DROP POLICY IF EXISTS "Users can read all votes after voting"     ON public.prediction_votes;
DROP POLICY IF EXISTS "Users can see votes after participating"   ON public.prediction_votes;

-- Ensure the security-definer helper exists (created in 009800; recreate here
-- in case it was rolled back or the order changed).
CREATE OR REPLACE FUNCTION public.current_user_voted_on_prediction(pred_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.prediction_votes
    WHERE prediction_id = pred_id
      AND user_id = (
        SELECT id FROM public.users
        WHERE auth_user_id = auth.uid()
        LIMIT 1
      )
  );
$$;

-- Recreate the policy using the security-definer function.
-- The function bypasses RLS on prediction_votes when checking the subquery,
-- which breaks the recursive chain.
CREATE POLICY "Users can read all votes after voting"
ON public.prediction_votes
FOR SELECT
TO authenticated
USING (public.current_user_voted_on_prediction(prediction_id));
