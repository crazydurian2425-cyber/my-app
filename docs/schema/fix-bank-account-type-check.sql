-- ============================================================================
-- Fix: planners_bank_account_type_check rejects the app's values.
--
-- Symptom (Profile → save bank): 保存に失敗しました: new row for relation
--   "planners" violates check constraint "planners_bank_account_type_check"
--
-- Cause: SCHEMA DRIFT. The live constraint allows ENGLISH account types
--   ('futsu'/'touza'/…) and existing rows store English (confirmed: a planner
--   row has bank_account_type = 'futsu'). The app + repo migration
--   (add-bank-account-type.sql), however, read/write the JAPANESE values
--   '普通' / '当座' (or NULL for PayPay/crypto). So every bank save is rejected.
--
-- Fix: realign the live data + constraint to the app contract ('普通'/'当座'/NULL).
--
-- IMPORTANT ORDERING: the constraint must be DROPPED *before* the UPDATE.
--   Otherwise the UPDATE's attempt to write '普通' is itself checked against the
--   still-active English-only constraint and fails (this is what made earlier
--   attempts roll back with the value showing as '普通'). Idempotent, safe to re-run.
-- ============================================================================

-- 0) (optional) Inspect the live constraint + existing values before changing:
--   SELECT pg_get_constraintdef(oid) FROM pg_constraint
--     WHERE conname = 'planners_bank_account_type_check';
--   SELECT bank_account_type, count(*) FROM public.planners GROUP BY 1 ORDER BY 2 DESC;

-- 1) Drop the drifted (English-only) constraint FIRST, so values can be rewritten.
ALTER TABLE public.planners
  DROP CONSTRAINT IF EXISTS planners_bank_account_type_check;

-- 2) Normalise every row to the only valid set. Map English variants to the JA
--    values; force anything else (blanks, crypto leftovers, junk) to NULL.
UPDATE public.planners
SET bank_account_type = CASE
  WHEN lower(btrim(bank_account_type)) IN ('futsu','ordinary','savings') THEN '普通'
  WHEN lower(btrim(bank_account_type)) IN ('touza','current','checking') THEN '当座'
  WHEN bank_account_type IN ('普通','当座')                              THEN bank_account_type
  ELSE NULL
END;

-- 3) Add the constraint that matches what the app actually sends.
ALTER TABLE public.planners
  ADD CONSTRAINT planners_bank_account_type_check
  CHECK (bank_account_type IS NULL OR bank_account_type IN ('普通','当座'));

-- 4) Verify:
--   SELECT pg_get_constraintdef(oid) FROM pg_constraint
--     WHERE conname = 'planners_bank_account_type_check';
--   SELECT bank_account_type, count(*) FROM public.planners GROUP BY 1;
--   -- expect only 普通 / 当座 / NULL
