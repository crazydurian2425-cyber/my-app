-- ============================================================================
-- MENTOR CLOCK-IN  —  5 mentors (TT / MIKE / FCKING / KIT / TIM), each with
-- their OWN login, clocking in from ONE registered laptop, only 09:15–09:30 JST.
--
-- MENTORS ARE NOT PLANNERS. This creates a separate `mentors` table keyed to
-- their own auth accounts. Nothing here touches `planners`, the dashboard,
-- transport, autosave, or any planner logic.
--
-- WHAT THIS SETS UP
--   • mentors           : the 5 mentor accounts (id = their auth user id).
--                         Rows are inserted by the /api/create-mentor endpoint
--                         when the admin creates each login.
--   • mentor_devices    : which laptop belongs to which mentor (a saved random
--                         device_key). A device must be approved=true to work.
--   • mentor_attendance : the clock-in log — one row per mentor per Tokyo day.
--                         CLOCK-IN ONLY (no clock-out).
--   • RPCs (SECURITY DEFINER — the real gate, runs on the server):
--       jj_mentor_register_device(key,label) : mentor enrols this laptop
--                                              (pending; admin approves)
--       jj_mentor_clock_in(key)              : enforces mentor + approved device
--                                              + 09:15–09:30 Asia/Tokyo, once/day
--
-- WHY RPCs, NOT DIRECT WRITES: the browser can NEVER insert a time or approve
--   its own device — every write goes through these functions, which read the
--   clock on the SERVER (Asia/Tokyo). A changed laptop clock, an edited page,
--   or an unregistered PC all get refused.
--
-- IDEMPOTENT: safe to re-run. Change the window in ONE place
--   (jj_mentor_clock_in → WIN_OPEN / WIN_CLOSE).
-- ============================================================================


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0) CLEAN UP any earlier draft of this feature                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- An earlier draft keyed mentor_devices/attendance to PLANNERS and added a
-- planners.is_mentor flag. If that version was ever run, rebuild those tables
-- against the new `mentors` table (they held no real data — the flow never
-- went live) and drop the flag. No-ops on a clean database.
do $$
begin
  if exists (
    select 1
      from information_schema.table_constraints tc
      join information_schema.constraint_column_usage ccu
        on ccu.constraint_name = tc.constraint_name
       and ccu.table_schema    = tc.table_schema
     where tc.table_schema = 'public'
       and tc.table_name   = 'mentor_devices'
       and tc.constraint_type = 'FOREIGN KEY'
       and ccu.table_name  = 'planners'
  ) then
    drop table if exists public.mentor_attendance;
    drop table if exists public.mentor_devices;
  end if;
end $$;

drop function if exists public.jj_mentor_register_device(text, text);
drop function if exists public.jj_mentor_clock_in(text);
drop function if exists public.jj_mentor_clock_out(text);
alter table public.planners drop column if exists is_mentor;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 1) MENTORS  (separate accounts — NOT planners)                            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
create table if not exists public.mentors (
  id         uuid primary key,              -- = auth user id (set by /api/create-mentor)
  name       text not null unique,          -- TT / MIKE / FCKING / KIT / TIM
  email      text not null unique,
  active     boolean not null default true, -- flip false to disable a mentor
  created_at timestamptz not null default now()
);

alter table public.mentors enable row level security;

-- A mentor may READ their own row (mentor.html shows "signed in as TT").
-- No client writes — rows are created by the admin endpoint (service role).
drop policy if exists mentors_own_select on public.mentors;
create policy mentors_own_select on public.mentors
  for select using (id = auth.uid());


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 2) MENTOR DEVICES  (which laptop belongs to a mentor)                     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
create table if not exists public.mentor_devices (
  id           uuid primary key default gen_random_uuid(),
  mentor_id    uuid not null references public.mentors(id) on delete cascade,
  device_key   text not null,                 -- long random secret, stored in the laptop's browser
  label        text,                          -- e.g. "KIT office laptop"
  approved     boolean not null default false,-- admin must approve before it can clock in
  created_at   timestamptz not null default now(),
  approved_at  timestamptz,
  last_used_at timestamptz,
  unique (mentor_id, device_key)
);
create index if not exists mentor_devices_mentor_idx on public.mentor_devices (mentor_id);

alter table public.mentor_devices enable row level security;

-- A mentor may READ their own devices (to show "this laptop is registered ✓").
drop policy if exists mentor_devices_own_select on public.mentor_devices;
create policy mentor_devices_own_select on public.mentor_devices
  for select using (mentor_id = auth.uid());
-- No direct INSERT/UPDATE/DELETE for the browser — enrolment goes through the
-- RPC below; approval happens in superadmin via the service-role proxy.


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 3) MENTOR ATTENDANCE  (the clock-in log — clock-in only)                  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
create table if not exists public.mentor_attendance (
  id           uuid primary key default gen_random_uuid(),
  mentor_id    uuid not null references public.mentors(id) on delete cascade,
  device_id    uuid references public.mentor_devices(id) on delete set null,
  work_date    date not null,                 -- Asia/Tokyo calendar day
  clock_in_at  timestamptz not null default now(),
  unique (mentor_id, work_date)               -- at most one clock-in per mentor per day
);
create index if not exists mentor_attendance_date_idx on public.mentor_attendance (work_date);

alter table public.mentor_attendance enable row level security;

