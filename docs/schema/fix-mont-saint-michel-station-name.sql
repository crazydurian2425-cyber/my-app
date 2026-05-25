-- ============================================================================
-- Fix "Mont-Saint-Michel Station" → "Gare de Pontorson"
--
-- The MSM village has no train station. The actual SNCF station serving
-- Mont-Saint-Michel is in Pontorson village, ~9 km inland, named
-- "Gare de Pontorson" (TER line from Rennes / Caen, with a shuttle to
-- the abbey).
--
-- Sofía's unit 2 (MSM) seed data stored "Mont-Saint-Michel Station" for
-- both arrival_location and departure_location. That string doesn't
-- resolve to a real Google Place — searchText falls back to "Le Mont
-- St Michel" (the village), so the End Trip transport ends at the
-- village square instead of the train station, with a wrong route +
-- duration.
--
-- This UPDATE rewrites any meta arrival_location / departure_location
-- whose value is exactly "Mont-Saint-Michel Station" to "Gare de
-- Pontorson". Idempotent — second run is a no-op because the WHERE
-- filter no longer matches.
-- ============================================================================

-- Fix arrival_location matches.
UPDATE public.travelers
SET    meta = jsonb_set(meta, '{unit_arrival_location}', '"Gare de Pontorson"'::jsonb)
WHERE  meta->>'unit_arrival_location' = 'Mont-Saint-Michel Station';

-- Fix departure_location matches.
UPDATE public.travelers
SET    meta = jsonb_set(meta, '{unit_departure_location}', '"Gare de Pontorson"'::jsonb)
WHERE  meta->>'unit_departure_location' = 'Mont-Saint-Michel Station';

-- ── Verify ──────────────────────────────────────────────────────────
-- No row should still carry the old string.
SELECT COUNT(*) AS still_bad
FROM   public.travelers
WHERE  meta->>'unit_arrival_location'   = 'Mont-Saint-Michel Station'
   OR  meta->>'unit_departure_location' = 'Mont-Saint-Michel Station';
-- → 0

-- Sofía's unit 2 row should now show "Gare de Pontorson" on both sides.
SELECT meta->>'unit_order' AS unit, destination,
       meta->>'unit_arrival_location'   AS arr_loc,
       meta->>'unit_departure_location' AS dep_loc
FROM   public.travelers
WHERE  meta->>'person_id' = '02'
ORDER  BY (meta->>'unit_order')::int;
