-- 0002_create_app_releases.sql
-- D1 Migration: In-app release telemetry and APK distribution registry

CREATE TABLE IF NOT EXISTS app_releases (
  id TEXT PRIMARY KEY,
  platform TEXT NOT NULL,
  latest_version TEXT NOT NULL,
  min_supported_version TEXT NOT NULL,
  apk_url TEXT NOT NULL,
  release_notes TEXT,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_app_releases_platform_created ON app_releases (platform, created_at DESC);
