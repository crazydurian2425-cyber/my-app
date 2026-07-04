-- Route snapshot per transport leg — the Google-API cost fix.
--
-- The dashboard now persists the LAST successful Routes API result for each
-- transport leg (distance / duration / fare / transit steps / polyline +
-- the cache key it was fetched under) directly on the itinerary row. On the
-- next plan open — any device, any browser, even after Safari evicted
-- localStorage — the leg renders from this snapshot with ZERO Routes API
-- calls, as long as the leg's endpoints / mode / time band are unchanged.
--
-- Without this column the dashboard still works: the insert degrades
-- gracefully (strips the field + retries, console warning), it just keeps
-- paying Google on every fresh-device open.
--
-- Safe to run repeatedly.

alter table public.itinerary_items
  add column if not exists route_snapshot jsonb;
