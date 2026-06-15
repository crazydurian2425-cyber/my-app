-- ============================================================================
-- Japan travelers — fix departure buffer + optimise unit-to-unit transport modes
--
-- (1) BUFFER: 4 non-flight legs were mis-stamped with the 180-min (flight)
--     buffer, cutting the last day ~3h short. Reset to 60 (the rail default;
--     per-method floors are flight 180 / train 30 / bus 20 / car 15).
--
-- (2) MODES: switch unit-to-unit legs to the most reliable/fastest realistic
--     transport (researched). Updates BOTH the departing unit's
--     unit_departure_method AND the arriving unit's unit_arrival_method so the
--     two anchors stay consistent. All affected legs were 'train'.
--       Otaru->Niseko, Furano->Hakodate          -> car  (rail ~1/day or 7h backtrack)
--       Tokyo->Kawaguchiko, Sapporo->Furano,
--       Beppu->Yufuin                             -> bus  (direct trains too sparse)
--       Hakone->Kyoto, Kawaguchiko->Kyoto         -> shinkansen (normalise; Odawara/Mishima feeder)
--       Hiroshima->Miyajima                       -> ferry (island access)
--
-- Keyed by meta.seed_batch='jp-01'. Idempotent (guards on the old value).
-- Pairs with docs/schema/seed-japan-travelers.sql.
-- ============================================================================

-- (1) Buffer: non-flight 180 -> 60
UPDATE public.travelers
SET meta = jsonb_set(meta, '{airport_buffer_minutes}', '60')
WHERE meta->>'seed_batch' = 'jp-01'
  AND meta->>'unit_departure_method' <> 'flight'
  AND (meta->>'airport_buffer_minutes')::int = 180;

-- (2a) DEPARTURE method — keyed by the next city (unit_departure_to)
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

-- (2b) ARRIVAL method — keyed by the unit's own city (destination column)
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
