-- ─────────────────────────────────────────────────────────────────────────────
-- Drop EVERY policy on prediction_votes (regardless of name) and replace with
-- two simple, non-recursive policies.
--
-- Previous migrations only dropped by known name — any extra policy (created
-- via dashboard or with a different name) survived and still caused 42P17.
-- ─────────────────────────────────────────────────────────────────────────────

-- Dynamic drop of all existing policies
DO $$
DECLARE
  pol text;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'prediction_votes'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.prediction_votes', pol);
    RAISE NOTICE 'Dropped policy: %', pol;
  END LOOP;
END$$;

-- Read: any authenticated user can read votes (no self-reference, no recursion)
CREATE POLICY "pv_read"
ON public.prediction_votes
FOR SELECT
TO authenticated
USING (true);

-- Insert: users can only insert their own vote
CREATE POLICY "pv_insert"
ON public.prediction_votes
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = (
    SELECT id FROM public.users
    WHERE auth_user_id = auth.uid()
    LIMIT 1
  )
);
