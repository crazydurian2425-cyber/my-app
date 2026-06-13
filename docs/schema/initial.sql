-- ============================================================================
-- Journey Junction — initial schema scaffold for Supabase project
-- hjchyqafkpbryzlqhpxc
--
-- Run this in: Supabase Dashboard → SQL Editor → New query → paste → Run.
-- Sections are independent — if one fails, fix and re-run only that section.
-- Idempotent: uses `if not exists` and `or replace` so re-running is safe.
--
-- After running this:
--   1. Verify in Table Editor that the tables appeared
--   2. Insert your own planner row (see SECTION 8 at the bottom)
--   3. Log in via /login.html with the same email
-- ============================================================================


-- ============================================================================
-- SECTION 1 — Extensions
-- ============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";


-- ============================================================================
-- SECTION 2 — Enum-like check values are inlined as CHECK constraints below
-- (avoids the hassle of altering enum types when you want to add a value).
-- ============================================================================


-- ============================================================================
-- SECTION 3 — Core tables
-- ============================================================================

-- planners ---------------------------------------------------------------
-- Each row corresponds 1:1 with an auth.users row. Login flow looks up the
-- planner row by auth uid; status='suspended' blocks login.
create table if not exists public.planners (
  id                  uuid primary key references auth.users(id) on delete cascade,
  name                text not null,
  email               text not null unique,
  phone               text,
  city                text not null default 'Tokyo',
  status              text not null default 'active'
                      check (status in ('active','suspended','pending')),
  is_subaccount       boolean not null default false,
  admin_created       boolean not null default false,
  -- soft profile fields the dashboard updates on first save:
  bank_name           text,
  bank_account_name   text,
  bank_account_no     text,
  bank_swift          text,
  paypal_email        text,
  payout_method       text,
  -- fraud / audit
  last_login_ip       text,
  last_login_country  text,
  last_login_city     text,
  last_login_at       timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- planner_applications --------------------------------------------------
-- Used by /apply.html (the public application form). Login.html queries
-- this on the "no planner row" branch to give a friendlier error.
create table if not exists public.planner_applications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,
  name        text not null,
  email       text not null,
  phone       text,
  city        text,
  bio         text,
  status      text not null default 'pending'
              check (status in ('pending','approved','rejected')),
  reviewed_by text,
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);


-- ============================================================================
-- SECTION 4 — Booking + plan tables
-- ============================================================================

-- travelers --------------------------------------------------------------
-- A traveler is the person who bought a plan. One traveler can produce N
-- plans (3D2N = 1 plan, sometimes split). Stored fields are mostly metadata
-- the planner sees while building the itinerary.
create table if not exists public.travelers (
  id              uuid primary key default gen_random_uuid(),
  name            text,
  name_ja         text,
  email           text,
  phone           text,
  -- trip basics
  destination     text,            -- 'Tokyo', 'Osaka', etc. Used by Places bias.
  arrival_date    date,
  arrival_time    text,            -- 'HH:MM' string for the time picker UI
  departure_date  date,
  departure_time  text,
  duration        text,            -- '3D2N', '5D4N', etc.
  group_size      int default 1,
  traveler_type   text,            -- 'family', 'couple', 'solo', 'corporate', etc.
  -- commercial
  planner_payout  numeric(10,2),
  bond_amount     numeric(10,2),
  requires_bond   boolean not null default false,
  -- planner-facing notes
  special_notes      text,
  special_notes_ja   text,
  language_pref      text default 'ja',
  created_at         timestamptz not null default now()
);

-- sets -------------------------------------------------------------------
-- A "set" groups N plans for one traveler (a 7D6N trip might be one set of
-- 2-3 plans handled by the same planner). For the autocomplete test you can
-- mostly ignore this — dashboard.html will just show "no sets".
create table if not exists public.sets (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid references public.planners(id) on delete set null,
  status      text not null default 'in_progress'
              check (status in ('in_progress','paid','completed','cancelled','submitted')),
  paid_at     timestamptz,
  completed_at timestamptz,
  created_at  timestamptz not null default now()
);

-- set_assignments --------------------------------------------------------
-- A planner is assigned to a set with a per-set status. Same planner can
-- have many open assignments, hence a separate join row.
create table if not exists public.set_assignments (
  id           uuid primary key default gen_random_uuid(),
  set_id       uuid references public.sets(id) on delete cascade,
  planner_id   uuid references public.planners(id) on delete cascade,
  status       text not null default 'in_progress'
               check (status in ('in_progress','paid','completed','cancelled','submitted')),
  paid_at      timestamptz,
  completed_at timestamptz,
  created_at   timestamptz not null default now(),
  unique (set_id, planner_id)
);

