-- ============================================================================
-- Japan travelers — realign per-departure airport/station buffers to the app's
-- per-method floors (the buffer is now PURE airport/station time; the ride to
-- the airport/station is subtracted separately by the planner's to-airport leg).
--
--   flight 180 · train/shinkansen/ferry 30 · bus 20 · car 15  (default 30)
--
-- Was: train/shinkansen/ferry/car all 60. Keyed by seed_batch='jp-01' on the
-- unit's departure method. Idempotent — safe to re-run.
-- ============================================================================
UPDATE public.travelers
SET meta = jsonb_set(
  meta,
  '{airport_buffer_minutes}',
  to_jsonb(
    CASE lower(meta->>'unit_departure_method')
      WHEN 'flight' THEN 180
      WHEN 'bus'    THEN 20
      WHEN 'car'    THEN 15
      ELSE 30                 -- train, shinkansen, ferry, anything else
    END
  )
)
WHERE meta->>'seed_batch' = 'jp-01'
  AND meta ? 'airport_buffer_minutes';
