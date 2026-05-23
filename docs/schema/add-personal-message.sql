-- ============================================================================
-- Review/Submit page — add the planner's personal note column
--
-- The new Review tab (formerly Wrap-up) replaces the transport_tips /
-- spend_breakdown / local_tips fields with a single freeform textarea
-- the planner uses to write a welcome message to the traveler.
--
-- Persisted on plans so it round-trips with the rest of the itinerary
-- and shows up at the top of the traveler-facing summary.
--
-- Idempotent — uses `if not exists`. Safe to re-run.
-- ============================================================================

ALTER TABLE public.plans
  ADD COLUMN IF NOT EXISTS personal_message_to_traveler TEXT;

-- Verify:
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='plans'
--     AND column_name='personal_message_to_traveler';
