-- Tracks old usernames so shared profile links stay valid after a username change.
-- /user/:username lookups fall back to this table and redirect to the current username.

CREATE TABLE username_history (
  old_username  TEXT        NOT NULL,
  user_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  changed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_username_history_old ON username_history(old_username);
CREATE INDEX idx_username_history_user_id   ON username_history(user_id);

ALTER TABLE username_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read" ON username_history FOR SELECT USING (true);

-- Auto-record the old username whenever users.username changes.
CREATE OR REPLACE FUNCTION record_username_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.username IS DISTINCT FROM NEW.username THEN
    INSERT INTO username_history(old_username, user_id)
    VALUES (OLD.username, OLD.id)
    ON CONFLICT (old_username) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_username_change
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION record_username_change();
