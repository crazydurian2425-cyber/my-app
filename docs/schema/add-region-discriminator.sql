-- ============================================================================
-- Japan market · Data layer — the `region` market discriminator.
--
-- Adds a `region` column ('FR' | 'JP') so France and Japan data live in one
-- Supabase but stay logically separated. Every existing row is the France
-- market, so the column defaults to 'FR' and existing data is stamped 'FR'.
--
-- WHY NO NEW RLS: planner-facing policies already scope every table to
-- auth.uid() (a planner only ever sees their OWN rows — see SECTION 8 of
-- initial.sql). A French planner therefore can't read Japanese rows regardless,
-- because they aren't their rows. So region does NOT need new planner RLS.
-- Region is enforced/used at three other layers:
--   • admin filtering   — superadmin uses the service-role proxy (bypasses RLS)
--                         and filters queries by the selected market.
--   • login scoping     — app rejects a planner whose region ≠ the domain.
--   • presentation      — domain/?market= picks language + currency.
--
-- Currency is NOT stored — it is derived from region in code (FR→EUR, JP→JPY).
--
-- region is added to the 3 market ANCHORS (planners, planner_applications,
-- travelers) and DENORMALISED onto sets + plans so the admin panel can filter
-- those by market without multi-table joins.
--
-- Idempotent. Run in the Supabase SQL editor.
-- ============================================================================

-- 1. Anchors -----------------------------------------------------------------
alter table public.planners
  add column if not exists region text not null default 'FR' check (region in ('FR','JP'));
alter table public.planner_applications
  add column if not exists region text not null default 'FR' check (region in ('FR','JP'));
alter table public.travelers
  add column if not exists region text not null default 'FR' check (region in ('FR','JP'));

-- 2. Denormalised onto sets + plans (for admin market filtering) -------------
alter table public.sets
  add column if not exists region text not null default 'FR' check (region in ('FR','JP'));
alter table public.plans
  add column if not exists region text not null default 'FR' check (region in ('FR','JP'));

-- 3. Indexes — every market-scoped query filters on region -------------------
create index if not exists planners_region_idx              on public.planners(region);
create index if not exists planner_applications_region_idx  on public.planner_applications(region);
create index if not exists travelers_region_idx             on public.travelers(region);
create index if not exists sets_region_idx                  on public.sets(region);
create index if not exists plans_region_idx                 on public.plans(region);

-- ── Verify ──────────────────────────────────────────────────────────
-- Every existing row should report region = 'FR'.
select 'planners'     as tbl, region, count(*) from public.planners             group by region
union all
select 'applications' as tbl, region, count(*) from public.planner_applications group by region
union all
select 'travelers'    as tbl, region, count(*) from public.travelers            group by region
union all
select 'sets'         as tbl, region, count(*) from public.sets                 group by region
union all
select 'plans'        as tbl, region, count(*) from public.plans                group by region
order by tbl, region;
