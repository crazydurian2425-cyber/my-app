# Execution Prompt — Convert Journey Junction Planner Platform from France/French/EUR to Japan/Japanese/JPY

You are converting the Journey Junction planner platform (`c:/Users/user/my-app`) from **France / French / euro** to **Japan / Japanese / yen**. The ENTIRE user-facing UI must end up in **Japanese** (every label, dashboard, admin console, CS console, public/legal pages, CS quick-reply chips, emails, and contract). Currency becomes **Japanese yen (¥, no decimals)**. **No France-specific content may remain** anywhere (cities, gateways, transport vocab, SEPA/IBAN, France imagery, France legal/company copy).

> **PRIME DIRECTIVE — KEEP ALL FUNCTIONS EXACTLY AS THEY ARE.** Do not change logic, data flow, DB schema, API contracts, validation, autosave, wallet math operations, realtime, the `/api/sb` proxy, or any behavior. You are ONLY changing user-facing language, currency display, locale, content strings, and a handful of hardcoded business-knob *amounts* (re-scaled — see Currency §). When in doubt, change the string, not the code path.

## Key architecture fact you MUST internalize before editing
The codebase is bilingual **EN ↔ FR**, but FR is stored under the language key **`ja`** (a legacy label from an earlier Japan→France pivot). So today:
- `TM_I18N.en` = English, `TM_I18N.ja` = **French** (NOT Japanese).
- `dt(en, fr)` and `isPlannerFR()` serve French when `TM_LANG === 'ja'`.
- `fmtMoney()` already has a live `¥` path; the euro path below it is dead code.

The conversion strategy is to **repurpose the `ja` key to hold real Japanese** (so you do NOT have to touch the ~43 `=== 'ja'` / `isPlannerFR` call-sites or the DB `lang` column). You translate the *contents* of every `ja` slot from French → Japanese, flip default-language and `lang`-attribute logic, remove France content, and re-scale yen amounts. **Do NOT introduce a third language code.** Keep exactly two: `en` (secondary) and `ja` (now = Japanese, primary/default).

---

## SECTION 1 — Language & i18n (make the whole UI Japanese, JP default)

### 1.1 Repurpose the `ja` dictionary slot → Japanese (do NOT rename the key)
- `dashboard.html` `const TM_I18N` spans **8197–8943 = `en`** (keep English as-is) and **8944 onward = `ja`** (currently French). Translate **every value** in the `ja` block from French to Japanese. ~490+ keys: `sidebar.*`, `nav.*`, `dash.*`, `itin.*`, `chip.*`, `tip.*`, `spend.*`, `deposit.*`, `pr.*`, `wallet.*`, `walletSnap.*`, `settings.*`, `profile.*`, `rules.*`, `slot.*`, `plan.*`. Update the `// NOTE: key is still 'ja'…` comment (8944–8947) to say it now holds Japanese.
- Update the **`en` dictionary** ONLY where it contains France-specific examples/symbols (€, IBAN/BIC, SEPA, city examples, transport vocab) — see Currency & France sections.

### 1.2 Default language + reset flag (`TM_LANG` init)
- `dashboard.html:9656` `let TM_LANG = (localStorage.getItem('jj_planner_lang') || 'ja')` — already defaults `ja`; KEEP.
- `dashboard.html:9650–9655` `jj_lang_resetv2` block wipes saved `jj_planner_lang`. Bump to `jj_lang_resetv3` and REMOVE the `localStorage.removeItem('jj_planner_lang')` so saved `ja` survives. Same in `apply.html:806–808`, `login.html ~769–771`, `signup.html ~543–545`, `forgot.html ~425–427`.
- Visitor auth pages default **`fr`** and support only `en`/`fr`: `apply.html:811–812` (`|| 'fr'`, `!== 'fr'`), `:822,825` `applyLang`. Change ALL `'fr'`→`'ja'` (value space → `en`/`ja`, default `ja`). Same in `login.html`, `signup.html`, `forgot.html`, `reset.html`. `terms.html`/`privacy.html` already default `ja` — keep, translate content.

