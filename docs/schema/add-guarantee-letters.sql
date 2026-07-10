-- Letter of guarantee support for the existing employment_letters flow.
--
-- Adds two columns so ONE table drives both letter kinds:
--   letter_type  — 'employment' (default, = today's contract) or 'guarantee'
--   custom_body  — the admin-edited guarantee text (null for employment letters)
--
-- The employment contract keeps its fixed template and never uses custom_body.
-- Existing rows default to 'employment', so nothing changes for them.
-- Additive + idempotent. Safe to run once (or again).

alter table public.employment_letters
  add column if not exists letter_type text not null default 'employment',
  add column if not exists custom_body text;

-- Verify:
--   select letter_type, count(*) from public.employment_letters group by 1;
