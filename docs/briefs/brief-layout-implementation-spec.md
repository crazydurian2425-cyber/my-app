# Brief Layout — Exact Implementation Spec

Apply this design to the Traveler Brief panel for ALL plans. Match the reference screenshots EXACTLY.

## Visual style

- **Theme**: Dark mode
- **Background**: `#1f1f1f` (deep charcoal)
- **Card surface**: same as background, divided by section lines only
- **Primary text**: `#ffffff` (white)
- **Secondary/label text**: `#8a8a8a` (medium gray) — used for field labels in small caps
- **Section dividers**: `#3a3a3a` thin hairlines (1px)
- **Accent green** (icons, section titles): `#3FBA73` (vibrant green)
- **Accent orange** (note from traveler): `#E08B3A`
- **Critical red badge**: background `#7a1f1f`, text `#ffb3b3`
- **NEW badge**: background `#1d3a5f`, text `#7BB8E8`, small pill
- **Interest pills**: background `#3d2e1f`, text `#E8B894` (warm cream)
- **Commission box**: background `#2a2a2a`, prominent

## Typography

- **Section headers**: 11px, bold, letter-spacing 1px, ALL CAPS, color `#3FBA73`, with icon prefix
- **Field labels**: 10px, bold, letter-spacing 0.8px, color `#8a8a8a`, ALL CAPS
- **Field values**: 14px, regular weight, color `#ffffff`
- **Note from traveler**: 14px, regular, light italic, color `#cccccc`

## Section icons (use these exactly)

| Section | Icon |
|---|---|
| TRAVELER BRIEF | 📍 (map pin) |
| TRIP BASICS | 🔄 (or path/route icon) |
| TRAVELERS | 👥 (people icon) |
| BUDGETS | 💰 (or wallet/coin icon) |
| ACCOMMODATION | 🛏 (bed icon) |
| FOOD & DINING | 🍴 (fork/knife icon) |
| INTERESTS & PRIORITIES | ❤️ (heart icon) |

If using an icon font like Tabler Icons or Lucide, use these names:
- `ti-map-pin`, `ti-route`, `ti-users`, `ti-wallet`, `ti-bed`, `ti-tools-kitchen-2`, `ti-heart`

## Layout — section by section

### HEADER
```
📍 TRAVELER BRIEF
─────────────────────────────────────────
```

### SECTION 1 — TRIP BASICS
Two-column grid layout. Labels small caps gray, values white.

```
🔄 TRIP BASICS
─────────────────────────────────────────
DESTINATION                      DURATION
Paris · Loire Valley             7D6N

ARRIVAL                          DEPARTURE
2026-09-12 · 10:30 am · CDG      2026-09-18 · 7:45 pm · CDG

PACE                             OCCASION  [NEW]
Moderate                         Honeymoon
```

Fields needed:
- destination (string, e.g. "Paris · Loire Valley")
- duration (string, e.g. "7D6N")
- arrival (date + time + airport code)
- departure (date + time + airport code)
- pace (Slow / Moderate / Active / Packed)
- occasion (Honeymoon / Anniversary / Birthday / Solo backpacking / etc.) — show `[NEW]` badge

### SECTION 2 — TRAVELERS
Two-column grid.

```
👥 TRAVELERS
─────────────────────────────────────────
GROUP TYPE                       AGES  [NEW]
Couple · 2 pax                   29, 31

LANGUAGES  [NEW]                 MOBILITY  [NEW]
English · Basic French           No limitations

PREVIOUS VISITS  [NEW]
First time in France
```

Fields needed:
- group_type + group_size
- ages (comma-separated list)
- languages
- mobility
- previous_visits_to_france

### SECTION 3 — BUDGETS
Two-column grid. NO yellow background — use the same dark style for consistency.

```
💰 BUDGETS
─────────────────────────────────────────
DAILY / PAX                      HOTEL / NIGHT / PAX
€120                             €110

SPLURGE WILLINGNESS  [NEW]       BOOKING AUTHORITY  [NEW]
1-2 splurges OK (€300+)          Planner books all
```

Fields needed:
- daily_spend_per_pax_eur
- hotel_budget_per_night_pax_eur
- splurge_willingness (display friendly: "Strict budget" / "1-2 splurges OK (€300+)" / "Frequent splurges" / "Luxury throughout")
- booking_authority (display friendly: "Planner books all" / "Planner recommends · they book" / "Mix")

### SECTION 4 — ACCOMMODATION  `[NEW SECTION]`

```
🛏 ACCOMMODATION  [NEW SECTION]
─────────────────────────────────────────
TYPE                             ROOM
Boutique hotel + 1N château      1 room · King bed

MUST-HAVES
Central location · Quiet street · Breakfast included · Romantic atmosphere
```

Fields needed:
- accommodation_type (e.g. "Boutique hotel + 1N château")
- room_config (e.g. "1 room · King bed")
- must_haves (string list separated by middots)

