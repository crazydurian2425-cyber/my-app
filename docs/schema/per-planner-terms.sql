-- ============================================================================
-- Per-planner Terms of Service — two versions, assigned per planner.
--
-- WHAT THIS ADDS
--   1. planners.terms_variant  — 'standard' (Normal) or 'premium'. Defaults to
--      'standard', so every existing + future planner sees the Normal terms
--      unless an admin explicitly moves them to Premium.
--   2. legal_docs slug 'terms_premium' — the Premium version's editable content,
--      SEEDED IDENTICAL to the current Normal terms ('terms' row) so both start
--      the same. Admin edits either version in the superadmin Terms editor.
--
-- terms.html reads the logged-in planner's terms_variant and loads the matching
-- legal_docs row ('terms' or 'terms_premium'), overlaid on the baked-in default
-- text. The public title (利用規約 / Terms of Service) is the same for both.
--
-- PREREQUISITE: run docs/schema/legal-docs.sql first (it creates legal_docs and
-- seeds the 'terms' row). This file copies that row into 'terms_premium'.
--
-- Idempotent: safe to re-run. Uses IF NOT EXISTS / ON CONFLICT throughout.
-- ============================================================================

-- 1. Per-planner variant column ----------------------------------------------
alter table public.planners
  add column if not exists terms_variant text not null default 'standard';

-- Constrain to the two known values (guarded so re-running doesn't error).
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'planners_terms_variant_chk'
  ) then
    alter table public.planners
      add constraint planners_terms_variant_chk
      check (terms_variant in ('standard','premium'));
  end if;
end $$;

-- Backfill any NULLs left by an older column add (defensive — column is NOT NULL
-- with a default, but live DB may have drifted).
update public.planners set terms_variant = 'standard' where terms_variant is null;

-- 2. Seed the Premium terms content, identical to Normal ---------------------
-- Copy the current 'terms' dict into 'terms_premium'. If an admin later edits
-- Premium, this row diverges; until then the two are the same text.
insert into public.legal_docs (slug, dict, updated_by)
select 'terms_premium', dict, 'seed-premium'
from public.legal_docs
where slug = 'terms'
on conflict (slug) do nothing;

-- If the 'terms' row didn't exist yet (legal-docs.sql not run), create an empty
-- premium row so the editor + page have something to read. terms.html falls back
-- to its baked-in defaults when the dict is empty, so Normal and Premium still
-- render identically.
insert into public.legal_docs (slug, dict, updated_by)
values ('terms_premium', '{}'::jsonb, 'seed-premium')
on conflict (slug) do nothing;

-- Verify:
--   select id, name, terms_variant from public.planners order by name;
--   select slug, jsonb_typeof(dict) from public.legal_docs where slug like 'terms%';
