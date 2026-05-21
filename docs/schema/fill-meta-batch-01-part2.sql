-- ============================================================================
-- Fill missing meta fields — Part 2 of 2.
--
-- Adds the remaining fields the Brief renders but Part 1 didn't fill:
--   languages, occasion, previous_visits_to_france,
--   daily_spend_per_pax_eur, hotel_budget_per_night_pax_eur
--
-- Budget defaults are tier-driven (per pax):
--   budget:    daily 70,  hotel 55
--   mid_range: daily 130, hotel 110
--   luxury:    daily 300, hotel 280
--
-- Pattern: `defaults || meta` — existing values win. Safe to re-run.
-- ============================================================================


-- ── 01 · Kaito · Japan · solo budget backpacker ──
UPDATE public.travelers SET meta = '{
  "languages":["Japanese","English"],
  "occasion":"solo_travel",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":70,
  "hotel_budget_per_night_pax_eur":55
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '01';

-- ── 02 · Sofía · Argentina · solo budget slow traveler ──
UPDATE public.travelers SET meta = '{
  "languages":["Spanish","English"],
  "occasion":"solo_travel",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":75,
  "hotel_budget_per_night_pax_eur":60
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '02';

-- ── 03 · Marcus · USA · solo mid writer ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"writing_retreat",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":145,
  "hotel_budget_per_night_pax_eur":115
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '03';

-- ── 04 · Anna · Germany · solo mid photographer ──
UPDATE public.travelers SET meta = '{
  "languages":["German","English"],
  "occasion":"photo_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":140,
  "hotel_budget_per_night_pax_eur":125
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '04';

-- ── 05 · Thabo · South Africa · solo mid wine ──
UPDATE public.travelers SET meta = '{
  "languages":["English","Afrikaans"],
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":150,
  "hotel_budget_per_night_pax_eur":135
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '05';

-- ── 06 · Wei Ling · Singapore · solo luxury ──
UPDATE public.travelers SET meta = '{
  "languages":["English","Mandarin"],
  "previous_visits_to_france":"been_once",
  "daily_spend_per_pax_eur":420,
  "hotel_budget_per_night_pax_eur":340
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '06';

-- ── 07 · Min-jun & Soo-jin · Korea · couple budget ──
UPDATE public.travelers SET meta = '{
  "languages":["Korean","English"],
  "occasion":"couple_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":85,
  "hotel_budget_per_night_pax_eur":62
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '07';

-- ── 08 · Liam & Chloé · Canada (QC) · couple budget ──
UPDATE public.travelers SET meta = '{
  "languages":["French","English"],
  "occasion":"couple_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":80,
  "hotel_budget_per_night_pax_eur":60
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '08';

-- ── 09 · Ethan & Mia · Australia · couple budget Corsica hikers ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"hiking_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":75,
  "hotel_budget_per_night_pax_eur":55
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '09';

-- ── 10 · Arjun & Priya · India · couple mid vegetarian anniversary ──
UPDATE public.travelers SET meta = '{
  "languages":["English","Hindi"],
  "occasion":"anniversary",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":130,
  "hotel_budget_per_night_pax_eur":110
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '10';

-- ── 11 · Lars & Emma · Netherlands · couple mid champagne ──
UPDATE public.travelers SET meta = '{
  "languages":["Dutch","English"],
  "occasion":"champagne_tour",
  "previous_visits_to_france":"been_once",
  "daily_spend_per_pax_eur":135,
  "hotel_budget_per_night_pax_eur":115
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '11';

-- ── 12 · Sarah & David · USA · couple mid celiac anniversary ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"anniversary",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":140,
  "hotel_budget_per_night_pax_eur":120
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '12';

-- ── 13 · James & Olivia · UK · couple mid Alps hikers ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"hiking_trip",
  "previous_visits_to_france":"been_multiple_times",
  "daily_spend_per_pax_eur":130,
  "hotel_budget_per_night_pax_eur":110
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '13';

-- ── 14 · Wei Zhang & Mei Liu · China · couple luxury 20th anniv ──
UPDATE public.travelers SET meta = '{
  "languages":["Mandarin","English"],
  "occasion":"anniversary",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":380,
  "hotel_budget_per_night_pax_eur":320
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '14';

-- ── 15 · Lucas & Mariana · Brazil · honeymoon budget ──
UPDATE public.travelers SET meta = '{
  "languages":["Portuguese","English"],
  "occasion":"honeymoon",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":85,
  "hotel_budget_per_night_pax_eur":70
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '15';

-- ── 16 · Joshua & Bea · Philippines · honeymoon budget halal ──
UPDATE public.travelers SET meta = '{
  "languages":["English","Tagalog"],
  "occasion":"honeymoon",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":90,
  "hotel_budget_per_night_pax_eur":75
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '16';

