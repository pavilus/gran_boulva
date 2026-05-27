-- Add voice/video media support to prediction_votes.
-- Same pattern as argument_media (20260525000600).

ALTER TABLE prediction_votes
  ADD COLUMN IF NOT EXISTS media_url      TEXT,
  ADD COLUMN IF NOT EXISTS media_type     TEXT CHECK (media_type IN ('audio', 'video')),
  ADD COLUMN IF NOT EXISTS media_duration INTEGER; -- seconds, max 30
