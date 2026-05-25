-- ============================================================================
-- Wipe everything Japan-related
--
-- Platform is France-only. Any traveler going to a Japanese city or
-- having Japan as origin is a stray (probably hand-added via the
-- pre-cleanup admin form or left over from an older seed batch we
-- never touched). This deletes them + their cascade artefacts:
--
--   set_assignments  ←  these block the cascade in the live DB
--                       (initial.sql says ON DELETE CASCADE but the
--                       deployed constraint is RESTRICT — schema drift)
--   itinerary_items  ←  CASCADE off plans
--   plans            ←  manually deleted by traveler_id
--   sets             ←  delete only sets that become orphaned (no
--                       remaining plans). Mixed sets keep the
--                       non-Japan plans.
--   travelers        ←  finally, the Japan-themed rows
--
-- Match criteria (any one is enough):
--   • destination IN (well-known Japanese cities)
--   • meta->>'origin_country' = 'Japan'
--   • meta->>'origin_city' is a Japanese city
--
-- Re-run safety: idempotent — second run hits zero rows.
-- ============================================================================

-- Reusable CTE expressed inline below. Pre-compute the set of Japan
-- traveler IDs once so the chain of dependent deletes can all reference
-- the same list without redundant subqueries.

WITH japan_cities AS (
  SELECT unnest(ARRAY[
    'Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nara',
    'Nagoya','Kobe','Okinawa','Hakone','Otaru','Niseko','Kawaguchiko',
    'Nagasaki','Yokohama','Sendai','Nagano','Matsumoto','Takayama',
    'Hakodate','Kanazawa','Yufuin','Beppu','Aomori','Disneyland Tokyo'
  ]) AS city
),
japan_travelers AS (
  SELECT id
  FROM   public.travelers
  WHERE  destination IN (SELECT city FROM japan_cities)
     OR  meta->>'origin_country' = 'Japan'
     OR  meta->>'origin_city'    IN (SELECT city FROM japan_cities)
)

-- ── 1. Wipe set_assignments for sets that have ANY Japan plan ──
-- (We delete the assignment row regardless of whether the set also has
-- non-Japan plans; the assignment is for the whole set, and the set
-- will either be deleted in step 4 or kept with only the non-Japan
-- plans. Either way the existing assignment is wrong.)
DELETE FROM public.set_assignments
WHERE  set_id IN (
  SELECT DISTINCT set_id FROM public.plans
  WHERE  set_id IS NOT NULL
    AND  traveler_id IN (SELECT id FROM japan_travelers)
);


-- ── 2. Wipe itinerary_items for Japan plans ──
DELETE FROM public.itinerary_items
WHERE  plan_id IN (
  SELECT id FROM public.plans
  WHERE  traveler_id IN (
    SELECT id FROM public.travelers
    WHERE  destination IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nara','Nagoya','Kobe','Okinawa','Hakone','Otaru','Niseko','Kawaguchiko','Nagasaki','Yokohama','Sendai','Nagano','Matsumoto','Takayama','Hakodate','Kanazawa','Yufuin','Beppu','Aomori','Disneyland Tokyo')
       OR  meta->>'origin_country' = 'Japan'
       OR  meta->>'origin_city'    IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nagoya','Kobe','Okinawa')
  )
);


-- ── 3. Wipe plans tied to Japan travelers ──
DELETE FROM public.plans
WHERE  traveler_id IN (
  SELECT id FROM public.travelers
  WHERE  destination IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nara','Nagoya','Kobe','Okinawa','Hakone','Otaru','Niseko','Kawaguchiko','Nagasaki','Yokohama','Sendai','Nagano','Matsumoto','Takayama','Hakodate','Kanazawa','Yufuin','Beppu','Aomori','Disneyland Tokyo')
     OR  meta->>'origin_country' = 'Japan'
     OR  meta->>'origin_city'    IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nagoya','Kobe','Okinawa')
);


-- ── 4. Wipe sets that now have no remaining plans ──
DELETE FROM public.sets
WHERE  NOT EXISTS (
  SELECT 1 FROM public.plans p WHERE p.set_id = sets.id
);


-- ── 5. Wipe the Japan traveler rows themselves ──
DELETE FROM public.travelers
WHERE  destination IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nara','Nagoya','Kobe','Okinawa','Hakone','Otaru','Niseko','Kawaguchiko','Nagasaki','Yokohama','Sendai','Nagano','Matsumoto','Takayama','Hakodate','Kanazawa','Yufuin','Beppu','Aomori','Disneyland Tokyo')
   OR  meta->>'origin_country' = 'Japan'
   OR  meta->>'origin_city'    IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nagoya','Kobe','Okinawa');


-- ── Verify ──────────────────────────────────────────────────────────
-- a) No Japan-destination traveler should remain.
SELECT COUNT(*) AS japan_travelers_remaining
FROM   public.travelers
WHERE  destination IN ('Tokyo','Kyoto','Osaka','Sapporo','Fukuoka','Hiroshima','Nara','Nagoya','Kobe','Okinawa','Hakone','Otaru','Niseko','Kawaguchiko','Nagasaki','Yokohama','Sendai','Nagano','Matsumoto','Takayama','Hakodate','Kanazawa','Yufuin','Beppu','Aomori','Disneyland Tokyo')
   OR  meta->>'origin_country' = 'Japan';
-- → 0

-- b) Current total — should be 38 unit rows / 16 distinct people
--    (Sofía's 3 + the 15 new mid-range travelers' 35 units) if you've
--    also run the reset SQL. If it's higher, there are still other
--    non-Japan stray travelers from old seeds.
SELECT COUNT(DISTINCT meta->>'person_id') AS travelers_meta_only,
       COUNT(DISTINCT name)               AS travelers_by_name,
       COUNT(*)                            AS unit_rows
FROM   public.travelers;

-- c) See what's left so you can spot any remaining strays.
SELECT name, destination, meta->>'origin_country' AS origin,
       meta->>'seed_batch' AS batch, status
FROM   public.travelers
ORDER  BY name, destination;
