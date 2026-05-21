# Task — Generate 150 International Travelers Visiting France

## Goal
Populate JourneyJunction's database with **150 realistic international traveler briefs**, each visiting France. These will be used by planners to practice itinerary building. Insert them into the appropriate database table in this project (you may need to check the schema first — likely `travelers` or `trips`).

---

## Hard rules (no exceptions)

1. **Every itinerary unit** is either **2D1N** OR **3D2N** — no other lengths allowed
2. **Each traveler has 2–5 units** stacked together (so total trip = 4–15 nights)
3. **All destinations within France** (mainland regions + overseas territories like Corsica, Reunion)
4. **All travelers come from OUTSIDE France** (international visitors)
5. **Dates spread across June 2026 – June 2027** (cover all seasons)
6. **Realistic city sequences** — don't put Paris → Nice → Paris → Lyon. Travelers move in logical geographic order.

---

## Distribution requirements (for variety)

### Group types — make exactly:
- **30 Solo travelers** (20%)
- **40 Couples** (27%) — dating, anniversary, mature couples
- **25 Honeymoons** (17%) — newlyweds, romantic focus
- **35 Families** (23%) — with kids of varying ages
- **20 Groups** (13%) — friends, multi-generational, work retreats

### Origin countries — distribute roughly:
- **Asia (35% = ~53 travelers)**: Japan, South Korea, China, Singapore, Malaysia, Thailand, India, Indonesia, Philippines, Vietnam, UAE, Saudi Arabia, Hong Kong, Taiwan
- **North America (25% = ~37)**: USA (mostly), Canada, Mexico
- **Europe non-France (20% = ~30)**: UK, Germany, Netherlands, Italy, Spain, Sweden, Switzerland, Poland, Belgium, Ireland, Denmark
- **Oceania (8% = ~12)**: Australia, New Zealand
- **South America (7% = ~11)**: Brazil, Argentina, Chile, Colombia
- **Africa (5% = ~7)**: South Africa, Morocco, Egypt, Nigeria, Kenya

### Budget tiers — split each group type into:
- **40% Budget tier** — backpackers, students, frugal travelers
- **45% Mid-range tier** — comfortable middle class, most travelers
- **15% Luxury tier** — high-end, splurge travelers

---

## Budget guidelines (use these EXACTLY)

All prices in EUR (€) per person per day, unless noted. These are realistic 2026 numbers.

### Solo travelers

| Tier | Hotel/night/pax | Daily spend/pax | Notes |
|---|---|---|---|
| Budget | €40–€70 | €60–€90 | Hostels, dorms, occasional private |
| Mid-range | €80–€140 | €110–€160 | 3★ hotels, mix of dining |
| Luxury | €200–€400+ | €250–€500 | 4-5★ boutique hotels |

### Couples (non-honeymoon)

| Tier | Hotel/night/pax | Daily spend/pax | Notes |
|---|---|---|---|
| Budget | €45–€75 | €70–€100 | Twin rooms, Airbnb |
| Mid-range | €90–€150 | €120–€180 | 3-4★ hotels, nice restaurants |
| Luxury | €220–€450+ | €280–€600 | Boutique 4-5★, fine dining |

### Honeymoons (always higher budget than regular couples)

| Tier | Hotel/night/pax | Daily spend/pax | Notes |
|---|---|---|---|
| Budget | €70–€110 | €100–€140 | Romantic but careful with money |
| Mid-range | €130–€220 | €170–€250 | Boutique hotels, champagne moments |
| Luxury | €350–€700+ | €400–€800+ | Château stays, Michelin, private tours |

### Families (calculate per pax; usually 2 adults + 1-3 kids)

| Tier | Hotel/night/pax | Daily spend/pax | Notes |
|---|---|---|---|
| Budget | €35–€60 | €50–€80 | Family rooms, apartments, picnics |
| Mid-range | €70–€130 | €90–€150 | Family suites, kid-friendly restaurants |
| Luxury | €180–€350+ | €220–€400 | Family resorts, kid clubs |

### Groups (friends or multi-gen, 3-8 pax)

| Tier | Hotel/night/pax | Daily spend/pax | Notes |
|---|---|---|---|
| Budget | €40–€70 | €60–€100 | Hostels, shared apartments |
| Mid-range | €80–€140 | €110–€170 | Apartments, mid-range hotels |
| Luxury | €200–€400+ | €260–€500 | Private villas, group dinners |

**Important:** Use realistic specific numbers, not the bounds. e.g., "€87/night/pax" not "€80-€140".

---

## City/Region combinations (use these realistic sequences)

Travelers should visit 2–5 places in geographic logic. Use these realistic itinerary patterns:

### "Classic First-Timer" patterns (most common — 40%)
- Paris 3D2N → Loire Valley 2D1N → Mont-Saint-Michel 2D1N
- Paris 3D2N → Nice 3D2N
- Paris 3D2N → Strasbourg 2D1N → Colmar 2D1N
- Paris 3D2N → Bordeaux 3D2N → Saint-Émilion 2D1N
- Paris 3D2N → Lyon 2D1N → Avignon 3D2N → Nice 3D2N

