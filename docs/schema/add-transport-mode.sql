-- ============================================================================
-- Persist the planner's chosen transport mode (Uber / Metro / Walk / ...)
-- on each transport-type itinerary_items row. The DOM dataset attribute
-- was the only source of truth before this column existed, so closing
-- and reopening a plan reset every transport back to "taxi" (the default
-- in refreshTransportSlot's `slot.dataset.transportMode || 'taxi'`).
--
-- Idempotent — uses `if not exists`. Safe to re-run.
-- ============================================================================

ALTER TABLE public.itinerary_items
  ADD COLUMN IF NOT EXISTS transport_mode TEXT
    CHECK (
      transport_mode IS NULL OR transport_mode IN (
        'walk','transit','taxi','rental','train','flight','ferry'
      )
    );

-- Verify:
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='itinerary_items'
--     AND column_name='transport_mode';
