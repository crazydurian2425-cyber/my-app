-- ============================================================================
-- Japan jp-01 — occasion rewrites + Mariana theme-park interest.
--   • #0011/#0012/#0013 honeymoon occasions fleshed out (were just "honeymoon")
--   • #0016 Kanya occasion reworded (dropped the odd "parents gifted a 40yo")
--   • #0014 Mariana: temples → theme_parks (family w/ young kids, Osaka = USJ)
-- The honeymoon late-night floor now keys off traveler_type, so these reworded
-- occasions do NOT affect it. Keyed by seed_batch='jp-01'. Idempotent.
-- ============================================================================
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion}',to_jsonb('Honeymoon — a first trip to Japan together, splitting time between Tokyo and a quiet lakeside ryokan beneath Mt. Fuji.'::text))
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0011';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion}',to_jsonb('Honeymoon in Hokkaido — cool summer air, fresh seafood, and quiet onsen evenings after the wedding rush.'::text))
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0012';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion}',to_jsonb('Honeymoon along the Seto Inland Sea — Himeji Castle, Hiroshima, and a night in a ryokan on Miyajima.'::text))
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0013';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion}',to_jsonb('A 40th-birthday family trip through Kyushu — the children experience their very first onsen.'::text))
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0016';
UPDATE public.travelers SET meta = jsonb_set(meta,'{interests}','["anime_pop_culture","theme_parks","food_dining","onsen","shopping"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0014';