### "South-focused" (15%)
- Nice 3D2N → Cannes 2D1N → Monaco 2D1N → Saint-Tropez 3D2N
- Marseille 3D2N → Aix-en-Provence 2D1N → Avignon 3D2N → Nice 2D1N
- Lyon 2D1N → Avignon 3D2N → Marseille 2D1N → Nice 3D2N

### "Wine routes" (10%)
- Bordeaux 3D2N → Saint-Émilion 2D1N → Cognac 2D1N
- Reims (Champagne) 3D2N → Épernay 2D1N → Paris 3D2N
- Beaune (Burgundy) 3D2N → Lyon 2D1N → Bordeaux 3D2N

### "Romantic / Honeymoon" (15%)
- Paris 3D2N → Loire Valley (château stay) 2D1N → Provence (Luberon) 3D2N → Nice 2D1N
- Paris 3D2N → Colmar 2D1N → Strasbourg 2D1N
- Saint-Tropez 3D2N → Cannes 2D1N → Monaco 2D1N

### "Adventure / Outdoors" (8%)
- Chamonix (Alps) 3D2N → Annecy 2D1N → Lyon 2D1N
- Pyrenees (Lourdes/Cauterets) 3D2N → Carcassonne 2D1N → Toulouse 2D1N
- Verdon Gorge 2D1N → Aix-en-Provence 2D1N → Marseille 3D2N

### "Off the beaten path" (7%)
- Brittany (Saint-Malo, Quimper) 3D2N → Mont-Saint-Michel 2D1N
- Corsica (Ajaccio + Bonifacio) — 2 units of 3D2N
- Alsace deep dive: Strasbourg 3D2N → Colmar 2D1N → Wine villages 2D1N

### "Family-friendly" (5%)
- Paris 3D2N → Disneyland Paris 2D1N → Loire (kid-friendly châteaux) 2D1N
- Paris 3D2N → Normandy (D-Day beaches) 2D1N → Mont-Saint-Michel 2D1N
- Nice 3D2N → Antibes 2D1N → Cannes 2D1N (beach family trips)

---

## Persona variation rules

### Names
Use **realistic names matching the origin country**. Examples:
- Japanese: Yuki Tanaka, Hiroshi Sato, Aiko Yamamoto
- Korean: Min-jun Kim, Seo-yeon Park, Ji-ho Lee
- American: Sarah Johnson, Michael Chen, Jessica Williams
- Brazilian: Lucas Silva, Mariana Oliveira, Pedro Santos
- Indian: Priya Sharma, Arjun Patel, Ananya Reddy
- German: Anna Müller, Tobias Schmidt, Lena Becker
- (use AI knowledge to pick authentic names for each country)

### Ages
- Solo travelers: range 22–55, most 25–40
- Couples: both in similar age range, 28–60
- Honeymoons: 26–38
- Families: parents 30–48, kids ages 2–17 (realistic combos)
- Groups: 22–50, friends usually same age, multi-gen 30-65

### Languages spoken
Always include native language + likely 2nd language:
- Asians: native + English (varying levels: basic/fluent)
- Europeans non-France: native + English (usually fluent) + sometimes French basics
- North Americans: English + maybe French basics
- South Americans: Spanish/Portuguese + English (mid level)

### Dietary restrictions (realistic distribution)
- 65% None
- 12% Vegetarian
- 5% Vegan
- 8% Halal (especially for Middle Eastern, Indonesian, Malaysian travelers)
- 3% Kosher
- 2% Gluten-free
- 4% Various allergies (nuts, shellfish, dairy)
- 1% Other (low FODMAP, diabetic, etc.)

### Trip occasions (mix across types)
- Honeymoon (only for honeymoon group)
- Anniversary
- Birthday (milestone like 30, 40, 50)
- Retirement trip
- Bucket list
- Family vacation
- Friends reunion
- Photography focus
- Wine pilgrimage
- Foodie adventure
- Cultural immersion
- Just leisure

### Interests (mix 3-5 per traveler from realistic categories)
- Art museums, History, Architecture, Photography
- Food/Wine, Michelin dining, Street food, Pastries
- Nature, Hiking, Beach, Lavender fields
- Shopping (luxury, vintage, markets), Fashion
- Nightlife, Local culture, Hidden gems
- Châteaux, Villages, UNESCO sites
- Adventure sports, Skiing, Water sports

### Pace preferences
- Slow (15%): in-depth, relaxed
- Moderate (60%): balanced
- Active (20%): packed days
- Packed (5%): see everything possible

### Daily timing
- Early risers (25%): start 7-8am
- Standard (60%): start 9-10am
- Late starters (15%): start after 10am

### Splurge willingness (independent of base tier)
- 30% Strict budget
- 50% 1-2 splurges OK
- 15% Frequent splurges
- 5% Luxury throughout