-- plans ------------------------------------------------------------------
-- Each plan = one itinerary the planner builds. plan_number orders the
-- plans within a set (Plan 1, Plan 2, ...). status drives the dashboard UI
-- (pending → in_progress → submitted → approved/revision → completed).
create table if not exists public.plans (
  id                       uuid primary key default gen_random_uuid(),
  set_id                   uuid references public.sets(id) on delete cascade,
  planner_id               uuid references public.planners(id) on delete set null,
  traveler_id              uuid references public.travelers(id) on delete set null,
  plan_number              int not null default 1,
  status                   text not null default 'pending'
                           check (status in ('pending','in_progress','submitted','revision','approved','bond_pending','completed','cancelled')),
  -- itinerary body
  itin_title               text,
  start_date               date,
  end_date                 date,
  arrival_date_snapshot    date,         -- frozen copy of traveler.arrival_date at assignment time
  transport_tips           text,
  spend_breakdown          text,
  local_tips               text,
  -- workflow
  submitted_at             timestamptz,
  admin_notes              text,
  -- per-plan commercial overrides (NULL = use traveler defaults)
  planner_payout_override  numeric(10,2),
  bond_amount_override     numeric(10,2),
  requires_bond_override   boolean,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);


-- ============================================================================
-- SECTION 5 — Itinerary items (this is where the autocomplete writes!)
-- ============================================================================

-- itinerary_items --------------------------------------------------------
-- Each row = one "slot" in the planner's itinerary builder (Activity, Meal,
-- Transport, Accommodation, or Free time). Google Places columns are
-- nullable so manual entries continue to work.
create table if not exists public.itinerary_items (
  id                  uuid primary key default gen_random_uuid(),
  plan_id             uuid not null references public.plans(id) on delete cascade,
  day_number          int  not null default 1,
  time                text,
  type                text not null default 'activity'
                      check (type in ('activity','meal','transport','accommodation','freetime')),
  title               text not null,
  address             text,
  duration_minutes    int,
  notes               text,
  sort_order          int not null default 0,

  -- Google Places metadata (nullable — populated when planner picks via autocomplete)
  google_place_id     text,
  latitude            numeric(9,6),
  longitude           numeric(9,6),
  rating              numeric(2,1),
  user_rating_count   int,
  price_level         text,
  phone               text,
  website             text,
  google_maps_url     text,
  opening_hours_json  jsonb,
  photo_refs          jsonb,
  place_types         jsonb,
  places_synced_at    timestamptz,

  created_at          timestamptz not null default now()
);

-- item_images ------------------------------------------------------------
-- Planner-uploaded photos for an itinerary item. Path is the key inside
-- the `itinerary-images` storage bucket (see SECTION 9).
create table if not exists public.item_images (
  id            uuid primary key default gen_random_uuid(),
  item_id       uuid not null references public.itinerary_items(id) on delete cascade,
  url           text not null,
  storage_path  text,
  created_at    timestamptz not null default now()
);


-- ============================================================================
-- SECTION 6 — Stub tables (kept minimal so dashboard.html doesn't error out
-- on queries against missing tables). Build out later as you wire features.
-- ============================================================================

create table if not exists public.conversations (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid references public.planners(id) on delete cascade,
  set_id      uuid references public.sets(id) on delete cascade,
  created_at  timestamptz not null default now()
);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender          text not null,       -- 'planner' | 'admin' | 'cs'
  body            text,
  attachment_url  text,
  created_at      timestamptz not null default now()
);

create table if not exists public.wallet_requests (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid not null references public.planners(id) on delete cascade,
  amount      numeric(10,2) not null,
  status      text not null default 'pending'
              check (status in ('pending','approved','rejected','paid')),
  created_at  timestamptz not null default now()
);

create table if not exists public.wallet_adjustments (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid not null references public.planners(id) on delete cascade,
  amount      numeric(10,2) not null,   -- positive = credit, negative = debit
  reason      text,
  created_by  text,
  created_at  timestamptz not null default now()
);

