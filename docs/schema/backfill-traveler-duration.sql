-- ============================================================================
-- Backfill empty travelers.duration so plan tiles show the day count.
--
-- Symptom: a plan card shows "家族 · " with no 〇泊〇日, and opening that plan
-- shows a hard-coded "3D2N" — because the traveler's `duration` COLUMN is empty.
-- The grid reads the column directly (blank when empty); the itinerary builder
-- fell back to a literal '3D2N'. The real fix is to populate the column.
--
-- Derives the value in priority order, only touching rows where duration is
-- currently empty. Format is "<days>D<nights>N" (e.g. 4D3N), matching the rest
-- of the data. Idempotent — re-running skips rows that are already filled.
-- ============================================================================

-- 0) DIAGNOSTIC — see which travelers are missing a duration and what we can
--    derive it from. Run this first to confirm (e.g. your Plan 15 traveler).
SELECT id, traveler_type, arrival_date,
       meta->>'trip_total_duration' AS meta_dur,
       meta->>'trip_start_date'     AS trip_start,
       meta->>'trip_end_date'       AS trip_end,
       meta->>'unit_departure_date' AS unit_dep
FROM public.travelers
WHERE coalesce(duration,'') = ''
ORDER BY arrival_date NULLS LAST;

-- 1) Copy the canonical label when meta already has it (e.g. '4D3N').
UPDATE public.travelers
SET duration = upper(meta->>'trip_total_duration')
WHERE coalesce(duration,'') = ''
  AND coalesce(meta->>'trip_total_duration','') <> '';

-- 2) Compute from trip_start_date / trip_end_date.
--    days = span + 1, nights = span (inclusive of arrival day).
UPDATE public.travelers
SET duration = (((meta->>'trip_end_date')::date - (meta->>'trip_start_date')::date) + 1)::text
            || 'D'
            || ((meta->>'trip_end_date')::date - (meta->>'trip_start_date')::date)::text || 'N'
WHERE coalesce(duration,'') = ''
  AND coalesce(meta->>'trip_start_date','') <> ''
  AND coalesce(meta->>'trip_end_date','')   <> '';

-- 3) Last resort: arrival_date → meta.unit_departure_date.
UPDATE public.travelers
SET duration = ((((meta->>'unit_departure_date')::date) - arrival_date) + 1)::text
            || 'D'
            || (((meta->>'unit_departure_date')::date) - arrival_date)::text || 'N'
WHERE coalesce(duration,'') = ''
  AND arrival_date IS NOT NULL
  AND coalesce(meta->>'unit_departure_date','') <> '';

-- 4) VERIFY — anything still blank here has no trip dates anywhere and must be
--    set by hand (or is a broken seed row).
SELECT id, traveler_type, arrival_date, duration
FROM public.travelers
WHERE coalesce(duration,'') = '';
