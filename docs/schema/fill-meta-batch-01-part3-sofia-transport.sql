-- ============================================================================
-- Phase 1 backfill: Sofía Romero (person_id=02) · 3 units · transport between units.
--
-- This is the PREVIEW fill — only Sofía. Once the Brief renders correctly
-- for her Plan 3 (Paris), we'll mass-fill the same shape for everyone else.
--
-- Fields filled per unit (stored in travelers.meta):
--   unit_arrival_method      flight / train / car
--   unit_arrival_location    airport code or station name
--   unit_arrival_from        origin city (Unit 1) OR previous unit's city
--   unit_departure_date      YYYY-MM-DD (last day of this unit)
--   unit_departure_time      HH:MM
--   unit_departure_method    flight / train / car
--   unit_departure_location  airport code or station name
--   unit_departure_to        destination country (last unit) OR next unit's city
--   airport_buffer_minutes   120 intl flight / 60 train / 90 domestic
--
-- For units 2 + 3 we also UPDATE the arrival_time column directly (it was
-- NULL on those legs — they're connecting transport from the previous unit,
-- not flights from origin).
--
-- Pattern: `defaults || meta` so existing keys win. Safe to re-run.
-- ============================================================================


-- ── Unit 1 · Saint-Malo · arrives 11 Jun 09:50 from Buenos Aires (flight via CDG→RNS) ──
--    departs 13 Jun 11:00 to Mont-Saint-Michel by train
UPDATE public.travelers SET meta = '{
  "unit_arrival_method":"flight",
  "unit_arrival_location":"RNS (via CDG transfer)",
  "unit_arrival_from":"Buenos Aires, Argentina",
  "unit_departure_date":"2026-06-13",
  "unit_departure_time":"11:00",
  "unit_departure_method":"train",
  "unit_departure_location":"Saint-Malo Station",
  "unit_departure_to":"Mont-Saint-Michel",
  "airport_buffer_minutes":120
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01'
  AND meta->>'person_id'  = '02'
  AND meta->>'unit_order' = '1';


-- ── Unit 2 · Mont-Saint-Michel · arrives 13 Jun 12:30 from Saint-Malo by train ──
--    departs 14 Jun 12:00 to Paris by train
UPDATE public.travelers
SET arrival_time = '12:30',
    meta = '{
      "unit_arrival_method":"train",
      "unit_arrival_location":"Mont-Saint-Michel Station",
      "unit_arrival_from":"Saint-Malo",
      "unit_departure_date":"2026-06-14",
      "unit_departure_time":"12:00",
      "unit_departure_method":"train",
      "unit_departure_location":"Mont-Saint-Michel Station",
      "unit_departure_to":"Paris",
      "airport_buffer_minutes":60
    }'::jsonb || meta
WHERE meta->>'seed_batch' = '01'
  AND meta->>'person_id'  = '02'
  AND meta->>'unit_order' = '2';


-- ── Unit 3 · Paris · arrives 14 Jun 14:00 from Mont-Saint-Michel by train ──
--    departs 16 Jun 17:00 to Buenos Aires (flight from CDG)
UPDATE public.travelers
SET arrival_time = '14:00',
    meta = '{
      "unit_arrival_method":"train",
      "unit_arrival_location":"Paris Gare Montparnasse",
      "unit_arrival_from":"Mont-Saint-Michel",
      "unit_departure_date":"2026-06-16",
      "unit_departure_time":"17:00",
      "unit_departure_method":"flight",
      "unit_departure_location":"CDG",
      "unit_departure_to":"Buenos Aires, Argentina",
      "airport_buffer_minutes":120
    }'::jsonb || meta
WHERE meta->>'seed_batch' = '01'
  AND meta->>'person_id'  = '02'
  AND meta->>'unit_order' = '3';


-- ── Verify ──
SELECT meta->>'unit_order' AS unit, destination, arrival_date, arrival_time,
       meta->>'unit_arrival_method'     AS arr_method,
       meta->>'unit_arrival_location'   AS arr_loc,
       meta->>'unit_arrival_from'       AS arr_from,
       meta->>'unit_departure_date'     AS dep_date,
       meta->>'unit_departure_time'     AS dep_time,
       meta->>'unit_departure_method'   AS dep_method,
       meta->>'unit_departure_location' AS dep_loc,
       meta->>'unit_departure_to'       AS dep_to
FROM public.travelers
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '02'
ORDER BY (meta->>'unit_order')::int;