-- A mentor may READ their own attendance. Admin reads everything via the proxy.
drop policy if exists mentor_attendance_own_select on public.mentor_attendance;
create policy mentor_attendance_own_select on public.mentor_attendance
  for select using (mentor_id = auth.uid());
-- No direct writes — clock-in happens only through the RPC below.


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 4) RPCs  (SECURITY DEFINER — the server-side gate)                        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- 4a) Enrol THIS laptop for the calling mentor. Stores the browser's random
--     device_key as pending (approved=false). The admin approves it afterwards.
create or replace function public.jj_mentor_register_device(p_device_key text, p_label text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
  v_approved boolean;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  end if;
  if not exists (select 1 from public.mentors where id = v_uid and active) then
    return jsonb_build_object('ok', false, 'reason', 'not_mentor');
  end if;
  if coalesce(btrim(p_device_key),'') = '' or length(p_device_key) < 20 then
    return jsonb_build_object('ok', false, 'reason', 'bad_device_key');
  end if;

  -- Re-registering the same key is harmless (keeps its approved state).
  insert into public.mentor_devices (mentor_id, device_key, label, approved)
  values (v_uid, p_device_key, nullif(btrim(p_label),''), false)
  on conflict (mentor_id, device_key)
    do update set label = coalesce(excluded.label, mentor_devices.label)
  returning id, approved into v_id, v_approved;

  return jsonb_build_object('ok', true, 'device_id', v_id, 'approved', v_approved);
end;
$$;

-- 4b) Clock in. Enforces: caller is an active mentor, the device is
--     registered + approved, and the SERVER clock (Asia/Tokyo) is inside
--     09:15–09:30. Once per Tokyo day.
create or replace function public.jj_mentor_clock_in(p_device_key text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  WIN_OPEN  constant int := 9*60 + 15;   -- 09:15  ← change window here
  WIN_CLOSE constant int := 9*60 + 30;   -- 09:30  ←
  v_uid   uuid := auth.uid();
  v_now   timestamptz := now();
  v_local timestamp   := v_now at time zone 'Asia/Tokyo';
  v_date  date        := (v_now at time zone 'Asia/Tokyo')::date;
  v_min   int;
  v_devid uuid;
begin
  if v_uid is null then return jsonb_build_object('ok', false, 'reason', 'not_authenticated'); end if;
  if not exists (select 1 from public.mentors where id = v_uid and active) then
    return jsonb_build_object('ok', false, 'reason', 'not_mentor');
  end if;

  select id into v_devid
    from public.mentor_devices
   where mentor_id = v_uid and device_key = p_device_key and approved
   limit 1;
  if v_devid is null then
    return jsonb_build_object('ok', false, 'reason', 'device_not_registered');
  end if;

  v_min := extract(hour from v_local)::int * 60 + extract(minute from v_local)::int;
  if v_min < WIN_OPEN  then return jsonb_build_object('ok', false, 'reason', 'too_early'); end if;
  if v_min > WIN_CLOSE then return jsonb_build_object('ok', false, 'reason', 'too_late');  end if;

  if exists (select 1 from public.mentor_attendance where mentor_id = v_uid and work_date = v_date) then
    return jsonb_build_object('ok', false, 'reason', 'already_clocked_in');
  end if;

  -- The unique (mentor_id, work_date) constraint is the real guard — a double
  -- click that races past the check above lands here and is reported cleanly.
  begin
    insert into public.mentor_attendance (mentor_id, device_id, work_date, clock_in_at)
    values (v_uid, v_devid, v_date, v_now);
  exception when unique_violation then
    return jsonb_build_object('ok', false, 'reason', 'already_clocked_in');
  end;
  update public.mentor_devices set last_used_at = v_now where id = v_devid;

  return jsonb_build_object('ok', true, 'clock_in_at', v_now, 'work_date', v_date);
end;
$$;

-- Lock the functions down: no anon; only signed-in accounts may call them.
-- (The functions themselves check the mentors table, so a planner calling
-- them gets 'not_mentor' and can do nothing.)
revoke all on function public.jj_mentor_register_device(text, text) from public, anon;
revoke all on function public.jj_mentor_clock_in(text)             from public, anon;
grant execute on function public.jj_mentor_register_device(text, text) to authenticated;
grant execute on function public.jj_mentor_clock_in(text)              to authenticated;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 5) VERIFY  (run after the above)                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Tables + functions exist:
--   select table_name from information_schema.tables
--     where table_name in ('mentors','mentor_devices','mentor_attendance');
--   select proname from pg_proc
--     where proname in ('jj_mentor_register_device','jj_mentor_clock_in');
--
-- The 5 mentor rows appear automatically as the admin creates each account
-- (superadmin → Mentor clock-in → Create login). Check with:
--   select name, email, active, created_at from public.mentors order by name;
--
-- Pending laptops waiting for approval:
--   select m.name, d.label, d.approved, d.created_at
--     from public.mentor_devices d join public.mentors m on m.id = d.mentor_id
--    order by d.created_at desc;
--
-- Today's attendance:
--   select m.name, a.work_date, a.clock_in_at at time zone 'Asia/Tokyo' as clock_in_jst
--     from public.mentor_attendance a join public.mentors m on m.id = a.mentor_id
--    where a.work_date = (now() at time zone 'Asia/Tokyo')::date
--    order by a.clock_in_at;
