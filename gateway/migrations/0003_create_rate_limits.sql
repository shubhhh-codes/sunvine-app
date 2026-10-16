-- 0003_create_rate_limits.sql
-- D1 Migration: Distributed rate limiting table for IP and account identifiers

CREATE TABLE IF NOT EXISTS auth_rate_limits (
  key TEXT PRIMARY KEY,
  attempts INTEGER NOT NULL DEFAULT 1,
  reset_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_rate_limits_reset ON auth_rate_limits (reset_at);