### Special notes (free-text "Note from traveler" — make these varied and personal)
Examples to vary:
- "First trip to Europe — bucket list for my parents (60th anniversary)"
- "Wife is celiac, please ensure all restaurants can accommodate"
- "Want lots of photo spots, we're amateur photographers"
- "Anniversary trip — would love a surprise champagne moment in Paris"
- "Family of 5, oldest kid is into history, youngest just wants Disneyland"
- "Honeymoon — please prioritize romance over efficiency"
- "Backpacking after college, on a tight budget but want authentic experiences"
- "Wine pilgrimage, husband is a sommelier, looking for cellar tours not just tastings"
- "Solo trip after divorce, want to feel alive again, push me out of comfort zone"
- "Returning to France for first time since 1995 honeymoon, mostly nostalgic spots"
- "Mom is in a wheelchair, please all venues need step-free access"
- "Kids ages 4 and 7, energy levels matter, lots of breaks needed"
- "Photo essay for travel magazine, need golden-hour iconic spots"
- "Birthday milestone, want to feel pampered, not budget-conscious"

Make notes specific and emotional — not generic.

---

## Data format

Insert each traveler with this structure (adjust column names to match the existing schema in this project):

```json
{
  "id": "auto-generated UUID",
  "name": "Full name realistic for origin country",
  "origin_country": "Country name",
  "origin_city": "City name (e.g., Tokyo, New York)",
  "ages": "List or comma-separated, e.g., '34, 32' or '38, 35, kids: 7, 4'",
  "group_type": "solo | couple | honeymoon | family | group",
  "group_size": "integer",
  "languages": "Comma-separated: native + others",
  "occasion": "From the list above",
  "arrival_date": "YYYY-MM-DD (June 2026 – June 2027)",
  "arrival_time": "HH:MM (realistic flight arrival, e.g. 10:00, 14:30, 22:15)",
  "departure_date": "YYYY-MM-DD",
  "departure_time": "HH:MM",
  "total_nights": "calculated from units",
  "pace": "slow | moderate | active | packed",
  "daily_timing": "early | standard | late",
  "budget_tier": "budget | mid_range | luxury",
  "hotel_budget_per_night_pax_eur": "integer, from tier table",
  "daily_spend_per_pax_eur": "integer, from tier table",
  "splurge_willingness": "strict | one_two_splurges | frequent | luxury_throughout",
  "dietary_restrictions": "none | vegetarian | vegan | halal | kosher | gluten_free | allergy: <X> | other: <X>",
  "mobility": "none | limited_walking | wheelchair | stroller | pregnancy",
  "interests": "Array of 3-5 from interest list",
  "must_avoid": "Free text, e.g. 'crowded peak times', 'tourist traps'",
  "previous_visits_to_france": "first_time | been_before | frequent",
  "booking_authority": "planner_books_all | planner_recommends | mix",
  "accommodation_preference": "hotel | ryokan_equivalent_boutique | mix | airbnb | hostel",
  "traveler_note": "Personal free-text note (varied, emotional)",
  "units": [
    {
      "order": 1,
      "city_or_region": "Paris",
      "nights": 2,
      "duration_label": "3D2N",
      "unit_start_date": "YYYY-MM-DD",
      "unit_end_date": "YYYY-MM-DD"
    },
    {
      "order": 2,
      "city_or_region": "Loire Valley",
      "nights": 1,
      "duration_label": "2D1N",
      "unit_start_date": "YYYY-MM-DD",
      "unit_end_date": "YYYY-MM-DD"
    }
  ]
}
```

---

## Implementation steps

1. **Explore the project first**:
   - Read the database schema (likely in a migrations folder or `.sql` file or Supabase config)
   - Look at the existing `Plan 1` and `Plan 2` data to see the actual format used
   - Identify the correct table and columns

2. **Generate the 150 travelers**:
   - Follow ALL the distribution rules above
   - Write them in batches of 30 (5 batches) to avoid context issues
   - Use realistic, varied data — don't repeat patterns

3. **Insert into database**:
   - Use whatever method matches the existing project (Supabase client, raw SQL, etc.)
   - Generate a SQL file first if direct insert isn't possible — show me before running

4. **Verify**:
   - After insert, count by group_type and origin_country to confirm distribution
   - Show me 5 random samples from the inserted data
   - Confirm all units are exactly 2D1N or 3D2N

5. **Don't auto-commit to git** — let me review first

---

## Quality checks before finalizing

Before declaring done, verify:
- [ ] Exactly 150 travelers created
- [ ] Group type distribution matches: 30 solo / 40 couple / 25 honeymoon / 35 family / 20 group
- [ ] Every unit is 2D1N or 3D2N (no 4D3N, no 5D4N, etc.)
- [ ] Every traveler has 2–5 units
- [ ] No traveler from France
- [ ] Dates fall June 2026 – June 2027
- [ ] Budgets follow the tier tables above
- [ ] Names match origin countries realistically
- [ ] Notes are varied and personal (not generic copy-paste)
- [ ] Unit dates are sequential (no overlaps)

---

## Start by asking me:
1. Confirm you found the right database table and schema
2. Show me what columns exist vs what's in my spec — flag any mismatches
3. Confirm we should generate 150, not break this into smaller batches

Wait for my answers before generating.
