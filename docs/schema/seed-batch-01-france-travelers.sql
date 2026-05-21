-- ============================================================================
-- France travelers seed — Batch 1 of 5 (30 PEOPLE → 105 rows, one per unit)
--
-- Each row = one 2D1N or 3D2N leg. Multi-city travelers appear N times
-- (same name + phone + notes, different city/dates each). Linked by
-- meta.person_id + meta.unit_order / unit_total.
--
-- Rollback: DELETE FROM public.travelers WHERE meta->>'seed_batch' = '01';
-- Safe to re-run.
-- ============================================================================

ALTER TABLE public.travelers ADD COLUMN IF NOT EXISTS meta jsonb;
CREATE INDEX IF NOT EXISTS travelers_meta_seed_batch_idx ON public.travelers((meta->>'seed_batch'));
CREATE INDEX IF NOT EXISTS travelers_meta_person_id_idx ON public.travelers((meta->>'person_id'));

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='travelers' AND column_name='meta') THEN
    -- Cleanup order matters — none of these FKs cascade:
    --   itinerary_items → plans → travelers
    --                  ↘ sets
    -- So we peel from the deepest dependency up.
    DELETE FROM public.itinerary_items
     WHERE plan_id IN (
       SELECT id FROM public.plans
        WHERE traveler_id IN (
          SELECT id FROM public.travelers WHERE meta->>'seed_batch' = '01'
        )
     );
    DELETE FROM public.plans
     WHERE traveler_id IN (
       SELECT id FROM public.travelers WHERE meta->>'seed_batch' = '01'
     );
    -- Old prototype sets used UUIDs starting with b0000001-... (from a previous
    -- shape of this file that pre-created sets).
    DELETE FROM public.itinerary_items
     WHERE plan_id IN (
       SELECT id FROM public.plans WHERE set_id::text LIKE 'b0000001-0000-4000-8000-%'
     );
    DELETE FROM public.plans WHERE set_id::text LIKE 'b0000001-0000-4000-8000-%';
    DELETE FROM public.sets WHERE id::text LIKE 'b0000001-0000-4000-8000-%';
    DELETE FROM public.travelers WHERE meta->>'seed_batch' = '01';
  END IF;
END $$;

INSERT INTO public.travelers (id, name, phone, destination, traveler_type, arrival_date, arrival_time, duration, group_size, special_notes, status, planner_payout, requires_bond, bond_amount, meta) VALUES

-- ── Person 01 · Kaito Yamada · Solo · Budget · Japan (4 units) ──
('a0000001-0000-4000-8000-000100010000','Kaito Yamada','+81-90-2847-3651','Marseille','solo','2026-06-04','14:30','3D2N',1,'Backpacking after a job change in Tokyo. Small budget but want to see real France, not just tourist Paris.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"01","unit_order":1,"unit_total":4,"trip_start_date":"2026-06-04","trip_end_date":"2026-06-10","trip_total_duration":"7D6N","origin_country":"Japan","origin_city":"Tokyo","ages":[26],"languages":["Japanese","English (intermediate)"],"occasion":"bucket_list","budget_tier":"budget","hotel_budget_per_night_pax_eur":52,"daily_spend_per_pax_eur":72,"pace":"active","daily_timing":"early","splurge_willingness":"strict","dietary_restrictions":"none","mobility":"none","interests":["food_wine","local_culture","photography","villages","markets"],"must_avoid":"tourist traps, chain restaurants","previous_visits_to_france":"first_time","booking_authority":"planner_recommends","accommodation_preference":"hostel"}'::jsonb),
('a0000001-0000-4000-8000-000100020000','Kaito Yamada','+81-90-2847-3651','Aix-en-Provence','solo','2026-06-06',NULL,'2D1N',1,'Backpacking after a job change in Tokyo. Small budget but want to see real France, not just tourist Paris.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"01","unit_order":2,"unit_total":4,"trip_start_date":"2026-06-04","trip_end_date":"2026-06-10","trip_total_duration":"7D6N","origin_country":"Japan","origin_city":"Tokyo","ages":[26],"languages":["Japanese","English (intermediate)"],"occasion":"bucket_list","budget_tier":"budget","hotel_budget_per_night_pax_eur":52,"daily_spend_per_pax_eur":72,"pace":"active","daily_timing":"early","splurge_willingness":"strict","dietary_restrictions":"none","mobility":"none","interests":["food_wine","local_culture","photography","villages","markets"],"must_avoid":"tourist traps, chain restaurants","previous_visits_to_france":"first_time","booking_authority":"planner_recommends","accommodation_preference":"hostel"}'::jsonb),
('a0000001-0000-4000-8000-000100030000','Kaito Yamada','+81-90-2847-3651','Avignon','solo','2026-06-07',NULL,'3D2N',1,'Backpacking after a job change in Tokyo. Small budget but want to see real France, not just tourist Paris.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"01","unit_order":3,"unit_total":4,"trip_start_date":"2026-06-04","trip_end_date":"2026-06-10","trip_total_duration":"7D6N","origin_country":"Japan","origin_city":"Tokyo","ages":[26],"languages":["Japanese","English (intermediate)"],"occasion":"bucket_list","budget_tier":"budget","hotel_budget_per_night_pax_eur":52,"daily_spend_per_pax_eur":72,"pace":"active","daily_timing":"early","splurge_willingness":"strict","dietary_restrictions":"none","mobility":"none","interests":["food_wine","local_culture","photography","villages","markets"],"must_avoid":"tourist traps, chain restaurants","previous_visits_to_france":"first_time","booking_authority":"planner_recommends","accommodation_preference":"hostel"}'::jsonb),
('a0000001-0000-4000-8000-000100040000','Kaito Yamada','+81-90-2847-3651','Nice','solo','2026-06-09',NULL,'2D1N',1,'Backpacking after a job change in Tokyo. Small budget but want to see real France, not just tourist Paris.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"01","unit_order":4,"unit_total":4,"trip_start_date":"2026-06-04","trip_end_date":"2026-06-10","trip_total_duration":"7D6N","origin_country":"Japan","origin_city":"Tokyo","ages":[26],"languages":["Japanese","English (intermediate)"],"occasion":"bucket_list","budget_tier":"budget","hotel_budget_per_night_pax_eur":52,"daily_spend_per_pax_eur":72,"pace":"active","daily_timing":"early","splurge_willingness":"strict","dietary_restrictions":"none","mobility":"none","interests":["food_wine","local_culture","photography","villages","markets"],"must_avoid":"tourist traps, chain restaurants","previous_visits_to_france":"first_time","booking_authority":"planner_recommends","accommodation_preference":"hostel"}'::jsonb),

-- ── Person 02 · Sofía Romero · Solo · Budget · Argentina (3 units) ──
('a0000001-0000-4000-8000-000200010000','Sofía Romero','+54-11-4567-8923','Saint-Malo','solo','2026-06-11','09:50','3D2N',1,'Quit my marketing job in Buenos Aires. Doing France slowly. Family back home is worried — please suggest places I can send postcards from.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"02","unit_order":1,"unit_total":3,"trip_start_date":"2026-06-11","trip_end_date":"2026-06-16","origin_country":"Argentina","origin_city":"Buenos Aires","ages":[28],"languages":["Spanish","English (intermediate)"],"occasion":"bucket_list","budget_tier":"budget","hotel_budget_per_night_pax_eur":58,"daily_spend_per_pax_eur":78,"pace":"slow","interests":["villages","photography","food_wine","local_culture","architecture"],"dietary_restrictions":"none","previous_visits_to_france":"first_time"}'::jsonb),
('a0000001-0000-4000-8000-000200020000','Sofía Romero','+54-11-4567-8923','Mont-Saint-Michel','solo','2026-06-13',NULL,'2D1N',1,'Quit my marketing job in Buenos Aires. Doing France slowly.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"02","unit_order":2,"unit_total":3,"trip_start_date":"2026-06-11","trip_end_date":"2026-06-16","origin_country":"Argentina","origin_city":"Buenos Aires","ages":[28],"budget_tier":"budget","interests":["villages","photography","food_wine"],"dietary_restrictions":"none"}'::jsonb),
('a0000001-0000-4000-8000-000200030000','Sofía Romero','+54-11-4567-8923','Paris','solo','2026-06-14',NULL,'3D2N',1,'Quit my marketing job in Buenos Aires. Doing France slowly.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"02","unit_order":3,"unit_total":3,"trip_start_date":"2026-06-11","trip_end_date":"2026-06-16","origin_country":"Argentina","origin_city":"Buenos Aires","ages":[28],"budget_tier":"budget","interests":["art_museums","architecture","food_wine"],"dietary_restrictions":"none"}'::jsonb),

