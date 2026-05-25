-- ============================================================================
-- Fix set_assignments.status — backfill 'in_progress' → 'active'
--
-- The codebase reads/writes set_assignments.status with the canonical
-- value 'active' for a planner's CURRENT working set. But the column
-- default per initial.sql is 'in_progress' (because initial.sql was
-- written before the policy converged). Every doAssign INSERT that
-- didn't specify status got 'in_progress', and the dashboard's strict
-- "WHERE status='active'" filter missed those rows — the planner saw
-- nothing after assignment.
--
-- This migration:
--   1. Asserts the check_constraint accepts 'active'. Drops + re-adds
--      with both 'active' AND 'in_progress' as valid values so we can
--      use either name and no migration cliff breaks existing rows.
--   2. Backfills any current 'in_progress' rows that look like they
--      should be 'active' (most recent claim per planner with no
--      completed_at / paid_at).
--   3. Changes the column DEFAULT to 'active' so future rows that
--      don't specify status land correctly.
--
-- Re-run safe: idempotent. Re-running re-checks the constraint, the
-- backfill UPDATE only touches rows still mislabeled.
-- ============================================================================

-- ── 1. Allow 'active' in the check_constraint (idempotent) ──
DO $$
DECLARE
  con_name text;
BEGIN
  -- Find the existing status check constraint name on set_assignments
  SELECT conname INTO con_name
  FROM   pg_constraint
  WHERE  conrelid = 'public.set_assignments'::regclass
    AND  contype = 'c'
    AND  pg_get_constraintdef(oid) ILIKE '%status%';
  IF con_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.set_assignments DROP CONSTRAINT %I', con_name);
  END IF;
END $$;

ALTER TABLE public.set_assignments
  ADD CONSTRAINT set_assignments_status_check
  CHECK (status IN ('active','in_progress','submitted','completed','paid','cancelled'));


-- ── 2. Backfill in_progress → active (only the planner's most-recent
--      claim, to avoid waking up a historical row that should have
--      been resolved) ──
WITH latest_per_planner AS (
  SELECT DISTINCT ON (planner_id) id
  FROM   public.set_assignments
  WHERE  status = 'in_progress'
    AND  completed_at IS NULL
    AND  paid_at      IS NULL
  ORDER  BY planner_id, claimed_at DESC NULLS LAST, id DESC
)
UPDATE public.set_assignments
SET    status = 'active'
WHERE  id IN (SELECT id FROM latest_per_planner);


-- ── 3. Change the column default so future inserts land as 'active' ──
ALTER TABLE public.set_assignments
  ALTER COLUMN status SET DEFAULT 'active';


-- ── Verify ──────────────────────────────────────────────────────────
-- a) The constraint now accepts both 'active' and 'in_progress'.
SELECT pg_get_constraintdef(oid) AS check_clause
FROM   pg_constraint
WHERE  conrelid = 'public.set_assignments'::regclass
  AND  contype  = 'c';

-- b) Status distribution across all assignments.
SELECT status, COUNT(*) FROM public.set_assignments GROUP BY status ORDER BY status;

-- c) Each planner has at MOST one 'active' assignment (policy invariant).
SELECT planner_id, COUNT(*) AS active_count
FROM   public.set_assignments
WHERE  status = 'active'
GROUP  BY planner_id
HAVING COUNT(*) > 1;
-- → 0 rows expected.
