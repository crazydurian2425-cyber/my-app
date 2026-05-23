-- ============================================================================
-- Restructure stop categories — hotel-specific slots
--
-- Adds:
--   • plans.hotel_check_in_time   (TIME, default 14:00)
--   • plans.hotel_check_out_time  (TIME, default 11:00)
--   • plans.hotel_stores_bags     (BOOLEAN, default TRUE)
--   • Expanded itinerary_items.type CHECK constraint to allow:
--     hotel_checkin, hotel_checkout, shopping, entertainment
--     (keeps existing 'accommodation' as a deprecated fallback so legacy
--     rows don't fail validation while we migrate.)
--
-- Idempotent — uses `if not exists` everywhere. Safe to re-run.
-- ============================================================================


-- ── plans ──────────────────────────────────────────────────────────────────
ALTER TABLE public.plans
  ADD COLUMN IF NOT EXISTS hotel_check_in_time  TIME DEFAULT '14:00',
  ADD COLUMN IF NOT EXISTS hotel_check_out_time TIME DEFAULT '11:00',
  ADD COLUMN IF NOT EXISTS hotel_stores_bags    BOOLEAN DEFAULT TRUE;


-- ── itinerary_items.type CHECK constraint ──────────────────────────────────
-- Postgres doesn't support "ALTER CONSTRAINT" — drop + re-add. We also drop
-- any extra CHECK constraint that references the `type` column under a
-- different name (defensive: covers cases where an earlier migration named
-- it differently). The DO block enumerates every CHECK constraint on
-- itinerary_items whose attkey list contains the `type` column and drops
-- them all. Then we add a single fresh one with the canonical name.
DO $$
DECLARE
  r record;
  type_attnum int;
BEGIN
  SELECT a.attnum INTO type_attnum
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'itinerary_items'
    AND a.attname = 'type';
  IF type_attnum IS NULL THEN
    RAISE NOTICE 'itinerary_items.type column not found — skipping';
    RETURN;
  END IF;
  FOR r IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'itinerary_items'
      AND con.contype = 'c'
      AND type_attnum = ANY (con.conkey)
  LOOP
    EXECUTE format('ALTER TABLE public.itinerary_items DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;

ALTER TABLE public.itinerary_items
  ADD CONSTRAINT itinerary_items_type_check
  CHECK (type IN (
    'activity',
    'meal',
    'transport',
    'accommodation',   -- deprecated; kept so legacy rows pass validation
    'freetime',
    'hotel_checkin',
    'hotel_checkout',
    'shopping',
    'entertainment'
  ));


-- ── Verify ─────────────────────────────────────────────────────────────────
--   SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='plans'
--     AND column_name LIKE 'hotel_%';
--
--   SELECT pg_get_constraintdef(con.oid)
--   FROM pg_constraint con
--   JOIN pg_class rel ON rel.oid = con.conrelid
--   WHERE rel.relname='itinerary_items' AND con.contype='c'
--     AND pg_get_constraintdef(con.oid) ILIKE '%type%IN%';