### 1.3 HTML `lang` attribute (activates Noto JP fonts)
- `dashboard.html:9769` `document.documentElement.lang = (lang === 'ja') ? 'fr' : 'en'` → change `'fr'`→`'ja'`. The `html[lang="ja"]` Noto Sans JP / Noto Serif JP stack is already wired everywhere.
- Same `? 'fr' : 'en'` → `? 'ja' : 'en'` in `apply.html:825` + `applyLang` in `login.html`, `signup.html`, `forgot.html`, `support.html`, `terms.html`, `privacy.html`.

### 1.4 `dt()` helper + its three lookup objects
- `dashboard.html:9687–9688`: KEEP `isPlannerFR()` / `dt(en, fr)` names+signatures (264 call-sites). Translate the DATA they read:
  - `BRIEF_LABEL_FR` (9692–9705) — labels → Japanese (`'Trip basics':'旅行の基本'`, `'Accommodation':'宿泊'`, `'Food & dining':'食事'`).
  - `ENUM_FR` (9708–9725) — enums → Japanese; replace France-flavored interest tags (lavender_fields→'花畑', cellar_tours→'酒蔵見学') keeping keys.
  - `CUISINE_FR` (9729–9752) — currently 100% French (bouchons, bouillabaisse, loire wines, niçoise…). **Replace whole set** with Japanese cuisine: ラーメン, 寿司, 天ぷら, 懐石, 居酒屋, 焼き鳥, 日本酒バー, 屋台, コンビニ飯, 和牛, そば/うどん. Keep lookup keyed by lowercased English source so `localizeCuisineCsv()` (9755–9763) + the `NO ` negative-marker handling still work.

### 1.5 Transport vocabulary (France rail → Japan rail)
- `TM_I18N.ja` (~9214–9225): `chip.rail` 'Métro/RER'→'JR/地下鉄'; `chip.shinkansen` 'TGV'→'新幹線'; `chip.taxi`→'タクシー'; `chip.walking` 'À pied'→'徒歩'; `chip.airport`→'空港'; `chip.parking`→'駐車場'; and the `*Text` variants (keep emoji).
- `TM_I18N.en`: `Métro/RER`→`JR / Metro`, `TGV`→`Shinkansen` (+ `*Text`).

### 1.6 Language toggle → JP-only (remove the toggle)
- Remove the EN/語 toggle buttons: `dashboard.html:7160` (`.sb-lang-btn`) + `:7751` (`.settings-lang-btn`) and the settings "Display & Language" row. Leave `applyLang`/`setLang` functions intact; just don't expose the switch. (apply/login/signup/support have no toggle — fine.)

### 1.7 Per-page i18n dictionaries
- `support.html` `SUP_I18N`: `en` ~558–610, **`ja` ~611–664 is French (102 keys)** → translate all (`sup.*`, `prefill.*` 638–642, `sup.faq.*` 612–637, `sup.tips.*` 660–663). `SUP_LANG` defaults `ja` (666) — keep.
- `login.html` `AUTH_I18N` (74 keys), `signup.html` (38), `apply.html` `APPLY_I18N` (150), `forgot.html`, `reset.html`: French is under the **`fr`** key. Per §1.2, **rename the `fr:` block to `ja:`** in each and translate French→Japanese. Update placeholders (phone/IBAN/cities).
- `privacy.html` (158–297) + `terms.html`: already default `ja` → translate the `ja` slot (legal — see §3.5).

### 1.8 Date/number locale calls
- `support.html:756` `fullTime()` JA path → `'ja-JP'`. `supercs999.html` `fullTime()` ~994, snoozed ~1314, notes ~1611: `'en-GB'`→`'ja-JP'` on JA path. `_worker.js:670` signed-date → `'ja-JP'`. `sign-letter.html` `'fr-FR'` (~342–343, 356) → `'ja-JP'`.

---

## SECTION 2 — Currency (EUR → JPY, ¥, no decimals)

> **Conversion anchor: 1 EUR = 183 JPY (owner-confirmed).** Apply to all re-scaled amounts; figures below are owner-set defaults.

