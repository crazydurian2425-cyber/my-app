-- ============================================================================
-- Japan travelers — bus legs use a 20-min departure buffer (was 60)
--
-- A 60-min buffer is too generous for a bus: it made the day's cut-off an hour
-- before the bus, so reaching the station ~17 min early (which is fine for a
-- bus) tripped a false "too late / may miss the bus" warning. 20 min is the
-- per-method floor and matches reality (short ride to the terminal + a few min).
--
-- Run AFTER the transport-mode switches (so the train->bus legs exist).
-- Keyed by meta.seed_batch='jp-01'. Idempotent.
-- ============================================================================

UPDATE public.travelers
SET meta = jsonb_set(meta, '{airport_buffer_minutes}', '20')
WHERE meta->>'seed_batch' = 'jp-01'
  AND meta->>'unit_departure_method' = 'bus'
  AND (meta->>'airport_buffer_minutes')::int <> 20;
