-- ============================================================================
-- Fix duplicate plans + prevent recurrence
--
-- Symptom: planner dashboard shows the SAME plan card twice (e.g. "Plan 1
-- · Plan 1" instead of single "Plan 1") after a set reassignment. Root
-- cause: somewhere in the doAssign code path a duplicate
-- (set_id, planner_id, traveler_id) row got inserted — possibly a
-- read-after-write race between the wipe DELETE and the existingPlannerPlans
-- SELECT, or a legacy fallback that didn't dedupe.
--
-- This migration:
--   1. DEDUPES existing duplicates (keeps the most recent row per
--      (set_id, planner_id, traveler_id))
--   2. ADDS a partial unique index to PREVENT future duplicates from
--      being inserted. NULL planner_id is excluded (template plans
--      can legitimately co-exist with planner copies on the same set).
--
-- After this, any future doAssign INSERT that would create a duplicate
-- will fail with 23505 unique_violation instead of silently corrupting
-- the dashboard. The admin sees a clear error and can investigate.
-- ============================================================================

-- ── 1. Dedupe existing duplicates ────────────────────────────────────
-- Keep the row with the latest created_at (or highest id as tie-breaker)
-- for each (set_id, planner_id, traveler_id) combo. Itinerary_items
-- cascade off the deleted plan via FK ON DELETE CASCADE — if any items
-- existed on a duplicate plan they go too.
WITH ranked AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY set_id, planner_id, traveler_id
           ORDER BY created_at DESC NULLS LAST, id DESC
         ) AS rn
  FROM   public.plans
  WHERE  planner_id IS NOT NULL
)
DELETE FROM public.plans
WHERE  id IN (SELECT id FROM ranked WHERE rn > 1);


-- ── 2. Partial unique index — block future duplicates ───────────────
-- Partial (WHERE planner_id IS NOT NULL) so the original template
-- plans (NULL planner_id) created by postSet can still coexist with
-- per-planner copies. Each REAL planner can only own ONE plan per
-- (set, traveler) combo.
CREATE UNIQUE INDEX IF NOT EXISTS plans_unique_per_planner
  ON public.plans (set_id, planner_id, traveler_id)
  WHERE planner_id IS NOT NULL;


-- ── Verify ──────────────────────────────────────────────────────────
-- a) No duplicate (set_id, planner_id, traveler_id) combos.
SELECT set_id, planner_id, traveler_id, COUNT(*) AS dupe_count
FROM   public.plans
WHERE  planner_id IS NOT NULL
GROUP  BY set_id, planner_id, traveler_id
HAVING COUNT(*) > 1;
-- → 0 rows expected

-- b) The unique index exists.
SELECT indexname FROM pg_indexes
WHERE  schemaname = 'public' AND tablename = 'plans'
  AND  indexname = 'plans_unique_per_planner';
-- → 1 row expected

-- c) Total plans by planner — sanity check
SELECT planner_id,
       COUNT(*)                                       AS total_plans,
       COUNT(DISTINCT set_id)                          AS sets,
       COUNT(DISTINCT (set_id, traveler_id))           AS distinct_combos
FROM   public.plans
WHERE  planner_id IS NOT NULL
GROUP  BY planner_id;
-- total_plans should equal distinct_combos for every planner.
