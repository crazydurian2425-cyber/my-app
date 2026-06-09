-- ============================================================================
-- Shift EVERY traveler/unit trip into July 2026 — keep day-of-month + length.
--
-- Goal (per the Anna Kowalski example):
--   2026-08-05 · 3D2N  ->  2026-07-05 · 3D2N
--   2026-08-07 · 2D1N  ->  2026-07-07 · 2D1N
--
-- Method: a per-TRIP uniform day-shift. For each traveler row the delta is
--   delta = make_date(2026, 7, day-of-month of meta.trip_start_date)
--           - meta.trip_start_date
-- Because meta.trip_start_date is identical across all of a person's units,
-- every unit of a trip shifts by the SAME number of days, so the leg chaining
-- (leg 2 arrival = leg 1 departure), durations, gaps, and the trip envelope are
-- preserved by construction. This is also the correct, safe behaviour for the
-- two trips that straddle a month boundary (Eduardo & Beatriz Jul->Aug, The
-- Anderson Party Sep->Oct): naive "set month=July" would push an end date
-- before its start; the whole-trip shift keeps them intact.
--
-- Fields moved (all by the same per-trip delta):
--   travelers : arrival_date, meta.trip_start_date, meta.trip_end_date,
--               meta.unit_departure_date
--   plans     : arrival_date_snapshot, start_date, end_date  (where non-null)
-- Untouched (correctly): arrival_time / departure_time (times), duration,
--   itinerary_items (day-number based — dates are computed live), sets.deadline
--   (that's the planner work deadline, not a trip date).
--
-- Transport: the Google Routes fetch reads the live trip-start date + day
-- offset, and its cache is keyed by date+hour, so after this runs the next
-- time a plan is opened it re-fetches July schedules automatically. No stored
-- route columns to migrate.
--
-- Trips already starting in July (delta = 0) are left unchanged.
-- Idempotency note: this is NOT idempotent — running it twice shifts twice.
-- Run ONCE. (Wrapped in a transaction; review the preview first.)
-- ============================================================================

-- ── PREVIEW (safe, read-only) — run this FIRST to eyeball the before/after ──
-- Comment out the BEGIN..COMMIT block below and run just this if you want a
-- dry run. Shows each unit's old vs new dates.
with d as (
  select id, name, arrival_date, duration,
         (meta->>'trip_start_date')::date as ts,
         (meta->>'trip_end_date')::date   as te,
         (meta->>'unit_departure_date')::date as ud,
         (make_date(2026, 7, extract(day from (meta->>'trip_start_date')::date)::int)
            - (meta->>'trip_start_date')::date) as delta
  from public.travelers
  where meta ? 'trip_start_date'
    and (meta->>'trip_start_date') ~ '^\d{4}-\d{2}-\d{2}$'
)
select name, duration,
       arrival_date            as old_arrival,
       arrival_date + delta     as new_arrival,
       ts as old_trip_start, ts + delta as new_trip_start,
       te as old_trip_end,   te + delta as new_trip_end,
       delta as shift_days
from d
order by name, arrival_date;


-- ── APPLY (atomic) ─────────────────────────────────────────────────────────
begin;

-- 1) PLANS FIRST — must read the ORIGINAL (un-shifted) traveler dates to
--    compute the delta. (If travelers were updated first, the delta would
--    collapse to ~0 because their trip_start_date would already be July.)
with d as (
  select tr.id as traveler_id,
         (make_date(2026, 7, extract(day from (tr.meta->>'trip_start_date')::date)::int)
            - (tr.meta->>'trip_start_date')::date) as delta
  from public.travelers tr
  where tr.meta ? 'trip_start_date'
    and (tr.meta->>'trip_start_date') ~ '^\d{4}-\d{2}-\d{2}$'
)
update public.plans p
set arrival_date_snapshot = case when p.arrival_date_snapshot is not null
                                 then p.arrival_date_snapshot + d.delta end,
    start_date            = case when p.start_date is not null
                                 then p.start_date + d.delta end,
    end_date              = case when p.end_date is not null
                                 then p.end_date + d.delta end
from d
where p.traveler_id = d.traveler_id
  and d.delta <> 0;   -- skip trips already in July (no-op)

-- 2) TRAVELERS — shift arrival_date + the three meta date keys by the same
--    per-trip delta. The `||` merge overwrites only the keys we rebuild;
--    any missing key is left untouched (te/ud guarded for safety).
with d as (
  select id,
         (meta->>'trip_start_date')::date as ts,
         (meta->>'trip_end_date')::date   as te,
         (meta->>'unit_departure_date')::date as ud,
         (make_date(2026, 7, extract(day from (meta->>'trip_start_date')::date)::int)
            - (meta->>'trip_start_date')::date) as delta
  from public.travelers
  where meta ? 'trip_start_date'
    and (meta->>'trip_start_date') ~ '^\d{4}-\d{2}-\d{2}$'
)
update public.travelers t
set arrival_date = t.arrival_date + d.delta,
    meta = t.meta
           || jsonb_build_object('trip_start_date', to_char(d.ts + d.delta, 'YYYY-MM-DD'))
           || (case when d.te is not null
                    then jsonb_build_object('trip_end_date', to_char(d.te + d.delta, 'YYYY-MM-DD'))
                    else '{}'::jsonb end)
           || (case when d.ud is not null
                    then jsonb_build_object('unit_departure_date', to_char(d.ud + d.delta, 'YYYY-MM-DD'))
                    else '{}'::jsonb end)
from d
where t.id = d.id
  and d.delta <> 0;

commit;


-- ── VERIFY (run after commit) ───────────────────────────────────────────────
-- Every arrival_date and meta.trip_start_date should now be in 2026-07.
-- (A few long trips may END in early August — that's expected.)
select name, arrival_date,
       meta->>'trip_start_date' as trip_start,
       meta->>'trip_end_date'   as trip_end,
       meta->>'unit_departure_date' as unit_departs
from public.travelers
order by arrival_date;

-- Any plan snapshot still outside July? (should return 0 rows for assigned ones
-- whose trip moved)
select id, traveler_id, arrival_date_snapshot, start_date, end_date
from public.plans
where arrival_date_snapshot is not null
  and date_part('month', arrival_date_snapshot) <> 7
order by arrival_date_snapshot;
