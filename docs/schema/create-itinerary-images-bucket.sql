-- ============================================================================
-- Create the Storage bucket the planner dashboard uploads itinerary photos to.
--
-- Symptom: photo upload fails with "Bucket not found" (400) and
--   "new row violates row-level security policy" — because the bucket
--   `itinerary-images` was never created (chat photos work because their
--   bucket `chat-media` exists).
--
-- The dashboard uploads with the anon publishable key (planners are gated by
-- jj_token, not a Supabase auth session) and displays via getPublicUrl — so the
-- bucket must be PUBLIC, with insert allowed for the anon/public role. This
-- mirrors the existing chat-media setup. Run once in the Supabase SQL editor.
-- ============================================================================

-- 1) Public bucket (idempotent)
insert into storage.buckets (id, name, public)
values ('itinerary-images', 'itinerary-images', true)
on conflict (id) do update set public = true;

-- 2) Policies on storage.objects, scoped to this bucket
drop policy if exists "itinerary-images public read"  on storage.objects;
drop policy if exists "itinerary-images upload"        on storage.objects;
drop policy if exists "itinerary-images update"        on storage.objects;
drop policy if exists "itinerary-images delete"        on storage.objects;

create policy "itinerary-images public read" on storage.objects
  for select to public using (bucket_id = 'itinerary-images');

create policy "itinerary-images upload" on storage.objects
  for insert to public with check (bucket_id = 'itinerary-images');

-- (optional) allow re-upload / cleanup of own bucket objects
create policy "itinerary-images update" on storage.objects
  for update to public using (bucket_id = 'itinerary-images');
create policy "itinerary-images delete" on storage.objects
  for delete to public using (bucket_id = 'itinerary-images');

-- Verify:
--   select id, public from storage.buckets where id = 'itinerary-images';
--   select policyname from pg_policies where tablename = 'objects'
--     and policyname like 'itinerary-images%';
