-- ============================================================================
-- 003_add_banking_columns_to_dealer_accounts.sql
-- Add missing banking and statutory tax columns to staging dealer_accounts
-- to achieve 100% schema parity with Production CSV export.
-- ============================================================================

ALTER TABLE public.dealer_accounts
  ADD COLUMN IF NOT EXISTS bank_name TEXT,
  ADD COLUMN IF NOT EXISTS account_number TEXT,
  ADD COLUMN IF NOT EXISTS ifsc_code TEXT,
  ADD COLUMN IF NOT EXISTS branch TEXT,
  ADD COLUMN IF NOT EXISTS pan_number TEXT,
  ADD COLUMN IF NOT EXISTS gst_number TEXT;

-- Recreate the view so it automatically exposes the new columns to the app gateway
CREATE OR REPLACE VIEW public.dealers AS
  SELECT * FROM public.dealer_accounts;
