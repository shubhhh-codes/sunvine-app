-- 0001_create_refresh_tokens.sql
-- D1 Migration: Rotating refresh token storage with cryptographic token hash and family revocation

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  dealer_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  device_name TEXT,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  rotated_at INTEGER,
  revoked_at INTEGER,
  user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family_id ON refresh_tokens (family_id);
