-- ============================================================================
-- One-off data migration for Plan 1 ONLY (Sofía's Saint-Malo unit), so the
-- planner can see the new hotel_checkin / hotel_checkout categories on a
-- real plan before we roll out to plans 2-30.
--
-- Strategy:
--   1. Day 1 → relabel the existing accommodation slot (if any) as
--      hotel_checkin. If no accommodation slot exists on Day 1, do nothing
--      — Phase 2 will auto-suggest one.
--   2. Last day → if an accommodation slot exists, relabel as
--      hotel_checkout. Otherwise skip.
--
-- The CHECK constraint update from add-stop-categories.sql MUST be run
-- before this script.
--
-- Idempotent: re-running this just re-applies the same UPDATEs (rows
-- already at hotel_checkin / hotel_checkout match the WHERE on first
-- run, no-op the second time).
-- ============================================================================


-- Sofía's plan #1 lives at sort_order = 1 of her plans (or by plan_number=1).
-- Use plan_number to make this resilient to row-shuffles in plans table.

WITH p1 AS (
  SELECT id, plan_number,
         -- day_count derived from itinerary_items max(day_number) so this
         -- works even if duration isn't filled in. Falls back to 1.
         GREATEST(1, COALESCE(
           (SELECT MAX(day_number) FROM public.itinerary_items WHERE plan_id = plans.id),
           1
         )) AS day_count
  FROM public.plans
  WHERE plan_number = 1
  LIMIT 1
)
-- Day 1 accommodation → hotel_checkin
UPDATE public.itinerary_items ii
SET    type = 'hotel_checkin'
FROM   p1
WHERE  ii.plan_id     = p1.id
  AND  ii.day_number  = 1
  AND  ii.type        = 'accommodation';

WITH p1 AS (
  SELECT id,
         GREATEST(1, COALESCE(
           (SELECT MAX(day_number) FROM public.itinerary_items WHERE plan_id = plans.id),
           1
         )) AS day_count
  FROM public.plans
  WHERE plan_number = 1
  LIMIT 1
)
-- Last day accommodation → hotel_checkout
UPDATE public.itinerary_items ii
SET    type = 'hotel_checkout'
FROM   p1
WHERE  ii.plan_id     = p1.id
  AND  ii.day_number  = p1.day_count
  AND  ii.type        = 'accommodation';


-- ── Verify ─────────────────────────────────────────────────────────────────
--   SELECT day_number, type, title, time
--   FROM public.itinerary_items
--   WHERE plan_id = (SELECT id FROM public.plans WHERE plan_number = 1)
--   ORDER BY day_number, sort_order;
