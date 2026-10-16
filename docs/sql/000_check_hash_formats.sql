-- ============================================================================
-- Read-Only Hash Format Distribution Check
-- Purpose: Count dealer_accounts rows by password_hash prefix.
-- Security: READ-ONLY. NEVER prints, outputs, or exposes actual password hashes.
-- Target: Run in Supabase SQL Editor on STAGING.
-- ============================================================================

SELECT 
    CASE 
        WHEN password_hash LIKE '$2a$%' THEN 'bcrypt ($2a$)'
        WHEN password_hash LIKE '$2b$%' THEN 'bcrypt ($2b$)'
        WHEN password_hash LIKE '$2y$%' THEN 'bcrypt ($2y$)'
        WHEN password_hash LIKE 'pbkdf2$%' THEN 'pbkdf2'
        WHEN password_hash IS NULL OR password_hash = '' THEN 'empty_or_null'
        ELSE 'other_unknown'
    END AS hash_format,
    COUNT(*) AS total_accounts
FROM public.dealer_accounts
GROUP BY 1
ORDER BY 2 DESC;
