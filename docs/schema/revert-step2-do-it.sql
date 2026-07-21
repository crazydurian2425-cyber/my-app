-- STEP 2 — THE REVERT. Paste the two IDs you found in STEP 1, then run the
-- whole block. Targets by exact id, so no ambiguity. Wrapped in a transaction.

begin;

do $$
declare
  v_planner uuid := 'PASTE_PLANNER_ID_HERE';
  v_set     uuid := 'PASTE_SET_ID_HERE';
  n_plans   int;
begin
  delete from public.item_images
   where item_id in (select ii.id from public.itinerary_items ii
                     join public.plans p on p.id = ii.plan_id
                     where p.planner_id = v_planner and p.set_id = v_set);

  delete from public.itinerary_items
   where plan_id in (select id from public.plans
                     where planner_id = v_planner and set_id = v_set);

  delete from public.plans
   where planner_id = v_planner and set_id = v_set;
  get diagnostics n_plans = row_count;

  delete from public.set_assignments
   where planner_id = v_planner and set_id = v_set;

  update public.sets
     set planner_id = null, status = 'open', claimed_at = null
   where id = v_set;

  raise notice 'Reverted: removed % plan copies; set returned to open pool.', n_plans;
end $$;

commit;
