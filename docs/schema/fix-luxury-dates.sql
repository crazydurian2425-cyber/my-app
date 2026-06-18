-- ============================================================================
-- Fix luxury (lux-jp-bond-01) traveler dates → Aug 1–16 window + consistent
-- durations. The 12 luxury travelers were staggered Jul–Sep and the live rows
-- also drifted on duration (e.g. a 3-night trip shown as 2泊3日). This sets
-- arrival_date, duration, and the meta trip/unit dates to matching values.
-- Keyed by person_id. Idempotent. jp-01 travelers are already correct — untouched.
-- ============================================================================
UPDATE public.travelers SET arrival_date='2026-08-01', duration='4D3N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-01'::text)),
    '{trip_end_date}', to_jsonb('2026-08-04'::text)),
    '{trip_total_duration}', to_jsonb('4D3N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-04'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0001';
UPDATE public.travelers SET arrival_date='2026-08-13', duration='4D3N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-13'::text)),
    '{trip_end_date}', to_jsonb('2026-08-16'::text)),
    '{trip_total_duration}', to_jsonb('4D3N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-16'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0002';
UPDATE public.travelers SET arrival_date='2026-08-02', duration='5D4N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-02'::text)),
    '{trip_end_date}', to_jsonb('2026-08-06'::text)),
    '{trip_total_duration}', to_jsonb('5D4N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-06'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0003';
UPDATE public.travelers SET arrival_date='2026-08-05', duration='5D4N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-05'::text)),
    '{trip_end_date}', to_jsonb('2026-08-09'::text)),
    '{trip_total_duration}', to_jsonb('5D4N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-09'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0004';
UPDATE public.travelers SET arrival_date='2026-08-08', duration='5D4N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-08'::text)),
    '{trip_end_date}', to_jsonb('2026-08-12'::text)),
    '{trip_total_duration}', to_jsonb('5D4N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-12'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0005';
UPDATE public.travelers SET arrival_date='2026-08-11', duration='5D4N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-11'::text)),
    '{trip_end_date}', to_jsonb('2026-08-15'::text)),
    '{trip_total_duration}', to_jsonb('5D4N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-15'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0006';
UPDATE public.travelers SET arrival_date='2026-08-01', duration='6D5N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-01'::text)),
    '{trip_end_date}', to_jsonb('2026-08-06'::text)),
    '{trip_total_duration}', to_jsonb('6D5N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-06'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0007';
UPDATE public.travelers SET arrival_date='2026-08-04', duration='6D5N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-04'::text)),
    '{trip_end_date}', to_jsonb('2026-08-09'::text)),
    '{trip_total_duration}', to_jsonb('6D5N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-09'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0008';
UPDATE public.travelers SET arrival_date='2026-08-07', duration='6D5N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-07'::text)),
    '{trip_end_date}', to_jsonb('2026-08-12'::text)),
    '{trip_total_duration}', to_jsonb('6D5N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-12'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0009';
UPDATE public.travelers SET arrival_date='2026-08-10', duration='6D5N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-10'::text)),
    '{trip_end_date}', to_jsonb('2026-08-15'::text)),
    '{trip_total_duration}', to_jsonb('6D5N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-15'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0010';
UPDATE public.travelers SET arrival_date='2026-08-03', duration='7D6N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-03'::text)),
    '{trip_end_date}', to_jsonb('2026-08-09'::text)),
    '{trip_total_duration}', to_jsonb('7D6N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-09'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0011';
UPDATE public.travelers SET arrival_date='2026-08-10', duration='7D6N',
  meta = jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{trip_start_date}', to_jsonb('2026-08-10'::text)),
    '{trip_end_date}', to_jsonb('2026-08-16'::text)),
    '{trip_total_duration}', to_jsonb('7D6N'::text)),
    '{unit_departure_date}', to_jsonb('2026-08-16'::text))
WHERE meta->>'seed_batch'='lux-jp-bond-01' AND meta->>'person_id'='0012';

-- Verify: SELECT meta->>'person_id' pid, arrival_date, duration,
--   meta->>'trip_start_date' s, meta->>'trip_end_date' e
--   FROM public.travelers WHERE meta->>'seed_batch'='lux-jp-bond-01' ORDER BY 1;
