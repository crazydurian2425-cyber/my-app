-- ============================================================================
-- Fix the route-order contradiction in Álvaro Serrano's brief note (jp-01,
-- person 0013, 4 unit rows).
--
-- The seeded note said the honeymoon ends "over good sake back in Osaka"
-- (JA: 最後は大阪でおいしい日本酒とともにくつろぎたいです) — but the seeded
-- route is Osaka (Aug 5–7) → Himeji → Hiroshima → Miyajima (Aug 10–11), with
-- the flight home from Hiroshima Airport. Osaka is the FIRST city, not the
-- last; the trip never returns there. A planner on the Miyajima unit rightly
-- asked "宮島でしょうか？大阪でしょうか？".
--
-- Rewords EN + JA so the narrative matches the route: sake in Osaka FIRST,
-- ending at Miyajima's torii. Keyed by the exact old EN text, so it touches
-- only these 4 rows; harmless no-op on re-run (0 rows match after the first).
-- ============================================================================

UPDATE public.travelers
SET special_notes = $sn$Honeymooning through Japan's history — starting with good sake in Osaka, then Himeji's castle, Hiroshima, and finally the torii at Miyajima.$sn$,
    meta = jsonb_set(
      coalesce(meta, '{}'::jsonb),
      '{special_notes_ja}',
      to_jsonb($ja$日本の歴史を巡る新婚旅行です。まずは大阪でおいしい日本酒を楽しんでから、姫路城、広島を訪ね、最後は宮島の鳥居で旅を締めくくりたいです。$ja$::text)
    )
WHERE special_notes = $sn$Honeymooning through Japan's history — Himeji's castle, Hiroshima, the torii at Miyajima — then unwinding over good sake back in Osaka.$sn$;

-- Verify (expect 4 rows, all person 0013 units — Osaka/Himeji/Hiroshima/Miyajima):
-- SELECT destination, special_notes, meta->>'special_notes_ja'
--   FROM public.travelers
--  WHERE name = 'Álvaro Serrano'
--  ORDER BY meta->>'unit_order';
