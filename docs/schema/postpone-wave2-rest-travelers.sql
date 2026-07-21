-- ============================================================================
-- WAVE 2 — shift the REMAINING travelers +137 days (the ones wave 1 froze
-- because their trip has worked plans). Run AFTER postpone-fresh-trips-only.sql.
--
-- What it does:
--   • Shifts arrival_date + meta.trip_start_date/trip_end_date/
--     unit_departure_date for every traveler NOT already tagged by wave 1,
--     and tags them meta.date_shift_batch = 'rest-137'.
--   • WORKED plans (submitted / approved / revision / completed / in_progress /
--     bond_pending, or any itin_title / itinerary_items) keep their
--     arrival_date_snapshot + start/end dates — the planner keeps seeing the
--     ORIGINAL dates on those plans (the snapshot overlay guarantees it).
--     Worked plans that have NO snapshot yet get one backfilled from the
--     traveler's CURRENT (pre-shift) date, so their display cannot move.
--   • NON-worked (pending, untouched) plans of these travelers shift +137 in
--     lockstep with the traveler.
--
-- Result: the admin "All travelers" list shows the shifted date for EVERYONE;
-- every future assignment/reassignment snapshots the new date; existing
-- submitted/opened work keeps its original dates.
--
-- Known cosmetic side effect (accepted): on plans a planner is ACTIVELY
-- working, the "trip context" sidebar reads live traveler meta and will show
-- the new dates while the plan itself stays on its frozen snapshot dates.
-- Clears up as those plans are submitted.
--
-- Idempotent: skips travelers tagged 'fresh-137' or 'rest-137'.
-- Revert: -137 block at the bottom (targets ONLY 'rest-137' rows).
-- ============================================================================


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ PREVIEW  (read-only)                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
select t.name, t.destination, t.duration,
       t.arrival_date        as old_arrival,
       t.arrival_date + 137  as new_arrival,
       (select count(*) from public.plans p
         where p.traveler_id = t.id
           and (p.submitted_at is not null
             or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
             or coalesce(p.itin_title,'') <> ''
             or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id))
       ) as worked_plans_kept_frozen
from public.travelers t
where coalesce(t.meta->>'date_shift_batch','') not in ('fresh-137','rest-137')
order by t.arrival_date;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ APPLY  (+137 days) — ONE atomic statement. Run once.                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
with
worked_plans as (
  select p.id, p.traveler_id
  from public.plans p
  where p.traveler_id is not null
    and (   p.submitted_at is not null
         or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
         or coalesce(p.itin_title,'') <> ''
         or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id))
),
rest_travelers as (
  select t.id, t.arrival_date
  from public.travelers t
  where coalesce(t.meta->>'date_shift_batch','') not in ('fresh-137','rest-137')
),
backfilled as (
  -- Freeze worked plans that have no snapshot yet, at the CURRENT (pre-shift)
  -- traveler date — otherwise their display would fall back to the live
  -- (about to shift) traveler date.
  update public.plans p
  set arrival_date_snapshot = rt.arrival_date
  from rest_travelers rt
  where p.traveler_id = rt.id
    and p.arrival_date_snapshot is null
    and rt.arrival_date is not null
    and p.id in (select id from worked_plans)
  returning p.id
),
shifted_travelers as (
  update public.travelers t
  set arrival_date = case when t.arrival_date is not null then t.arrival_date + 137 end,
      meta = (case when jsonb_typeof(t.meta) = 'object' then t.meta else '{}'::jsonb end)
             || (case when (t.meta->>'trip_start_date')     ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_start_date',     to_char((t.meta->>'trip_start_date')::date     + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'trip_end_date')       ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_end_date',       to_char((t.meta->>'trip_end_date')::date       + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'unit_departure_date') ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('unit_departure_date', to_char((t.meta->>'unit_departure_date')::date + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || jsonb_build_object('date_shift_batch','rest-137')
  where t.id in (select id from rest_travelers)
  returning t.id
)
update public.plans p
set arrival_date_snapshot = case when p.arrival_date_snapshot is not null then p.arrival_date_snapshot + 137 end,
    start_date            = case when p.start_date            is not null then p.start_date            + 137 end,
    end_date              = case when p.end_date              is not null then p.end_date              + 137 end
where p.traveler_id in (select id from shifted_travelers)
  and p.id not in (select id from worked_plans)
  and (p.arrival_date_snapshot is not null or p.start_date is not null or p.end_date is not null);


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ VERIFY  (one query at a time)                                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- V1. Every traveler is now tagged by one of the two waves (must be 0):
select count(*) as untagged_travelers
from public.travelers
where coalesce(meta->>'date_shift_batch','') not in ('fresh-137','rest-137');

-- V2. Every worked plan is protected by a snapshot (must be 0):
select count(*) as worked_plans_without_snapshot
from public.plans p
where p.traveler_id is not null
  and p.arrival_date_snapshot is null
  and (p.submitted_at is not null
       or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
       or coalesce(p.itin_title,'') <> ''
       or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id));

-- V3. Spot-check wave-2 travelers (dates should be ~Dec 2026 onward, aligned):
select name, destination, arrival_date,
       meta->>'trip_start_date'     as trip_start,
       meta->>'unit_departure_date' as unit_departs
from public.travelers
where meta->>'date_shift_batch' = 'rest-137'
order by arrival_date;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ REVERT wave 2 only  (-137) — uncomment to run. Backfilled snapshots are   ║
-- ║ kept (they hold correct pre-shift dates either way).                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
/*
with
worked_plans as (
  select p.id
  from public.plans p
  where p.traveler_id is not null
    and (   p.submitted_at is not null
         or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
         or coalesce(p.itin_title,'') <> ''
         or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id))
),
reverted as (
  update public.travelers t
  set arrival_date = case when t.arrival_date is not null then t.arrival_date - 137 end,
      meta = ((case when jsonb_typeof(t.meta) = 'object' then t.meta else '{}'::jsonb end)
             || (case when (t.meta->>'trip_start_date')     ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_start_date',     to_char((t.meta->>'trip_start_date')::date     - 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'trip_end_date')       ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_end_date',       to_char((t.meta->>'trip_end_date')::date       - 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'unit_departure_date') ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('unit_departure_date', to_char((t.meta->>'unit_departure_date')::date - 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             ) - 'date_shift_batch'
  where t.meta->>'date_shift_batch' = 'rest-137'
  returning t.id
)
update public.plans p
set arrival_date_snapshot = case when p.arrival_date_snapshot is not null then p.arrival_date_snapshot - 137 end,
    start_date            = case when p.start_date            is not null then p.start_date            - 137 end,
    end_date              = case when p.end_date              is not null then p.end_date              - 137 end
where p.traveler_id in (select id from reverted)
  and p.id not in (select id from worked_plans)
  and (p.arrival_date_snapshot is not null or p.start_date is not null or p.end_date is not null);
*/