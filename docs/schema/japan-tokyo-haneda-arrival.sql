-- ============================================================================
-- Japan travelers — normalize all Tokyo international arrivals to Haneda (HND)
--
-- The jp-01 seed split Tokyo arrivals between Narita (NRT) and Haneda (HND) with
-- inconsistent labels. Haneda is ~15 km from central Tokyo (vs Narita ~70 km),
-- is served by all of these origins, and makes the arrival taxi far shorter and
-- cheaper. Normalizes every first-leg Tokyo flight arrival to "Haneda Airport (HND)".
--
-- Targets the first unit (unit_order=1) arriving by flight into Tokyo.
-- Keyed by meta.seed_batch='jp-01'. Idempotent.
-- ============================================================================

UPDATE public.travelers
SET meta = jsonb_set(meta, '{unit_arrival_location}', '"Haneda Airport (HND)"')
WHERE meta->>'seed_batch'        = 'jp-01'
  AND destination                = 'Tokyo'
  AND (meta->>'unit_order')::int = 1
  AND meta->>'unit_arrival_method' = 'flight';

-- Verify (optional):
-- SELECT meta->>'person_id' AS pid, meta->>'origin_city' AS from_city,
--        meta->>'unit_arrival_location' AS gateway
-- FROM public.travelers
-- WHERE meta->>'seed_batch'='jp-01' AND destination='Tokyo' AND (meta->>'unit_order')::int=1
-- ORDER BY pid;