-- ── Person 03 · Marcus Cohen · Solo · Mid · USA (4 units) ──
('a0000001-0000-4000-8000-000300010000','Marcus Cohen','+1-718-555-3741','Paris','solo','2026-06-18','16:30','3D2N',1,'Brooklyn writer working on a novel. Want quiet cafés, old bookstores, places I can journal without being rushed.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"03","unit_order":1,"unit_total":4,"trip_start_date":"2026-06-18","trip_end_date":"2026-06-24","origin_country":"USA","origin_city":"New York","ages":[33],"budget_tier":"mid_range","hotel_budget_per_night_pax_eur":115,"daily_spend_per_pax_eur":145,"pace":"slow","interests":["art_museums","architecture","food_wine","hidden_gems","cafes"],"dietary_restrictions":"none"}'::jsonb),
('a0000001-0000-4000-8000-000300020000','Marcus Cohen','+1-718-555-3741','Loire Valley','solo','2026-06-20',NULL,'2D1N',1,'Brooklyn writer working on a novel. Quiet places to journal.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"03","unit_order":2,"unit_total":4,"trip_start_date":"2026-06-18","trip_end_date":"2026-06-24","origin_country":"USA","budget_tier":"mid_range","interests":["châteaux","architecture","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-000300030000','Marcus Cohen','+1-718-555-3741','Mont-Saint-Michel','solo','2026-06-21',NULL,'2D1N',1,'Brooklyn writer working on a novel. Quiet places to journal.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"03","unit_order":3,"unit_total":4,"trip_start_date":"2026-06-18","trip_end_date":"2026-06-24","origin_country":"USA","budget_tier":"mid_range","interests":["architecture","photography"]}'::jsonb),
('a0000001-0000-4000-8000-000300040000','Marcus Cohen','+1-718-555-3741','Nice','solo','2026-06-22',NULL,'3D2N',1,'Brooklyn writer working on a novel. Quiet places to journal.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"03","unit_order":4,"unit_total":4,"trip_start_date":"2026-06-18","trip_end_date":"2026-06-24","origin_country":"USA","budget_tier":"mid_range","interests":["beach","food_wine","architecture"]}'::jsonb),

-- ── Person 04 · Anna Weber · Solo · Mid · Germany (4 units) ──
('a0000001-0000-4000-8000-000400010000','Anna Weber','+49-30-12345678','Nice','solo','2026-06-22','11:00','3D2N',1,'Photography focus — amateur but serious. Need golden hour spots on the coast. Travelling light, no group tours.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"04","unit_order":1,"unit_total":4,"trip_start_date":"2026-06-22","trip_end_date":"2026-06-28","origin_country":"Germany","origin_city":"Berlin","ages":[35],"budget_tier":"mid_range","hotel_budget_per_night_pax_eur":125,"daily_spend_per_pax_eur":140,"pace":"moderate","interests":["photography","beach","villages","food_wine"],"dietary_restrictions":"vegetarian"}'::jsonb),
('a0000001-0000-4000-8000-000400020000','Anna Weber','+49-30-12345678','Cannes','solo','2026-06-24',NULL,'2D1N',1,'Photography focus — amateur but serious. Golden hour coast shots.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"04","unit_order":2,"unit_total":4,"trip_start_date":"2026-06-22","trip_end_date":"2026-06-28","budget_tier":"mid_range","interests":["photography","beach"],"dietary_restrictions":"vegetarian"}'::jsonb),
('a0000001-0000-4000-8000-000400030000','Anna Weber','+49-30-12345678','Monaco','solo','2026-06-25',NULL,'2D1N',1,'Photography focus — amateur but serious. Golden hour coast shots.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"04","unit_order":3,"unit_total":4,"trip_start_date":"2026-06-22","trip_end_date":"2026-06-28","budget_tier":"mid_range","interests":["photography","architecture"],"dietary_restrictions":"vegetarian"}'::jsonb),
('a0000001-0000-4000-8000-000400040000','Anna Weber','+49-30-12345678','Saint-Tropez','solo','2026-06-26',NULL,'3D2N',1,'Photography focus — amateur but serious. Golden hour coast shots.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"04","unit_order":4,"unit_total":4,"trip_start_date":"2026-06-22","trip_end_date":"2026-06-28","budget_tier":"mid_range","interests":["photography","beach","villages"],"dietary_restrictions":"vegetarian"}'::jsonb),

-- ── Person 05 · Thabo Mthembu · Solo · Mid · South Africa (3 units) ──
('a0000001-0000-4000-8000-000500010000','Thabo Mthembu','+27-21-555-2891','Bordeaux','solo','2026-06-27','19:45','3D2N',1,'Run a wine import business in Cape Town. Want château visits with actual winemakers, not tasting rooms.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"05","unit_order":1,"unit_total":3,"trip_start_date":"2026-06-27","trip_end_date":"2026-07-01","origin_country":"South Africa","origin_city":"Cape Town","ages":[31],"budget_tier":"mid_range","hotel_budget_per_night_pax_eur":135,"daily_spend_per_pax_eur":150,"occasion":"wine_pilgrimage","interests":["food_wine","villages","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-000500020000','Thabo Mthembu','+27-21-555-2891','Saint-Émilion','solo','2026-06-29',NULL,'2D1N',1,'Wine import business owner. Château visits with winemakers.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"05","unit_order":2,"unit_total":3,"trip_start_date":"2026-06-27","trip_end_date":"2026-07-01","budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","villages"]}'::jsonb),
('a0000001-0000-4000-8000-000500030000','Thabo Mthembu','+27-21-555-2891','Cognac','solo','2026-06-30',NULL,'2D1N',1,'Wine import business owner. Cellar tours preferred.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"05","unit_order":3,"unit_total":3,"trip_start_date":"2026-06-27","trip_end_date":"2026-07-01","budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","cellar_tours"]}'::jsonb),

-- ── Person 06 · Wei Ling Tan · Solo · Luxury · Singapore (4 units) ──
('a0000001-0000-4000-8000-000600010000','Wei Ling Tan','+65-9123-4567','Paris','solo','2026-07-02','06:15','3D2N',1,'Pampering myself after a brutal year at the firm. Michelin stars, spa moments, the works.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"06","unit_order":1,"unit_total":4,"trip_start_date":"2026-07-02","trip_end_date":"2026-07-09","origin_country":"Singapore","origin_city":"Singapore","ages":[42],"budget_tier":"luxury","hotel_budget_per_night_pax_eur":340,"daily_spend_per_pax_eur":420,"occasion":"birthday","interests":["michelin_dining","food_wine","art_museums","shopping"]}'::jsonb),
('a0000001-0000-4000-8000-000600020000','Wei Ling Tan','+65-9123-4567','Lyon','solo','2026-07-04',NULL,'2D1N',1,'Pampering myself after a brutal year. Michelin + spa.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"06","unit_order":2,"unit_total":4,"trip_start_date":"2026-07-02","trip_end_date":"2026-07-09","budget_tier":"luxury","interests":["michelin_dining","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-000600030000','Wei Ling Tan','+65-9123-4567','Avignon','solo','2026-07-05',NULL,'3D2N',1,'Pampering myself after a brutal year. Michelin + spa.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"06","unit_order":3,"unit_total":4,"trip_start_date":"2026-07-02","trip_end_date":"2026-07-09","budget_tier":"luxury","interests":["food_wine","villages","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-000600040000','Wei Ling Tan','+65-9123-4567','Nice','solo','2026-07-07',NULL,'3D2N',1,'Pampering myself after a brutal year. Michelin + spa.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"06","unit_order":4,"unit_total":4,"trip_start_date":"2026-07-02","trip_end_date":"2026-07-09","budget_tier":"luxury","interests":["beach","michelin_dining","spa"]}'::jsonb),

