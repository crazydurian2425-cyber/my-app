-- ============================================================================
-- Fix airport_buffer_minutes for NON-flight departures
--
-- The reset SQL set meta.airport_buffer_minutes = 180 on every unit
-- regardless of departure method. For trains/buses/cars, 180 min is
-- way too high — the dashboard ends up computing a SUGGESTED END
-- 3 hours before the train, which is unrealistic. A 9:00 am train
-- shouldn't cut off the day at 6:00 am.
--
-- Realistic buffers:
--   flight  →  180 min  (3 h: airport transit + check-in + security + gate)
--   train   →   60 min  (gare arrival 15-20 min before, modest cushion)
--   bus     →   45 min
--   car     →   30 min  (just drive — buffer is for traffic/parking)
--
-- This UPDATE rewrites airport_buffer_minutes per-method. Idempotent —
-- second run hits the same final values.
-- ============================================================================

UPDATE public.travelers
SET    meta = jsonb_set(meta, '{airport_buffer_minutes}',
                (CASE meta->>'unit_departure_method'
                  WHEN 'flight' THEN '180'
                  WHEN 'train'  THEN '60'
                  WHEN 'bus'    THEN '45'
                  WHEN 'car'    THEN '30'
                  ELSE                '90'
                 END)::jsonb)
WHERE  meta ? 'unit_departure_method';


-- ── Verify ──────────────────────────────────────────────────────────
-- a) Distribution by method.
SELECT meta->>'unit_departure_method'              AS method,
       (meta->>'airport_buffer_minutes')::int      AS buffer_min,
       COUNT(*)                                     AS unit_rows
FROM   public.travelers
WHERE  meta ? 'unit_departure_method'
GROUP  BY method, buffer_min
ORDER  BY method;

-- b) Per-unit view — confirms train units now have 60, flights have 180.
SELECT meta->>'person_id' AS person, name, destination,
       meta->>'unit_departure_method'           AS method,
       meta->>'unit_departure_time'             AS dep_time,
       (meta->>'airport_buffer_minutes')::int   AS buffer_min
FROM   public.travelers
WHERE  meta ? 'unit_departure_method'
ORDER  BY (meta->>'person_id')::int, (meta->>'unit_order')::int;
