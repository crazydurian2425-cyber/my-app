-- ============================================================================
-- Fix 2D1N planner commission: ¥7,300 → ¥5,500 (jp-01 batch).
--
-- The jp-01 seed flat-set planner_payout = 7300 on every unit, but the
-- intended rate (dashboard baseCommissionForDuration) is 3D2N ¥7,300 /
-- 2D1N ¥5,500 — and the planner dashboard card already shows ¥5,500 for
-- 2D1N. This aligns the stored payout (what the wallet credits) with that.
--
-- In-place UPDATE — preserves assignments/plans. Reads live; future + pending
-- 2D1N plans will credit ¥5,500. Already-paid wallet entries are unchanged.
-- Idempotent: re-running matches nothing (none left at 7300). Only touches
-- 2D1N units still at the flat 7300, so any admin-customised payout is safe.
-- 3D2N (¥7,300) and the luxury bond batch are untouched.
-- ============================================================================

UPDATE public.travelers
SET planner_payout = 5500
WHERE meta->>'seed_batch' = 'jp-01'
  AND duration = '2D1N'
  AND planner_payout = 7300;

-- Verify:
--   SELECT duration, planner_payout, count(*)
--     FROM public.travelers WHERE meta->>'seed_batch' = 'jp-01'
--     GROUP BY duration, planner_payout ORDER BY duration;
--   -- expect 2D1N → 5500, 3D2N → 7300