-- ── Person 07 · Min-jun Kim & Soo-jin Choi · Couple · Budget · South Korea (2 units) ──
('a0000001-0000-4000-8000-000700010000','Min-jun Kim & Soo-jin Choi','+82-10-3847-2910','Paris','couple','2026-07-07','13:00','3D2N',2,'Dating two years, first overseas trip together. Saving for a flat — want it special but careful.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"07","unit_order":1,"unit_total":2,"trip_start_date":"2026-07-07","trip_end_date":"2026-07-11","origin_country":"South Korea","origin_city":"Seoul","ages":[29,30],"budget_tier":"budget","hotel_budget_per_night_pax_eur":62,"daily_spend_per_pax_eur":85,"interests":["photography","art_museums","food_wine","shopping"]}'::jsonb),
('a0000001-0000-4000-8000-000700020000','Min-jun Kim & Soo-jin Choi','+82-10-3847-2910','Nice','couple','2026-07-09',NULL,'3D2N',2,'Dating two years, first overseas trip together. Saving for a flat.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"07","unit_order":2,"unit_total":2,"trip_start_date":"2026-07-07","trip_end_date":"2026-07-11","budget_tier":"budget","interests":["beach","photography","food_wine"]}'::jsonb),

-- ── Person 08 · Liam Tremblay & Chloé Bélanger · Couple · Budget · Canada (4 units) ──
('a0000001-0000-4000-8000-000800010000','Liam Tremblay & Chloé Bélanger','+1-514-555-7392','Nice','couple','2026-07-12','22:15','3D2N',2,'Quebec nurses, saved two years. Want beach + good food without burning the budget on five-star.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"08","unit_order":1,"unit_total":4,"trip_start_date":"2026-07-12","trip_end_date":"2026-07-19","origin_country":"Canada","origin_city":"Montreal","ages":[32,30],"budget_tier":"budget","languages":["French","English"],"interests":["beach","food_wine","villages"]}'::jsonb),
('a0000001-0000-4000-8000-000800020000','Liam Tremblay & Chloé Bélanger','+1-514-555-7392','Cannes','couple','2026-07-14',NULL,'3D2N',2,'Quebec nurses. Beach + good food on a budget.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"08","unit_order":2,"unit_total":4,"trip_start_date":"2026-07-12","trip_end_date":"2026-07-19","budget_tier":"budget","interests":["beach","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-000800030000','Liam Tremblay & Chloé Bélanger','+1-514-555-7392','Monaco','couple','2026-07-16',NULL,'2D1N',2,'Quebec nurses. Beach + good food on a budget.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"08","unit_order":3,"unit_total":4,"trip_start_date":"2026-07-12","trip_end_date":"2026-07-19","budget_tier":"budget","interests":["architecture","photography"]}'::jsonb),
('a0000001-0000-4000-8000-000800040000','Liam Tremblay & Chloé Bélanger','+1-514-555-7392','Saint-Tropez','couple','2026-07-17',NULL,'3D2N',2,'Quebec nurses. Beach + good food on a budget.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"08","unit_order":4,"unit_total":4,"trip_start_date":"2026-07-12","trip_end_date":"2026-07-19","budget_tier":"budget","interests":["beach","villages"]}'::jsonb),

-- ── Person 09 · Ethan Walker & Mia Robinson · Couple · Budget · Australia (2 units) ──
('a0000001-0000-4000-8000-000900010000','Ethan Walker & Mia Robinson','+61-2-9876-5432','Corsica (Ajaccio)','couple','2026-07-17','10:30','3D2N',2,'Late 20s, sick of Eurail crowds. Corsica because nobody we know has been. Camping or simple guesthouses fine.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"09","unit_order":1,"unit_total":2,"trip_start_date":"2026-07-17","trip_end_date":"2026-07-21","origin_country":"Australia","origin_city":"Sydney","ages":[27,28],"budget_tier":"budget","interests":["beach","hiking","villages","photography"]}'::jsonb),
('a0000001-0000-4000-8000-000900020000','Ethan Walker & Mia Robinson','+61-2-9876-5432','Corsica (Bonifacio)','couple','2026-07-19',NULL,'3D2N',2,'Late 20s. Corsica off-the-beaten-path.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"09","unit_order":2,"unit_total":2,"trip_start_date":"2026-07-17","trip_end_date":"2026-07-21","budget_tier":"budget","interests":["beach","hiking","villages"]}'::jsonb),

-- ── Person 10 · Arjun Patel & Priya Sharma · Couple · Mid · India (3 units) ──
('a0000001-0000-4000-8000-001000010000','Arjun Patel & Priya Sharma','+91-98-7654-3210','Paris','couple','2026-07-22','07:45','3D2N',2,'Both vegetarian (Priya strict, Arjun OK with eggs). Need restaurants beyond "we''ll do a salad". 8th anniversary.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"10","unit_order":1,"unit_total":3,"trip_start_date":"2026-07-22","trip_end_date":"2026-07-27","origin_country":"India","origin_city":"Mumbai","ages":[35,33],"budget_tier":"mid_range","hotel_budget_per_night_pax_eur":115,"daily_spend_per_pax_eur":140,"occasion":"anniversary","dietary_restrictions":"vegetarian","interests":["food_wine","architecture","art_museums"]}'::jsonb),
('a0000001-0000-4000-8000-001000020000','Arjun Patel & Priya Sharma','+91-98-7654-3210','Strasbourg','couple','2026-07-24',NULL,'2D1N',2,'Both vegetarian — need real options, not afterthoughts. 8th anniversary.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"10","unit_order":2,"unit_total":3,"trip_start_date":"2026-07-22","trip_end_date":"2026-07-27","budget_tier":"mid_range","dietary_restrictions":"vegetarian","interests":["architecture","villages","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001000030000','Arjun Patel & Priya Sharma','+91-98-7654-3210','Colmar','couple','2026-07-25',NULL,'3D2N',2,'Both vegetarian. 8th anniversary.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"10","unit_order":3,"unit_total":3,"trip_start_date":"2026-07-22","trip_end_date":"2026-07-27","budget_tier":"mid_range","dietary_restrictions":"vegetarian","interests":["villages","photography","food_wine"]}'::jsonb),

-- ── Person 11 · Lars Bakker & Emma Visser · Couple · Mid · Netherlands (3 units) ──
('a0000001-0000-4000-8000-001100010000','Lars Bakker & Emma Visser','+31-20-555-1234','Reims (Champagne)','couple','2026-07-26','14:10','3D2N',2,'Both love wine but don''t know champagne well. Want actual maisons, not the Moët bus tour.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"11","unit_order":1,"unit_total":3,"trip_start_date":"2026-07-26","trip_end_date":"2026-07-31","origin_country":"Netherlands","origin_city":"Amsterdam","ages":[38,36],"budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","architecture","cellar_tours"]}'::jsonb),
('a0000001-0000-4000-8000-001100020000','Lars Bakker & Emma Visser','+31-20-555-1234','Épernay','couple','2026-07-28',NULL,'2D1N',2,'Champagne deep-dive — real maisons not chains.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"11","unit_order":2,"unit_total":3,"trip_start_date":"2026-07-26","trip_end_date":"2026-07-31","budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","cellar_tours"]}'::jsonb),
('a0000001-0000-4000-8000-001100030000','Lars Bakker & Emma Visser','+31-20-555-1234','Paris','couple','2026-07-29',NULL,'3D2N',2,'Unwinding in Paris after the champagne route.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"11","unit_order":3,"unit_total":3,"trip_start_date":"2026-07-26","trip_end_date":"2026-07-31","budget_tier":"mid_range","interests":["food_wine","art_museums","architecture"]}'::jsonb),