### 2.1 Formatters — already yen
- `dashboard.html:9954–9958 fmtMoney()` and `9960–9964 fmtMoneyRaw()` already `return '¥' + n.toLocaleString('en-GB')` on the FIRST line; the euro `return` below is unreachable. **Delete the dead euro return** in each (and unused `_isFrMoney()` at 9953 if nothing else uses it). Keep `'en-GB'` grouping (`¥1,234`, no decimals). Do NOT switch money grouping to `'ja-JP'`.

### 2.2 Re-scaled business-knob amounts (LOGIC values, not just strings)
- **Weekly salary** €1,000 → **¥183,000**: `superadmin999.html:4553 WEEKLY_SALARY_AMOUNT = 1000`→`183000` (also drives "Pay €…" buttons 4673/4788 + total 4677 — fix `€`→`¥`, `.toLocaleString('en-GB')`). i18n: `walletSnap.weeklyRule` (en 8313 / ja 9052); `terms.html s4.pW` (en 264 / ja 324) + copy 180; `support.html sup.faq.aW` (en 594 / ja 647) + copy 475; `sign-letter.html ~114`.
- **Protection buffer** €200/€500: `FIRST_PAYOUT_RETENTION_MIN` default `dashboard.html:10298 = 200`→**36600** (200×183); overridable via `platform_settings.first_payout_retention_min` (loaded 10310) — update seed too. "€500 safety buffer" copy (7513, profile/walletSnap) → `¥91,500`. Dynamic displays (10688/10715/10795/10799) use `fmtMoney()` → auto-¥.
- **Large-payout deposit** (`terms.html`): €10,000→**¥1,830,000**, €4,000→**¥732,000** (copy 184, `s4.p4` en 268 / ja 328).
- **Commission/splurge** (`dashboard.html`): `splurgeAmountForTier` (12722–12723) `{150,300,600}`→`{27000,55000,110000}` (×183, rounded to clean ¥1,000); `baseCommissionForDuration` (12726–12731) `40`/`30`→`7300`/`5500` (×183, rounded). Update EUR comments (12720/12725).

### 2.3 Transport cost formula (`_costFromRealKm`, dashboard.html:18320–18327) — re-scale, keep shape
- taxi `Math.max(8, Math.round(3 + km*1.9))` → `Math.max(1500, Math.round(550 + km*350))`
- car `Math.round(8 + km*0.30)` → `Math.round(1500 + km*55)`
- train `Math.round(15 + km*0.40)` → `Math.round(2750 + km*73)`
- hsr `Math.round(30 + km*0.25)` → `Math.round(5500 + km*46)`; walk stays `0`. (All ×183, rounded to clean figures.) Update EUR comments 18315–18318.
- **ALSO re-scale the Haversine fallback heuristic** (the ~2.5/2.8 per-km constants nearby) — converting only one place leaves half the itineraries at euro scale.

### 2.4 Hardcoded `€` / SEPA / EUR copy → ¥ / Japan bank
Replace every literal `€`/`EUR`/`SEPA`/`euros` in user-facing strings (translate surrounding `ja` text). Hotspots: `dashboard.html` spend ph (en 8516 / ja 9246), `slot.cost.label "(€)"` (en 8618 / ja 9342)→`(¥)`, brief budget demo 7319 `€150/day · Paris`→`¥20,000/日 · 東京`, static `€0` fallbacks (7228/7233/7238/7393–7476), payout chip "EUR" 7784, "Bank transfer (SEPA)" + `profile.bank.*`/`wallet.method.sepa`→"銀行振込"/drop SEPA, "All earnings in Euros"→"全ての収入は日本円（¥）です", timezone "Central European Time"→"日本標準時 (JST · UTC+9)". `terms.html` (161/176/250/260/310/320). `support.html` (592/645). `supercs999.html` payout chips (1762/1781), bond (1564/1580), pending-amount locale 2075 `'fr-FR'`→`'ja-JP'`. `superadmin999.html` EUR placeholders/egs (daily-budget 10500→1921500, bond 6000→1098000, payout €5,000–10,000→¥915,000–¥1,830,000, adjustments 4000/-500→732000/-91500, €50 bond 1818→¥9,150, weekly desc 1530 €1,000→¥183,000, budget displays 3075/3535 `'€'`→`'¥'`, `€0` cells). DB meta cols `daily_spend_per_pax_eur` / `hotel_budget_per_night_pax_eur`: **keep names**; re-scale any seed values used.

