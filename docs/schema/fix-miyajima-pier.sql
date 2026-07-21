-- Fix ONLY the Miyajima arrival gateway: bare "Miyajima" -> "Miyajima Pier"
-- so it resolves to the real ferry terminal (宮島桟橋) instead of the island
-- centre. Touches nothing else. Safe to run once; re-running is a no-op.

-- STEP 1 — PREVIEW (read only). Confirm which rows will change.
select id, name, destination,
       meta->>'unit_arrival_method'   as arr_method,
       meta->>'unit_arrival_location' as arr_now
from public.travelers
where meta->>'unit_arrival_location' = 'Miyajima';

-- STEP 2 — APPLY.
begin;

update public.travelers
set meta = jsonb_set(meta, '{unit_arrival_location}', '"Miyajima Pier"'::jsonb, false)
where meta->>'unit_arrival_location' = 'Miyajima';

-- Check the row count above, then:
commit;