create table if not exists public.wallet_pending_payments (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid not null references public.planners(id) on delete cascade,
  amount      numeric(10,2) not null,
  source      text,
  created_at  timestamptz not null default now()
);

create table if not exists public.platform_settings (
  key         text primary key,
  value       jsonb,
  updated_at  timestamptz not null default now()
);

-- employment_letters -----------------------------------------------------
-- Used by /api/send-employment-letter + /sign-letter.html. Token = single
-- secret link the planner clicks to sign.
create table if not exists public.employment_letters (
  id                  uuid primary key default gen_random_uuid(),
  planner_id          uuid references public.planners(id) on delete set null,
  planner_name        text not null,
  planner_email       text not null,
  start_date          date not null,
  signing_token       text not null unique default replace(gen_random_uuid()::text, '-', ''),
  status              text not null default 'pending'
                      check (status in ('pending','signed','cancelled')),
  signed_at           timestamptz,
  signature_image_url text,
  signed_user_agent   text,
  signed_ip           text,
  created_by          text,
  created_at          timestamptz not null default now()
);


-- ============================================================================
-- SECTION 7 — Indexes (speed up the queries dashboard.html actually runs)
-- ============================================================================

create index if not exists planners_email_idx               on public.planners(email);
create index if not exists planners_status_idx              on public.planners(status);
create index if not exists plans_planner_id_idx             on public.plans(planner_id);
create index if not exists plans_set_id_idx                 on public.plans(set_id);
create index if not exists set_assignments_planner_id_idx   on public.set_assignments(planner_id);
create index if not exists itinerary_items_plan_id_idx      on public.itinerary_items(plan_id);
create index if not exists itinerary_items_place_id_idx     on public.itinerary_items(google_place_id) where google_place_id is not null;
create index if not exists item_images_item_id_idx          on public.item_images(item_id);
create index if not exists messages_conversation_id_idx     on public.messages(conversation_id);


-- ============================================================================
-- SECTION 8 — Row Level Security (RLS)
-- Planner-facing pages use the anon key + Supabase JS client. Each request
-- carries the planner's JWT, so auth.uid() resolves to their user UUID.
-- Without RLS, anon key would expose every planner's rows to every other
-- planner. Admin/CS pages bypass RLS via the service-role key behind the
-- /api/sb worker proxy.
-- ============================================================================

alter table public.planners               enable row level security;
alter table public.planner_applications   enable row level security;
alter table public.travelers              enable row level security;
alter table public.sets                   enable row level security;
alter table public.set_assignments        enable row level security;
alter table public.plans                  enable row level security;
alter table public.itinerary_items        enable row level security;
alter table public.item_images            enable row level security;
alter table public.conversations          enable row level security;
alter table public.messages               enable row level security;
alter table public.wallet_requests        enable row level security;
alter table public.wallet_adjustments     enable row level security;
alter table public.wallet_pending_payments enable row level security;
alter table public.platform_settings      enable row level security;
alter table public.employment_letters     enable row level security;

-- planners: read + update own row
drop policy if exists "planners self read"   on public.planners;
drop policy if exists "planners self update" on public.planners;
create policy "planners self read"   on public.planners for select using (auth.uid() = id);
create policy "planners self update" on public.planners for update using (auth.uid() = id);

-- travelers: planners can read travelers attached to their own plans
drop policy if exists "travelers via own plans" on public.travelers;
create policy "travelers via own plans" on public.travelers
  for select using (
    exists (select 1 from public.plans p where p.traveler_id = travelers.id and p.planner_id = auth.uid())
  );

-- sets: read sets the planner is assigned to
drop policy if exists "sets own" on public.sets;
create policy "sets own" on public.sets for select using (
  planner_id = auth.uid()
  or exists (select 1 from public.set_assignments sa where sa.set_id = sets.id and sa.planner_id = auth.uid())
);

-- set_assignments: planner's own assignments
drop policy if exists "set_assignments own" on public.set_assignments;
create policy "set_assignments own" on public.set_assignments for all using (planner_id = auth.uid());

-- plans: full CRUD on own plans
drop policy if exists "plans own" on public.plans;
create policy "plans own" on public.plans for all using (planner_id = auth.uid());

-- itinerary_items: planner can CRUD items on their own plans
drop policy if exists "itinerary_items via own plan" on public.itinerary_items;
create policy "itinerary_items via own plan" on public.itinerary_items for all using (
  exists (select 1 from public.plans p where p.id = itinerary_items.plan_id and p.planner_id = auth.uid())
);

