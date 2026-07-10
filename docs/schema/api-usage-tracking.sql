-- ============================================================================
-- Per-planner Google API usage tracking  (powers /superapi999)
--
-- WHAT THIS ADDS
--   1. api_usage_daily — one row per (planner, day, api), holding a running
--      call count. Written by the planner's browser via the SECURITY DEFINER
--      RPC below; read by the admin console via the service-role proxy.
--   2. jj_bump_api_usage(p_counts jsonb) — the ONLY write path. Keyed on
--      auth.uid(), so a planner can only ever increment THEIR OWN row. Called
--      from dashboard.html's batched flush (~once/60s, only when there is
--      something to report). Fire-and-forget on the client; failures are
--      swallowed and never affect the app.
--
-- Counts calls the browser actually FIRES (cache hits don't fire) — so this
-- closely mirrors what Google bills, but split per planner, which Google's own
-- console can never show.
--
-- Idempotent: safe to re-run. Adds nothing to existing tables.
-- ============================================================================

-- 1. Table -------------------------------------------------------------------
create table if not exists public.api_usage_daily (
  planner_id  uuid not null references public.planners(id) on delete cascade,
  usage_date  date not null default (now() at time zone 'Asia/Tokyo')::date,
  api         text not null,
  count       bigint not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (planner_id, usage_date, api)
);

create index if not exists api_usage_daily_date_idx on public.api_usage_daily (usage_date);

-- RLS on, no direct policies: planners write only through the SECURITY DEFINER
-- RPC (which bypasses RLS but pins auth.uid()); admin reads through the
-- service-role proxy (which also bypasses RLS). No anon/authenticated direct
-- table access is granted, so a planner can never read or edit the raw table.
alter table public.api_usage_daily enable row level security;

-- 2. The one write path ------------------------------------------------------
-- Accepts { "routes": 4, "places_search": 2, ... } and increments each api's
-- count for the CALLER (auth.uid()) for today's Tokyo date. Ignored gracefully
-- when called without a logged-in user (auth.uid() null) or with junk keys.
create or replace function public.jj_bump_api_usage(p_counts jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  k    text;
  v    bigint;
  uid  uuid := auth.uid();
  d    date := (now() at time zone 'Asia/Tokyo')::date;
begin
  if uid is null or p_counts is null or jsonb_typeof(p_counts) <> 'object' then
    return;
  end if;
  for k, v in
    -- Only numeric JSON values — a string/object value would raise a cast
    -- error and abort the whole batch; skip it instead.
    select key, greatest(0, floor((value)::text::numeric)::bigint)
    from jsonb_each(p_counts)
    where jsonb_typeof(value) = 'number'
  loop
    -- Guard: sane api-name keys only, positive increments only.
    if k ~ '^[a-z_]{1,40}$' and v > 0 and v < 100000 then
      insert into public.api_usage_daily (planner_id, usage_date, api, count, updated_at)
      values (uid, d, k, v, now())
      on conflict (planner_id, usage_date, api)
      do update set count = public.api_usage_daily.count + excluded.count,
                    updated_at = now();
    end if;
  end loop;
end $$;

-- Planners (authenticated) may CALL the bump RPC; they still can't touch the
-- table directly (no table grants + RLS on).
revoke all on function public.jj_bump_api_usage(jsonb) from public;
grant execute on function public.jj_bump_api_usage(jsonb) to authenticated;

-- Verify:
--   select planner_id, usage_date, api, count
--     from public.api_usage_daily order by usage_date desc, count desc limit 50;
