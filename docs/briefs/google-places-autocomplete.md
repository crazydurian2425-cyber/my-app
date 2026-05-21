# Google Places Autocomplete — Itinerary Builder

**Status:** Ready to implement
**Owner:** Teemo
**Last updated:** May 2026

## Overview

Replace the current 3-field manual entry (Name + Address + What to order) in the itinerary builder with a **single Google Places autocomplete search**. Selecting a place auto-fills name, address, coordinates, rating, opening hours, and photos. The planner only writes a personal 1-2 sentence recommendation.

## Why

- **Planner speed:** ~15 sec per stop instead of ~2 min. Saves 15-20 min per 3D2N itinerary.
- **Data accuracy:** No typos, no invented places, no out-of-date hours.
- **Better UX:** Auto-pulled photos and ratings make the traveler-facing itinerary look professional.
- **Easier QA:** System can verify the planner picked a real, currently-open place.

## Scope

### In scope
- Add Google Places autocomplete in the itinerary stop form
- Auto-fill stop metadata on place selection
- Persist place data so traveler-facing itinerary can show photos, ratings, map pins, links
- Display selection clearly with "Change" option to re-search
- Handle errors gracefully (API failure, no results, rate limit)
- Manual entry fallback for places not on Google

### Out of scope
- Map view of itinerary (separate ticket)
- Booking integration (separate ticket)
- Reviews beyond basic Google rating

## Technology

**Google Places API (New)** — specifically:
- Autocomplete (New) endpoint
- Place Details (New) — **Pro tier** ($17 per 1,000 requests)
- Photo (New) endpoint

**Why Pro tier:** gives us name, address, location, rating, opening hours, phone, website — everything travelers actually need. Essentials tier is too basic (no ratings/hours), Enterprise tier is overkill.

### Cost estimate
- $200/month free credit covers ALL usage for the first ~300 itineraries/month
- Expected cost for first year: **$0/month**
- At 500 itineraries/month with photo caching: ~$100/month

## Google Cloud setup

1. Create or use existing Google Cloud project
2. Enable **Places API (New)** in APIs & Services
3. Create an API key under Credentials
4. Restrict the frontend key:
   - HTTP referrers: `https://journeyjunction.com/*` and `localhost` for dev
   - API restriction: Places API (New) only
5. Create a separate backend key (for Place Details proxy):
   - Restrict to your server IP
   - API restriction: Places API only
6. Store in environment variables:
   - `GOOGLE_PLACES_API_KEY_FRONTEND`
   - `GOOGLE_PLACES_API_KEY_BACKEND`
7. **Set billing alert at $50/month** as safety net

## Architecture

### Session token pattern (critical for cost!)

Google bills autocomplete keystrokes + 1 details lookup as a **single session** — but only if you use a session token correctly.

```
User starts typing → generate UUID v4 session token
Each keystroke → call Autocomplete (New) with same token
User selects result → call Place Details (New) with same token (ONCE)
After selection → discard token, generate new one for next search
```

⚠️ **Abandoned sessions cost money.** If user types but never selects, each autocomplete request costs $2.83 per 1,000. Mitigation: only start the session when user has typed at least 3 characters.

## Frontend implementation

### HTML structure

```html
<div class="stop-search">
  <input
    type="text"
    id="placeSearch"
    placeholder="Search restaurant, attraction, or hotel..."
    autocomplete="off"
  />
  <ul id="placeResults" class="dropdown" hidden></ul>
</div>

<div id="selectedPlace" class="place-card" hidden>
  <img id="placePhoto" />
  <div>
    <h4 id="placeName"></h4>
    <p id="placeAddress"></p>
    <span id="placeRating"></span>
    <button type="button" id="clearPlace">Change</button>
  </div>
</div>

<label for="recommendation">Recommendation (1-2 sentences)</label>
<textarea id="recommendation" rows="3"></textarea>
```

### Autocomplete request (with debouncing)

```javascript
let sessionToken = null;
const API_KEY = import.meta.env.VITE_GOOGLE_PLACES_API_KEY;
let debounceTimer;

document.getElementById("placeSearch").addEventListener("input", (e) => {
  clearTimeout(debounceTimer);
  const query = e.target.value.trim();
  if (query.length < 3) return hideDropdown();

  // Only generate session token when user actually commits to searching
  if (!sessionToken) sessionToken = crypto.randomUUID();

  debounceTimer = setTimeout(() => fetchPredictions(query), 300);
});

async function fetchPredictions(query) {
  const response = await fetch(
    "https://places.googleapis.com/v1/places:autocomplete",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY
      },
      body: JSON.stringify({
        input: query,
        sessionToken: sessionToken,
        // Bias toward the current itinerary unit's city — improves relevance
        locationBias: {
          circle: {
            center: { latitude: 48.8566, longitude: 2.3522 }, // Set per unit
            radius: 50000.0
          }
        }
      })
    }
  );
  const data = await response.json();
  showDropdown(data.suggestions || []);
}
```

### Place selection → details request

