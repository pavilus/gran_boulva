-- When a user is followed, their follower count increases which can push them
-- over the Tier 1 threshold (score >= 15 AND followers >= 10).
-- This trigger fires refresh_creator_tier() for the followed user automatically
-- so tier upgrades happen without waiting for a manual dashboard refresh.

CREATE OR REPLACE FUNCTION public.trigger_refresh_tier_on_follow()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.refresh_creator_tier(NEW.following_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS refresh_tier_on_new_follow ON public.follows;

CREATE TRIGGER refresh_tier_on_new_follow
  AFTER INSERT ON public.follows
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_refresh_tier_on_follow();
