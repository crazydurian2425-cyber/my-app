-- ============================================================================
-- Fix: planners_bank_account_type_check rejects the app's values.
--
-- Symptom (Profile → save bank): 保存に失敗しました: new row for relation
--   "planners" violates check constraint "planners_bank_account_type_check"
--
-- Cause: SCHEMA DRIFT. The app + repo migration (add-bank-account-type.sql)
--   store bank_account_type as the Japanese values '普通' / '当座' (and NULL
--   when PayPay is the payout method). The live DB, however, carries a CHECK
--   constraint — NOT present in the repo — that only allows some other set
--   (e.g. English 'ordinary'/'current'), so '普通'/'当座' are rejected.
--
-- Fix: realign the live constraint with what the app actually sends:
--   '普通', '当座', or NULL. Idempotent and safe to re-run.
-- ============================================================================

-- 0) (optional) Inspect what the live constraint currently allows + existing
--    values, before changing anything:
--   SELECT pg_get_constraintdef(oid) AS def
--     FROM pg_constraint WHERE conname = 'planners_bank_account_type_check';
--   SELECT bank_account_type, count(*) FROM public.planners GROUP BY 1 ORDER BY 2 DESC;

-- 1) Force bank_account_type into the only valid set. '普通'/'当座' are the only
--    legal values; map common English variants, and set EVERYTHING else
--    (blanks, crypto-payout leftovers like 'USDT', junk) to NULL — otherwise
--    the ADD CONSTRAINT below fails on those rows. (A crypto/PayPay planner has
--    no bank account type, so NULL is the correct value for them anyway.)
UPDATE public.planners
SET bank_account_type = CASE
  WHEN lower(btrim(bank_account_type)) IN ('futsu','ordinary','savings') THEN '普通'
  WHEN lower(btrim(bank_account_type)) IN ('touza','current','checking') THEN '当座'
  WHEN bank_account_type IN ('普通','当座')                              THEN bank_account_type
  ELSE NULL
END;

-- 2) Replace the drifted constraint with one matching the app contract.
ALTER TABLE public.planners
  DROP CONSTRAINT IF EXISTS planners_bank_account_type_check;

ALTER TABLE public.planners
  ADD CONSTRAINT planners_bank_account_type_check
  CHECK (bank_account_type IS NULL OR bank_account_type IN ('普通','当座'));

-- 3) Verify:
--   SELECT pg_get_constraintdef(oid) FROM pg_constraint
--     WHERE conname = 'planners_bank_account_type_check';
--   -- expect: CHECK ((bank_account_type IS NULL OR bank_account_type = ANY (ARRAY['普通','当座'])))
