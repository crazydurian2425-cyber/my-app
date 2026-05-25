-- ============================================================================
-- Translate pace values: form labels → code-recognised keys
--
-- The Edit/Add traveler form's pace dropdown used to store strings like
-- "Relaxed", "Moderate", "Fast-paced", "Structured" — but the dashboard's
-- day-end calculator only checks for "slow" / "active" / "packed" (with
-- "moderate" as the implicit no-adjust default). So none of the form
-- values were triggering any adjustment — every traveler defaulted to
-- the base 10:30 pm end regardless of what was picked.
--
-- This migration translates existing values in BOTH locations the
-- dashboard reads (travelers.pace column AND meta.pace JSONB key) to
-- the code's expected vocabulary. Case-insensitive — catches "Relaxed",
-- "relaxed", "RELAXED" etc.
--
-- New mapping:
--   relaxed     →  slow      ( -30 min)
--   moderate    →  moderate  (no change, no adjust)
--   fast-paced  →  active    ( +30 min)
--   structured  →  active    ( +30 min — "structured" implies a tight
--                              schedule, treated as active not packed)
--
-- The form HTML was updated in the same commit to use the new values
-- directly (<option value="slow">Slow</option> etc.), so any future
-- saves write the correct keys.
--
-- Re-run safe: idempotent. Second run hits zero rows because the WHERE
-- clauses no longer match.
-- ============================================================================

-- ── 1. Column travelers.pace ────────────────────────────────────────
UPDATE public.travelers SET pace = 'slow'      WHERE LOWER(pace) = 'relaxed';
UPDATE public.travelers SET pace = 'active'    WHERE LOWER(pace) = 'fast-paced';
UPDATE public.travelers SET pace = 'active'    WHERE LOWER(pace) = 'structured';
-- 'moderate' stays as 'moderate' — no change needed for that branch.

-- ── 2. Meta key meta.pace ───────────────────────────────────────────
UPDATE public.travelers
SET    meta = jsonb_set(meta, '{pace}', '"slow"'::jsonb)
WHERE  LOWER(meta->>'pace') = 'relaxed';

UPDATE public.travelers
SET    meta = jsonb_set(meta, '{pace}', '"active"'::jsonb)
WHERE  LOWER(meta->>'pace') = 'fast-paced';

UPDATE public.travelers
SET    meta = jsonb_set(meta, '{pace}', '"active"'::jsonb)
WHERE  LOWER(meta->>'pace') = 'structured';

-- ── 3. Lowercase any TitleCase value the form might have written
--      (e.g. "Moderate", "Slow") so the column matches the new dropdown
--      values exactly.
UPDATE public.travelers SET pace = LOWER(pace) WHERE pace IS NOT NULL AND pace <> LOWER(pace);
UPDATE public.travelers
SET    meta = jsonb_set(meta, '{pace}', to_jsonb(LOWER(meta->>'pace')))
WHERE  meta->>'pace' IS NOT NULL AND meta->>'pace' <> LOWER(meta->>'pace');


-- ── Verify ──────────────────────────────────────────────────────────
-- a) Every distinct pace value should now be one of:
--    slow / moderate / active / packed (or NULL).
SELECT pace, COUNT(*) FROM public.travelers GROUP BY pace ORDER BY pace;

SELECT meta->>'pace' AS meta_pace, COUNT(*)
FROM   public.travelers
WHERE  meta ? 'pace'
GROUP  BY meta_pace
ORDER  BY meta_pace;

-- b) Per-traveler view — confirm Lukas / Park / Kowalski / Santos /
--    O'Connor end up with 'active' on either column or meta, so the
--    dashboard now bumps their end-of-day to 11:00 pm.
SELECT meta->>'person_id' AS person, name,
       t.pace             AS column_pace,
       meta->>'pace'      AS meta_pace
FROM   public.travelers t
WHERE  meta ? 'person_id'
ORDER  BY (meta->>'person_id')::int, (meta->>'unit_order')::int;
