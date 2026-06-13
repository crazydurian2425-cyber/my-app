# Japan market — deep plan

> Status: **PLAN ONLY — no code until this is approved.**
> Supersedes `japan-market-roadmap.md` (lighter draft).

## 1. The vision (confirmed)

> **TL;DR — Japan is a 1:1 clone of France.** Identical concept, identical flow,
> identical admin-approval for everything (incl. payouts). The ONLY differences
> are market-level: language (JA+EN), currency (¥), **payout method (PayPay +
> JP bank instead of SEPA/IBAN — the only net-new UI)**, region-fenced data, and
> its own domain. Nothing about *how it works* changes.

Two domains, one shared backend, full platform in both markets.

```
journeyjunctionplanner.com   →  FR + EN  ·  €  ·  France travelers ─┐
                                                                     ├─ ONE Supabase + ONE Worker
(japan domain — TBD)         →  JA + EN  ·  ¥  ·  Japan  travelers ─┘   region-fenced ('FR' | 'JP')
```

- **France domain:** French + English toggle, euros, only France travelers/planners.
- **Japan domain:** Japanese + English toggle, yen, only Japan travelers/planners.
- **Shared** Supabase + Worker + codebase. Markets kept apart by a `region` tag.
- **Scope:** everything — planner portal, traveler/public side, admin, emails, payouts.
- **Delivery:** built on a side branch, reviewed as a whole, goes live only when approved.

## 2. Can ONE backend keep France and Japan separate? Yes.

We do **not** use two databases (that would double every migration and drift —
we already fight drift on one). Instead, **logical separation** inside one
Supabase, enforced on two layers:

- **Layer 1 — every row is tagged `region` ('FR' | 'JP').** France queries ask
  for `region='FR'`, Japan for `region='JP'`. The other market's rows never come
  back.
- **Layer 2 — Row-Level Security (RLS) enforces it in the database.** Even a
  hand-crafted request can't read the other market's rows. This is what makes it
  *real* separation, not just UI hiding.

Result: behaves like two separate backends, but is one to maintain. (Note: your
live DB is already missing some RLS policies — writing these properly is part of
the work, not a checkbox.)

## 3. Architecture

```
            ┌─────────────────── ONE Cloudflare Worker (_worker.js) ───────────────────┐
 host =  ───┤  reads request host → 'FR' | 'JP'  (only matters server-side, for emails) │
            └───────────────┬───────────────────────────────────────────────────────────┘
                            │ serves the SAME static files to both domains
                            ▼
        dashboard.html / login / signup / apply / admin   (each reads its own hostname → market)
                            │
                            ▼
            ┌──────────────── ONE Supabase ────────────────┐
            │  planners / travelers / sets / plans / …       │
            │  every market-anchored row carries `region`    │
            │  RLS fences FR ⟷ JP                            │
            └────────────────────────────────────────────────┘
```

The page decides its **look** (language, currency, branding) from its own
hostname. The database decides what data is **reachable** from the stored
`region` + RLS. Look vs. access are separate on purpose.

## 4. Data layer — the separation model

> **`region` = the trip's DESTINATION market (which country is visited), NOT the
> traveler's nationality.** Japan travelers come from all over the world and
> visit Japan, so a traveler from the US on a Japan trip is `region='JP'`. The
> traveler's own language is a separate field (`language_pref`).

**Add `region` ('FR' | 'JP', default 'FR') to:**
- `planners`, `planner_applications`, `travelers` (the market anchors)
- `sets`, `plans` (denormalised copy, so admin + RLS can filter market without
  multi-table joins)

**Backfill:** every existing row → `'FR'` (current data is the France market).

**RLS policies (the important part):**
- A planner reads only their *own* rows (already true today via `planner_id`)
  **and** only within their region.
- Admin/CS (service-role via the `/api/sb` proxy) can see both, but the admin UI
  filters by a chosen market.
- Assignment guard: a planner can only be assigned travelers/sets of the **same**
  region.

**Login scoping:** a France account can't log into the Japan domain and vice
versa — the login checks the planner's `region` against the domain's region.

## 5. What changes, surface by surface (the "Everything")

### A. Market detection (foundation)
- A small shared `region.js`: hostname → `region` + a per-region config
  (locale, currency, currency symbol, timezone, gateways). One source of truth.
- A preview override (`?market=JP`) so the JP experience can be reviewed before
  the domain exists.

### B. Planner portal (`dashboard.html`)
- Currency: route all money through the existing `fmtMoney` chokepoint → ¥ for JP
  (yen, no decimals; no currency conversion — JP rows store yen natively).
