-- add-letter-brand.sql
-- Per-letter brand so each employment / guarantee / final-confirmation letter
-- renders the company that ISSUED it, independent of the viewing domain.
--
-- Existing rows default to 'jj' (Journey Junction) — a signed Journey Junction
-- contract must NEVER be reskinned to another brand. New letters are stamped by
-- the Worker with the issuing domain's brand ('jj' or 'vbd').
--
-- Run this BEFORE issuing any Vacations by Design letters (otherwise the Worker
-- falls back to inserting without a brand and the letter reads back as jj).

ALTER TABLE employment_letters
  ADD COLUMN IF NOT EXISTS brand text NOT NULL DEFAULT 'jj';

-- Optional: confirm the backfill (every existing row is Journey Junction).
-- SELECT brand, count(*) FROM employment_letters GROUP BY brand;