-- ── 17 · Ryan & Ashley · USA · honeymoon mid Provence Michelin ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"honeymoon",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":155,
  "hotel_budget_per_night_pax_eur":130
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '17';

-- ── 18 · Marco & Sofia · Italy · honeymoon mid pescatarian ──
UPDATE public.travelers SET meta = '{
  "languages":["Italian","English"],
  "occasion":"honeymoon",
  "previous_visits_to_france":"been_once",
  "daily_spend_per_pax_eur":135,
  "hotel_budget_per_night_pax_eur":115
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '18';

-- ── 19 · Sophie & Tom · UK · honeymoon luxury château + sommelier ──
UPDATE public.travelers SET meta = '{
  "languages":["English","Basic French"],
  "occasion":"honeymoon",
  "previous_visits_to_france":"been_multiple_times",
  "daily_spend_per_pax_eur":380,
  "hotel_budget_per_night_pax_eur":340
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '19';

-- ── 20 · Aishah & Faizal · Malaysia · family budget halal Disney ──
UPDATE public.travelers SET meta = '{
  "languages":["Malay","English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":80,
  "hotel_budget_per_night_pax_eur":60
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '20';

-- ── 21 · Hannah & Daniel · New Zealand · family budget 3 kids ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":75,
  "hotel_budget_per_night_pax_eur":55
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '21';

-- ── 22 · Carmen & Pablo · Spain · family budget beach ──
UPDATE public.travelers SET meta = '{
  "languages":["Spanish","English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"been_multiple_times",
  "daily_spend_per_pax_eur":80,
  "hotel_budget_per_night_pax_eur":60
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '22';

-- ── 23 · Jessica & Brian · USA · family mid 3 young kids nut allergy ──
UPDATE public.travelers SET meta = '{
  "languages":["English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":140,
  "hotel_budget_per_night_pax_eur":120
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '23';

-- ── 24 · Diego & Laura · Mexico · family mid teens ──
UPDATE public.travelers SET meta = '{
  "languages":["Spanish","English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":130,
  "hotel_budget_per_night_pax_eur":110
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '24';

-- ── 25 · Hiroshi & Akiko · Japan · family mid daughter 8 ──
UPDATE public.travelers SET meta = '{
  "languages":["Japanese","English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":135,
  "hotel_budget_per_night_pax_eur":115
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '25';

-- ── 26 · Khalid & Fatima · UAE · family luxury halal teens ──
UPDATE public.travelers SET meta = '{
  "languages":["Arabic","English"],
  "occasion":"family_vacation",
  "previous_visits_to_france":"been_once",
  "daily_spend_per_pax_eur":360,
  "hotel_budget_per_night_pax_eur":310
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '26';

-- ── 27 · Camila & friends · Chile · group budget Pyrenees hikers ──
UPDATE public.travelers SET meta = '{
  "languages":["Spanish","English"],
  "occasion":"hiking_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":70,
  "hotel_budget_per_night_pax_eur":50
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '27';

-- ── 28 · Youssef & friends · Morocco · group budget halal Provence ──
UPDATE public.travelers SET meta = '{
  "languages":["Arabic","French"],
  "occasion":"group_trip",
  "previous_visits_to_france":"been_multiple_times",
  "daily_spend_per_pax_eur":80,
  "hotel_budget_per_night_pax_eur":60
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '28';

-- ── 29 · Xiao & friends · China · group mid wine traders ──
UPDATE public.travelers SET meta = '{
  "languages":["Mandarin","English"],
  "occasion":"wine_pilgrimage",
  "previous_visits_to_france":"been_once",
  "daily_spend_per_pax_eur":150,
  "hotel_budget_per_night_pax_eur":130
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '29';

-- ── 30 · Ji-hoon & friends · Korea · group mid Alps + Riviera ──
UPDATE public.travelers SET meta = '{
  "languages":["Korean","English"],
  "occasion":"group_trip",
  "previous_visits_to_france":"first_time",
  "daily_spend_per_pax_eur":135,
  "hotel_budget_per_night_pax_eur":115
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '30';


-- ── Verify: every batch-01 person now carries the Part-2 meta keys too ──
SELECT meta->>'person_id' AS person, COUNT(*) AS units,
       BOOL_AND(meta ? 'languages')                       AS languages,
       BOOL_AND(meta ? 'occasion')                        AS occasion,
       BOOL_AND(meta ? 'previous_visits_to_france')       AS prev_visits,
       BOOL_AND(meta ? 'daily_spend_per_pax_eur')         AS daily_budget,
       BOOL_AND(meta ? 'hotel_budget_per_night_pax_eur')  AS hotel_budget
FROM public.travelers
WHERE meta->>'seed_batch' = '01'
GROUP BY meta->>'person_id'
ORDER BY (meta->>'person_id')::int;
