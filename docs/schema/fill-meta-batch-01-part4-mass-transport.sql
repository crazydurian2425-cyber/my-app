-- ============================================================================
-- Mass-apply transport meta to ALL batch-01 travelers (people 01-30).
--
-- Backfills the per-unit transport fields used by the Brief panel + Day
-- forms (arrival floor, departure cap, locked transfer blocks):
--
--   unit_arrival_method      flight (first unit) / train (later units)
--   unit_arrival_location    closest airport (first) / "<city> Station" (later)
--   unit_arrival_from        origin city+country (first) / prev unit's city
--   unit_departure_date      arrival_date + (days - 1)
--   unit_departure_time      11:00 (mid-day transfer) / 17:00 (last unit flight)
--   unit_departure_method    train (middle) / flight (last unit)
--   unit_departure_location  "<city> Station" (middle) / closest airport (last)
--   unit_departure_to        next unit's city (middle) / origin city+country (last)
--   airport_buffer_minutes   120 for flight, 60 for train
--
-- Pattern: jsonb_build_object(...) || t.meta — existing meta wins, so
-- person 02 (Sofía, already filled by part 3) is not overwritten. Any
-- traveler that already has the keys keeps their values.
--
-- Single-pass SQL. Safe to re-run.
-- ============================================================================

WITH airports AS (
  -- French city → closest IATA airport for flight legs.
  SELECT * FROM (VALUES
    ('Paris',             'CDG'),
    ('Versailles',        'CDG'),
    ('Reims',             'CDG'),
    ('Île-de-France',     'CDG'),
    ('Lyon',              'LYS'),
    ('Marseille',         'MRS'),
    ('Nice',              'NCE'),
    ('Cannes',            'NCE'),
    ('Bordeaux',          'BOD'),
    ('Toulouse',          'TLS'),
    ('Strasbourg',        'SXB'),
    ('Lille',             'LIL'),
    ('Nantes',            'NTE'),
    ('Rennes',            'RNS'),
    ('Saint-Malo',        'RNS'),
    ('Mont-Saint-Michel', 'RNS'),
    ('Avignon',           'AVN'),
    ('Corsica',           'AJA'),
    ('Ajaccio',           'AJA'),
    ('Bastia',            'BIA')
  ) AS x(city, iata)
),
unit_chain AS (
  SELECT
    t.id,
    t.destination,
    t.arrival_date,
    t.duration,
    t.meta,
    (t.meta->>'unit_order')::int AS unit_order,
    (t.meta->>'unit_total')::int AS unit_total,
    t.meta->>'origin_country' AS origin_country,
    t.meta->>'origin_city'    AS origin_city,
    t.meta->>'person_id'      AS person_id,
    LAG(t.destination)  OVER w AS prev_destination,
    LEAD(t.destination) OVER w AS next_destination
  FROM public.travelers t
  WHERE t.meta->>'seed_batch' = '01'
  WINDOW w AS (
    PARTITION BY t.meta->>'person_id'
    ORDER BY (t.meta->>'unit_order')::int
  )
)
UPDATE public.travelers t
SET meta = jsonb_build_object(
  -- ── Arrival ───────────────────────────────────────────
  'unit_arrival_method', CASE
    WHEN u.unit_order = 1 THEN 'flight'
    ELSE 'train'
  END,
  'unit_arrival_location', CASE
    WHEN u.unit_order = 1 THEN COALESCE(a_arr.iata, 'CDG')
    ELSE u.destination || ' Station'
  END,
  'unit_arrival_from', CASE
    WHEN u.unit_order = 1
      THEN COALESCE(NULLIF(u.origin_city,'') || ', ','') || COALESCE(u.origin_country,'origin')
    ELSE COALESCE(u.prev_destination, 'previous stop')
  END,

  -- ── Departure ─────────────────────────────────────────
  'unit_departure_date',
    (u.arrival_date
     + GREATEST(0, COALESCE(substring(u.duration FROM '(\d+)D')::int, 1) - 1)
       * INTERVAL '1 day'
    )::date::text,
  'unit_departure_time', CASE
    WHEN u.unit_order = u.unit_total THEN '17:00'   -- last unit: late afternoon flight
    ELSE '11:00'                                    -- middle units: mid-morning transfer
  END,
  'unit_departure_method', CASE
    WHEN u.unit_order = u.unit_total THEN 'flight'
    ELSE 'train'
  END,
  'unit_departure_location', CASE
    WHEN u.unit_order = u.unit_total THEN COALESCE(a_dep.iata, 'CDG')
    ELSE u.destination || ' Station'
  END,
  'unit_departure_to', CASE
    WHEN u.unit_order = u.unit_total
      THEN COALESCE(NULLIF(u.origin_city,'') || ', ','') || COALESCE(u.origin_country,'home')
    ELSE COALESCE(u.next_destination, 'next stop')
  END,

  -- ── Airport buffer ────────────────────────────────────
  'airport_buffer_minutes', CASE
    WHEN u.unit_order = 1 OR u.unit_order = u.unit_total THEN 120
    ELSE 60
  END
) || t.meta  -- existing meta wins → Sofía (filled by part 3) isn't overwritten
FROM unit_chain u
LEFT JOIN airports a_arr ON a_arr.city = u.destination
LEFT JOIN airports a_dep ON a_dep.city = u.destination
WHERE t.id = u.id;


-- ── Verify: count travelers that now carry the full transport metadata ──
SELECT
  COUNT(*) FILTER (WHERE meta ? 'unit_arrival_method')      AS has_arr_method,
  COUNT(*) FILTER (WHERE meta ? 'unit_arrival_location')    AS has_arr_loc,
  COUNT(*) FILTER (WHERE meta ? 'unit_arrival_from')        AS has_arr_from,
  COUNT(*) FILTER (WHERE meta ? 'unit_departure_date')      AS has_dep_date,
  COUNT(*) FILTER (WHERE meta ? 'unit_departure_time')      AS has_dep_time,
  COUNT(*) FILTER (WHERE meta ? 'unit_departure_method')    AS has_dep_method,
  COUNT(*) FILTER (WHERE meta ? 'unit_departure_location')  AS has_dep_loc,
  COUNT(*) FILTER (WHERE meta ? 'unit_departure_to')        AS has_dep_to,
  COUNT(*) FILTER (WHERE meta ? 'airport_buffer_minutes')   AS has_buffer,
  COUNT(*)                                                  AS total_units
FROM public.travelers
WHERE meta->>'seed_batch' = '01';


-- ── Sanity preview: first 6 units showing what was filled (joined with siblings) ──
SELECT
  meta->>'person_id'             AS person,
  meta->>'unit_order'             AS unit,
  destination,
  arrival_date,
  meta->>'unit_arrival_method'   AS arr,
  meta->>'unit_arrival_from'      AS arr_from,
  meta->>'unit_departure_date'   AS dep_date,
  meta->>'unit_departure_method' AS dep,
  meta->>'unit_departure_to'      AS dep_to
FROM public.travelers
WHERE meta->>'seed_batch' = '01'
ORDER BY (meta->>'person_id')::int, (meta->>'unit_order')::int
LIMIT 12;
