-- Track the Stripe payment amount for founding supporter purchases.
ALTER TABLE waitlist ADD COLUMN IF NOT EXISTS amount_cents INTEGER;
