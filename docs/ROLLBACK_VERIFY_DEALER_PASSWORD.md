# Rollback Guide: `001_verify_dealer_password.sql`

This guide explains the changes made by `001_verify_dealer_password.sql` and provides the exact procedure to safely revert/rollback the migration on Supabase.

---

## 1. What Changed in the Database? (Simple Explanation)

- **Existing Tables & Columns**: **NO changes**. No columns were added, modified, or dropped from `dealer_accounts` or any other table.
- **Existing Records/Data**: **NO changes**. No rows were updated or deleted.
- **What Was Added**: Exactly **one helper function** named `public.verify_dealer_password(p_mobile text, p_password text)`.
- **Permissions**: Execution permission is restricted strictly to `service_role` (Cloudflare Worker backend). All public and anonymous access is revoked.

---

## 2. When Should You Rollback?

You can safely run the rollback script if:
- You want to completely remove the custom RPC verification function.
- You decide to use a different password verification approach (e.g. Workers Paid plan).
- You want to restore Staging Supabase to its exact clean state prior to this migration.

---

## 3. Rollback Instructions (Step-by-Step)

1. Open your **Supabase Dashboard** for the **Staging** project (`voyargkmlkrlidyxjcbk`).
2. In the left navigation menu, click **SQL Editor**.
3. Click **New Query**.
4. Copy and paste the SQL script below.
5. Click **Run** (or press `Ctrl+Enter` / `Cmd+Enter`).
6. The query will drop the function and execute a verification check returning `0 rows`, confirming complete removal.

---

## 4. Rollback SQL Script

```sql
-- ============================================================================
-- Rollback Script: Remove public.verify_dealer_password
-- Target: Supabase SQL Editor (Staging)
-- Safety: Completely non-destructive. Tables & dealer accounts are untouched.
-- ============================================================================

-- Step 1: Revoke all execution permissions
REVOKE ALL ON FUNCTION public.verify_dealer_password(text, text) 
FROM PUBLIC, anon, authenticated, service_role;

-- Step 2: Drop the function from the public schema
DROP FUNCTION IF EXISTS public.verify_dealer_password(text, text);

-- Step 3: Verification check
-- Expected Result: 0 rows returned (confirms the function is completely gone)
SELECT proname, proowner::regrole AS function_owner
FROM pg_proc
WHERE proname = 'verify_dealer_password';
```

---

## 5. Verification After Rollback

When you run the verification query:
```sql
SELECT proname FROM pg_proc WHERE proname = 'verify_dealer_password';
```
- **If removed successfully**: Result shows `0 rows` (empty table).
- Your Supabase database is now 100% back to its original state.
