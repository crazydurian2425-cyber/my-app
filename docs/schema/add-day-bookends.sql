-- ============================================================================
-- Day Bookends migration — adds the columns needed for locked anchors
-- (arrival / morning-at-hotel / end-of-day / departure), per-plan hotel
-- metadata, and auto-suggestion tracking.
--
-- Idempotent — uses `if not exists` everywhere. Safe to re-run.
-- ============================================================================


-- ── travelers ──────────────────────────────────────────────────────────────
-- daily_timing was previously a free-text string in meta ("Early (7-8am)").
-- Promote to a normalised text column with a check constraint so the form
-- can branch on it without parsing the legacy label. Backfill below.
ALTER TABLE public.travelers
  ADD COLUMN IF NOT EXISTS daily_timing TEXT
    CHECK (daily_timing IN ('early','standard','late'))
    DEFAULT 'standard';

ALTER TABLE public.travelers
  ADD COLUMN IF NOT EXISTS hotel_includes_breakfast BOOLEAN DEFAULT FALSE;

ALTER TABLE public.travelers
  ADD COLUMN IF NOT EXISTS accepts_evening_suggestions BOOLEAN DEFAULT TRUE;

-- Backfill daily_timing from meta. Maps the legacy labels onto the normalised
-- enum. Anything we don't recognise is left as the default ('standard').
UPDATE public.travelers
SET daily_timing = CASE
  WHEN meta->>'daily_timing' ILIKE 'early%'    THEN 'early'
  WHEN meta->>'daily_timing' ILIKE 'standard%' THEN 'standard'
  WHEN meta->>'daily_timing' ILIKE 'late%'     THEN 'late'
  WHEN meta->>'daily_timing' = 'early'         THEN 'early'
  WHEN meta->>'daily_timing' = 'standard'      THEN 'standard'
  WHEN meta->>'daily_timing' = 'late'          THEN 'late'
  ELSE daily_timing
END
WHERE daily_timing IS NULL OR daily_timing = 'standard';


-- ── plans ──────────────────────────────────────────────────────────────────
-- Per-plan hotel anchor. Used by the morning-at-hotel and end-of-day locked
-- anchors. Populated by the planner when they pick the hotel for the unit
-- (or by the meta backfill if we promote unit_accommodation_* keys later).
ALTER TABLE public.plans
  ADD COLUMN IF NOT EXISTS hotel_name      TEXT,
  ADD COLUMN IF NOT EXISTS hotel_address   TEXT,
  ADD COLUMN IF NOT EXISTS hotel_lat       NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS hotel_lng       NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS hotel_place_id  TEXT;


-- ── itinerary_items ────────────────────────────────────────────────────────
-- is_locked + anchor_type identify the special locked rows (arrival /
-- morning / end-of-day / departure). suggestion_source flags rows that
-- the planner accepted from the evening/morning suggestion cards — useful
-- for retention/analytics later.
ALTER TABLE public.itinerary_items
  ADD COLUMN IF NOT EXISTS is_locked         BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS anchor_type       TEXT
    CHECK (anchor_type IS NULL OR anchor_type IN ('arrival','morning','end_of_day','departure')),
  ADD COLUMN IF NOT EXISTS suggestion_source TEXT
    CHECK (suggestion_source IS NULL OR suggestion_source IN ('evening_suggestion','morning_suggestion'));


-- ── Verify ─────────────────────────────────────────────────────────────────
-- Run these by hand after the ALTERs to confirm.
--   SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='travelers'
--     AND column_name IN ('daily_timing','hotel_includes_breakfast','accepts_evening_suggestions');
--
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='plans'
--     AND column_name LIKE 'hotel_%';
--
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='itinerary_items'
--     AND column_name IN ('is_locked','anchor_type','suggestion_source');
--
--   -- Spot check the daily_timing backfill against the meta values:
--   SELECT meta->>'person_id' AS person,
--          meta->>'daily_timing' AS meta_timing,
--          daily_timing AS normalised
--   FROM public.travelers
--   WHERE meta->>'seed_batch' = '01'
--   ORDER BY (meta->>'person_id')::int, (meta->>'unit_order')::int
--   LIMIT 12;
