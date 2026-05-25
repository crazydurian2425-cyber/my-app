-- ============================================================================
-- Force-assign a set to a planner via direct SQL
--
-- Reliable bypass for the buggy doAssign() admin flow. Run this in
-- Supabase SQL editor any time the admin tool's Assign button doesn't
-- result in the planner seeing the new set. Bypasses RLS entirely
-- (SQL editor uses the service_role connection) and writes the rows
-- the dashboard needs to render the set on the planner's side.
--
-- HOW TO USE:
--   1. Replace _PLANNER_ID_ with the planner's auth.users.id (UUID).
--      For Ben: 4716c499-6102-47bf-9b0e-7ff8b049aff8
--   2. Replace _SET_NUMBER_ with the set number you want to assign
--      (e.g. 9 for Set #009).
--   3. Run. The dashboard picks up the new active set on next reload.
--
-- Re-run safe: idempotent. If the assignment row already exists, it's
-- revived to status='active' with claimed_at=now(). If plans already
-- exist for (set, planner, traveler), they're skipped.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────
-- EDIT THESE TWO VALUES, then run the whole file.
-- ────────────────────────────────────────────────────────────────────────
-- planner_id: copy from your planners table — the auth.users.id of the
--             planner you're assigning to. For Ben: see comment above.
-- set_number: the integer column on the sets table. For Set #009 use 9.

-- ────────────────────────────────────────────────────────────────────────
-- Step 0 · Demote any OTHER 'active' or 'in_progress' assignments this
--          planner has (one active set per planner policy).
-- ────────────────────────────────────────────────────────────────────────
UPDATE public.set_assignments
SET    status = 'completed'
WHERE  planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8'   -- ← PLANNER ID
  AND  status IN ('active', 'in_progress')
  AND  set_id != (SELECT id FROM public.sets WHERE set_number = 9);  -- ← SET NUMBER


-- ────────────────────────────────────────────────────────────────────────
-- Step 1 · Upsert the assignment row (revive if exists, insert if not).
--          status='active' so the dashboard's active-set query finds it.
-- ────────────────────────────────────────────────────────────────────────
UPDATE public.set_assignments
SET    status     = 'active',
       claimed_at = NOW(),
       deadline   = (NOW() + INTERVAL '2 days')::date,
       completed_at = NULL,
       paid_at      = NULL
WHERE  planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8'
  AND  set_id     = (SELECT id FROM public.sets WHERE set_number = 9);

INSERT INTO public.set_assignments (set_id, planner_id, claimed_at, deadline, status)
SELECT (SELECT id FROM public.sets WHERE set_number = 9),
       '4716c499-6102-47bf-9b0e-7ff8b049aff8'::uuid,
       NOW(),
       (NOW() + INTERVAL '2 days')::date,
       'active'
WHERE  NOT EXISTS (
  SELECT 1 FROM public.set_assignments
  WHERE  planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8'
    AND  set_id     = (SELECT id FROM public.sets WHERE set_number = 9)
);


-- ────────────────────────────────────────────────────────────────────────
-- Step 2 · Tag the set itself as claimed by this planner.
-- ────────────────────────────────────────────────────────────────────────
UPDATE public.sets
SET    status     = 'claimed',
       planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8',
       claimed_at = NOW()
WHERE  set_number = 9;


-- ────────────────────────────────────────────────────────────────────────
-- Step 3 · Create plan copies for the planner from the set's template
--          (NULL-planner rows created by postSet). Skip duplicates.
-- ────────────────────────────────────────────────────────────────────────
INSERT INTO public.plans
  (set_id, traveler_id, plan_number, planner_id, status, arrival_date_snapshot)
SELECT p.set_id, p.traveler_id, p.plan_number,
       '4716c499-6102-47bf-9b0e-7ff8b049aff8'::uuid,
       CASE WHEN p.plan_number = 1 THEN 'in_progress' ELSE 'pending' END,
       t.arrival_date
FROM   public.plans     p
JOIN   public.sets      s ON s.id = p.set_id
JOIN   public.travelers t ON t.id = p.traveler_id
WHERE  s.set_number = 9
  AND  p.planner_id IS NULL
  AND  NOT EXISTS (
    SELECT 1 FROM public.plans p2
    WHERE  p2.set_id      = p.set_id
      AND  p2.traveler_id = p.traveler_id
      AND  p2.planner_id  = '4716c499-6102-47bf-9b0e-7ff8b049aff8'::uuid
  );


-- ────────────────────────────────────────────────────────────────────────
-- Verify
-- ────────────────────────────────────────────────────────────────────────
SELECT 'ASSIGNMENT' AS item,
       sa.set_id::text, sa.status,
       sa.claimed_at::text,
       s.set_number::text AS set_no
FROM   public.set_assignments sa
JOIN   public.sets s ON s.id = sa.set_id
WHERE  sa.planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8'
ORDER  BY sa.claimed_at DESC
LIMIT  5;

SELECT 'PLAN' AS item,
       p.id::text, p.plan_number::text, p.status,
       t.name, t.destination
FROM   public.plans p
JOIN   public.sets s     ON s.id = p.set_id
JOIN   public.travelers t ON t.id = p.traveler_id
WHERE  s.set_number = 9
  AND  p.planner_id = '4716c499-6102-47bf-9b0e-7ff8b049aff8'
ORDER  BY p.plan_number;
