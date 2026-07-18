-- add-planner-brand.sql
-- Per-planner brand: a planner is permanently tied to the brand they applied
-- under. The application is stamped with the brand of the domain it came from
-- (jj = Journey Junction, vbd = Vacations by Design); on approval that brand is
-- carried onto the planner. Everything the planner touches — dashboard skin,
-- letters, emails — then follows THEIR brand, not the viewing/admin domain.
--
-- Existing rows default to 'jj' (Journey Junction). Run this before deploying
-- the per-planner brand changes; the app is defensive if it hasn't run yet
-- (it falls back to inserting without brand → reads back as jj).

ALTER TABLE planner_applications
  ADD COLUMN IF NOT EXISTS brand text NOT NULL DEFAULT 'jj';

ALTER TABLE planners
  ADD COLUMN IF NOT EXISTS brand text NOT NULL DEFAULT 'jj';

-- Optional sanity check:
-- SELECT brand, count(*) FROM planners GROUP BY brand;
