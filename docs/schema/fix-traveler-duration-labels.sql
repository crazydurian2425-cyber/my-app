-- ============================================================================
-- Fix drifted / blank traveler duration labels (4 single-unit travelers)
--
-- WHY
--   The `duration` column drives how many day-cards the planner's itinerary
--   builder tiles ("units tile to duration label"). For these 4 SINGLE-UNIT
--   trips the label had drifted from the real arrival -> departure span:
--     • 1 stale  (Daniel & Grace Park: label 3D2N, trip is 4 days)
--     • 3 blank  (Chen Wei, Olivia & James Thompson, Isabella & Matteo Romano)
--   so planners were handed the wrong number of days (e.g. a 4-day trip built
--   as 3 days, missing the departure day).
--
--   Each record's own meta.trip_total_duration ALREADY holds the correct value;
--   the fixes below simply set `duration` to match the actual dates.
--
--   Verified safe: all 4 are unit_total = 1 (the leg IS the whole trip), so the
--   whole-trip span is the correct per-record duration. Multi-city travelers
--   (one row per leg) were checked and are all consistent — untouched here.
--
-- SAFETY
--   Scoped by explicit id + a guard on the current (wrong) value. Idempotent:
--   re-running after the fix updates 0 rows, and it will not overwrite a value
--   that was corrected some other way in the meantime.
-- ============================================================================

-- Daniel & Grace Park · Tokyo · 2026-08-13 -> 2026-08-16   (3D2N -> 4D3N)
update public.travelers
   set duration = '4D3N'
 where id = 'c0000001-0000-4000-8000-000200010000'
   and duration = '3D2N';

-- Chen Wei · Kanazawa · 2026-08-05 -> 2026-08-09           ('' -> 5D4N)
update public.travelers
   set duration = '5D4N'
 where id = 'c0000001-0000-4000-8000-000400010000'
   and coalesce(duration, '') = '';

-- Olivia & James Thompson · Kyoto · 2026-08-08 -> 2026-08-12  ('' -> 5D4N)
update public.travelers
   set duration = '5D4N'
 where id = 'c0000001-0000-4000-8000-000500010000'
   and coalesce(duration, '') = '';

-- Isabella & Matteo Romano · Hakone · 2026-08-10 -> 2026-08-15  ('' -> 6D5N)
update public.travelers
   set duration = '6D5N'
 where id = 'c0000001-0000-4000-8000-001000010000'
   and coalesce(duration, '') = '';

-- Verify (all four `duration` values should now match `meta_total`):
--   select id, name, destination, duration, arrival_date,
--          meta->>'unit_departure_date' as departs,
--          meta->>'trip_total_duration' as meta_total
--     from public.travelers
--    where id in ('c0000001-0000-4000-8000-000200010000',
--                 'c0000001-0000-4000-8000-000400010000',
--                 'c0000001-0000-4000-8000-000500010000',
--                 'c0000001-0000-4000-8000-001000010000');
