-- ============================================================================
-- Enable Supabase Realtime for the planner dashboard (admin → planner instant).
--
-- The planner dashboard already SUBSCRIBES to these tables over a realtime
-- WebSocket (dashboard.html subscribePlannerRealtime) and re-renders within
-- ~½ second on any change. But Supabase only PUSHES changes for tables added to
-- the `supabase_realtime` publication — and on the live DB they weren't, so the
-- subscription connected but received nothing (you had to refresh).
--
-- This migration:
--   1) Sets REPLICA IDENTITY FULL so change events carry the row's planner_id —
--      required for the `planner_id=eq.<id>` filter to match on UPDATE/DELETE
--      (default replica identity ships only the primary key).
--   2) Adds the tables to the `supabase_realtime` publication (idempotent).
--
-- RLS still applies to realtime — the planner only ever receives THEIR OWN rows
-- (planner_id = auth.uid()), via the same SELECT policies the dashboard already
-- uses to load these tables. No app code change needed.
--
-- Safe to run repeatedly.
-- ============================================================================

-- 1) Replica identity FULL on the filtered tables.
alter table public.set_assignments        replica identity full;
alter table public.plans                   replica identity full;
alter table public.sets                    replica identity full;
alter table public.wallet_requests         replica identity full;
alter table public.wallet_adjustments      replica identity full;
alter table public.wallet_pending_payments replica identity full;

-- 2) Add each table to the realtime publication only if not already a member.
do $$
declare t text;
begin
  foreach t in array array[
    'set_assignments','plans','sets',
    'wallet_requests','wallet_adjustments','wallet_pending_payments'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ── Verify ──────────────────────────────────────────────────────────
-- Every table below should appear (6 rows).
select tablename
from   pg_publication_tables
where  pubname = 'supabase_realtime' and schemaname = 'public'
  and  tablename in ('set_assignments','plans','sets','wallet_requests','wallet_adjustments','wallet_pending_payments')
order  by tablename;
