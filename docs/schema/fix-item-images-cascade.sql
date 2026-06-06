-- ============================================================================
-- Restore ON DELETE CASCADE on item_images.item_id → itinerary_items(id).
--
-- Symptom: autosave (and Submit) logs a 409 Conflict + Postgres 23503:
--   update or delete on table "itinerary_items" violates foreign key
--   constraint "item_images_item_id_fkey" on table "item_images"
-- Result: stale itinerary_items rows that have a photo can't be deleted, so they
-- linger → DUPLICATE stops accumulate in the plan on each save.
--
-- Root cause: the live FK is RESTRICT, but initial.sql (line 221) always
-- declared it `on delete cascade`. Schema drift. The dashboard's save logic
-- assumes deleting an itinerary_item also removes its item_images — true only
-- under CASCADE. Cascade deletes also bypass child-table RLS, so the planner's
-- own delete of an itinerary_item cleanly removes its images.
--
-- Idempotent. Run in the Supabase SQL editor.
-- ============================================================================

alter table public.item_images
  drop constraint if exists item_images_item_id_fkey;

alter table public.item_images
  add constraint item_images_item_id_fkey
  foreign key (item_id) references public.itinerary_items(id) on delete cascade;

-- ── Verify ──────────────────────────────────────────────────────────
-- confdeltype 'c' = CASCADE (was 'r' = RESTRICT / 'a' = NO ACTION before).
select conname, confdeltype
from   pg_constraint
where  conrelid = 'public.item_images'::regclass
  and  conname  = 'item_images_item_id_fkey';
-- → confdeltype = c
