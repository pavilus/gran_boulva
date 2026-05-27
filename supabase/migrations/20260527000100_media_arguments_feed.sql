-- Migration: RPC for the Voice & Video arguments feed
-- Returns the most recent arguments that have audio/video attachments.
-- SECURITY DEFINER so it bypasses the voter-gate RLS (public feed).
-- Timestamp: 20260527000100

CREATE OR REPLACE FUNCTION get_media_arguments_feed(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
  id              UUID,
  user_id         UUID,
  matchup_id      UUID,
  option_id       UUID,
  body            TEXT,
  media_url       TEXT,
  media_type      TEXT,
  media_duration  INTEGER,
  like_count      INTEGER,
  reply_count     INTEGER,
  created_at      TIMESTAMPTZ,
  "user"          JSONB,
  matchup         JSONB
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT
    a.id,
    a.user_id,
    a.matchup_id,
    a.option_id,
    a.body,
    a.media_url,
    a.media_type,
    a.media_duration,
    a.like_count,
    a.reply_count,
    a.created_at,
    jsonb_build_object(
      'username',               u.username,
      'avatar_url',             u.avatar_url,
      'gender',                 u.gender,
      'verification_type',      u.verification_type,
      'verification_badge_style', u.verification_badge_style,
      'verification_status',    u.verification_status
    ) AS "user",
    jsonb_build_object(
      'id',       m.id,
      'title_ht', m.title_ht,
      'title_en', m.title_en
    ) AS matchup
  FROM arguments a
  JOIN users u ON u.id = a.user_id
  JOIN matchups m ON m.id = a.matchup_id
  WHERE a.status = 'active'
    AND a.media_url IS NOT NULL
  ORDER BY a.created_at DESC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION get_media_arguments_feed(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_media_arguments_feed(INTEGER) TO anon;
