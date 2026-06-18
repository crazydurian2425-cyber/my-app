-- ============================================================================
-- Terms set-size fix — apply to the LIVE legal_docs row (slug='terms').
-- The EN clause hard-coded "all 15 plans in a set"; a set is 5–15 plans, so the
-- count is now dropped (the JA s4.p2 is already count-agnostic: セットまたはプラン).
-- terms.html (the seed/fallback) is already updated; this pushes the same fix to
-- the DB the public page actually reads. Idempotent.
-- ============================================================================
UPDATE public.legal_docs SET dict =
  jsonb_set(dict,
    '{en,s4.p2}', to_jsonb('Commission is released after all the plans in a set are reviewed and approved by admin. Standard release time is within <strong>24 hours of final approval</strong>, subject to banking-day delays.'::text))
WHERE slug = 'terms';

-- Verify: SELECT dict->'en'->>'s4.p2' FROM public.legal_docs WHERE slug='terms';
