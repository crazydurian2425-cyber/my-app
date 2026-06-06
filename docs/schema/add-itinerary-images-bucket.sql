-- ============================================================================
-- Create the `itinerary-images` storage bucket (+ policies).
--
-- Symptom: uploading a photo on an itinerary stop fails with
--   StorageApiError: Bucket not found
-- so photos never persist — neither via autosave nor on Submit. Across all
-- itinerary_items, ZERO have a saved image.
--
-- Root cause: the bucket the dashboard uploads to ('itinerary-images', see the
-- picker + submit upload paths) was never created on the live project (schema
-- drift). The CS chat works because it uses a DIFFERENT bucket, 'chat-media',
-- which does exist.
--
-- Idempotent. Run in the Supabase SQL editor.
-- ============================================================================

-- 1. Create the bucket. Public read so getPublicUrl() works in <img src>.
insert into storage.buckets (id, name, public)
values ('itinerary-images', 'itinerary-images', true)
on conflict (id) do update set public = true;

-- 2. Policies on storage.objects, scoped to this bucket (won't affect chat-media).
-- Public read (the dashboard renders images straight from the public URL).
drop policy if exists "itinerary-images read" on storage.objects;
create policy "itinerary-images read" on storage.objects
  for select using (bucket_id = 'itinerary-images');

-- Authenticated planners can upload their itinerary photos.
drop policy if exists "itinerary-images insert" on storage.objects;
create policy "itinerary-images insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'itinerary-images');

-- Tidy: let authenticated users replace / remove their own uploads.
drop policy if exists "itinerary-images update" on storage.objects;
create policy "itinerary-images update" on storage.objects
  for update to authenticated using (bucket_id = 'itinerary-images');
drop policy if exists "itinerary-images delete" on storage.objects;
create policy "itinerary-images delete" on storage.objects
  for delete to authenticated using (bucket_id = 'itinerary-images');

-- ── Verify ──────────────────────────────────────────────────────────
select id, public from storage.buckets where id = 'itinerary-images';      -- → public = true
select polname from pg_policy where polrelid = 'storage.objects'::regclass
  and polname like 'itinerary-images%' order by polname;                   -- → 4 rows
