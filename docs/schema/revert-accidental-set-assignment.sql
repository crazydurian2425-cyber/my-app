-- Revert ONE accidental set assignment. Removes Set 3 from the planner and
-- returns it to the open pool. Touches nothing else — the planner's completed
-- Set 2, other planners, and Set 3's template plans are all left alone.
--
-- HOW TO USE: edit the two values on the PLANNER_NAME / SET_NUMBER lines below,
-- then run the whole block in the Supabase SQL editor. It is wrapped in a
-- transaction and will ABORT on its own if the name or set number is ambiguous,
-- so it can't touch the wrong person. Safe to run once.

begin;

do $$
declare
  v_planner uuid;
  v_set     uuid;
  n_plans   int;
begin
  -- ►► EDIT THESE TWO LINES ◄◄
  select id into strict v_planner from public.planners where name = '安部鈴香';
  select id into strict v_set     from public.sets    where set_number = 3;
  -- (STRICT = abort if zero or more than one row matches — no wrong target.)

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

  raise notice 'Reverted: removed % plan copies; Set % returned to open pool.', n_plans, v_set;
end $$;

commit;