-- item_images: planner can CRUD images on their own items
drop policy if exists "item_images via own item" on public.item_images;
create policy "item_images via own item" on public.item_images for all using (
  exists (
    select 1 from public.itinerary_items i
    join public.plans p on p.id = i.plan_id
    where i.id = item_images.item_id and p.planner_id = auth.uid()
  )
);

-- conversations + messages
drop policy if exists "conversations own" on public.conversations;
create policy "conversations own" on public.conversations for all using (planner_id = auth.uid());
drop policy if exists "messages via own conv" on public.messages;
create policy "messages via own conv" on public.messages for all using (
  exists (select 1 from public.conversations c where c.id = messages.conversation_id and c.planner_id = auth.uid())
);

-- wallet_* — planner can read their own, writes via admin (service role bypasses RLS)
drop policy if exists "wallet_requests own"        on public.wallet_requests;
drop policy if exists "wallet_adjustments own"     on public.wallet_adjustments;
drop policy if exists "wallet_pending_payments own" on public.wallet_pending_payments;
create policy "wallet_requests own"         on public.wallet_requests         for select using (planner_id = auth.uid());
create policy "wallet_adjustments own"      on public.wallet_adjustments      for select using (planner_id = auth.uid());
create policy "wallet_pending_payments own" on public.wallet_pending_payments for select using (planner_id = auth.uid());
-- Planners can also insert wallet_requests for themselves (the "request payout" button)
drop policy if exists "wallet_requests self insert" on public.wallet_requests;
create policy "wallet_requests self insert" on public.wallet_requests for insert with check (planner_id = auth.uid());

-- planner_applications — anyone can insert (public apply form), nobody reads (admin only via service role)
drop policy if exists "applications public insert" on public.planner_applications;
create policy "applications public insert" on public.planner_applications for insert with check (true);

-- platform_settings — readable to authenticated planners (anon side)
drop policy if exists "platform_settings read" on public.platform_settings;
create policy "platform_settings read" on public.platform_settings for select using (true);

-- employment_letters — admin-only (service role bypasses RLS, no public policy)
-- (No SELECT policy => no anon-side access. Worker /api/letter uses service role.)


-- ============================================================================
-- SECTION 9 — Storage bucket for itinerary photos
-- Run this AFTER the table block above. If the bucket already exists this is
-- a no-op.
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('itinerary-images', 'itinerary-images', true)
on conflict (id) do nothing;

-- Storage policies: planners can upload + read their own uploads, anyone can
-- read (bucket is public — public URL is how images appear in the itinerary).
drop policy if exists "itinerary-images public read"  on storage.objects;
drop policy if exists "itinerary-images planner write" on storage.objects;
create policy "itinerary-images public read"
  on storage.objects for select using (bucket_id = 'itinerary-images');
create policy "itinerary-images planner write"
  on storage.objects for insert with check (bucket_id = 'itinerary-images' and auth.role() = 'authenticated');
create policy "itinerary-images planner update"
  on storage.objects for update using (bucket_id = 'itinerary-images' and auth.role() = 'authenticated');
create policy "itinerary-images planner delete"
  on storage.objects for delete using (bucket_id = 'itinerary-images' and auth.role() = 'authenticated');

-- Also need a bucket for the engagement-letter signature uploads
insert into storage.buckets (id, name, public)
values ('employment-letter-signatures', 'employment-letter-signatures', true)
on conflict (id) do nothing;
drop policy if exists "letter-sig public read" on storage.objects;
create policy "letter-sig public read"
  on storage.objects for select using (bucket_id = 'employment-letter-signatures');


-- ============================================================================
-- SECTION 10 — Seed your planner row
-- This makes ben1000@gmail.com able to log in.
-- 1) Confirms the email (so login.html doesn't reject with "Email not confirmed")
-- 2) Inserts a matching planners row using the SAME uuid as auth.users.id
-- ============================================================================

update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, now())
where email = 'ben1000@gmail.com';

insert into public.planners (id, name, email, city, status)
select id, 'Ben', email, 'Tokyo', 'active'
from auth.users
where email = 'ben1000@gmail.com'
on conflict (id) do nothing;


-- ============================================================================
-- DONE.
-- Try logging in at https://my-app.shinsenna2023.workers.dev/login.html
-- with ben1000@gmail.com + whatever password you set during signup.
-- ============================================================================