-- ── Person 12 · Sarah Johnson & David Anderson · Couple · Mid · USA (4 units) ──
('a0000001-0000-4000-8000-001200010000','Sarah Johnson & David Anderson','+1-415-555-9182','Marseille','couple','2026-07-30','11:20','3D2N',2,'SF couple, married 12 years. Provence-focused. Sarah is celiac — please verify every kitchen.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"12","unit_order":1,"unit_total":4,"trip_start_date":"2026-07-30","trip_end_date":"2026-08-06","origin_country":"USA","origin_city":"San Francisco","ages":[34,36],"budget_tier":"mid_range","occasion":"anniversary","dietary_restrictions":"gluten_free","interests":["food_wine","lavender_fields","villages"]}'::jsonb),
('a0000001-0000-4000-8000-001200020000','Sarah Johnson & David Anderson','+1-415-555-9182','Aix-en-Provence','couple','2026-08-01',NULL,'2D1N',2,'SF couple. Sarah celiac — verify kitchens. Provence focus.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"12","unit_order":2,"unit_total":4,"trip_start_date":"2026-07-30","trip_end_date":"2026-08-06","budget_tier":"mid_range","dietary_restrictions":"gluten_free","interests":["villages","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001200030000','Sarah Johnson & David Anderson','+1-415-555-9182','Avignon','couple','2026-08-02',NULL,'3D2N',2,'SF couple. Sarah celiac. Provence focus.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"12","unit_order":3,"unit_total":4,"trip_start_date":"2026-07-30","trip_end_date":"2026-08-06","budget_tier":"mid_range","dietary_restrictions":"gluten_free","interests":["villages","lavender_fields","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-001200040000','Sarah Johnson & David Anderson','+1-415-555-9182','Nice','couple','2026-08-04',NULL,'3D2N',2,'SF couple. Sarah celiac. Wrap-up on the Riviera.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"12","unit_order":4,"unit_total":4,"trip_start_date":"2026-07-30","trip_end_date":"2026-08-06","budget_tier":"mid_range","dietary_restrictions":"gluten_free","interests":["beach","food_wine"]}'::jsonb),

-- ── Person 13 · James Foster & Olivia Hughes · Couple · Mid · UK (3 units) ──
('a0000001-0000-4000-8000-001300010000','James Foster & Olivia Hughes','+44-20-7946-0321','Chamonix','couple','2026-08-04','16:45','3D2N',2,'Peak District hikers. James proposed last winter — not a honeymoon but the trip we''ve dreamed about for 10 years. Want serious mountain time.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"13","unit_order":1,"unit_total":3,"trip_start_date":"2026-08-04","trip_end_date":"2026-08-09","origin_country":"United Kingdom","origin_city":"Manchester","ages":[40,38],"budget_tier":"mid_range","interests":["hiking","adventure_sports","villages","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001300020000','James Foster & Olivia Hughes','+44-20-7946-0321','Annecy','couple','2026-08-06',NULL,'2D1N',2,'Hikers from the Peak District. Mountain trip of a lifetime.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"13","unit_order":2,"unit_total":3,"trip_start_date":"2026-08-04","trip_end_date":"2026-08-09","budget_tier":"mid_range","interests":["nature","photography","villages"]}'::jsonb),
('a0000001-0000-4000-8000-001300030000','James Foster & Olivia Hughes','+44-20-7946-0321','Lyon','couple','2026-08-07',NULL,'3D2N',2,'Hikers from the Peak District. Wind down in Lyon.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"13","unit_order":3,"unit_total":3,"trip_start_date":"2026-08-04","trip_end_date":"2026-08-09","budget_tier":"mid_range","interests":["food_wine","architecture"]}'::jsonb),

-- ── Person 14 · Wei Zhang & Mei Liu · Couple · Luxury · China (5 units) ──
('a0000001-0000-4000-8000-001400010000','Wei Zhang & Mei Liu','+86-138-2847-1928','Paris','couple','2026-08-09','08:20','3D2N',2,'20th wedding anniversary. We''ve been before but always with group tours — this time we want it slow, private, intimate.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"14","unit_order":1,"unit_total":5,"trip_start_date":"2026-08-09","trip_end_date":"2026-08-17","origin_country":"China","origin_city":"Shanghai","ages":[45,42],"budget_tier":"luxury","hotel_budget_per_night_pax_eur":380,"daily_spend_per_pax_eur":500,"occasion":"anniversary","interests":["food_wine","michelin_dining","shopping","luxury_brands"]}'::jsonb),
('a0000001-0000-4000-8000-001400020000','Wei Zhang & Mei Liu','+86-138-2847-1928','Loire Valley','couple','2026-08-11',NULL,'3D2N',2,'20th anniversary. Slow, private, intimate.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"14","unit_order":2,"unit_total":5,"trip_start_date":"2026-08-09","trip_end_date":"2026-08-17","budget_tier":"luxury","interests":["châteaux","food_wine","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-001400030000','Wei Zhang & Mei Liu','+86-138-2847-1928','Lyon','couple','2026-08-13',NULL,'2D1N',2,'20th anniversary. Slow, private.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"14","unit_order":3,"unit_total":5,"trip_start_date":"2026-08-09","trip_end_date":"2026-08-17","budget_tier":"luxury","interests":["food_wine","michelin_dining"]}'::jsonb),
('a0000001-0000-4000-8000-001400040000','Wei Zhang & Mei Liu','+86-138-2847-1928','Avignon','couple','2026-08-14',NULL,'2D1N',2,'20th anniversary. Slow, private.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"14","unit_order":4,"unit_total":5,"trip_start_date":"2026-08-09","trip_end_date":"2026-08-17","budget_tier":"luxury","interests":["villages","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001400050000','Wei Zhang & Mei Liu','+86-138-2847-1928','Nice','couple','2026-08-15',NULL,'3D2N',2,'20th anniversary. Wrap up on the Riviera.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"14","unit_order":5,"unit_total":5,"trip_start_date":"2026-08-09","trip_end_date":"2026-08-17","budget_tier":"luxury","interests":["beach","luxury_brands","michelin_dining"]}'::jsonb),

-- ── Person 15 · Lucas Silva & Mariana Oliveira · Honeymoon · Budget · Brazil (3 units) ──
('a0000001-0000-4000-8000-001500010000','Lucas Silva & Mariana Oliveira','+55-11-9876-5432','Paris','honeymoon','2026-08-13','19:30','3D2N',2,'Just got married in São Paulo. Tight honeymoon budget after the wedding bill but want it to FEEL romantic.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"15","unit_order":1,"unit_total":3,"trip_start_date":"2026-08-13","trip_end_date":"2026-08-18","origin_country":"Brazil","origin_city":"São Paulo","ages":[29,27],"budget_tier":"budget","occasion":"honeymoon","interests":["villages","architecture","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001500020000','Lucas Silva & Mariana Oliveira','+55-11-9876-5432','Colmar','honeymoon','2026-08-15',NULL,'2D1N',2,'Honeymoon. Romantic, budget-conscious.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"15","unit_order":2,"unit_total":3,"trip_start_date":"2026-08-13","trip_end_date":"2026-08-18","budget_tier":"budget","occasion":"honeymoon","interests":["villages","photography","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-001500030000','Lucas Silva & Mariana Oliveira','+55-11-9876-5432','Strasbourg','honeymoon','2026-08-16',NULL,'3D2N',2,'Honeymoon. Romantic, budget-conscious.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"15","unit_order":3,"unit_total":3,"trip_start_date":"2026-08-13","trip_end_date":"2026-08-18","budget_tier":"budget","occasion":"honeymoon","interests":["architecture","food_wine","local_culture"]}'::jsonb),

