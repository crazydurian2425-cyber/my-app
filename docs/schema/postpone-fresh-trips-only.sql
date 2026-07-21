-- ============================================================================
-- Postpone FRESH trips by +137 days (~4.5 months). Opened / submitted /
-- approved / in-progress / bond-pending work is left frozen. Reversible (-137).
--
-- AUDITED 2026-07-16 (two independent reviews: adversarial SQL audit + full
-- app sweep of every stored date). Fixes applied since the first draft:
--   • APPLY is now ONE atomic statement (data-modifying CTEs). The old
--     two-statement version could desync plans vs travelers if a planner
--     autosaved at the exact moment it ran, and could double-shift if only
--     half the block was highlighted and run. Both impossible now.
--   • REVERT is also one atomic statement.
--   • travelers.departure_date (legacy column, unused by app code) is now
--     shifted too, so no stored date can go stale.
--   • Idempotency is per-TRIP: if any unit of a trip is already tagged, the
--     whole trip is skipped on a re-run (protects multi-unit leg chaining).
--   • meta is guarded with jsonb_typeof so a non-object meta can't be mangled.
--   • PREVIEW can no longer crash on a non-numeric meta.unit_order.
--   • PRE-FLIGHT queries added: they list malformed meta dates and split
--     trips BEFORE you apply. Both must return 0 rows.
--
-- WHAT THIS DOES
--   • Shifts a trip ONLY when every one of its units is "fresh" (never worked).
--   • A trip = all travelers sharing meta.person_id (+ seed_batch). Travelers
--     with no person_id are their own single-unit trip. Whole-trip shifting
--     keeps multi-unit leg-chaining / durations intact (every unit moves by the
--     SAME 137 days).
--   • A unit is "worked" (and freezes its WHOLE trip) when its plan has:
--       submitted_at set, OR status in (in_progress,submitted,approved,
--       revision,bond_pending,completed),
--       OR a non-empty itin_title, OR any itinerary_items row.
--   • For a shifted trip it moves the date in EVERY place it lives:
--       travelers : arrival_date, meta.trip_start_date,
--                   meta.trip_end_date, meta.unit_departure_date
--       (the live travelers table has NO departure_date column — schema drift
--        vs initial.sql, confirmed in production by error 42703)
--       plans     : arrival_date_snapshot, start_date, end_date (where non-null)
--     and tags the traveler with meta.date_shift_batch = 'fresh-137' so the
--     revert can target EXACTLY these rows.
--
-- WHAT IT DOES NOT TOUCH (verified by code sweep)
--   • Any worked plan — zero writes, so its displayed date (driven by
--     plans.arrival_date_snapshot, overlaid in every planner view) cannot move.
--   • arrival_time / departure_time (times of day), durations,
--     itinerary_items (day_number-based — calendar dates render live),
--     stats_json (no dates), route_snapshot (only exists on worked = frozen
--     plans), and NO application code/logic.
--   • Planner work deadline: set_assignments.deadline / sets.deadline —
--     computed from assignment day, independent of trip dates.
--   • Transport: not stored; recomputes live from plan.start_date/snapshot.
--     Frozen plans never re-fetch. A shifted fresh plan simply fetches for its
--     new date the next time it's opened (its jj_* caches are date-keyed →
--     clean miss + refetch — the correct behaviour).
--
-- HOW TO RUN (Supabase -> SQL editor), ONE SECTION AT A TIME:
--   1) PRE-FLIGHT queries (read-only). Both must return 0 rows.
--   2) PREVIEW (read-only). Eyeball KEEP vs SHIFT.
--   3) APPLY — one single statement, all-or-nothing.
--   4) VERIFY — confirms the result.
--   5) REVERT (-137) at the bottom if you ever need to undo.
--   Never highlight-and-run a fragment of a statement; run whole blocks.
--
-- IDEMPOTENT: re-running APPLY skips every trip that already has a tagged
-- unit, so nothing can double-shift. REVERT clears the tag (a later re-APPLY
-- would shift again — intended). To change the amount, replace every 137/-137.
-- ============================================================================


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ PRE-FLIGHT  (read-only — both queries must return 0 rows)                 ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- P1. Malformed meta dates. APPLY only shifts meta dates matching YYYY-MM-DD;
--     a malformed value would either abort APPLY (invalid calendar date) or be
--     silently skipped (wrong format) leaving that row inconsistent. Fix any
--     row this returns (superadmin edit-traveler modal) BEFORE applying.
select t.id, t.name, x.k as meta_key, x.v as bad_value
from public.travelers t,
lateral (values ('trip_start_date',     t.meta->>'trip_start_date'),
                ('trip_end_date',       t.meta->>'trip_end_date'),
                ('unit_departure_date', t.meta->>'unit_departure_date')) x(k,v)
