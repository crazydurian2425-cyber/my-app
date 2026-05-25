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
--   1. DEDUPES existing duplicates. Explicitly deletes itinerary_items
--      first, THEN the duplicate plan row. The FK from itinerary_items
--      → plans is declared ON DELETE CASCADE in initial.sql but the
--      LIVE database has it as RESTRICT (schema drift), so we can't
--      trust cascade to fire.
--   2. ADDS a partial unique index to PREVENT future duplicates from
--      being inserted. NULL planner_id is excluded (template plans
--      can legitimately co-exist with planner copies on the same set).
--
-- After this, any future doAssign INSERT that would create a duplicate
-- will fail with 23505 unique_violation instead of silently corrupting
-- the dashboard.
--
-- Implementation: uses inline CTEs (no TEMP TABLE) so Supabase's
-- "creates a table without RLS" linter warning never fires.
-- ============================================================================

-- ── 1a. Delete itinerary_items linked to duplicate plans ──
-- The live FK is RESTRICT, not CASCADE (despite what initial.sql says),
-- so items on duplicate plans would block their deletion. Wipe first.
WITH dupe_plan_ids AS (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY set_id, planner_id, traveler_id
      ORDER BY created_at DESC NULLS LAST, id DESC
    ) AS rn
    FROM   public.plans
    WHERE  planner_id IS NOT NULL
  ) ranked
  WHERE  rn > 1
)
DELETE FROM public.itinerary_items
WHERE  plan_id IN (SELECT id FROM dupe_plan_ids);


-- ── 1b. Delete the duplicate plan rows themselves ──
-- Re-evaluate the same CTE because the previous DELETE doesn't change
-- which plans are duplicates — rn is computed off plans alone.
WITH dupe_plan_ids AS (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY set_id, planner_id, traveler_id
      ORDER BY created_at DESC NULLS LAST, id DESC
    ) AS rn
    FROM   public.plans
    WHERE  planner_id IS NOT NULL
  ) ranked
  WHERE  rn > 1
)
DELETE FROM public.plans
WHERE  id IN (SELECT id FROM dupe_plan_ids);


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