-- ── Person 16 · Joshua Cruz & Bea Reyes · Honeymoon · Budget · Philippines (4 units) ──
('a0000001-0000-4000-8000-001600010000','Joshua Cruz & Bea Reyes','+63-917-555-2839','Saint-Tropez','honeymoon','2026-08-18','12:50','3D2N',2,'Honeymoon. Bea has a halal diet — please verify every restaurant. Both excited about the beach.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"16","unit_order":1,"unit_total":4,"trip_start_date":"2026-08-18","trip_end_date":"2026-08-24","origin_country":"Philippines","origin_city":"Manila","ages":[30,28],"budget_tier":"budget","occasion":"honeymoon","dietary_restrictions":"halal","interests":["beach","food_wine","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001600020000','Joshua Cruz & Bea Reyes','+63-917-555-2839','Cannes','honeymoon','2026-08-20',NULL,'2D1N',2,'Honeymoon. Bea halal — verify restaurants.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"16","unit_order":2,"unit_total":4,"trip_start_date":"2026-08-18","trip_end_date":"2026-08-24","budget_tier":"budget","occasion":"honeymoon","dietary_restrictions":"halal","interests":["beach","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001600030000','Joshua Cruz & Bea Reyes','+63-917-555-2839','Monaco','honeymoon','2026-08-21',NULL,'2D1N',2,'Honeymoon. Bea halal.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"16","unit_order":3,"unit_total":4,"trip_start_date":"2026-08-18","trip_end_date":"2026-08-24","budget_tier":"budget","occasion":"honeymoon","dietary_restrictions":"halal","interests":["architecture","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001600040000','Joshua Cruz & Bea Reyes','+63-917-555-2839','Nice','honeymoon','2026-08-22',NULL,'3D2N',2,'Honeymoon. Bea halal.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"16","unit_order":4,"unit_total":4,"trip_start_date":"2026-08-18","trip_end_date":"2026-08-24","budget_tier":"budget","occasion":"honeymoon","dietary_restrictions":"halal","interests":["beach","food_wine"]}'::jsonb),

-- ── Person 17 · Ryan Martinez & Ashley Brooks · Honeymoon · Mid · USA (4 units) ──
('a0000001-0000-4000-8000-001700010000','Ryan Martinez & Ashley Brooks','+1-303-555-7849','Paris','honeymoon','2026-08-23','09:10','3D2N',2,'Honeymoon — please prioritize romance over efficiency. Slow mornings, sunset dinners, no 8 AM start.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"17","unit_order":1,"unit_total":4,"trip_start_date":"2026-08-23","trip_end_date":"2026-08-30","origin_country":"USA","origin_city":"Denver","ages":[31,29],"budget_tier":"mid_range","hotel_budget_per_night_pax_eur":190,"daily_spend_per_pax_eur":220,"occasion":"honeymoon","interests":["food_wine","michelin_dining","villages","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001700020000','Ryan Martinez & Ashley Brooks','+1-303-555-7849','Loire Valley','honeymoon','2026-08-25',NULL,'2D1N',2,'Honeymoon — romance over efficiency. Slow mornings.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"17","unit_order":2,"unit_total":4,"trip_start_date":"2026-08-23","trip_end_date":"2026-08-30","budget_tier":"mid_range","occasion":"honeymoon","interests":["châteaux","villages","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001700030000','Ryan Martinez & Ashley Brooks','+1-303-555-7849','Luberon (Provence)','honeymoon','2026-08-26',NULL,'3D2N',2,'Honeymoon. Ashley wants Provence lavender (even late season).','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"17","unit_order":3,"unit_total":4,"trip_start_date":"2026-08-23","trip_end_date":"2026-08-30","budget_tier":"mid_range","occasion":"honeymoon","interests":["lavender_fields","villages","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-001700040000','Ryan Martinez & Ashley Brooks','+1-303-555-7849','Nice','honeymoon','2026-08-28',NULL,'3D2N',2,'Honeymoon. Ryan wants Michelin. Sunset dinners.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"17","unit_order":4,"unit_total":4,"trip_start_date":"2026-08-23","trip_end_date":"2026-08-30","budget_tier":"mid_range","occasion":"honeymoon","interests":["beach","michelin_dining","photography"]}'::jsonb),

-- ── Person 18 · Marco Rossi & Sofia Esposito · Honeymoon · Mid · Italy (3 units) ──
('a0000001-0000-4000-8000-001800010000','Marco Rossi & Sofia Esposito','+39-02-555-8472','Paris','honeymoon','2026-08-28','18:00','3D2N',2,'Italian honeymoon. We love food but please NOT Italian restaurants in France. Sofia is pescatarian.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"18","unit_order":1,"unit_total":3,"trip_start_date":"2026-08-28","trip_end_date":"2026-09-02","origin_country":"Italy","origin_city":"Milan","ages":[33,31],"budget_tier":"mid_range","occasion":"honeymoon","dietary_restrictions":"other: pescatarian (Sofia)","interests":["food_wine","architecture","art_museums"]}'::jsonb),
('a0000001-0000-4000-8000-001800020000','Marco Rossi & Sofia Esposito','+39-02-555-8472','Colmar','honeymoon','2026-08-30',NULL,'2D1N',2,'Italian honeymoon. No Italian restaurants. Sofia pescatarian.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"18","unit_order":2,"unit_total":3,"trip_start_date":"2026-08-28","trip_end_date":"2026-09-02","budget_tier":"mid_range","occasion":"honeymoon","dietary_restrictions":"other: pescatarian (Sofia)","interests":["villages","photography"]}'::jsonb),
('a0000001-0000-4000-8000-001800030000','Marco Rossi & Sofia Esposito','+39-02-555-8472','Strasbourg','honeymoon','2026-08-31',NULL,'3D2N',2,'Italian honeymoon. Sofia pescatarian.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"18","unit_order":3,"unit_total":3,"trip_start_date":"2026-08-28","trip_end_date":"2026-09-02","budget_tier":"mid_range","occasion":"honeymoon","dietary_restrictions":"other: pescatarian (Sofia)","interests":["architecture","food_wine"]}'::jsonb),

