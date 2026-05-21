-- ============================================================================
-- Fill missing meta fields for all 30 batch-01 travelers.
--
-- Adds splurge_willingness, booking_authority, accommodation_preference,
-- accommodation_room, accommodation_must_haves, dining_style,
-- cuisine_interests, daily_timing, intensity, mobility, must_avoid — driven
-- by each person's persona (group type, tier, occasion, dietary, origin).
--
-- Pattern: `defaults || meta` — existing meta wins on conflict, so any field
-- a traveler already had stays untouched. Safe to re-run.
--
-- Applies to all units (unit_order 1..N) of each person via meta.person_id.
-- ============================================================================


-- ── Person 01 · Kaito Yamada · Solo · Budget · Japan · backpacker ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"strict",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"hostel",
  "accommodation_room":"1 dorm bed or single",
  "accommodation_must_haves":["Central location","Wifi","24h check-in","Lockers"],
  "dining_style":"Adventurous · Street food",
  "cuisine_interests":["Local bistros","Markets","Pastries","Street food"],
  "daily_timing":"Early (7-8am)",
  "intensity":"Active walking (8-10km/day)",
  "mobility":"none",
  "must_avoid":"Tourist traps, chain restaurants"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '01';

-- ── Person 02 · Sofía Romero · Solo · Budget · Argentina · slow traveler ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"airbnb",
  "accommodation_room":"Private room with shared bath",
  "accommodation_must_haves":["Central location","Wifi","Quiet street","Photo-iconic views"],
  "dining_style":"Familiar comfort",
  "cuisine_interests":["Local bistros","Pastries","Cafes","Crêpes"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Light walking (4-6km/day)",
  "mobility":"none",
  "must_avoid":"Large tour groups, fast schedules"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '02';

-- ── Person 03 · Marcus Cohen · Solo · Mid · USA · writer ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"hotel",
  "accommodation_room":"1 quiet room · Single bed · Desk",
  "accommodation_must_haves":["Quiet street","Desk","Coffee in lobby","Wifi"],
  "dining_style":"Familiar comfort",
  "cuisine_interests":["Cafes","Local bistros","French classics","Pastries"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Light walking (4-6km/day)",
  "mobility":"none",
  "must_avoid":"Crowded tourist sites"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '03';

-- ── Person 04 · Anna Weber · Solo · Mid · Germany · photographer ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"Single room · Sea view if possible",
  "accommodation_must_haves":["Sea view","Early breakfast","Wifi","Walkable to coast"],
  "dining_style":"Adventurous",
  "cuisine_interests":["Local bistros","Seafood","Markets","Pastries"],
  "daily_timing":"Early (7-8am)",
  "intensity":"Active walking · Equipment-heavy",
  "mobility":"none",
  "must_avoid":"Crowded peak times, all-inclusive resorts"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '04';

-- ── Person 05 · Thabo Mthembu · Solo · Mid · South Africa · wine ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"Frequent splurges",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"1 room · King bed",
  "accommodation_must_haves":["Walking distance to maisons","Concierge","Wifi","Wine storage available"],
  "dining_style":"Adventurous · Wine pairings",
  "cuisine_interests":["French classics","Wine pairings","Cellar tours","Cheese"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking (5-8km/day)",
  "mobility":"none",
  "must_avoid":"Group bus tours"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '05';

-- ── Person 06 · Wei Ling Tan · Solo · Luxury · Singapore · pampering ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Deluxe suite · King bed · Spa access",
  "accommodation_must_haves":["Central","Spa","Michelin restaurant onsite","Concierge"],
  "dining_style":"Fine dining · Adventurous",
  "cuisine_interests":["Michelin","French classics","Champagne","Wine pairings"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Light walking · Often by car",
  "mobility":"none",
  "must_avoid":"Hostels, public buses"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '06';

-- ── Person 07 · Min-jun & Soo-jin · Couple · Budget · Korea ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"hotel",
  "accommodation_room":"1 room · Queen bed",
  "accommodation_must_haves":["Central","Wifi","Photo-worthy","Near transit"],
  "dining_style":"Adventurous",
  "cuisine_interests":["French classics","Pastries","Photo cafes","Local bistros"],
  "daily_timing":"Early (7-8am)",
  "intensity":"Active walking (8-10km/day)",
  "mobility":"none",
  "must_avoid":"Long bus rides"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '07';

-- ── Person 08 · Liam & Chloé · Couple · Budget · Canada · Quebec nurses ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"airbnb",
  "accommodation_room":"1 bedroom apt · Queen bed",
  "accommodation_must_haves":["Kitchen","Beach access","Wifi","Quiet"],
  "dining_style":"Adventurous · Local",
  "cuisine_interests":["French classics","Seafood","Local bistros","Wine"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking + Beach",
  "mobility":"none",
  "must_avoid":"Chain hotels"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '08';

-- ── Person 09 · Ethan & Mia · Couple · Budget · Australia · Corsica ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"airbnb",
  "accommodation_room":"Simple room · Twin or double",
  "accommodation_must_haves":["Hiking trail access","Beach access","Simple","Wifi"],
  "dining_style":"Adventurous",
  "cuisine_interests":["Local Corsican","Seafood","Markets","Charcuterie"],
  "daily_timing":"Early (7-8am)",
  "intensity":"Active hiking (10-15km/day)",
  "mobility":"none",
  "must_avoid":"Resort towns, group tours"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '09';

-- ── Person 10 · Arjun & Priya · Couple · Mid · India · vegetarian anniversary ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"1 room · King bed · Romantic",
  "accommodation_must_haves":["Vegetarian-friendly restaurants nearby","Central","Romantic atmosphere","Wifi"],
  "dining_style":"Adventurous · Vegetarian-verified",
  "cuisine_interests":["Vegetarian French","Pastries","Cheese","Cafes"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Restaurants without vegetarian options"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '10';

-- ── Person 11 · Lars & Emma · Couple · Mid · Netherlands · champagne ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"Boutique 1 room · King bed",
  "accommodation_must_haves":["Walking distance to maisons","Quiet street","Wine storage available","Wifi"],
  "dining_style":"Adventurous · Wine pairings",
  "cuisine_interests":["Champagne","French classics","Cheese","Wine pairings"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Chain tours, tourist tastings"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '11';

-- ── Person 12 · Sarah & David · Couple · Mid · USA · celiac anniversary ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"1 room · King bed",
  "accommodation_must_haves":["Gluten-free options at breakfast","Quiet","Romantic","Lavender views if season"],
  "dining_style":"Adventurous · Gluten-free verified",
  "cuisine_interests":["Gluten-free pastries","Wine pairings","Provence cuisine","Markets"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Places that cannot accommodate celiac"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '12';

-- ── Person 13 · James & Olivia · Couple · Mid · UK · Alps hikers ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"hotel",
  "accommodation_room":"Mountain-view double · King or twin",
  "accommodation_must_haves":["Hiking trail access","Boot storage","Hearty breakfast","Hot tub if possible"],
  "dining_style":"Adventurous · Hearty",
  "cuisine_interests":["Savoyard cuisine","Cheese","Wine","Local pubs"],
  "daily_timing":"Early (7-8am)",
  "intensity":"Active hiking (10-15km/day)",
  "mobility":"none",
  "must_avoid":"City days, museums"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '13';

-- ── Person 14 · Wei Zhang & Mei Liu · Couple · Luxury · China · 20th anniv ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Junior suite · King bed · City view",
  "accommodation_must_haves":["Private check-in","Concierge","Spa","Premium amenities"],
  "dining_style":"Fine dining",
  "cuisine_interests":["Michelin","Champagne","French classics","Wine pairings"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Light walking · Often by car",
  "mobility":"none",
  "must_avoid":"Group tours, fast schedules"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '14';

-- ── Person 15 · Lucas & Mariana · Honeymoon · Budget · Brazil ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"1 room · Queen bed · Romantic",
  "accommodation_must_haves":["Romantic atmosphere","Quiet","Wifi","Iconic photo spots"],
  "dining_style":"Adventurous",
  "cuisine_interests":["French classics","Wine","Cafes","Pastries"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Obvious tourist traps"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '15';

-- ── Person 16 · Joshua & Bea · Honeymoon · Budget · Philippines · halal ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"1 room · King bed · Sea view",
  "accommodation_must_haves":["Halal-friendly area","Beach access","Romantic","Wifi"],
  "dining_style":"Adventurous · Halal-verified",
  "cuisine_interests":["Halal-friendly French","Seafood","Mediterranean","Pastries"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking + Beach",
  "mobility":"none",
  "must_avoid":"Non-halal restaurants"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '16';

-- ── Person 17 · Ryan & Ashley · Honeymoon · Mid · USA · Provence Michelin ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"1 room · King bed · Lavender or sunset view",
  "accommodation_must_haves":["Romantic atmosphere","Sunset views","Late breakfast","Spa or pool"],
  "dining_style":"Fine dining · Romantic",
  "cuisine_interests":["Michelin","Provence cuisine","Lavender honey","Wine pairings"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Light walking (4-6km/day)",
  "mobility":"none",
  "must_avoid":"Early starts, tour groups"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '17';

-- ── Person 18 · Marco & Sofia · Honeymoon · Mid · Italy · pescatarian ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"ryokan_equivalent_boutique",
  "accommodation_room":"1 room · King bed · Romantic",
  "accommodation_must_haves":["Quiet street","Romantic atmosphere","Authentic local feel","Wifi"],
  "dining_style":"Adventurous · Pescatarian",
  "cuisine_interests":["French classics","Pescatarian options","Wine","Pastries"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Italian-style restaurants"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '18';

-- ── Person 19 · Sophie & Tom · Honeymoon · Luxury · UK · château + sommelier ──
UPDATE public.travelers SET meta = '{
  "accommodation_room":"Château suite · King bed · Period décor",
  "accommodation_must_haves":["Actual château stay","Cellar access","Sommelier on staff","Privacy"],
  "dining_style":"Fine dining · Romantic",
  "cuisine_interests":["Michelin","Champagne","Loire wines","Cellar tours","Aged classics"],
  "daily_timing":"Late starts (after 10am)",
  "intensity":"Light walking · Often driven",
  "mobility":"none",
  "must_avoid":"Chain hotels, group tours"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '19';

-- ── Person 20 · Aishah & Faizal family · Family · Budget · Malaysia · halal ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"1 family room · 2 doubles · Sleeps 4",
  "accommodation_must_haves":["Halal-friendly area","Near Disneyland/transport","Family rooms available","Wifi"],
  "dining_style":"Reliable · Kid-friendly · Halal",
  "cuisine_interests":["Halal-friendly French","Kid-friendly cafes","Pastries","Crêpes"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Light walking · Stroller-friendly",
  "must_avoid":"Non-halal restaurants, late dinners"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '20';

-- ── Person 21 · Hannah & Daniel family · Family · Budget · NZ · 3 kids ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"strict",
  "booking_authority":"planner_books_all",
  "accommodation_preference":"airbnb",
  "accommodation_room":"Apartment · Sleeps 5",
  "accommodation_must_haves":["Kitchen","Multiple beds","Beach/nature access","Wifi"],
  "dining_style":"Reliable · Kid-friendly",
  "cuisine_interests":["French classics","Kid-friendly cafes","Crêpes","Picnics"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking + Nature",
  "mobility":"none",
  "must_avoid":"Long city days"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '21';

-- ── Person 22 · Carmen & Pablo family · Family · Budget · Spain · beach ──
UPDATE public.travelers SET meta = '{
  "splurge_willingness":"1-2 splurges OK",
  "booking_authority":"planner_recommends",
  "accommodation_preference":"airbnb",
  "accommodation_room":"Apartment · Sleeps 4 · Beach proximity",
  "accommodation_must_haves":["Beach within walking","Kitchen","Family-friendly","Pool if possible"],
  "dining_style":"Reliable · Family-friendly",
  "cuisine_interests":["Seafood","French classics","Beach cafes","Ice cream"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking + Beach",
  "mobility":"none",
  "must_avoid":"Museums, walking tours"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '22';

-- ── Person 23 · Jessica & Brian family · Family · Mid · USA · 3 young kids ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Family suite · Sleeps 5",
  "accommodation_must_haves":["Family rooms","Nut-free kitchen verified","Stroller-friendly","Late check-in possible"],
  "dining_style":"Reliable · Kid-friendly · Nut-aware",
  "cuisine_interests":["Nut-free French","Pastries (nut-free)","Crêpes","Kid-friendly cafes"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Light walking · Stroller pace"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '23';

-- ── Person 24 · Diego & Laura family · Family · Mid · Mexico · teens ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"1 family room or connecting · Sleeps 4",
  "accommodation_must_haves":["Central","Wifi for teens","Shopping nearby","Restaurants walkable"],
  "dining_style":"Reliable · Adventurous",
  "cuisine_interests":["French classics","Pastries","Bistros","Shopping street snacks"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking + Shopping",
  "mobility":"none",
  "must_avoid":"Fine dining, very late dinners"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '24';

-- ── Person 25 · Hiroshi & Akiko family · Family · Mid · Japan · daughter 8 ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Family room · Sleeps 3",
  "accommodation_must_haves":["English-speaking staff","Central","Family-friendly","Wifi"],
  "dining_style":"Reliable · Kid-friendly",
  "cuisine_interests":["French classics","Pastries","Crêpes","Cafes"],
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Long museum days"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '25';

-- ── Person 26 · Khalid & Fatima family · Family · Luxury · UAE · halal teens ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Family suite · Sleeps 4",
  "accommodation_must_haves":["Halal-friendly area","Premium amenities","Concierge","Privacy"],
  "dining_style":"Fine dining · Halal-verified",
  "cuisine_interests":["Halal-friendly fine dining","Pastries","Mediterranean","Premium cuisine"],
  "intensity":"Light walking · Often by car",
  "mobility":"none",
  "must_avoid":"Non-halal restaurants"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '26';

-- ── Person 27 · Camila & friends · Group · Budget · Chile · Pyrenees hikers ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hostel",
  "accommodation_room":"Refuge or hostel · Sleeps 4",
  "accommodation_must_haves":["Trailhead access","Boot storage","Hot showers","Hearty breakfast"],
  "dining_style":"Adventurous · Hearty",
  "cuisine_interests":["Mountain cuisine","Local cheeses","Wine","Hearty meals"],
  "intensity":"Active hiking (10-15km/day)",
  "mobility":"none",
  "must_avoid":"City days, fine dining"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '27';

-- ── Person 28 · Youssef & friends · Group · Budget · Morocco · halal Provence ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"airbnb",
  "accommodation_room":"Apartment · Sleeps 5",
  "accommodation_must_haves":["Halal-friendly area","Kitchen","Beach access","Wifi"],
  "dining_style":"Adventurous · Halal-verified",
  "cuisine_interests":["Halal-friendly French","Mediterranean","Seafood","Markets"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Non-halal restaurants"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '28';

-- ── Person 29 · Xiao & friends · Group · Mid · China · wine traders ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Multiple rooms · Group rate",
  "accommodation_must_haves":["Group dining","Walking to maisons","Wine cellar","Wifi"],
  "dining_style":"Fine dining · Wine pairings",
  "cuisine_interests":["Wine pairings","Cellar tours","French classics","Cheese"],
  "daily_timing":"Standard (9-10am)",
  "intensity":"Moderate walking",
  "mobility":"none",
  "must_avoid":"Tourist tastings"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '29';

-- ── Person 30 · Ji-hoon & friends · Group · Mid · Korea · Alps + Riviera ──
UPDATE public.travelers SET meta = '{
  "accommodation_preference":"hotel",
  "accommodation_room":"Multiple rooms · Group rate",
  "accommodation_must_haves":["Central","Nightlife nearby","Wifi","Photo-worthy"],
  "dining_style":"Adventurous",
  "cuisine_interests":["French classics","Bistros","Nightlife snacks","Wine"],
  "intensity":"Active walking + Hiking",
  "mobility":"none",
  "must_avoid":"Museums, slow tours"
}'::jsonb || meta
WHERE meta->>'seed_batch' = '01' AND meta->>'person_id' = '30';


-- ── Verify: every batch-01 person should now carry the full set of meta keys ──
SELECT meta->>'person_id' AS person, COUNT(*) AS units,
       BOOL_AND(meta ? 'splurge_willingness')       AS splurge,
       BOOL_AND(meta ? 'booking_authority')         AS booking,
       BOOL_AND(meta ? 'accommodation_preference')  AS accom_pref,
       BOOL_AND(meta ? 'accommodation_room')        AS accom_room,
       BOOL_AND(meta ? 'accommodation_must_haves')  AS accom_mh,
       BOOL_AND(meta ? 'dining_style')              AS dining,
       BOOL_AND(meta ? 'cuisine_interests')         AS cuisines,
       BOOL_AND(meta ? 'daily_timing')              AS timing,
       BOOL_AND(meta ? 'intensity')                 AS intensity,
       BOOL_AND(meta ? 'mobility')                  AS mobility,
       BOOL_AND(meta ? 'must_avoid')                AS must_avoid
FROM public.travelers
WHERE meta->>'seed_batch' = '01'
GROUP BY meta->>'person_id'
ORDER BY (meta->>'person_id')::int;
