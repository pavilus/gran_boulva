-- ─────────────────────────────────────────────────────────────────────────────
-- Fix infinite recursion in prediction_votes RLS.
-- The "see votes after participating" policy queried prediction_votes from
-- inside the prediction_votes policy, causing an infinite loop (42P17).
-- Solution: use a SECURITY DEFINER helper that bypasses RLS for the check.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Drop the recursive policy
DROP POLICY IF EXISTS "Users can see votes after participating" ON public.prediction_votes;

-- 2. Security-definer helper: checks if the current user has voted on a
--    given prediction WITHOUT triggering RLS on prediction_votes again.
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

-- 3. Re-create the policy using the security-definer function (no recursion)
CREATE POLICY "Users can see votes after participating"
ON public.prediction_votes
FOR SELECT
USING (public.current_user_voted_on_prediction(prediction_id));
