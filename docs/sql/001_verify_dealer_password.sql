-- ============================================================================
-- Migration: Additive SECURITY DEFINER Function for Dealer Password Check
-- Target: STAGING SUPABASE ONLY (Run in Supabase SQL Editor by Administrator)
-- Purpose: Offload bcrypt cost-10 verification to PostgreSQL to fit Cloudflare
--          Workers Free plan CPU limit (10ms).
-- Security:
--   - Additive only: creates a single new function, alters no existing tables.
--   - SECURITY DEFINER with fixed search_path = public, extensions.
--   - NEVER returns password_hash or sensitive columns.
--   - Returns ONLY the dealer id (UUID) on valid match, or NULL if invalid.
--   - Permissions: Revoked from PUBLIC, anon, authenticated.
--   - Granted exclusively to service_role.
-- ============================================================================

-- Ensure pgcrypto extension is active
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION public.verify_dealer_password(
    p_mobile TEXT,
    p_password TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_dealer_id UUID;
    v_password_hash TEXT;
BEGIN
    -- Match by exact 10-digit mobile number, or with +91 prefix
    SELECT id, password_hash INTO v_dealer_id, v_password_hash
    FROM public.dealer_accounts
    WHERE mobile_number = p_mobile
       OR mobile_number = ('+91' || p_mobile)
       OR RIGHT(mobile_number, 10) = p_mobile
    LIMIT 1;

    -- Return NULL if no account matches
    IF v_dealer_id IS NULL OR v_password_hash IS NULL THEN
        RETURN NULL;
    END IF;

    -- Verify standard bcrypt ($2a$, $2b$, $2y$, $2x$)
    IF v_password_hash LIKE '$2%' THEN
        IF crypt(p_password, v_password_hash) = v_password_hash THEN
            RETURN v_dealer_id;
        END IF;
    END IF;

    -- Return NULL if password verification fails
    RETURN NULL;
END;
$$;

-- Strict privilege lockdown: Revoke execution from PUBLIC, anon, and authenticated
REVOKE ALL ON FUNCTION public.verify_dealer_password(TEXT, TEXT) FROM PUBLIC, anon, authenticated;

-- Grant execution privilege strictly to service_role (Cloudflare Worker only)
GRANT EXECUTE ON FUNCTION public.verify_dealer_password(TEXT, TEXT) TO service_role;