---

## SECTION 3 — France → Japan content (zero France remnants)

### 3.1 Hero imagery & city→image maps (`dashboard.html ~9845–9895`)
Replace France hero consts (`FR_HERO_EIFFEL/_ARC/_LAVENDER/_NICE/_MSM/_LOIRE`) + `PREF_HERO`/`CITY_HERO` (16+ French cities) with Japan destinations + new Unsplash IDs + Japanese alt text: Tokyo (浅草寺/渋谷), Kyoto (伏見稲荷/嵐山/祇園), Osaka (道頓堀), 広島 (宮島鳥居), 奈良 (東大寺), 箱根/河口湖 (富士山), 金沢 (兼六園), 高山, 直島, 長野 (善光寺). Update `_fallback_*`/`'Other'` Eiffel→富士山 and "… · France"→"… · 日本". Fallback Fuji URL must be reliable on mobile + desktop.

### 3.2 City/region/airport/rail data (`dashboard.html`)
- `AIRPORT_BY_CITY` (12695–12703): CDG/NCE/SXB/RNS… → Tokyo `HND`/`NRT`, Osaka/Kyoto/Kobe `KIX`, Nagoya `NGO`, Fukuoka `FUK`, Sapporo `CTS`, Okinawa `OKA`, Hiroshima `HIJ`, Sendai `SDJ`.
- `RAIL_CITIES` (12746) / `ISLAND_CITIES` (12747): JP rail cities + islands (沖縄, 直島, 北海道). `guessTransport()` (12748–12752) French phrases → Japanese (電車 / フェリー・飛行機 / 車・電車).
- Transport From→To ph (en 8610 / ja 9334) "Paris → Lyon"→"東京 → 京都". City egs (7650/8387/8407/9125; `superadmin999.html:6827`) "e.g. Paris…"→"例：東京、京都、大阪".
- `apply.html FRENCH_CITIES` (763–772) + mirror `PREFECTURES_PROFILE` (dashboard ~12540): replace with Japanese prefectures (東京都, 神奈川県, 京都府, 大阪府, 兵庫県, 北海道, 福岡県, 沖縄県… その他) — **update both together**. Picker label "— Sélectionnez votre région —"→"— 地域を選択 —".
- `dashboard.html:12978` "· final departure from France"→"· 日本からの最終出発". Address-strip regex `/,?\s*France\s*$/i` (~13845) → handle `, Japan` / `日本` / `〒xxx-xxxx`.
- IANA `Europe/Paris` (~19069, 22649) → `Asia/Tokyo`.

### 3.3 Banking/payout UI (remove SEPA/IBAN/BIC; Japan bank)
- **KEEP DB columns + field→column mapping** (`bank_holder`, `bank_branch_code`, `bank_account`, `payout_method`). Change ONLY: tab "Bank transfer (SEPA)"→"銀行振込（日本）"; labels/ph to Japanese bank format — 銀行名 / 支店コード / 口座種別 普通・当座 / 口座番号 / 口座名義カナ; error copy → Japanese. If relaxing `_isValidIban`/`_isValidBic` (~12289–12398), keep the same call-sites + return contract. Crypto (USDT/USDC) tab stays — Japanese copy. PayPay fields (`paypay_id`/`paypay_holder`) already exist — localize.
- Placeholders `profile.ph.bic 'BNPAFRPP'`, `profile.ph.account 'FR76…'`, `profile.ph.phone '+33 6…'` → `+81 90 …`, Japanese bank examples (MUFG/SMBC/みずほ). Fix in `en` AND `ja` and in apply/signup/login.