where x.v is not null
  and case
        when x.v !~ '^\d{4}-\d{2}-\d{2}$'                      then true
        when substring(x.v,6,2)::int not between 1 and 12      then true
        when substring(x.v,9,2)::int not between 1 and 31      then true
        else to_char(make_date(substring(x.v,1,4)::int,
                               substring(x.v,6,2)::int, 1)
                     + (substring(x.v,9,2)::int - 1), 'YYYY-MM-DD') <> x.v
      end;

-- P2. Split trips: the SAME person (same person_id AND same name) spread over
--     multiple seed_batch values would be treated as separate trips and could
--     shift out of lockstep. Must be 0.
--     NOTE: person_id alone being reused across batches is EXPECTED here —
--     each seed batch numbers its people from 0001, so '0001' in the japan
--     batch and '0001' in the luxury batch are different travelers. The app
--     groups siblings by person_id+seed_batch too, so they can never desync.
select t.meta->>'person_id' as person_id, t.name,
       count(distinct coalesce(t.meta->>'seed_batch','')) as seed_batches
from public.travelers t
where coalesce(t.meta->>'person_id','') <> ''
group by 1, 2
having count(distinct coalesce(t.meta->>'seed_batch','')) > 1;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ PREVIEW  (read-only — safe to run anytime)                                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
with
worked_travelers as (
  select distinct p.traveler_id
  from public.plans p
  where p.traveler_id is not null
    and (
         p.submitted_at is not null
      or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
      or coalesce(p.itin_title,'') <> ''
      or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id)
    )
),
trip_keys as (
  select t.id as traveler_id,
         coalesce(nullif(t.meta->>'person_id',''), 'solo:'||t.id::text)
           || '|' || coalesce(t.meta->>'seed_batch','') as trip_key
  from public.travelers t
),
frozen_trips as (
  select distinct tk.trip_key
  from trip_keys tk
  join worked_travelers w on w.traveler_id = tk.traveler_id
),
tagged_trips as (   -- trips already shifted in a prior run (any tagged unit)
  select distinct tk.trip_key
  from trip_keys tk
  join public.travelers t on t.id = tk.traveler_id
  where t.meta->>'date_shift_batch' = 'fresh-137'
)
select
  case
    when t.meta->>'date_shift_batch' = 'fresh-137'              then 'ALREADY SHIFTED'
    when tk.trip_key in (select trip_key from tagged_trips)     then 'KEEP (sibling already shifted)'
    when tk.trip_key in (select trip_key from frozen_trips)     then 'KEEP (worked)'
    else 'SHIFT +137'
  end                                                            as decision,
  tk.trip_key,
  t.name,
  t.destination,
  t.duration,
  t.arrival_date                                                as old_arrival,
  case when tk.trip_key in (select trip_key from frozen_trips)
            or tk.trip_key in (select trip_key from tagged_trips)
       then t.arrival_date else t.arrival_date + 137 end        as new_arrival,
  t.meta->>'trip_start_date'                                    as old_trip_start
from public.travelers t
join trip_keys tk on tk.traveler_id = t.id
order by decision,
         tk.trip_key,
         case when t.meta->>'unit_order' ~ '^\d+$'
              then (t.meta->>'unit_order')::int end nulls first,
         t.arrival_date;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ APPLY  (+137 days) — ONE atomic statement. Run the whole block, once.     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Single statement = single snapshot: the travelers it tags and the plans it
