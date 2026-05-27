-- Migration: Add voice/video media support to arguments and argument_replies
-- Timestamp: 20260525000600

-- ── 1. Add media columns to arguments ───────────────────────────────────────
ALTER TABLE arguments
  ADD COLUMN IF NOT EXISTS media_url      TEXT,
  ADD COLUMN IF NOT EXISTS media_type     TEXT CHECK (media_type IN ('audio', 'video')),
  ADD COLUMN IF NOT EXISTS media_duration INTEGER; -- seconds, max 30

-- ── 2. Add media columns to argument_replies ────────────────────────────────
ALTER TABLE argument_replies
  ADD COLUMN IF NOT EXISTS media_url      TEXT,
  ADD COLUMN IF NOT EXISTS media_type     TEXT CHECK (media_type IN ('audio', 'video')),
  ADD COLUMN IF NOT EXISTS media_duration INTEGER; -- seconds, max 30

-- ── 3. Update get_matchup_arguments_for_voter() to include media columns ────
-- Drop and recreate so the SELECT includes the new columns.
-- (This function already exists; we replace it to expose media_url/type/duration.)
CREATE OR REPLACE FUNCTION get_matchup_arguments_for_voter(
  p_matchup_id UUID,
  p_sort TEXT DEFAULT 'top'
)
RETURNS TABLE (
  id                    UUID,
  user_id               UUID,
  matchup_id            UUID,
  option_id             UUID,
  body                  TEXT,
  like_count            INTEGER,
  dislike_count         INTEGER,
  reply_count           INTEGER,
  boost_expires_at      TIMESTAMPTZ,
  visibility_score      INTEGER,
  status                TEXT,
  created_at            TIMESTAMPTZ,
  support_count         INTEGER,
  support_coins         INTEGER,
  share_count           INTEGER,
  save_count            INTEGER,
  view_count            INTEGER,
  is_boosted            BOOLEAN,
  final_score           NUMERIC,
  my_reaction           TEXT,
  media_url             TEXT,
  media_type            TEXT,
  media_duration        INTEGER,
  "user"                JSONB,
  "option"              JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller_id UUID;
  v_has_voted BOOLEAN;
BEGIN
  -- Get caller
  v_caller_id := auth.uid();

  -- Check if caller has voted on this matchup
  SELECT EXISTS (
    SELECT 1 FROM votes
    WHERE matchup_id = p_matchup_id
      AND user_id = v_caller_id
  ) INTO v_has_voted;

  -- Only return rows if caller has voted (or is admin/service_role bypasses RLS)
  IF NOT v_has_voted THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    a.id,
    a.user_id,
    a.matchup_id,
    a.option_id,
    a.body,
    a.like_count,
    a.dislike_count,
    a.reply_count,
    a.boost_expires_at,
    a.visibility_score,
    a.status,
    a.created_at,
    a.support_count,
    a.support_coins,
    a.share_count,
    a.save_count,
    a.view_count,
    (a.boost_expires_at IS NOT NULL AND a.boost_expires_at > NOW()) AS is_boosted,
    a.final_score,
    (
      SELECT ar.reaction_type
      FROM argument_reactions ar
      WHERE ar.argument_id = a.id AND ar.user_id = v_caller_id
      LIMIT 1
    ) AS my_reaction,
    a.media_url,
    a.media_type,
    a.media_duration,
    (
      SELECT jsonb_build_object(
        'username',               u.username,
        'avatar_url',             u.avatar_url,
        'gender',                 u.gender,
        'verification_type',      u.verification_type,
        'verification_badge_style', u.verification_badge_style,
        'verification_status',    u.verification_status
      )
      FROM users u WHERE u.id = a.user_id
    ) AS "user",
    (
      SELECT jsonb_build_object(
        'option_label', mo.option_label,
        'option_name',  mo.option_name
      )
      FROM matchup_options mo WHERE mo.id = a.option_id
    ) AS "option"
  FROM arguments a
  WHERE a.matchup_id = p_matchup_id
    AND a.status = 'active'
  ORDER BY
    CASE WHEN p_sort = 'top'     THEN a.final_score  END DESC NULLS LAST,
    CASE WHEN p_sort = 'recent'  THEN EXTRACT(EPOCH FROM a.created_at) END DESC NULLS LAST,
    a.created_at DESC;
END;
$$;

-- ── 4. Grant execute on the updated RPC ─────────────────────────────────────
GRANT EXECUTE ON FUNCTION get_matchup_arguments_for_voter(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_matchup_arguments_for_voter(UUID, TEXT) TO service_role;

-- ── 5. Storage bucket: argument-media (public) ───────────────────────────────
-- Create public bucket for audio/video argument media
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'argument-media',
  'argument-media',
  true,
  52428800,  -- 50 MB max (generous; actual files are tiny ≤30s audio/video)
  ARRAY['audio/m4a', 'audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/wav',
        'video/mp4', 'video/quicktime', 'video/x-m4v']
)
ON CONFLICT (id) DO NOTHING;

-- ── 6. Storage RLS policies for argument-media ───────────────────────────────
-- Any authenticated user can read (public bucket, but belt-and-suspenders)
CREATE POLICY "argument_media_read_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'argument-media');

-- Only the file owner can upload (path must start with their user id)
CREATE POLICY "argument_media_upload_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'argument-media'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );

-- Owner can delete their own files
CREATE POLICY "argument_media_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'argument-media'
    AND auth.uid()::TEXT = (storage.foldername(name))[1]
  );
