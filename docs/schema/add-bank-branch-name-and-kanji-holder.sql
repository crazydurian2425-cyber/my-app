-- ============================================================================
-- Add 支店名 (branch name) and 口座名義漢字 (kanji account holder) to planners.
--
-- The bank-details form previously stored only the branch CODE and the KATAKANA
-- holder. Admins and furikomi forms often also need the branch NAME and the
-- kanji holder name. These two columns store them.
--
-- NULLABLE → safe for EVERY existing planner: their rows get NULL, all forms and
-- payout lines keep working, and the new fields simply show blank until a
-- planner next saves their bank details. No existing data is touched.
-- Idempotent — safe to re-run.
-- ============================================================================
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS bank_branch_name  text;
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS bank_holder_kanji text;