### 3.4 Marketing/onboarding/recruitment copy
- `dashboard.html rules.what.body`/`rules.role.body` (en 8395/8397 + ja 9133/9135) → Japan wording.
- `apply.html` (556–557, 605, 402–416, 682), `signup.html` (446, 482, 503, 513–514): "France, through your eyes", "Paris boulevards to Provence vineyards", "800+ planners" → Japan ("日本を、あなたの視点で"; "東京の路地から京都の寺社まで"). Update `en` too (English must not say France).
- `login.html` testimonial "Senior planner · Paris" (569/689/728)→"シニアプランナー · 東京".

### 3.5 Legal / company entity / jurisdiction
- **Company entity is UNCHANGED — keep the existing UK Journey Junction Ltd** (the "Birmingham … United Kingdom" address + "Company No. 15791277" + incorporation date) in ALL 7 locations (`apply.html:516`, `login.html:672`, `terms.html:228`, `privacy.html:180`, `sign-letter.html:668–672`, `superadmin999.html:8276`, `_worker.js:545`). Do NOT replace it with a Japan entity. Leave the address/number in Latin script; only the surrounding label/heading text becomes Japanese.
- **Governing law / privacy regulator → JAPAN (owner-confirmed).** Replace the France-specific clauses (all written in Japanese in the `ja` slot): "laws of France" / "Tribunal de commerce de Paris" (terms 216/242/244) → **Japanese law + 東京地方裁判所 (Tokyo District Court)**; "CNIL" (privacy 271) → **個人情報保護委員会 (PPC)**; "French tax/accounting legislation" (privacy 268/280) → **Japanese tax & accounting law** (keep the 7-year retention, now under Japanese statute). The operating entity stays **UK Journey Junction Ltd** (kept above) — word the clauses so the UK company provides the service while **Japanese law governs and Japanese courts/regulators apply** for the Japan market.

### 3.6 Defaults & seed data
- `_worker.js:271` default city `'Paris'`→`'Tokyo'`. `docs/schema/initial.sql:112 travelers.language_pref` default `'en'`→`'ja'`.
- `superadmin999.html` "Paris"/"e.g. RNS or Saint-Malo Station" (1199/2168/2187/3095/6665/6730/6827) → Tokyo / "例：HND または 東京駅".
- France seed SQL (`seed-batch-01-france-travelers.sql`, `reset-to-france-mid-range*.sql`) — do NOT re-run; do NOT run `wipe-japan-data.sql`. If sample data needed, build a Japan seed with the SAME metadata structure (`meta.person_id`, `meta.unit_order`, yen `*_eur` values).

### 3.7 Final sweep
Grep HTML/JS for residual: `France`, `français`, `Paris`, `Lyon`, `Marseille`, `Strasbourg`, `Nice`, `CDG`, `SXB`, `RNS`, `TGV`, `RER`, `métro`, `SEPA`, `IBAN`, `BIC`, `Eiffel`, `Birmingham`, `€`, `EUR`, `Europe/Paris`, `fr-FR`, `Bonjour`. Every hit in served code must be gone.

---

## SECTION 4 — CS chips, emails, contract

### 4.1 CS quick-reply chips (`supercs999.html QUICK_REPLIES_DEFAULTS`, 1757–1794)
- `en` array (1758–1774) stays English (update `€`→`¥` at 1762). **`ja` array (1776–1793) is French** → translate all 16 to Japanese. **Preserve exactly**: every emoji prefix, every `{placeholder}` (`{first_name}`, `{set_num}`, `{planner_short}`, `{pending_amt}`), and ARRAY ORDER (index-aligned with `QR_DEFAULT_KEYS` 1798–1803 + the `en` array — no add/remove/reorder). `€{pending_amt}`→`¥{pending_amt}` (1781). Bond chip → Japanese bank wording; drop SEPA/crypto-EUR.
- Lang selector: `:536–537` "Français"→"日本語" / `data-lang="ja"`; title (2040)→"日本語のクイック返信". `setQuickReplyLang` guard (1806–1808) allows `en`/`ja` — keep. `CS_QR_LANG` default (1805) `'en'`→`'ja'`. Seed any DB quick replies in Japanese.
- Static CS UI: chat-empty (382/383), typing (395), filters Open/Unread/Mine/Closed (336–339), Pin/Snooze/Take (440–442) → Japanese (keep emoji + tag-filter keys `bond/payout/dispute/training`).
- `/api/translate` (`_worker.js ~724–760`; dashboard ~729): set source `japanese`→`english` (planners now write Japanese). Keep contract/call-sites.