### SECTION 5 — FOOD & DINING  `[NEW SECTION]`

```
🍴 FOOD & DINING  [NEW SECTION]
─────────────────────────────────────────
DIETARY  [CRITICAL]              DINING STYLE
Vegetarian (1 pax) · No shellfish  Adventurous

CUISINE INTERESTS
French classics · Wine pairings · Pastries · 1 Michelin dinner
```

**Important — DIETARY field rules:**
- If dietary is "None" → no badge, just text "None"
- If dietary has ANY restriction (vegetarian, allergy, halal, etc.) → red `[CRITICAL]` badge MUST appear next to the label

### SECTION 6 — INTERESTS & PRIORITIES

```
❤️ INTERESTS & PRIORITIES
─────────────────────────────────────────
INTERESTS
[Art museums]  [Châteaux]  [Wine tasting]  [Seine cruise]  [Local markets]

INTENSITY  [NEW]                 DAILY TIMING  [NEW]
Moderate walking                 Standard (9-10am)

MUST AVOID
Tourist trap restaurants · Bus tours · Crowded peak times
```

Interest pills:
- Background: `#3d2e1f`
- Text: `#E8B894`
- Padding: 6px 14px
- Border-radius: 999px
- Font-size: 13px

### SECTION 7 — TRIP CONTEXT (privacy-protected — see below)

```
📍 TRIP CONTEXT · 3 UNITS · 5 NIGHTS TOTAL
─────────────────────────────────────────
🔒 Unit 1: Saint-Malo · 3D2N · 11 Jun – 12 Jun    [Planned by another]
🔒 Unit 2: Mont-Saint-Michel · 2D1N · 13 Jun       [Awaiting planner]
[YOU ARE HERE] Paris · 3D2N · 14 Jun – 15 Jun     €40
```

**Privacy rules:**
- Other units: show city/duration/dates, hide commission, faded styling (opacity 0.6)
- Your unit: full info including commission, green border + "YOU ARE HERE" badge
- Status labels for other units: "Planned by another" / "Awaiting planner" / "Completed"

### COMMISSION BOX

```
─────────────────────────────────────────
YOUR COMMISSION                                       €40
─────────────────────────────────────────
```

- Background: `#2a2a2a` (slightly lighter than page bg)
- Padding: 14px 16px
- Border-radius: 6px
- Commission in large bold green: `#3FBA73`
- Verify amount matches pricing rules:
  - 3D2N = €40 base
  - 2D1N = €30 base
  - + €10 continuity if planner has previous unit of same trip
  - NOT €48, NOT €55 — use the actual rule

### NOTE FROM TRAVELER (bottom, orange accent)

```
NOTE FROM TRAVELER
Honeymoon trip — would love a romantic dinner on the Seine, a special château 
stay in the Loire, and tips for hidden Paris spots away from the crowds. 🥂
```

- Section header color: `#E08B3A` (orange)
- Body text color: `#cccccc`
- Font weight: regular (not italic this time — based on the reference image)
- No box around it, just left-aligned text with section header

## Specific data binding

Each field on this brief maps to the database. Make sure to query/render these from the `travelers` table joined with the current `plans` row:

```sql
-- For plan brief, get traveler data:
SELECT t.*, p.unit_order, p.destination AS unit_destination, 
       p.duration AS unit_duration, p.unit_start_date, p.unit_end_date,
       p.commission_eur
FROM plans p
JOIN travelers t ON t.id = p.traveler_id
WHERE p.id = :current_plan_id;

-- For trip context (other units of same trip):
SELECT id, unit_order, destination, duration, unit_start_date, 
       unit_end_date, status, assigned_planner_id
FROM plans
WHERE traveler_id = :traveler_id
ORDER BY unit_order;
```

## NEW badges policy

The blue `[NEW]` badges in the reference were marking newly-added fields during development. In the FINAL implementation, REMOVE these badges. Only keep:
- `[CRITICAL]` red badge on Dietary (always when restrictions exist)
- `[NEW SECTION]` blue badge on Accommodation and Food (remove after launch)
- `[YOU ARE HERE]` green badge in Trip Context (always)

## Acceptance criteria

- [ ] All 7 sections rendered in order
- [ ] Section headers have green icon + label
- [ ] Two-column grid layout where shown
- [ ] Dark theme exactly matches reference colors
- [ ] CRITICAL red badge appears whenever dietary has restrictions
- [ ] Privacy mode applied to other planners' units in Trip Context
- [ ] Commission calculation uses correct base rates (€30 / €40)
- [ ] Interest values displayed as cream-colored pills
- [ ] Note from traveler has orange section header
- [ ] All 150 plans render correctly (test 5 random plans)

## Start here

Render this brief layout for Plan 1 (the first traveler in your database). Show me the result before applying to all plans. If anything is missing data (e.g., a field is null), show a subtle "—" placeholder instead of breaking the layout.
