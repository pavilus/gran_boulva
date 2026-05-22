-- ─────────────────────────────────────────────────────────────────────────────
-- The "read all votes after voting" policy keeps causing infinite recursion
-- (42P17) because any subquery on prediction_votes inside a prediction_votes
-- policy creates a loop — even with SECURITY DEFINER helpers.
--
-- Simple fix: drop all the complex SELECT policies and allow any authenticated
-- user to read prediction_votes.  Vote tallies are not sensitive (they're
-- shown publicly on results pages), and the app already gates the UI so users
-- only SEE results after they have voted.
-- ─────────────────────────────────────────────────────────────────────────────

-- Drop every variant of the recursive "after voting" policy
DROP POLICY IF EXISTS "Users can read all votes after voting"   ON public.prediction_votes;
DROP POLICY IF EXISTS "Users can see votes after participating" ON public.prediction_votes;

-- Also replace the "own votes" policy with a single open read policy
DROP POLICY IF EXISTS "Users can read own prediction votes"     ON public.prediction_votes;

-- Simple: any authenticated user can read prediction_votes (no recursion)
CREATE POLICY "Authenticated users can read prediction votes"
ON public.prediction_votes
FOR SELECT
TO authenticated
USING (true);
