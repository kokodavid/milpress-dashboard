-- ============================================================
-- app_content: single-row global config for the mobile app
-- ============================================================
CREATE TABLE IF NOT EXISTS app_content (
  id                          int PRIMARY KEY DEFAULT 1,
  intro_video_url             text,
  intro_video_thumbnail_url   text,
  help_video_url              text,
  updated_at                  timestamptz NOT NULL DEFAULT now(),

  -- enforce single-row invariant
  CONSTRAINT app_content_single_row CHECK (id = 1)
);

-- Seed the single row so upserts always succeed
INSERT INTO app_content (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- Auto-update updated_at on every write
CREATE OR REPLACE FUNCTION set_app_content_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_app_content_updated_at
BEFORE UPDATE ON app_content
FOR EACH ROW EXECUTE FUNCTION set_app_content_updated_at();

-- RLS
ALTER TABLE app_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated admins can read app_content"
  ON app_content FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated admins can insert app_content"
  ON app_content FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated admins can update app_content"
  ON app_content FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);


-- ============================================================
-- app_resources: ordered list of downloadable resources
-- ============================================================
CREATE TABLE IF NOT EXISTS app_resources (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label         text NOT NULL,
  file_url      text NOT NULL DEFAULT '',   -- PDF or video file
  audio_url     text NOT NULL DEFAULT '',   -- companion audio (MP3/M4A)
  type          text NOT NULL DEFAULT 'pdf', -- 'pdf' | 'video'
  display_order int  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Seed the two default resources
INSERT INTO app_resources (label, type, display_order)
VALUES
  ('Alphabets Chart', 'pdf', 1),
  ('Mouth Sync Guide', 'pdf', 2)
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE app_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated admins can read app_resources"
  ON app_resources FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated admins can insert app_resources"
  ON app_resources FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated admins can update app_resources"
  ON app_resources FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated admins can delete app_resources"
  ON app_resources FOR DELETE
  TO authenticated
  USING (true);
