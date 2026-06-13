# Japan pivot — full France → Japan conversion (execution prompt)

> Status: **PLAN ONLY — no code until approved.**
> Supersedes the dual-market plan (`japan-market-plan.md`). This is a SINGLE
> market: the platform becomes Japan. Reverse of the original Japan→France pivot.

## Decisions (confirmed)
- **Single market: Japan.** No France, no region flag, no two domains.
- **Language: Japanese + English toggle** (default Japanese).
- **Currency: Yen (¥)** everywhere, no decimals.
- **Status: test / pre-launch** → safe to convert aggressively; reversible via git + DB backup.
- **Domain:** stays `journeyjunctionplanner.com`, now serving Japan. Brand stays "Journey Junction".

## Approach
- Fresh branch off `main` (e.g. `japan-pivot`). Direct in-place conversion (French→Japanese, €→¥, France→Japan config) — NOT the dual-market machinery.
- **Reuse** the Japanese translations already written on `japan-market` (dashboard/login/apply/forgot).
- The dual-market work (region.js, region column, parallel-track t(), login scoping) is **set aside** — not needed for one market. Simpler result.
- Take a **Supabase backup / enable PITR** before the data wipe.

## Phase 1 — Backend (data wipe + cleanup)
- **Backup first.**
- Wipe operational test data in FK-safe order (children → parents):
  `item_images → itinerary_items → plans → set_assignments → sets →
   wallet_requests / wallet_adjustments / wallet_pending_payments →
   messages → conversations → employment_letters →
   travelers → planner_applications`
- Planner accounts: **(decision)** keep one test login, or also wipe
  `planners` + their `auth.users` rows for a fully clean slate.
- Keep: schema, `platform_settings`, storage buckets.
- Optional: drop the now-unneeded `region` column (single market).
- Keep the canonical `auth.uid()` RLS policies (security) — run `rls-2-fix.sql`.

## Phase 2 — Language (French → Japanese)
- Replace French strings (currently in the `ja`/`fr` i18n slots) with **Japanese**
  on every page: dashboard, login, apply, forgot, reset, support, superadmin,
  supercs, terms, privacy, signup, sign-letter.
- Default language **Japanese**; keep **EN** toggle (flag = Japan/UK).
- Convert dynamic strings: `dt(en, fr)` → Japanese; brief/enum/cuisine maps → Japanese.
- `<html lang>` → `ja`.

## Phase 3 — Currency (€ → ¥)
- `fmtMoney` / `fmtMoneyRaw` → always ¥ (integer, comma thousands). Remove the
  French "1 000 €" suffix logic.
- Strip €/SEPA wording from labels, hints, settings chip.
- **Hardcoded amounts** (e.g. "€1,000 weekly salary") → **real yen figures** *(need from you)*.

## Phase 4 — Config / content
- Timezone `Europe/Paris` → `Asia/Tokyo`.
- Gateways Paris/Nice → **Tokyo (Narita/Haneda), Osaka (Kansai)**.
- City lists: French regions → **Japanese prefectures**.
- Hero images: France (Eiffel/Riviera) → **Japan (Fuji/Tokyo)**.
- "France" labels → "日本 / Japan". Example placeholders → Tokyo/Kyoto/Osaka.

## Phase 5 — Payouts (€/SEPA → ¥/PayPay+bank)
- Payout form: **PayPay** (phone/ID + holder) + **JP bank** (bank, branch 支店,
  account type 普通/当座, number, holder). Remove SEPA/IBAN + crypto.
- Still admin-approved (unchanged flow).

## Phase 6 — Emails
- Approval + contract emails → **Japanese**. Login/sign links stay on the domain.
- `APPROVAL_FROM` sender stays (or switch to a JP-branded address later).

## Phase 7 — Test + go live
- Test the whole flow on the local/preview build (Japanese, ¥, Tokyo, payout).
- Merge `japan-pivot` → `main` → auto-deploys to `journeyjunctionplanner.com`.
- Update Google API key referrers + Supabase redirect URLs if the domain/usage changed (already set for this domain).

## Open items to confirm before build
- [ ] Wipe planner accounts too, or keep one test login?
- [ ] Yen figures for any hardcoded amounts (weekly-salary rule, etc.).
- [ ] Keep English toggle on every page (yes, per decision) — confirm.

## Reversibility
Test data + git: fully reversible. The branch isn't merged until approved; the
data wipe is recoverable from the pre-wipe backup/PITR.
