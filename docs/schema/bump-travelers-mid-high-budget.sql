-- ============================================================================
-- Bump all travelers to mid-range "comfortable" / mid-high budget
--
-- Keep tier = mid_range (not luxury yet — splurge_willingness covers the
-- "comfortable" feel without crossing into luxury), but raise the explicit
-- daily and hotel meta keys so the brief reflects "comfortable mid" not
-- "entry mid".
--
-- Multiplier approach (not flat +€X) so proportions stay sensible across
-- existing variance:
--   daily_spend_per_pax_eur  × 1.15  → rounded to nearest 5
--   hotel_budget_per_night_eur × 1.20 → rounded to nearest 10
--
-- Worked examples (post-bump):
--   Sofía solo:        daily 150 → 175,  hotel 140 → 170
--   Lukas solo:        daily 145 → 165,  hotel 130 → 160
--   Park solo:         daily 140 → 160,  hotel 125 → 150
--   Kowalski solo:     daily 130 → 150,  hotel 115 → 140
--   Carter couple:     daily 170 → 195,  hotel 320 → 380
--   Tan honeymoon:     daily 180 → 205,  hotel 340 → 410
--   Thompson family-4: daily 135 → 155,  hotel 500 → 600
--   Cohen 3-unit cpl:  daily 165 → 190,  hotel 300 → 360
--   Reyes honeymoon:   daily 180 → 205,  hotel 340 → 410
--
-- Tier stays mid_range. Splurge_willingness unchanged (some 'occasional',
-- some 'frequent' — keep the spectrum).
--
-- Re-run safety: NOT idempotent — every run multiplies again. Don't
-- run twice. Roll back with:
--   UPDATE travelers SET meta = jsonb_set(... × 1/1.15 ...) ... ;
-- or restore from a Supabase point-in-time backup.
-- ============================================================================

UPDATE public.travelers
SET    meta = jsonb_set(
  jsonb_set(
    meta,
    '{daily_spend_per_pax_eur}',
    to_jsonb(
      (ROUND( (meta->>'daily_spend_per_pax_eur')::numeric * 1.15 / 5 ) * 5)::int
    )
  ),
  '{hotel_budget_per_night_eur}',
  to_jsonb(
    (ROUND( (meta->>'hotel_budget_per_night_eur')::numeric * 1.20 / 10 ) * 10)::int
  )
)
WHERE  meta ? 'daily_spend_per_pax_eur'
  AND  meta ? 'hotel_budget_per_night_eur';


-- Mirror the new daily into the legacy budget_per_day column so the
-- brief's fallback renderer agrees with the meta source of truth.
-- For hotel_budget we keep the old per-pax convention on the legacy
-- column (= meta value / group_size) since some old code paths still
-- assume that.
UPDATE public.travelers
SET    budget_per_day = (meta->>'daily_spend_per_pax_eur')::int,
       hotel_budget   = ROUND(
         (meta->>'hotel_budget_per_night_eur')::numeric / GREATEST(COALESCE(group_size,1), 1)
       )::int
WHERE  meta ? 'daily_spend_per_pax_eur'
  AND  meta ? 'hotel_budget_per_night_eur';


-- ── Verify ──────────────────────────────────────────────────────────
-- Spot-check the new values.
SELECT meta->>'person_id'                              AS person,
       name,
       group_size,
       (meta->>'daily_spend_per_pax_eur')::int        AS daily_pax,
       (meta->>'hotel_budget_per_night_eur')::int     AS hotel_total,
       budget_per_day                                  AS legacy_daily,
       hotel_budget                                    AS legacy_hotel_pax
FROM   public.travelers
WHERE  meta ? 'daily_spend_per_pax_eur'
ORDER  BY (meta->>'person_id')::int, (meta->>'unit_order')::int;
