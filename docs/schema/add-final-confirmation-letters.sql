-- ============================================================================
-- Final confirmation letter — a THIRD letter_type on the existing
-- employment_letters flow, where the planner signs AND uploads an identity
-- document, then it's sent back to admin.
--
-- Builds on add-guarantee-letters.sql (letter_type + custom_body already exist).
-- This file adds:
--   • id_image_url    — path of the uploaded ID inside the PRIVATE bucket
--   • id_uploaded_at  — when the planner attached it
--   • a PRIVATE storage bucket 'letter-ids' for the ID photos
--
-- letter_type has no CHECK constraint, so 'final_confirmation' is already a
-- valid value — engagement + guarantee letters are unaffected.
--
-- SECURITY: the bucket is PRIVATE (public=false). storage.objects has RLS and
-- we add NO policies, so the anon/publishable key can neither read nor write
-- it. Only the worker's service-role key (which bypasses RLS) uploads the ID
-- (from the public sign endpoint) and downloads it for the admin console
-- through the /api/sb proxy. A planner's ID is never publicly reachable.
--
-- Additive + idempotent. Safe to run once (or again).
-- ============================================================================

alter table public.employment_letters
  add column if not exists id_image_url   text,
  add column if not exists id_uploaded_at timestamptz;

-- Private bucket for the uploaded identity documents.
insert into storage.buckets (id, name, public)
values ('letter-ids', 'letter-ids', false)
on conflict (id) do nothing;

-- Belt-and-braces: if the bucket already existed as public, force it private.
update storage.buckets set public = false where id = 'letter-ids' and public is distinct from false;

-- Verify:
--   select letter_type, count(*) from public.employment_letters group by 1;
--   select id, public from storage.buckets where id = 'letter-ids';
--   select column_name from information_schema.columns
--     where table_name='employment_letters' and column_name in ('id_image_url','id_uploaded_at');
