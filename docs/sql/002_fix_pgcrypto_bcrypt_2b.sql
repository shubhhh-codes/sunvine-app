-- ============================================================================
-- Migration: Fix $2b$ Prefix Normalization for PostgreSQL pgcrypto
-- Target: STAGING SUPABASE ONLY (Run in Supabase SQL Editor by Administrator)
-- Issue: PostgreSQL pgcrypto crypt() natively recognizes $2a$ prefix for bcrypt.
--        Node.js bcrypt/bcryptjs generates $2b$ hashes. Passing $2b$ causes
--        pgcrypto to fall back to DES salt, always returning false.
-- Fix: Normalize $2b$ and $2y$ prefixes to $2a$ during verification.
-- ============================================================================

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
    v_normalized_hash TEXT;
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
        -- Normalize $2b$ / $2y$ prefix to $2a$ for pgcrypto compatibility
        v_normalized_hash := regexp_replace(v_password_hash, '^\$2[by]\$', '$2a$');

        IF crypt(p_password, v_normalized_hash) = v_normalized_hash THEN
            RETURN v_dealer_id;
        END IF;
    END IF;

    -- Return NULL if password verification fails
    RETURN NULL;
END;
$$;

-- Ensure privileges remain strictly locked to service_role
REVOKE ALL ON FUNCTION public.verify_dealer_password(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_dealer_password(TEXT, TEXT) TO service_role;