-- ── Person 19 · Sophie Edwards & Tom Bennett · Honeymoon · Luxury · UK (4 units) ──
('a0000001-0000-4000-8000-001900010000','Sophie Edwards & Tom Bennett','+44-7700-902341','Paris','honeymoon','2026-09-03','14:20','3D2N',2,'Honeymoon. Saving 5 years for this. Sophie wants château stay in Loire. Tom is a sommelier — real cellars, not touristy.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"19","unit_order":1,"unit_total":4,"trip_start_date":"2026-09-03","trip_end_date":"2026-09-10","origin_country":"United Kingdom","origin_city":"London","ages":[34,36],"budget_tier":"luxury","hotel_budget_per_night_pax_eur":480,"daily_spend_per_pax_eur":620,"occasion":"honeymoon","interests":["food_wine","michelin_dining","cellar_tours"]}'::jsonb),
('a0000001-0000-4000-8000-001900020000','Sophie Edwards & Tom Bennett','+44-7700-902341','Loire Valley','honeymoon','2026-09-05',NULL,'3D2N',2,'Honeymoon. Sophie wants actual château stay, not village hotel.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"19","unit_order":2,"unit_total":4,"trip_start_date":"2026-09-03","trip_end_date":"2026-09-10","budget_tier":"luxury","occasion":"honeymoon","accommodation_preference":"château","interests":["châteaux","food_wine","cellar_tours"]}'::jsonb),
('a0000001-0000-4000-8000-001900030000','Sophie Edwards & Tom Bennett','+44-7700-902341','Luberon (Provence)','honeymoon','2026-09-07',NULL,'3D2N',2,'Honeymoon. Tom is a sommelier — real cellars.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"19","unit_order":3,"unit_total":4,"trip_start_date":"2026-09-03","trip_end_date":"2026-09-10","budget_tier":"luxury","occasion":"honeymoon","interests":["villages","food_wine","lavender_fields"]}'::jsonb),
('a0000001-0000-4000-8000-001900040000','Sophie Edwards & Tom Bennett','+44-7700-902341','Nice','honeymoon','2026-09-09',NULL,'2D1N',2,'Honeymoon wrap-up.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"19","unit_order":4,"unit_total":4,"trip_start_date":"2026-09-03","trip_end_date":"2026-09-10","budget_tier":"luxury","occasion":"honeymoon","interests":["beach","michelin_dining"]}'::jsonb),

-- ── Person 20 · Aishah binti Rahman & Faizal Yusoff · Family · Budget · Malaysia (3 units) ──
('a0000001-0000-4000-8000-002000010000','Aishah binti Rahman & Faizal Yusoff','+60-12-345-6789','Paris','family','2026-09-07','22:30','3D2N',4,'Family of 4, kids 9 and 6. Halal-only. Younger one only cares about Disneyland — balance with culture for the older.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"20","unit_order":1,"unit_total":3,"trip_start_date":"2026-09-07","trip_end_date":"2026-09-12","origin_country":"Malaysia","origin_city":"Kuala Lumpur","ages":[33,35,9,6],"budget_tier":"budget","dietary_restrictions":"halal","mobility":"stroller","interests":["family_activities","architecture","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002000020000','Aishah binti Rahman & Faizal Yusoff','+60-12-345-6789','Disneyland Paris','family','2026-09-09',NULL,'2D1N',4,'Family of 4, kids 9 and 6. Halal-only. Disneyland for the younger one.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"20","unit_order":2,"unit_total":3,"trip_start_date":"2026-09-07","trip_end_date":"2026-09-12","budget_tier":"budget","dietary_restrictions":"halal","mobility":"stroller","interests":["family_activities","theme_parks"]}'::jsonb),
('a0000001-0000-4000-8000-002000030000','Aishah binti Rahman & Faizal Yusoff','+60-12-345-6789','Loire Valley','family','2026-09-10',NULL,'3D2N',4,'Family of 4, kids 9 and 6. Halal-only. Castles for the older.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"20","unit_order":3,"unit_total":3,"trip_start_date":"2026-09-07","trip_end_date":"2026-09-12","budget_tier":"budget","dietary_restrictions":"halal","mobility":"stroller","interests":["châteaux","family_activities","villages"]}'::jsonb),

-- ── Person 21 · Hannah Cooper & Daniel Wright · Family · Budget · New Zealand (2 units) ──
('a0000001-0000-4000-8000-002100010000','Hannah Cooper & Daniel Wright','+64-9-555-2847','Saint-Malo','family','2026-09-12','11:15','3D2N',5,'Family of 5 — kids 13, 10, 7. First time out of NZ. Want castles + the MSM tides. Skip Paris this trip.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"21","unit_order":1,"unit_total":2,"trip_start_date":"2026-09-12","trip_end_date":"2026-09-16","origin_country":"New Zealand","origin_city":"Auckland","ages":[38,40,13,10,7],"budget_tier":"budget","interests":["châteaux","family_activities","nature","beach"]}'::jsonb),
('a0000001-0000-4000-8000-002100020000','Hannah Cooper & Daniel Wright','+64-9-555-2847','Mont-Saint-Michel','family','2026-09-14',NULL,'3D2N',5,'Family of 5 — kids 13, 10, 7. The MSM tides experience.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"21","unit_order":2,"unit_total":2,"trip_start_date":"2026-09-12","trip_end_date":"2026-09-16","budget_tier":"budget","interests":["nature","family_activities","photography"]}'::jsonb),

-- ── Person 22 · Carmen García & Pablo Ruiz · Family · Budget · Spain (3 units) ──
('a0000001-0000-4000-8000-002200010000','Carmen García & Pablo Ruiz','+34-91-555-3729','Nice','family','2026-09-16','09:40','3D2N',4,'Driving up from Barcelona with kids (11 and 8). Pure beach family vacation — no museums please.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"22","unit_order":1,"unit_total":3,"trip_start_date":"2026-09-16","trip_end_date":"2026-09-21","origin_country":"Spain","origin_city":"Barcelona","ages":[36,38,11,8],"budget_tier":"budget","interests":["beach","family_activities","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-002200020000','Carmen García & Pablo Ruiz','+34-91-555-3729','Antibes','family','2026-09-18',NULL,'2D1N',4,'Beach family vacation. Kids 11 and 8.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"22","unit_order":2,"unit_total":3,"trip_start_date":"2026-09-16","trip_end_date":"2026-09-21","budget_tier":"budget","interests":["beach","family_activities"]}'::jsonb),
('a0000001-0000-4000-8000-002200030000','Carmen García & Pablo Ruiz','+34-91-555-3729','Cannes','family','2026-09-19',NULL,'3D2N',4,'Beach family vacation. Kids 11 and 8.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"22","unit_order":3,"unit_total":3,"trip_start_date":"2026-09-16","trip_end_date":"2026-09-21","budget_tier":"budget","interests":["beach","family_activities","photography"]}'::jsonb),

-- ── Person 23 · Jessica Williams & Brian Williams · Family · Mid · USA (5 units) ──
('a0000001-0000-4000-8000-002300010000','Jessica Williams & Brian Williams','+1-415-555-2847','Paris','family','2026-09-21','11:45','3D2N',5,'Family of 5, kids 7, 4, 2. Brian has severe nut allergy — flag every menu. Oldest obsessed with knights/castles.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"23","unit_order":1,"unit_total":5,"trip_start_date":"2026-09-21","trip_end_date":"2026-09-28","origin_country":"USA","origin_city":"San Francisco","ages":[38,36,7,4,2],"budget_tier":"mid_range","dietary_restrictions":"allergy: nuts (severe, Brian)","mobility":"stroller","interests":["family_activities","architecture","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002300020000','Jessica Williams & Brian Williams','+1-415-555-2847','Disneyland Paris','family','2026-09-23',NULL,'2D1N',5,'Family of 5. Severe nut allergy. Kids 7, 4, 2.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"23","unit_order":2,"unit_total":5,"trip_start_date":"2026-09-21","trip_end_date":"2026-09-28","budget_tier":"mid_range","dietary_restrictions":"allergy: nuts (severe, Brian)","mobility":"stroller","interests":["family_activities","theme_parks"]}'::jsonb),
('a0000001-0000-4000-8000-002300030000','Jessica Williams & Brian Williams','+1-415-555-2847','Loire Valley','family','2026-09-24',NULL,'3D2N',5,'Family of 5. Severe nut allergy. Oldest loves castles.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"23","unit_order":3,"unit_total":5,"trip_start_date":"2026-09-21","trip_end_date":"2026-09-28","budget_tier":"mid_range","dietary_restrictions":"allergy: nuts (severe, Brian)","mobility":"stroller","interests":["châteaux","family_activities"]}'::jsonb),
('a0000001-0000-4000-8000-002300040000','Jessica Williams & Brian Williams','+1-415-555-2847','Normandy','family','2026-09-26',NULL,'2D1N',5,'Family of 5. Severe nut allergy.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"23","unit_order":4,"unit_total":5,"trip_start_date":"2026-09-21","trip_end_date":"2026-09-28","budget_tier":"mid_range","dietary_restrictions":"allergy: nuts (severe, Brian)","mobility":"stroller","interests":["history","beach","family_activities"]}'::jsonb),
('a0000001-0000-4000-8000-002300050000','Jessica Williams & Brian Williams','+1-415-555-2847','Mont-Saint-Michel','family','2026-09-27',NULL,'2D1N',5,'Family of 5. Severe nut allergy. Wrap with the abbey.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"23","unit_order":5,"unit_total":5,"trip_start_date":"2026-09-21","trip_end_date":"2026-09-28","budget_tier":"mid_range","dietary_restrictions":"allergy: nuts (severe, Brian)","mobility":"stroller","interests":["architecture","family_activities","photography"]}'::jsonb),