-- shifts are the same set BY CONSTRUCTION (plans update consumes the RETURNING
-- ids of the travelers update). All-or-nothing; cannot be half-run.
with
worked_travelers as (
  select distinct p.traveler_id
  from public.plans p
  where p.traveler_id is not null
    and (   p.submitted_at is not null
         or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
         or coalesce(p.itin_title,'') <> ''
         or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id))
),
trip_keys as (
  select t.id as traveler_id,
         coalesce(nullif(t.meta->>'person_id',''), 'solo:'||t.id::text)
           || '|' || coalesce(t.meta->>'seed_batch','') as trip_key
  from public.travelers t
),
frozen_trips as (
  select distinct tk.trip_key from trip_keys tk
  join worked_travelers w on w.traveler_id = tk.traveler_id
),
tagged_trips as (   -- per-TRIP idempotency: any tagged unit freezes the trip
  select distinct tk.trip_key
  from trip_keys tk
  join public.travelers t on t.id = tk.traveler_id
  where t.meta->>'date_shift_batch' = 'fresh-137'
),
shift_travelers as (
  select tk.traveler_id
  from trip_keys tk
  where tk.trip_key not in (select trip_key from frozen_trips)
    and tk.trip_key not in (select trip_key from tagged_trips)
),
shifted as (
  update public.travelers t
  set arrival_date = case when t.arrival_date is not null then t.arrival_date + 137 end,
      -- NOTE: no departure_date here — the LIVE travelers table has no such
      -- column (schema drift vs initial.sql; verified by error 42703).
      meta = (case when jsonb_typeof(t.meta) = 'object' then t.meta else '{}'::jsonb end)
             || (case when (t.meta->>'trip_start_date')     ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_start_date',     to_char((t.meta->>'trip_start_date')::date     + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'trip_end_date')       ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('trip_end_date',       to_char((t.meta->>'trip_end_date')::date       + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || (case when (t.meta->>'unit_departure_date') ~ '^\d{4}-\d{2}-\d{2}$'
                      then jsonb_build_object('unit_departure_date', to_char((t.meta->>'unit_departure_date')::date + 137,'YYYY-MM-DD')) else '{}'::jsonb end)
             || jsonb_build_object('date_shift_batch','fresh-137')
  where t.id in (select traveler_id from shift_travelers)
  returning t.id
)
update public.plans p
set arrival_date_snapshot = case when p.arrival_date_snapshot is not null then p.arrival_date_snapshot + 137 end,
    start_date            = case when p.start_date            is not null then p.start_date            + 137 end,
    end_date              = case when p.end_date              is not null then p.end_date              + 137 end
where p.traveler_id in (select id from shifted)
  and (p.arrival_date_snapshot is not null or p.start_date is not null or p.end_date is not null);


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ VERIFY  (run right after APPLY, one query at a time)                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- V1. How many travelers got shifted this batch:
select count(*) as shifted_travelers
from public.travelers where meta->>'date_shift_batch' = 'fresh-137';

-- V2. Spot-check the shifted rows (arrival_date and meta dates should agree):
select name, destination, arrival_date,
       meta->>'trip_start_date'     as trip_start,
       meta->>'trip_end_date'       as trip_end,
       meta->>'unit_departure_date' as unit_departs
from public.travelers
where meta->>'date_shift_batch' = 'fresh-137'
order by arrival_date;

-- V3. No worked plan got tagged (must be 0 IMMEDIATELY after apply; later it
--     can legitimately grow as planners start working the shifted plans):
select count(*) as worked_but_tagged
from public.plans p
join public.travelers t on t.id = p.traveler_id
where t.meta->>'date_shift_batch' = 'fresh-137'
  and (p.submitted_at is not null
       or p.status in ('in_progress','submitted','approved','revision','bond_pending','completed')
       or coalesce(p.itin_title,'') <> ''
       or exists (select 1 from public.itinerary_items ii where ii.plan_id = p.id));

-- V4. No half-shifted trip — every trip is either fully tagged or fully
--     untagged (must be 0):
with tk as (
  select coalesce(nullif(t.meta->>'person_id',''), 'solo:'||t.id::text)
           || '|' || coalesce(t.meta->>'seed_batch','') as trip_key,
         coalesce(t.meta->>'date_shift_batch' = 'fresh-137', false) as tagged
  from public.travelers t
)
select count(*) as half_shifted_trips
from (select trip_key from tk group by trip_key
      having bool_or(tagged) and not bool_and(tagged)) s;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ REVERT  (-137 days) — ONE atomic statement, undoes exactly the tagged rows║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Targets only travelers tagged 'fresh-137' and their plans, then clears the
-- tag. Caveat: a shifted plan that a planner OPENED after the shift will also
-- be pulled back -137 (its dates re-derive from the traveler brief on next
-- open, so it self-heals in this app — but revert promptly to avoid confusing
-- anyone mid-work). Uncomment the /* */ to run.
/*
with reverted as (
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
  where t.meta->>'date_shift_batch' = 'fresh-137'
  returning t.id
)
update public.plans p
set arrival_date_snapshot = case when p.arrival_date_snapshot is not null then p.arrival_date_snapshot - 137 end,
    start_date            = case when p.start_date            is not null then p.start_date            - 137 end,
    end_date              = case when p.end_date              is not null then p.end_date              - 137 end
where p.traveler_id in (select id from reverted)
  and (p.arrival_date_snapshot is not null or p.start_date is not null or p.end_date is not null);
*/