-- ============================================================================
-- Create the Storage bucket chat attachments upload to.
--
-- Symptom: sending an image in chat (CS console, planner dashboard, or the
--   support page) fails with "Upload failed: Bucket not found" — because the
--   bucket `chat-media` does not exist in this Supabase project.
--
-- All three surfaces upload via sb.storage.from('chat-media') with the anon
-- publishable key and display via the public URL, so the bucket must be PUBLIC
-- with insert allowed for the anon/public role. Mirrors the itinerary-images
-- setup. Run once in the Supabase SQL editor. Idempotent.
-- ============================================================================

-- 1) Public bucket (idempotent)
insert into storage.buckets (id, name, public)
values ('chat-media', 'chat-media', true)
on conflict (id) do update set public = true;

-- 2) Policies on storage.objects, scoped to this bucket
drop policy if exists "chat-media public read" on storage.objects;
drop policy if exists "chat-media upload"      on storage.objects;
drop policy if exists "chat-media update"      on storage.objects;
drop policy if exists "chat-media delete"      on storage.objects;

create policy "chat-media public read" on storage.objects
  for select to public using (bucket_id = 'chat-media');

create policy "chat-media upload" on storage.objects
  for insert to public with check (bucket_id = 'chat-media');

-- allow re-upload / cleanup (CS console removes old attachments on delete)
create policy "chat-media update" on storage.objects
  for update to public using (bucket_id = 'chat-media');
create policy "chat-media delete" on storage.objects
  for delete to public using (bucket_id = 'chat-media');

-- Verify:
--   select id, public from storage.buckets where id = 'chat-media';
--   select policyname from pg_policies where tablename = 'objects'
--     and policyname like 'chat-media%';
