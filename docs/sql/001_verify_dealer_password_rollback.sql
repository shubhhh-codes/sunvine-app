-- ============================================================================
-- Rollback Migration for: 001_verify_dealer_password.sql
-- Target: STAGING SUPABASE (Run in Supabase SQL Editor if rollback is needed)
-- Action: Completely removes public.verify_dealer_password function and permissions.
-- Safety: Leaves all tables, columns, and dealer accounts 100% untouched.
-- Note: Does NOT drop pgcrypto because pgcrypto is used by other system UUIDs/hashes.
-- ============================================================================

-- 1. Revoke any remaining privileges
REVOKE ALL ON FUNCTION public.verify_dealer_password(text, text) FROM PUBLIC, anon, authenticated, service_role;

-- 2. Drop the verification function
DROP FUNCTION IF EXISTS public.verify_dealer_password(text, text);

-- 3. Verification check: confirms function no longer exists in PostgreSQL catalog
SELECT proname, proowner::regrole AS function_owner
FROM pg_proc
WHERE proname = 'verify_dealer_password';
-- Expected result: 0 rows returned (confirming complete removal)
