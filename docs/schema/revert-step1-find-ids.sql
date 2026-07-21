-- STEP 1 — LOOK ONLY. Changes nothing. Run this to see which rows match,
-- then copy the right planner id + set id into revert-step2 below.

-- How many planners answer to this name? (usually 1)
select id as planner_id, name, email, city
from public.planners
where name = '安部鈴香';

-- How many sets carry number 3? (this is the one returning >1 row)
-- The city + status columns tell you which is the accidental Osaka one.
select s.id as set_id, s.set_number, s.city, s.status, s.planner_id,
       p.name as planner_name
from public.sets s
left join public.planners p on p.id = s.planner_id
where s.set_number = 3
order by s.claimed_at desc nulls last;
