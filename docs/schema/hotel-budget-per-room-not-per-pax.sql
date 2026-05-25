-- ============================================================================
-- Hotel budget convention switch: per-pax → total per night
--
-- Hotels price PER ROOM, not per person. The old key
-- `meta.hotel_budget_per_night_pax_eur` forced the planner to multiply
-- by group_size every time they checked a real Booking.com listing —
-- error-prone and didn't match how hotel quotes actually arrive.
--
-- New key: `meta.hotel_budget_per_night_eur` (total per night for the
-- group's accommodation). Backfill = old value × group_size.
--
-- Solo travelers (group_size=1) are unaffected numerically (€140 stays
-- €140). Couples double, families × group_size — admin can hand-tune
-- families afterwards if a 4-pax × €125 = €500 budget is unrealistic
-- for one family room.
--
-- Daily spend (`meta.daily_spend_per_pax_eur`) STAYS per-pax — food +
-- activities scale linearly with number of people. Only hotel is the
-- exception because rooms don't scale linearly.
--
-- Re-run safety: the WHERE clause filters to rows that still have the
-- old key, so a second run is a no-op. Idempotent.
-- ============================================================================

UPDATE public.travelers t
SET    meta = (
  jsonb_set(
    t.meta,
    '{hotel_budget_per_night_eur}',
    to_jsonb(
      ROUND(
        COALESCE((t.meta->>'hotel_budget_per_night_pax_eur')::numeric, 0)
        * GREATEST(COALESCE(t.group_size, 1), 1)
      )::int
    )
  )
) - 'hotel_budget_per_night_pax_eur'
WHERE  t.meta ? 'hotel_budget_per_night_pax_eur';


-- ── Verify ───────────────────────────────────────────────────────────
-- a) No row should still carry the old per-pax key.
SELECT COUNT(*) AS still_per_pax
FROM   public.travelers
WHERE  meta ? 'hotel_budget_per_night_pax_eur';
-- → 0

-- b) Spot-check the migrated values.
SELECT meta->>'person_id'                       AS person,
       name,
       group_size,
       (meta->>'hotel_budget_per_night_eur')::int AS hotel_total_per_night,
       (meta->>'daily_spend_per_pax_eur')::int   AS daily_per_pax
FROM   public.travelers
WHERE  meta ? 'hotel_budget_per_night_eur'
ORDER  BY (meta->>'person_id')::int, (meta->>'unit_order')::int;
-- Expected:
--   Sofía (1 pax): €140
--   Carter couple: €320
--   Tan honeymoon: €340
--   Thompson family (4): €500  ← admin may want to lower to ~€220
--   Reyes honeymoon: €340