```javascript
async function selectPlace(placeId) {
  // Pro tier fields — keeps cost low by only fetching what we render
  const fields = [
    "id", "displayName", "formattedAddress", "location",
    "rating", "userRatingCount", "priceLevel",
    "regularOpeningHours", "internationalPhoneNumber",
    "websiteUri", "googleMapsUri", "types"
    // NOTE: do NOT include "photos" here — fetch separately when traveler views
  ].join(",");

  const response = await fetch(
    `https://places.googleapis.com/v1/places/${placeId}?sessionToken=${sessionToken}`,
    {
      headers: {
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": fields
      }
    }
  );
  const place = await response.json();
  renderSelectedPlace(place);

  // Reset for next search
  sessionToken = null;
}
```

## Data model

Add these columns to your `stops` table (Postgres syntax — adjust for your DB):

| Column | Type | Source | Notes |
|---|---|---|---|
| `id` | uuid | generated | Primary key |
| `itinerary_unit_id` | uuid | FK | Which city/unit this stop belongs to |
| `day_number` | int | form | 1, 2, 3... |
| `time` | time | form | e.g. 19:30 |
| `category` | enum | form | meal, attraction, hotel, activity, transport |
| `google_place_id` | string | Places API `id` | Persisted for refresh |
| `name` | string | `displayName.text` | Auto-filled, planner can override |
| `address` | string | `formattedAddress` | |
| `latitude` | decimal | `location.latitude` | For map pins |
| `longitude` | decimal | `location.longitude` | For map pins |
| `rating` | decimal | `rating` | 0.0 - 5.0, nullable |
| `user_rating_count` | int | `userRatingCount` | Nullable |
| `price_level` | enum | `priceLevel` | nullable |
| `phone` | string | `internationalPhoneNumber` | nullable |
| `website` | string | `websiteUri` | nullable |
| `google_maps_url` | string | `googleMapsUri` | Direct link to Google Maps |
| `opening_hours_json` | jsonb | `regularOpeningHours` | Full structure preserved |
| `photo_refs` | jsonb | (fetched later) | Array of photo resource names |
| `place_types` | jsonb | `types[]` | restaurant, lodging, etc. |
| `recommendation_note` | text | form | Planner's 1-2 sentences |
| `created_at` | timestamp | system | |
| `updated_at` | timestamp | system | |

## Photo handling (do this to keep costs at $0)

**Don't load photos when planner builds the itinerary.** Only load them when traveler actually views their itinerary.

```javascript
// Only fetch photos on traveler-facing view
const photoUrl = `https://places.googleapis.com/v1/${photoName}/media?maxWidthPx=800&key=${API_KEY}`;
```

**Cache to Cloudflare R2 or S3** after first view. Each photo costs ~$0.007 from Google. After caching, served free from your bucket.

## Error handling

| Scenario | Behavior |
|---|---|
| API key missing/invalid | Show "Search temporarily unavailable. Contact support." |
| Rate limit (429) | Backoff 1s, retry once. If still failing, fall back to manual entry. |
| No results | Show "No places found. Try different search." with manual entry button. |
| Network error | Toast "Connection issue, retrying..." then retry once. |
| Place Details fails after selection | Keep autocomplete result on screen, show retry button. Don't lose work. |
| Planner edits auto-filled fields | Allowed — save edits, keep place_id link. |

## Manual entry fallback

Always show "Can't find it? Enter manually" link below search input. Routes to the original 3-field flow. Required for:
- Small bistros not on Google
- Brand-new venues
- API outage fallback

Flag manually-entered stops in QA (quality risk).

## Acceptance criteria

- [ ] Planner can search a Paris restaurant by name and see ≥3 relevant results within 1 second
- [ ] Selecting a result auto-fills name, address, rating, hours within 2 seconds
- [ ] Saved itinerary in DB has `google_place_id` and all metadata persisted
- [ ] Refreshing the page reloads the place from DB (no extra API call)
- [ ] If API is unreachable, form falls back to manual entry without losing data
- [ ] Session tokens correctly grouped: each search session costs <$0.02 even after many keystrokes
- [ ] Photos lazy-loaded on traveler view, cached after first load
- [ ] Billing alert configured at $50/month threshold

## Estimated effort

| Task | Hours |
|---|---|
| Google Cloud setup + API key restrictions | 1h |
| Frontend: autocomplete UI + dropdown + selection card | 4-6h |
| Frontend: integrate with form state, persist on submit | 2-3h |
| Backend: proxy endpoint + Redis cache (optional but recommended) | 3-4h |
| Database migration for new stop columns | 1-2h |
| Error handling + manual fallback | 2-3h |
| Display logic for traveler-facing itinerary | 3-4h |
| Photo caching to R2/S3 | 2-3h |
| Testing + edge cases | 2-3h |
| **TOTAL** | **20-29h** |

## References

- [Places API (New) overview](https://developers.google.com/maps/documentation/places/web-service/op-overview)
- [Autocomplete (New) docs](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete)
- [Place Details (New) docs](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Session tokens billing](https://developers.google.com/maps/documentation/places/web-service/session-tokens)
- [Pricing calculator](https://mapsplatform.google.com/pricing/)