-- ── Person 24 · Diego Hernández & Laura Morales · Family · Mid · Mexico (3 units) ──
('a0000001-0000-4000-8000-002400010000','Diego Hernández & Laura Morales','+52-55-1234-5678','Paris','family','2026-09-26','06:30','3D2N',4,'Family of 4 — teens 14 and 11. Want shopping (older) and food (younger). Budget-conscious mid-range, not luxury.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"24","unit_order":1,"unit_total":3,"trip_start_date":"2026-09-26","trip_end_date":"2026-10-02","origin_country":"Mexico","origin_city":"Mexico City","ages":[42,40,14,11],"budget_tier":"mid_range","interests":["shopping","food_wine","architecture","family_activities"]}'::jsonb),
('a0000001-0000-4000-8000-002400020000','Diego Hernández & Laura Morales','+52-55-1234-5678','Loire Valley','family','2026-09-28',NULL,'3D2N',4,'Family of 4, teens. Castles for the kids.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"24","unit_order":2,"unit_total":3,"trip_start_date":"2026-09-26","trip_end_date":"2026-10-02","budget_tier":"mid_range","interests":["châteaux","family_activities","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-002400030000','Diego Hernández & Laura Morales','+52-55-1234-5678','Nice','family','2026-09-30',NULL,'3D2N',4,'Family of 4, teens. Riviera wrap-up.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"24","unit_order":3,"unit_total":3,"trip_start_date":"2026-09-26","trip_end_date":"2026-10-02","budget_tier":"mid_range","interests":["beach","food_wine","shopping"]}'::jsonb),

-- ── Person 25 · Hiroshi Sato & Akiko Sato · Family · Mid · Japan (3 units) ──
('a0000001-0000-4000-8000-002500010000','Hiroshi Sato & Akiko Sato','+81-3-5555-2849','Paris','family','2026-09-30','13:20','3D2N',3,'Couple + 8-yr-old daughter. First Europe trip. Please English-speaking guides. Daughter loves Disney, we want castles instead.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"25","unit_order":1,"unit_total":3,"trip_start_date":"2026-09-30","trip_end_date":"2026-10-05","origin_country":"Japan","origin_city":"Tokyo","ages":[37,35,8],"budget_tier":"mid_range","interests":["châteaux","architecture","family_activities","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002500020000','Hiroshi Sato & Akiko Sato','+81-3-5555-2849','Loire Valley','family','2026-10-02',NULL,'2D1N',3,'Family with 8-yr-old daughter. English-speaking guides preferred.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"25","unit_order":2,"unit_total":3,"trip_start_date":"2026-09-30","trip_end_date":"2026-10-05","budget_tier":"mid_range","interests":["châteaux","family_activities"]}'::jsonb),
('a0000001-0000-4000-8000-002500030000','Hiroshi Sato & Akiko Sato','+81-3-5555-2849','Mont-Saint-Michel','family','2026-10-03',NULL,'3D2N',3,'Family with 8-yr-old. English-speaking guides preferred.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"25","unit_order":3,"unit_total":3,"trip_start_date":"2026-09-30","trip_end_date":"2026-10-05","budget_tier":"mid_range","interests":["architecture","family_activities","photography"]}'::jsonb),

-- ── Person 26 · Khalid Al-Mansoori & Fatima Al-Hashimi · Family · Luxury · UAE (5 units) ──
('a0000001-0000-4000-8000-002600010000','Khalid Al-Mansoori & Fatima Al-Hashimi','+971-50-555-2847','Paris','family','2026-10-05','23:10','3D2N',4,'Family of 4, teens 15 and 12. Halal-only, no compromises — had bad experiences. Luxury but kid-appropriate.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"26","unit_order":1,"unit_total":5,"trip_start_date":"2026-10-05","trip_end_date":"2026-10-14","origin_country":"United Arab Emirates","origin_city":"Dubai","ages":[44,40,15,12],"budget_tier":"luxury","hotel_budget_per_night_pax_eur":280,"daily_spend_per_pax_eur":350,"dietary_restrictions":"halal","interests":["shopping","food_wine","architecture","luxury_brands"]}'::jsonb),
('a0000001-0000-4000-8000-002600020000','Khalid Al-Mansoori & Fatima Al-Hashimi','+971-50-555-2847','Reims (Champagne)','family','2026-10-07',NULL,'3D2N',4,'Family of 4, teens. Halal-only. Note: champagne tasting NOT for travelers — they prefer the architecture and dining (no alcohol).','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"26","unit_order":2,"unit_total":5,"trip_start_date":"2026-10-05","trip_end_date":"2026-10-14","budget_tier":"luxury","dietary_restrictions":"halal","interests":["architecture","food_wine_non_alcoholic"]}'::jsonb),
('a0000001-0000-4000-8000-002600030000','Khalid Al-Mansoori & Fatima Al-Hashimi','+971-50-555-2847','Loire Valley','family','2026-10-09',NULL,'3D2N',4,'Family of 4, teens. Halal-only. Castles for the kids.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"26","unit_order":3,"unit_total":5,"trip_start_date":"2026-10-05","trip_end_date":"2026-10-14","budget_tier":"luxury","dietary_restrictions":"halal","interests":["châteaux","family_activities","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002600040000','Khalid Al-Mansoori & Fatima Al-Hashimi','+971-50-555-2847','Nice','family','2026-10-11',NULL,'3D2N',4,'Family of 4, teens. Halal-only. Riviera time.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"26","unit_order":4,"unit_total":5,"trip_start_date":"2026-10-05","trip_end_date":"2026-10-14","budget_tier":"luxury","dietary_restrictions":"halal","interests":["beach","luxury_brands","shopping"]}'::jsonb),
('a0000001-0000-4000-8000-002600050000','Khalid Al-Mansoori & Fatima Al-Hashimi','+971-50-555-2847','Cannes','family','2026-10-13',NULL,'2D1N',4,'Family of 4, teens. Halal-only. Final stop.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"26","unit_order":5,"unit_total":5,"trip_start_date":"2026-10-05","trip_end_date":"2026-10-14","budget_tier":"luxury","dietary_restrictions":"halal","interests":["beach","shopping","luxury_brands"]}'::jsonb),

-- ── Person 27 · Camila Vargas & friends · Group · Budget · Chile (3 units) ──
('a0000001-0000-4000-8000-002700010000','Camila Vargas & friends','+56-2-2555-3847','Pyrenees (Lourdes)','group','2026-10-10','17:30','3D2N',4,'Four uni friends from Santiago. Hiking-focused. Tight budget — refuges over fancy hotels.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"27","unit_order":1,"unit_total":3,"trip_start_date":"2026-10-10","trip_end_date":"2026-10-15","origin_country":"Chile","origin_city":"Santiago","ages":[26,27,25,28],"budget_tier":"budget","interests":["hiking","adventure_sports","nature","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002700020000','Camila Vargas & friends','+56-2-2555-3847','Carcassonne','group','2026-10-12',NULL,'2D1N',4,'Four uni friends, hiking-focused. Carcassonne for the medieval pause.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"27","unit_order":2,"unit_total":3,"trip_start_date":"2026-10-10","trip_end_date":"2026-10-15","budget_tier":"budget","interests":["architecture","villages","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002700030000','Camila Vargas & friends','+56-2-2555-3847','Toulouse','group','2026-10-13',NULL,'3D2N',4,'Four uni friends. Toulouse wrap-up — food + city.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"27","unit_order":3,"unit_total":3,"trip_start_date":"2026-10-10","trip_end_date":"2026-10-15","budget_tier":"budget","interests":["food_wine","architecture","local_culture"]}'::jsonb),