- Timezone: `Asia/Tokyo` vs `Europe/Paris` for any time display.
- Hero label / gateways / placeholders: from region config, not hardcoded
  ("FRANCE" → "JAPAN / 日本", "Paris, Lyon" → "Tokyo, Kyoto, Osaka").
- Language: add a Japanese (`ja`) pack to the existing FR/EN i18n dictionary.
- Language toggle: shows **FR+EN** on the France domain, **JA+EN** on Japan.
- Data queries: filtered by region (backed by RLS).

### C. Public / traveler-facing pages (`apply`, `login`, `signup`, landing)
- **Two audiences on the Japan domain, different language defaults:**
  - *Planners* (local Japanese experts) → **Japanese default + EN toggle**
    (login, apply, dashboard).
  - *Travelers* (international tourists, from anywhere, visiting Japan) →
    **English-primary** (or the traveler's `language_pref`).
- So the **JA pack is mainly planner + admin-facing**; traveler-facing output
  stays English-centric — same as France's international travelers.
- `apply` / `signup` **stamp the new row's `region`** from the domain it came
  through (apply on the Japan domain → `region='JP'`).
- Branding/marketing copy per market (not just translation — distinct audience).

### D. Admin (`superadmin999.html`)
- Market switcher (FR / JP) to triage applications, planners, sets, plans.
- Region-aware approval + contract emails: Japanese text, yen, and the Japan
  login URL. `JJ_PLANNER_URL` becomes a per-region lookup, not one constant.

### E. Emails
- Language, currency, logo, and login/sign links all chosen by the **planner's
  stored region** (data-driven, since emails are sent server-side).

### F. Payouts (region-aware payout profile)
- France keeps **SEPA / IBAN**. Japan uses **PayPay** or **Japanese bank
  transfer** — **no crypto**.
- The payout profile form becomes region-aware: FR shows IBAN/SWIFT; JP shows
  **PayPay ID / phone** + **JP bank fields** (bank 銀行, branch 支店, account
  type, number, holder). SWIFT is not used for domestic JP payouts.
- Payouts today appear **admin-processed (manual)** — admin marks a wallet
  request paid — so Japan needs the right **fields + form**, not a new payment
  API/integration. *(To confirm: payouts are manual today, correct?)*

### G. Domain + infra (go-live)
- Register the Japan domain; add it as a Custom Domain on the same Worker.
- Add it to the Google Maps API key referrers + Supabase Auth redirect URLs.

## 6. Language strategy

Three packs total — **FR, EN, JA**. EN is translated once and shared.

| Domain | Default | Toggle | Never shows |
|--------|---------|--------|-------------|
| France | French   | FR ⇄ EN | Japanese |
| Japan  | Japanese | JA ⇄ EN | French   |

## 7. Build & review approach

- All work on a branch (e.g. `japan-market`) — **nothing touches the live site**
  until you approve.
- You review the whole Japan experience at once, via the `?market=JP` preview on
  a non-production deployment (or locally).
- Merge → go live only when you're happy.
- The DB migration is the one piece that must run on the shared Supabase before
  testing; it is additive and invisible to France (everything stays `'FR'`).

## 8. Decisions

- [x] **Japan payouts** — PayPay or JP bank transfer, **no crypto**. ✓
- [x] **Travelers** — international visitors to Japan; traveler-facing content is
      English-primary, JA is for planners/admin. ✓
- [ ] **Japan domain name** (register only when ready; needed at go-live).
- [x] **Payouts are manual / admin-approved** (like France) — no payment API. ✓
- [x] **Traveler-facing scope = whatever France already does** (Japan mirrors it
      exactly). No France-vs-Japan difference in concept. ✓
- [ ] **Japan domain name** (register only at go-live).
- [ ] **Japan gateway cities** (e.g. Tokyo Narita/Haneda, Osaka Kansai) — easy default.
- [ ] Keep or drop the inert `region` column from the earlier attempt.

## 9. Risks / gotchas

- **JPY has no decimals** (¥1,500, not ¥1,500.00) — formatting + any math.
- **France-pivot leftovers** — gateway cities, "arrive ~14:00", `Europe/Paris`
  are baked in from the pivot; making them region-aware is more than translation.
- **RLS gaps on the live DB** — must be written carefully; partly missing today.
- **Payouts** — the one piece that is genuinely new, not "same engine, new data."

## 10. Suggested build order (inside the branch)

1. Data layer + RLS (region tags, backfill, fences, login scoping).
2. Market detection (`region.js`) + preview override.
3. Planner portal: currency → timezone/gateways → JA language.
4. Public pages: JA + region-stamping on apply/signup.
5. Admin: market switcher + region-aware emails.
6. Payouts: JP rail.
7. Go-live: domain + Google key + Supabase URLs.

Each step is reviewable; nothing ships to the live site until the whole is
approved and merged.
