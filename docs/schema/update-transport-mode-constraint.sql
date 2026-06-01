-- ============================================================================
-- Widen the itinerary_items.transport_mode CHECK constraint to every mode the
-- dashboard actually uses today. The original constraint (add-transport-mode.sql)
-- only allowed 'walk','transit','taxi','rental','train','flight','ferry' — but
-- the app also stores 'car', 'hsr', and now 'bike'. If the constraint is
-- enforced on the live DB, autosaving one of those legs fails silently and the
-- mode resets on reload. This re-creates the constraint with the full set.
--
-- Idempotent — drops the old constraint if present, then re-adds. Safe to re-run.
-- Run in the Supabase SQL editor (click "Run without RLS" if prompted).
-- ============================================================================

ALTER TABLE public.itinerary_items
  DROP CONSTRAINT IF EXISTS itinerary_items_transport_mode_check;

ALTER TABLE public.itinerary_items
  ADD CONSTRAINT itinerary_items_transport_mode_check
    CHECK (
      transport_mode IS NULL OR transport_mode IN (
        'walk','bike','transit','taxi','car','rental','train','hsr','flight','ferry'
      )
    );

-- Verify:
--   SELECT conname, pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conrelid = 'public.itinerary_items'::regclass
--     AND conname = 'itinerary_items_transport_mode_check';
