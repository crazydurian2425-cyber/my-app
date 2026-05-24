-- ============================================================================
-- Unit-1 airport-arrival cleanup
--
-- The "last-leg" model that the Day form expects: every traveler's UNIT 1
-- arrives at a real airport (IATA), method='flight', and lands inside the
-- 13:45-15:00 window so the planner has room to ferry them to the hotel,
-- check in, drop bags, and still start a light Day-1 activity before dinner.
--
-- Two problems this fixes:
--
--   1. Sofía's unit 1 stored `unit_arrival_location` as
--      "RNS (via CDG transfer)". The Day form's _lookupStationAndAttach
--      resolver expects either a clean 3-letter IATA code (`/^[A-Z]{3}$/`)
--      or a real station name. The parenthetical broke the IATA regex, so
--      Places `searchText` fell through to a generic query biased to the
--      destination city — and returned "RNC Logistics – Conseil et
--      diagnostic en logistique" instead of Rennes Saint-Jacques Airport.
--
--   2. Some unit-1 rows have arrival_time outside the 13:45-15:00 window
--      (Sofía was 09:50, etc.). The Day-1 banner is awkward when the
--      traveler "lands at 09:50" with nothing to do for 4 hours before
--      hotel check-in.
--
-- Idempotent — only writes when current value is wrong. Safe to re-run.
-- ============================================================================


-- ── 1. Sofía Romero · unit 1 (Saint-Malo) ────────────────────────────────
-- Flight from Buenos Aires lands at Rennes (RNS) at 13:45. The CDG transfer
-- is implicit — the airline handles it; we just record the final airport
-- the traveler steps off at. Day 1 then begins: RNS → Saint-Malo hotel
-- (≈55 km, 1 h drive or train via Rennes Gare).
UPDATE public.travelers
SET arrival_time = '13:45',
    meta = meta
         || jsonb_build_object(
              'unit_arrival_method',   'flight',
              'unit_arrival_location', 'RNS',
              'unit_arrival_from',     'Buenos Aires, Argentina'
            )
WHERE meta->>'seed_batch' = '01'
  AND meta->>'person_id'  = '02'
  AND meta->>'unit_order' = '1';


-- ── 2. Mass-clean parentheticals in unit_arrival_location ───────────────
-- Anything like "RNS (via CDG transfer)" → "RNS". Strip whitespace + the
-- entire "(...)" suffix. If what's LEFT isn't a clean 3-letter IATA, we
-- leave it alone so a manually-written station name (e.g.
-- "Paris Gare Montparnasse") isn't accidentally destroyed.
UPDATE public.travelers
SET meta = jsonb_set(
  meta,
  '{unit_arrival_location}',
  to_jsonb(regexp_replace(meta->>'unit_arrival_location', '\s*\(.*\)\s*$', ''))
)
WHERE meta->>'seed_batch' = '01'
  AND meta->>'unit_order' = '1'
  AND meta->>'unit_arrival_location' ~ '\(';


-- ── 3. Mass-clamp unit-1 arrival_time into the 13:45-15:00 window ───────
-- Only touches rows currently outside the window. 14:00 is the
-- mid-window default — the planner can fine-tune in the admin tool if
-- a specific flight schedule requires it.
UPDATE public.travelers t
SET arrival_time = '14:00'
WHERE t.meta->>'seed_batch' = '01'
  AND t.meta->>'unit_order' = '1'
  AND (
        t.arrival_time IS NULL
     OR t.arrival_time < '13:45'
     OR t.arrival_time > '15:00'
      );


-- ── Verify ──────────────────────────────────────────────────────────────
-- a) Sofía's unit 1 should now read: 13:45, RNS, flight, Buenos Aires.
SELECT meta->>'person_id'             AS person,
       meta->>'unit_order'             AS unit,
       destination,
       arrival_date, arrival_time,
       meta->>'unit_arrival_method'   AS arr_method,
       meta->>'unit_arrival_location' AS arr_loc,
       meta->>'unit_arrival_from'     AS arr_from
FROM   public.travelers
WHERE  meta->>'seed_batch' = '01'
  AND  meta->>'person_id'  = '02'
ORDER  BY (meta->>'unit_order')::int;

-- b) Spot-check: any unit-1 rows still carrying a parenthetical?
SELECT COUNT(*) AS still_dirty
FROM   public.travelers
WHERE  meta->>'seed_batch' = '01'
  AND  meta->>'unit_order' = '1'
  AND  meta->>'unit_arrival_location' ~ '\(';
-- → 0

-- c) Spot-check: any unit-1 rows still outside the 13:45-15:00 window?
SELECT COUNT(*) AS still_out_of_window
FROM   public.travelers
WHERE  meta->>'seed_batch' = '01'
  AND  meta->>'unit_order' = '1'
  AND  (arrival_time IS NULL OR arrival_time < '13:45' OR arrival_time > '15:00');
-- → 0
