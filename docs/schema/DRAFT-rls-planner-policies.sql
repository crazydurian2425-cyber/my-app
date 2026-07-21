-- ============================================================================
-- ⚠️  DRAFT — DO NOT RUN AS-IS.  Review + test table-by-table first.
--
-- Purpose: close the "RLS Disabled in Public" CRITICAL findings by enabling
-- Row Level Security + adding policies that let a PLANNER touch only their own
-- data through the public/anon key, while the admin/CS/worker paths (which use
-- the service-role key via the /api/sb proxy) keep bypassing RLS untouched.
--
-- OWNERSHIP MODEL
--   • A planner's row id == auth.uid()  (the worker creates planners keyed by
--     the auth user id — see handleCreatePlanner in _worker.js).
--   • plans.planner_id, sets.planner_id, set_assignments.planner_id,
--     conversations.planner_id all reference that same id.
--   • itinerary_items → plans (plan_id) ; item_images → itinerary_items (item_id)
--   • messages → conversations (conversation_id) ; travelers ← plans (traveler_id)
--
-- ‼️  BEFORE YOU ENABLE ANYTHING — READ THE 6 CAVEATS AT THE BOTTOM.
--     Enabling RLS with wrong/missing policies makes the planner dashboard
--     return EMPTY and looks like a total outage. Roll out ONE table at a time.
-- ============================================================================


-- ── STEP 0 · INSPECT what already exists (run these SELECTs first, change nothing)
--   conversations + messages already have INERT policies ("Policy Exists RLS
--   Disabled"). See what they are before enabling, or they snap on and may be
--   wrong/too-open:
--     select schemaname, tablename, policyname, cmd, roles, qual, with_check
--       from pg_policies
--      where schemaname='public'
--        and tablename in ('conversations','messages','plans','travelers',
--                          'itinerary_items','item_images','sets','set_assignments','planners')
--      order by tablename, policyname;
--   Drop any stale ones you don't recognise BEFORE the create policy blocks below.


-- ── Supporting indexes (cheap, do first — the EXISTS policies below scan these)
create index if not exists idx_plans_planner_id       on public.plans(planner_id);
create index if not exists idx_plans_set_id           on public.plans(set_id);
create index if not exists idx_plans_traveler_id      on public.plans(traveler_id);
create index if not exists idx_items_plan_id          on public.itinerary_items(plan_id);
create index if not exists idx_item_images_item_id    on public.item_images(item_id);
create index if not exists idx_sa_planner_id          on public.set_assignments(planner_id);
create index if not exists idx_conv_planner_id        on public.conversations(planner_id);
create index if not exists idx_msg_conversation_id    on public.messages(conversation_id);


-- ══ 1 · PLANNERS ═══════════════════════════════════════════════════════════
-- Own row only. No client insert/delete (the worker creates rows).
alter table public.planners enable row level security;
create policy planners_select_own on public.planners
  for select to authenticated using (id = auth.uid());
create policy planners_update_own on public.planners
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());


-- ══ 2 · SET_ASSIGNMENTS ════════════════════════════════════════════════════
-- A planner reads + manages only their own assignment rows.
alter table public.set_assignments enable row level security;
create policy sa_planner_all on public.set_assignments
  for all to authenticated
  using      (planner_id = auth.uid())
  with check (planner_id = auth.uid());


