-- Normalise vague arrival / departure gateways so every unit starts from a
-- real station / airport / ferry terminal (not a bare city or island name).
--
-- WHY: the dashboard resolves unit_arrival_location / unit_departure_location
-- via Google Places textSearch. A bare city ("Hiroshima") resolves to the city
-- centre, and an airport written "Kansai KIX" (no "Airport" keyword) gets a
-- city bias and can match a local bus stop — both give wrong Day-1 taxi
-- distances. Fix = replace the vague value with the specific terminal name.
--
-- Only rows that STILL hold the exact vague value are touched (keyed on the old
-- string), so anything a planner already corrected is left alone. jsonb only —
-- no other traveler fields change. Safe to run once; re-running is a no-op.
--
-- ============================================================================
-- STEP 1 — PREVIEW (read only). See exactly which rows will change.
-- ============================================================================
with fixes(oldv, newv) as (
  values
    ('Kansai KIX',      'Kansai International Airport (KIX)'),
    ('New Chitose CTS', 'New Chitose Airport (CTS)'),
    ('Hakodate HKD',    'Hakodate Airport (HKD)'),
    ('Hiroshima HIJ',   'Hiroshima Airport (HIJ)'),
    ('Fukuoka FUK',     'Fukuoka Airport (FUK)'),
    ('Nagasaki NGS',    'Nagasaki Airport (NGS)'),
    ('Himeji',          'Himeji Station'),
    ('Hiroshima',       'Hiroshima Station'),
    ('Miyajima',        'Miyajima Pier'),
    ('Hakone-Yumoto',   'Hakone-Yumoto Station'),
    ('Odawara',         'Odawara Station')
)
select t.id, t.name, t.destination,
       t.meta->>'unit_arrival_method'    as arr_method,
       t.meta->>'unit_arrival_location'  as arr_now,
       fa.newv                           as arr_new,
       t.meta->>'unit_departure_method'  as dep_method,
       t.meta->>'unit_departure_location' as dep_now,
       fd.newv                           as dep_new
from public.travelers t
left join fixes fa on fa.oldv = t.meta->>'unit_arrival_location'
left join fixes fd on fd.oldv = t.meta->>'unit_departure_location'
where fa.oldv is not null or fd.oldv is not null
order by t.name, t.meta->>'unit_order';


-- ============================================================================
-- STEP 2 — APPLY. Run this whole block after the preview looks right.
--          Wrapped in a transaction; check the row counts, then it commits.
-- ============================================================================
begin;

with fixes(oldv, newv) as (
  values
    ('Kansai KIX',      'Kansai International Airport (KIX)'),
    ('New Chitose CTS', 'New Chitose Airport (CTS)'),
    ('Hakodate HKD',    'Hakodate Airport (HKD)'),
    ('Hiroshima HIJ',   'Hiroshima Airport (HIJ)'),
    ('Fukuoka FUK',     'Fukuoka Airport (FUK)'),
    ('Nagasaki NGS',    'Nagasaki Airport (NGS)'),
    ('Himeji',          'Himeji Station'),
    ('Hiroshima',       'Hiroshima Station'),
    ('Miyajima',        'Miyajima Pier'),
    ('Hakone-Yumoto',   'Hakone-Yumoto Station'),
    ('Odawara',         'Odawara Station')
)
-- Fix the ARRIVAL side
update public.travelers t
set meta = jsonb_set(t.meta, '{unit_arrival_location}', to_jsonb(f.newv), false)
from fixes f
where t.meta->>'unit_arrival_location' = f.oldv;

with fixes(oldv, newv) as (
  values
    ('Kansai KIX',      'Kansai International Airport (KIX)'),
    ('New Chitose CTS', 'New Chitose Airport (CTS)'),
    ('Hakodate HKD',    'Hakodate Airport (HKD)'),
    ('Hiroshima HIJ',   'Hiroshima Airport (HIJ)'),
    ('Fukuoka FUK',     'Fukuoka Airport (FUK)'),
    ('Nagasaki NGS',    'Nagasaki Airport (NGS)'),
    ('Himeji',          'Himeji Station'),
    ('Hiroshima',       'Hiroshima Station'),
    ('Miyajima',        'Miyajima Pier'),
    ('Hakone-Yumoto',   'Hakone-Yumoto Station'),
    ('Odawara',         'Odawara Station')
)
-- Fix the DEPARTURE side
update public.travelers t
set meta = jsonb_set(t.meta, '{unit_departure_location}', to_jsonb(f.newv), false)
from fixes f
where t.meta->>'unit_departure_location' = f.oldv;

-- Review the two UPDATE row counts above (expected: ~10 arrival, ~4 departure).
-- If they look wrong, run:  rollback;
-- If they look right:
commit;