### 4.2 Approval email (`superadmin999.html ~8148–8295`)
- Translate subject (8204) + body (8205–8253) French→Japanese. Keep `{loginUrl}`. **Add a Japanese greeting pattern** to the first-name regex (8293–8295: "Bonjour X,"/"Hi X," → also "こんにちは X、" / "X さん、") or name extraction breaks. Keep Resend sender + Basic-Auth.

### 4.3 Employment-letter email (`_worker.js:499–562`)
- Translate body (subject 560, heading 519, paragraphs 521–523, button 529, fallback 535, footer 545) → Japanese. Keep `{firstName}`/`${signUrl}`, table styling, signing-token logic, Resend call. The "**English** —" courtesy line (540) — keep or translate (owner's call). Footer → Japan entity. Date (670) → `'ja-JP'`.

### 4.4 Service contract (`sign-letter.html`, all French, `lang="fr"`)
- `<html lang="ja">`. Translate everything: title (86), instruction (87), field labels (92/96/100), clauses (106–127), Signature (136), drawing instr (137), buttons (142/153/166), signed-state (179–182), error (189–190), "Signé le" (163–164). Preserve `{f-name}`/`{f-start}`/`{f-today}` + signature-canvas/submit logic. "1 000 €"+"SEPA" (112–115)→"¥135,000"+Japanese payment wording. Dates `'fr-FR'`→`'ja-JP'` (342–343/356).

### 4.5 Supabase Auth emails (out of code)
Password-reset / verification / OTP templates live in the Supabase dashboard (Settings → Email Templates) — **not in this repo**. Flag to owner to switch those to Japanese separately.

---

## SECTION 5 — Japan scaffolding already present (reuse, don't rebuild)
- `fmtMoney`/`fmtMoneyRaw` already yen (delete dead euro returns — §2.1).
- `TM_LANG` already defaults `ja`; `travLocale()` (9974–9978) already reads `name_ja`/`special_notes_ja` when `TM_LANG==='ja'`.
- DB cols `travelers.name_ja`, `special_notes_ja`, `language_pref`, planner `city` default `Tokyo` already exist — no migration needed (only `language_pref` default flip, §3.6).
- Noto Sans JP / Noto Serif JP + `html[lang="ja"]` CSS already loaded everywhere — activate via `lang='ja'` (§1.3).
- `cs_quick_replies.lang` already supports `ja`; the ~43 `=== 'ja'` checks already route to the `ja` slot — repurposing `ja`'s contents reuses all of it with zero call-site churn.

---

## ⛔ DO NOT CHANGE (translate strings/amounts only — never the logic)
- **Autosave/draft round-trip** — `saveDraft`/`silentSaveDraft`/`autoSaveDraft`/`_flushAutoSave` (22402–22523), `_persistDraft` insert-then-delete data-loss guard (22239–22401). Translate toast strings only.
- **Google Routes fetch/parse** — `fetchRouteData`/`applyRouteDataToSlot` (18157–18431): units, travelMode, polyline/steps, cache+TTL, time-snap. Only re-scale `_costFromRealKm` coefficients (keep shape).
- **Wallet logic** — `loadWallet`/`loadWalletAdjustments`/`loadPendingPayments` (10297–10912): queries, retention-unlock (3-set), weekly-bonus (≥2 sets/7-day), override-cap math. Only re-scale amount constants + ¥ display.
- **Review/approval** — `buildReviewPage`/`submitFromReviewPage`/`submitPlan` (21043–22151): all validation, status machine, item persistence. UI strings only.
- **Set assignment + isolated plan copies** — `autoCreateMissingPlans` (10248–10263), per-plan isolation, claimed_at reset detection. No logic change.
- **Supabase realtime** — `subscribePlannerRealtime`/`refreshWallet` (22838–22854): filters, RLS, table list. No change.
- **`/api/sb` proxy** — `_worker.js handleSupabaseProxy` (125–209): service-role swap, header stripping, allowlists, auth model, status codes. Security-critical — do not touch (only ADD a table to allowlist if a new table is introduced).
- **Hotel-bookend + arrival/return-taxi seeding** — `renderDayBookends` (19909–20126), `endDayBackToHotel`/`endTripToAirport`, is_locked, orphan-sweep/dedupe.
- **Timeline-summary renderer + stats** — commission calc, `_perPaxTransportCost`, `stats_json`. Labels + ¥ only.
- **Auth/login/signup/apply** — `_worker.js handleCreatePlanner` (214–291): auth, suspended-block, password ≥8, RLS, sessions. Change only default city Paris→Tokyo, lang fr→ja, UI strings.
- **i18n machinery** — `t()`/`dt()`/`applyLang()`/`setLang()` bodies+signatures, `data-i18n` processing, the ~43 `=== 'ja'`/`isPlannerFR` sites. Repurpose `ja` CONTENTS; do not rename the key or add a 3rd language.
- **Employment-letter signing flow** — `handleSendEmploymentLetter`/`handleGetLetter`/`handleSignLetter` (447–706): token auth, status checks, signature storage, Resend. Text only.
- **DB schema & column names** — keep `daily_spend_per_pax_eur`, `hotel_budget_per_night_pax_eur`, `bank_holder`/`bank_branch_code`/`bank_account`, `payout_method` as-is (legacy). RLS unchanged.
- **All `{placeholder}` tokens + emoji labels** — preserve exactly.
- **Crypto (USDT/USDC, TRC20/ERC20/BEP20) + PayPay logic** — keep behavior; localize copy.
- **CS chip `en`/`ja` array index-alignment with `QR_DEFAULT_KEYS`** — no add/remove/reorder.

---

## ✅ Acceptance checklist
1. Repo-wide grep over served HTML/JS finds ZERO: `€`, `EUR`, `SEPA`, `IBAN`, `BIC`, `France`, `français`, `Bonjour`, `Paris`, `Lyon`, `Marseille`, `Strasbourg`, `Nice`, `CDG`, `SXB`, `RNS`, `TGV`, `RER`, `métro`, `Eiffel`, `Birmingham`, `Europe/Paris`, `fr-FR` (unused `docs/*.md`/`*.sql` may retain them but must not be served/run).
2. Every `TM_I18N.ja` (dashboard 8944+), `SUP_I18N.ja`, and the renamed `ja` dicts in apply/login/signup/forgot/reset/terms/privacy are Japanese — no French / half-translated values.
3. `BRIEF_LABEL_FR`, `ENUM_FR`, `CUISINE_FR` contain Japanese (CUISINE fully replaced); `dt()`/`localizeCuisineCsv` still work; no French shown to a JA planner.
4. Planner dashboard, superadmin, supercs, support, apply, login, signup, forgot, terms, privacy, sign-letter all render 100% Japanese on load (`html lang='ja'`, Noto JP active); EN/語 toggle removed.
5. All 16 CS `ja` chips Japanese with emoji + every `{token}` preserved, order intact; `CS_QR_LANG` defaults `'ja'`; lang button reads "日本語".
6. Approval email, employment-letter email, service contract all Japanese; approval first-name regex matches Japanese greetings; placeholders preserved.
7. Currency displays as ¥ with no decimals everywhere; dead euro return lines deleted; no static `€0` fallback remains.
8. Re-scaled amounts (1 EUR = ¥183) consistent across ALL surfaces: weekly **¥183,000**, buffer `FIRST_PAYOUT_RETENTION_MIN=36600` / "¥91,500" copy, deposit **¥1,830,000 / ¥732,000**, splurge **{27000,55000,110000}**, base commission **{7300,5500}**.
9. `_costFromRealKm` re-scaled ×183 (formula shape kept: taxi max(1500,550+350km); car 1500+55km; train 2750+73km; hsr 5500+46km) AND the Haversine fallback heuristic re-scaled too.
10. `AIRPORT_BY_CITY`, `RAIL_CITIES`, `ISLAND_CITIES`, hero maps, `FRENCH_CITIES`, `PREFECTURES_PROFILE` all Japan data; picker↔profile prefecture lists match.
11. Banking UI shows Japanese bank fields; SEPA/IBAN/BIC gone; DB columns + mapping unchanged; placeholders +81 / Japanese banks.
12. **Company entity stays UK** (Birmingham address + Company No. 15791277 unchanged in all 7 locations); Terms/Privacy now cite **Japanese law + 東京地方裁判所 + APPI / 個人情報保護委員会 (PPC)** + Japanese tax law; no "laws of France" / "Tribunal de commerce de Paris" / "CNIL" / French-tax wording remains.
13. Date/number locale uses `'ja-JP'` on JA paths; money grouping stays `'en-GB'` in `fmtMoney`.
14. All protected functions verified unchanged + working after conversion.
15. `_worker.js` default city = Tokyo, default lang = ja; `language_pref` schema default = ja; `jj_lang_reset` flag bumped so saved `ja` isn't wiped.
16. `/api/translate` source = japanese→english; endpoint contract unchanged.

---

## ⚠️ Risk notes (the traps)
1. **`ja` key is OVERLOADED** — it stores FRENCH and is read by ~43 `=== 'ja'`/`isPlannerFR` sites + `cs_quick_replies.lang`. The strategy hinges on repurposing `ja` CONTENTS without renaming. `dt(en, fr)` is a strict ternary — only two languages.
2. **Threshold amounts are LOGIC, not strings** (weekly 1000, buffer 200/500, deposit 10000/4000, splurge 150/300/600, commission 40/30, transport coeffs). Re-scale at **1 EUR = ¥183** AND keep consistent across dashboard/superadmin/terms/support/sign-letter. A mismatch = wrong payouts.
3. **Transport cost lives in TWO places** — `_costFromRealKm` AND the Haversine fallback (~2.5/2.8 per-km). Convert both.
4. `fmtMoney`/`fmtMoneyRaw` have unreachable euro returns after the live ¥ return — delete carefully; keep `'en-GB'` grouping (switching to `'ja-JP'` can drop the separator).
5. **Schema drift** (project memory): live FKs are RESTRICT not CASCADE; some RLS/unique constraints missing vs `initial.sql`. Write seed/migration SQL defensively. Don't re-run France seeds; don't run `wipe-japan-data.sql`.
6. IBAN/BIC validators use mod-97 — Japanese accounts have no IBAN. If relaxed, keep same call-sites/return contract + DB mapping or payout entry breaks. Safest: lightweight format check, defer hard validation to backend.
7. Approval-email first-name regex strips "Bonjour X,"/"Hi X," — add Japanese pattern or firstName silently breaks.
8. Visitor auth pages use `en`/`fr` (default `fr`); dashboard/support/terms/privacy use `en`/`ja`. Flip auth pages to `en`/`ja` (rename `fr`→`ja`, default `ja`, fix `applyLang`); a missed file leaves French to new applicants.
9. `jj_lang_resetv2` wipes saved `jj_planner_lang` — since `ja` now = Japanese, leaving the wipe deletes valid preferences; bump the flag + remove the `removeItem`.
10. Hero/city image swap is the biggest content change — ~16+ cities + 6 hero consts need new Unsplash IDs + Japanese alt; Fuji fallback URL must be reliable on mobile + desktop.
11. `data-i18n*` attributes drive translation — an element missing its attribute/key silently falls back to source text; sweep for hardcoded strings (chat-empty, filter buttons, contract labels).
12. Supabase Auth email templates (reset/OTP/verify) are NOT in this repo — Supabase dashboard only. Flag to owner.
13. Deploy is auto on push to main (Cloudflare Workers Builds) — do NOT run `wrangler`. A half-finished push goes live; stage + verify before pushing.
14. CS chip arrays are index-aligned with `QR_DEFAULT_KEYS` — reordering breaks the intent matcher.
15. `_worker.js` email/contract HTML is server-side — edit directly in the Worker; frontend i18n checks won't catch a bad string there.