-- ══ 3 · SETS ═══════════════════════════════════════════════════════════════
-- Sets a planner owns OR is assigned to. (If planners are meant to BROWSE
-- unclaimed sets, this needs an extra rule — see CAVEAT #3.)
alter table public.sets enable row level security;
create policy sets_planner_select on public.sets
  for select to authenticated using (
    planner_id = auth.uid()
    or exists (select 1 from public.set_assignments sa
                where sa.set_id = sets.id and sa.planner_id = auth.uid())
  );
create policy sets_planner_update on public.sets
  for update to authenticated using (
    planner_id = auth.uid()
    or exists (select 1 from public.set_assignments sa
                where sa.set_id = sets.id and sa.planner_id = auth.uid())
  ) with check (
    planner_id = auth.uid()
    or exists (select 1 from public.set_assignments sa
                where sa.set_id = sets.id and sa.planner_id = auth.uid())
  );


-- ══ 4 · PLANS ══════════════════════════════════════════════════════════════
-- Own plan copies, plus the planner_id-IS-NULL "template" rows that live in a
-- set they're assigned to (the app claims/copies these on first open).
alter table public.plans enable row level security;
create policy plans_select on public.plans
  for select to authenticated using (
    planner_id = auth.uid()
    or (planner_id is null and exists (
         select 1 from public.set_assignments sa
          where sa.set_id = plans.set_id and sa.planner_id = auth.uid()))
  );
create policy plans_insert on public.plans
  for insert to authenticated with check (planner_id = auth.uid());
create policy plans_update on public.plans
  for update to authenticated using (
    planner_id = auth.uid()
    or (planner_id is null and exists (
         select 1 from public.set_assignments sa
          where sa.set_id = plans.set_id and sa.planner_id = auth.uid()))
  ) with check (
    planner_id = auth.uid() or planner_id is null
  );
create policy plans_delete on public.plans
  for delete to authenticated using (planner_id = auth.uid());


-- ══ 5 · ITINERARY_ITEMS ════════════════════════════════════════════════════
-- Any item whose parent plan the planner owns.
alter table public.itinerary_items enable row level security;
create policy items_all on public.itinerary_items
  for all to authenticated
  using (exists (select 1 from public.plans p
                  where p.id = itinerary_items.plan_id and p.planner_id = auth.uid()))
  with check (exists (select 1 from public.plans p
                  where p.id = itinerary_items.plan_id and p.planner_id = auth.uid()));


-- ══ 6 · ITEM_IMAGES ════════════════════════════════════════════════════════
alter table public.item_images enable row level security;
create policy imgs_all on public.item_images
  for all to authenticated
  using (exists (select 1 from public.itinerary_items it
                   join public.plans p on p.id = it.plan_id
                  where it.id = item_images.item_id and p.planner_id = auth.uid()))
  with check (exists (select 1 from public.itinerary_items it
                   join public.plans p on p.id = it.plan_id
                  where it.id = item_images.item_id and p.planner_id = auth.uid()));


-- ══ 7 · TRAVELERS (read-only for planners — admin writes via proxy) ═════════
-- A planner may READ a traveler that sits on one of their plans, plus that
-- traveler's multi-leg siblings (same meta.person_id + meta.seed_batch), which
-- the dashboard fetches to show the "trip context". No planner writes.
alter table public.travelers enable row level security;
create policy travelers_select on public.travelers
  for select to authenticated using (
    exists (select 1 from public.plans p
             where p.traveler_id = travelers.id and p.planner_id = auth.uid())
    or exists (
      select 1 from public.plans p
        join public.travelers me on me.id = p.traveler_id
       where p.planner_id = auth.uid()
         and me.meta->>'person_id'  is not null
         and me.meta->>'person_id'  = travelers.meta->>'person_id'
         and me.meta->>'seed_batch' = travelers.meta->>'seed_batch')
  );


-- ══ 8 · CONVERSATIONS ══════════════════════════════════════════════════════
alter table public.conversations enable row level security;
create policy conv_all on public.conversations
  for all to authenticated
  using      (planner_id = auth.uid())
  with check (planner_id = auth.uid());


-- ══ 9 · MESSAGES ═══════════════════════════════════════════════════════════
-- Messages inside the planner's own conversation. (Planner updates read_at;
-- inserts their own chat turns.)
alter table public.messages enable row level security;
create policy msg_select on public.messages
  for select to authenticated using (
    exists (select 1 from public.conversations c
             where c.id = messages.conversation_id and c.planner_id = auth.uid()));
create policy msg_insert on public.messages
  for insert to authenticated with check (
    exists (select 1 from public.conversations c
             where c.id = messages.conversation_id and c.planner_id = auth.uid()));
create policy msg_update on public.messages
  for update to authenticated using (
    exists (select 1 from public.conversations c
             where c.id = messages.conversation_id and c.planner_id = auth.uid()))
  with check (
    exists (select 1 from public.conversations c
             where c.id = messages.conversation_id and c.planner_id = auth.uid()));


-- ============================================================================
-- ‼️  CAVEATS — verify each BEFORE rolling to production
--
-- 1. auth.uid() == planners.id ?  If ANY legacy planner row has id != their
--    auth user id, that planner gets locked out. Check:
--      select count(*) from planners p
--       where not exists (select 1 from auth.users u where u.id = p.id);
--
-- 2. anon (logged-out) role gets ZERO access (policies are `to authenticated`).
--    Confirm nothing pre-login reads these tables directly. login/forgot/reset
--    use auth endpoints (not table reads), so this should be fine — verify.
--
-- 3. Do planners BROWSE unclaimed sets (planner_id null, no assignment)? The
--    §3 sets policy only exposes owned/assigned sets. If there's a "claim a
--    set" browse screen, add a read rule for unassigned sets.
--
-- 4. REALTIME: superadmin/supercs subscribe with the DIRECT anon key (sbRT),
--    not the proxy. Realtime honours RLS, so their live feeds may go silent
--    once RLS is on. Decide: give them a service-role realtime path, or accept.
--
-- 5. TEMPLATE ITEMS: if the copy flow reads itinerary_items off a null-planner
--    template plan, §5 (owned-plan-only) will hide them. Check whether copies
--    duplicate items server-side or read template items client-side.
--
-- 6. ROLL OUT ONE TABLE AT A TIME. Suggested safe order (least → most risky):
--      conversations → messages → item_images → itinerary_items → set_assignments
--      → sets → plans → travelers → planners
--    After each `enable`, exercise the planner dashboard (open a plan, edit a
--    stop, save, chat) before moving on. `alter table X disable row level
--    security;` instantly rolls a table back if something breaks.
-- ============================================================================