-- ── Person 28 · Youssef El Amrani & friends · Group · Budget · Morocco (4 units) ──
('a0000001-0000-4000-8000-002800010000','Youssef El Amrani & friends','+212-661-234567','Marseille','group','2026-10-14','12:00','3D2N',5,'Five guys, childhood friends from Casablanca. Halal-only. Want Provence — markets, food, beaches. One big group dinner splurge OK.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"28","unit_order":1,"unit_total":4,"trip_start_date":"2026-10-14","trip_end_date":"2026-10-21","origin_country":"Morocco","origin_city":"Casablanca","ages":[28,29,27,30,28],"budget_tier":"budget","dietary_restrictions":"halal","interests":["food_wine","local_culture","markets"]}'::jsonb),
('a0000001-0000-4000-8000-002800020000','Youssef El Amrani & friends','+212-661-234567','Aix-en-Provence','group','2026-10-16',NULL,'2D1N',5,'Five friends from Casablanca. Halal-only. Markets + villages.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"28","unit_order":2,"unit_total":4,"trip_start_date":"2026-10-14","trip_end_date":"2026-10-21","budget_tier":"budget","dietary_restrictions":"halal","interests":["villages","markets","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-002800030000','Youssef El Amrani & friends','+212-661-234567','Avignon','group','2026-10-17',NULL,'3D2N',5,'Five friends from Casablanca. Halal-only.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"28","unit_order":3,"unit_total":4,"trip_start_date":"2026-10-14","trip_end_date":"2026-10-21","budget_tier":"budget","dietary_restrictions":"halal","interests":["architecture","food_wine","photography"]}'::jsonb),
('a0000001-0000-4000-8000-002800040000','Youssef El Amrani & friends','+212-661-234567','Nice','group','2026-10-19',NULL,'3D2N',5,'Five friends from Casablanca. Halal-only. Beaches finale.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"28","unit_order":4,"unit_total":4,"trip_start_date":"2026-10-14","trip_end_date":"2026-10-21","budget_tier":"budget","dietary_restrictions":"halal","interests":["beach","food_wine"]}'::jsonb),

-- ── Person 29 · Xiao Liu & friends · Group · Mid · China (4 units) ──
('a0000001-0000-4000-8000-002900010000','Xiao Liu & friends','+86-138-9876-5432','Bordeaux','group','2026-10-19','08:45','3D2N',6,'Six colleagues from a wine-trading firm in Shenzhen. Want the trade side: cellar tours, blending sessions.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"29","unit_order":1,"unit_total":4,"trip_start_date":"2026-10-19","trip_end_date":"2026-10-25","origin_country":"China","origin_city":"Shenzhen","ages":[34,38,32,40,36,33],"budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","cellar_tours","architecture"]}'::jsonb),
('a0000001-0000-4000-8000-002900020000','Xiao Liu & friends','+86-138-9876-5432','Saint-Émilion','group','2026-10-21',NULL,'2D1N',6,'Six wine-trade colleagues. Real cellar tours, not tourist tastings.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"29","unit_order":2,"unit_total":4,"trip_start_date":"2026-10-19","trip_end_date":"2026-10-25","budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","cellar_tours","villages"]}'::jsonb),
('a0000001-0000-4000-8000-002900030000','Xiao Liu & friends','+86-138-9876-5432','Cognac','group','2026-10-22',NULL,'2D1N',6,'Six wine-trade colleagues. Cognac houses preferred.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"29","unit_order":3,"unit_total":4,"trip_start_date":"2026-10-19","trip_end_date":"2026-10-25","budget_tier":"mid_range","occasion":"wine_pilgrimage","interests":["food_wine","cellar_tours"]}'::jsonb),
('a0000001-0000-4000-8000-002900040000','Xiao Liu & friends','+86-138-9876-5432','Paris','group','2026-10-23',NULL,'3D2N',6,'Six wine-trade colleagues. Paris for the unwind.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"29","unit_order":4,"unit_total":4,"trip_start_date":"2026-10-19","trip_end_date":"2026-10-25","budget_tier":"mid_range","interests":["food_wine","shopping","luxury_brands"]}'::jsonb),

-- ── Person 30 · Ji-hoon Park & friends · Group · Mid · South Korea (4 units) ──
('a0000001-0000-4000-8000-003000010000','Ji-hoon Park & friends','+82-10-9876-5432','Chamonix','group','2026-10-25','15:00','3D2N',4,'Four friends from Seoul, late 20s. Skiing not in season but want the Alps anyway, then drive to Riviera. Nature + food + nightlife.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"30","unit_order":1,"unit_total":4,"trip_start_date":"2026-10-25","trip_end_date":"2026-11-01","origin_country":"South Korea","origin_city":"Seoul","ages":[27,28,26,29],"budget_tier":"mid_range","interests":["hiking","food_wine","nightlife","photography"]}'::jsonb),
('a0000001-0000-4000-8000-003000020000','Ji-hoon Park & friends','+82-10-9876-5432','Annecy','group','2026-10-27',NULL,'3D2N',4,'Four friends from Seoul. Annecy for the lake.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"30","unit_order":2,"unit_total":4,"trip_start_date":"2026-10-25","trip_end_date":"2026-11-01","budget_tier":"mid_range","interests":["nature","photography","food_wine"]}'::jsonb),
('a0000001-0000-4000-8000-003000030000','Ji-hoon Park & friends','+82-10-9876-5432','Lyon','group','2026-10-29',NULL,'2D1N',4,'Four friends from Seoul. Lyon food stop.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"30","unit_order":3,"unit_total":4,"trip_start_date":"2026-10-25","trip_end_date":"2026-11-01","budget_tier":"mid_range","interests":["food_wine","nightlife"]}'::jsonb),
('a0000001-0000-4000-8000-003000040000','Ji-hoon Park & friends','+82-10-9876-5432','Nice','group','2026-10-30',NULL,'3D2N',4,'Four friends from Seoul. Riviera wrap-up.','unassigned',48,false,NULL,
 '{"seed_batch":"01","person_id":"30","unit_order":4,"unit_total":4,"trip_start_date":"2026-10-25","trip_end_date":"2026-11-01","budget_tier":"mid_range","interests":["beach","nightlife","food_wine"]}'::jsonb);

-- ── STEP 3 ── verify ────────────────────────────────────────────────────
SELECT 'rows in batch 01' AS metric, count(*) AS value FROM public.travelers WHERE meta->>'seed_batch' = '01'
UNION ALL SELECT 'unique people', count(DISTINCT meta->>'person_id') FROM public.travelers WHERE meta->>'seed_batch' = '01'
UNION ALL SELECT 'unassigned', count(*) FROM public.travelers WHERE meta->>'seed_batch' = '01' AND status = 'unassigned'
UNION ALL SELECT 'units 2D1N', count(*) FROM public.travelers WHERE meta->>'seed_batch' = '01' AND duration = '2D1N'
UNION ALL SELECT 'units 3D2N', count(*) FROM public.travelers WHERE meta->>'seed_batch' = '01' AND duration = '3D2N'
UNION ALL SELECT 'invalid durations', count(*) FROM public.travelers WHERE meta->>'seed_batch' = '01' AND duration NOT IN ('2D1N','3D2N');
