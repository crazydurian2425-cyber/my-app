-- Adds a JSONB column to cache the trip stats the planner's Review tab
-- computes (stops, walking km, spend €, day count). The read-only plan
-- summary reads these so it shows the EXACT same numbers as the Review tab —
-- it can't recompute the walking-inside-transit from saved data alone.
--
-- Shape: { "stops": 4, "walking_km": 4.2, "spend_eur": 98, "days": 2 }
--
-- Safe to run repeatedly.
alter table public.plans
  add column if not exists stats_json jsonb;
