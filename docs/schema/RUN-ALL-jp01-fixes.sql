-- ============================================================================
-- RUN-ALL — jp-01 Japan traveler fixes (this session), in one transaction.
-- Paste into the Supabase SQL editor and Run. Idempotent + safe to re-run.
-- Bundles: room_type clarity · flight-home times · buffer fix · transport modes
--          · Tokyo->Haneda arrival.
-- ============================================================================
BEGIN;

-- 1) ROOM TYPE — France-clear "rooms · guests · split" for all 20 travelers
UPDATE public.travelers AS t
SET meta = jsonb_set(t.meta, '{room_type}', to_jsonb(v.room_type::text), true)
FROM (VALUES
  ('0001','1 single room · 1 guest'),('0002','1 single room · 1 guest'),
  ('0003','1 single room · 1 guest'),('0004','1 single room · 1 guest'),
  ('0005','1 single room · 1 guest'),('0006','1 double room · 2 guests'),
  ('0007','1 double room · 2 guests'),('0008','1 double room · 2 guests'),
  ('0009','1 double room · 2 guests'),('0010','1 double room · 2 guests'),
  ('0011','1 junior suite · 2 guests'),('0012','1 junior suite · 2 guests'),
  ('0013','1 junior suite · 2 guests'),
  ('0014','2 connecting rooms · 4 guests (2 adults + 2 children)'),
  ('0015','3 connecting rooms · 5 guests (2 per room + 1)'),
  ('0016','2 connecting rooms · 4 guests (2 adults + 2 children)'),
  ('0017','2 rooms · 3 guests (1 double + 1 twin for the teens)'),
  ('0018','2 twin rooms · 4 guests (2 per room)'),
  ('0019','2 rooms · 4 guests (2 per room)'),
  ('0020','2 rooms · 3 guests (1 double + 1 single)')
) AS v(person_id, room_type)
WHERE t.meta->>'seed_batch'='jp-01' AND t.meta->>'person_id'=v.person_id;

-- 2) FLIGHT HOME — final international flight moved to ~16:00-17:00
UPDATE public.travelers AS t
SET meta = jsonb_set(t.meta, '{unit_departure_time}', to_jsonb(v.dep_time::text), true)
FROM (VALUES
  ('0001','16:40'),('0002','16:30'),('0003','16:55'),('0004','16:20'),('0005','16:50'),
  ('0006','16:15'),('0007','16:35'),('0008','17:00'),('0009','16:25'),('0010','16:45'),
  ('0011','16:55'),('0012','16:30'),('0013','16:50'),('0014','16:20'),('0015','17:00'),
  ('0016','16:35'),('0017','16:45'),('0018','16:30'),('0019','16:40'),('0020','16:55')
) AS v(person_id, dep_time)
WHERE t.meta->>'seed_batch'='jp-01' AND t.meta->>'person_id'=v.person_id
  AND (t.meta->>'unit_order')::int = (t.meta->>'unit_total')::int
  AND t.meta->>'unit_departure_method' = 'flight';

-- 3) BUFFER — non-flight legs mis-stamped with 180 -> 60
UPDATE public.travelers
SET meta = jsonb_set(meta, '{airport_buffer_minutes}', '60')
WHERE meta->>'seed_batch'='jp-01'
  AND meta->>'unit_departure_method' <> 'flight'
  AND (meta->>'airport_buffer_minutes')::int = 180;

-- 4) TRANSPORT MODES — departure side (keyed by next city)
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_departure_method}', '"car"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_departure_method'='train'
  AND meta->>'unit_departure_to' IN ('Niseko','Hakodate');
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_departure_method}', '"bus"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_departure_method'='train'
  AND meta->>'unit_departure_to' IN ('Kawaguchiko','Furano','Yufuin');
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_departure_method}', '"shinkansen"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_departure_method'='train'
  AND meta->>'unit_departure_to' = 'Kyoto';
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_departure_method}', '"ferry"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_departure_method'='train'
  AND meta->>'unit_departure_to' = 'Miyajima';

-- 4) TRANSPORT MODES — arrival side (keyed by the unit's own city)
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_arrival_method}', '"car"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_arrival_method'='train'
  AND destination IN ('Niseko','Hakodate');
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_arrival_method}', '"bus"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_arrival_method'='train'
  AND destination IN ('Kawaguchiko','Furano','Yufuin');
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_arrival_method}', '"shinkansen"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_arrival_method'='train'
  AND destination = 'Kyoto';
UPDATE public.travelers SET meta = jsonb_set(meta, '{unit_arrival_method}', '"ferry"')
WHERE meta->>'seed_batch'='jp-01' AND meta->>'unit_arrival_method'='train'
  AND destination = 'Miyajima';

-- 5) TOKYO ARRIVAL — normalize all first-leg Tokyo flights to Haneda (HND)
UPDATE public.travelers
SET meta = jsonb_set(meta, '{unit_arrival_location}', '"Haneda Airport (HND)"')
WHERE meta->>'seed_batch'='jp-01' AND destination='Tokyo'
  AND (meta->>'unit_order')::int = 1 AND meta->>'unit_arrival_method'='flight';

COMMIT;

-- Verify (run after): one row per traveler with the key fields.
-- SELECT meta->>'person_id' AS pid, destination,
--        meta->>'room_type' AS room, meta->>'airport_buffer_minutes' AS buf,
--        meta->>'unit_departure_method' AS dep_mode, meta->>'unit_arrival_location' AS arr_loc,
--        meta->>'unit_departure_time' AS dep_time
-- FROM public.travelers WHERE meta->>'seed_batch'='jp-01'
-- ORDER BY pid, (meta->>'unit_order')::int;
