// ─────────────────────────────────────────────────────────────
// region.js — single source of truth for WHICH MARKET a page serves.
//
// Loaded by every page BEFORE its main script. The market is decided purely
// from the hostname the browser is on, so ONE set of files serves both the
// France domain and the Japan domain.
//
// IMPORTANT — this drives PRESENTATION only (language, currency, branding).
// Data isolation is enforced server-side by each planner's stored `region`
// column (see docs/schema/add-region-discriminator.sql) + RLS. NEVER trust
// the browser's hostname for deciding what data a user may access.
//
// Exposes two globals:
//   window.JJ_REGION  → 'FR' | 'JP'
//   window.JJ_CONFIG  → the active region's presentation config (below)
// ─────────────────────────────────────────────────────────────
(function () {
  // hostname → region. Add the Japan domain here once it is registered.
  var HOST_REGION = {
    'journeyjunctionplanner.com':     'FR',
    'www.journeyjunctionplanner.com': 'FR',
    // 'journeyjunctionjapan.com':    'JP',   // ← uncomment when the JP domain is live
    // 'www.journeyjunctionjapan.com':'JP',
  }

  // Per-region presentation config. Currency, locale, timezone are DERIVED
  // from region here — one source of truth, no separate DB column to drift.
  var REGION_CONFIG = {
    FR: {
      region: 'FR', country: 'France',
      defaultLocale: 'fr', currency: 'EUR', currencySymbol: '€',
      timezone: 'Europe/Paris',
    },
    JP: {
      region: 'JP', country: 'Japan',
      defaultLocale: 'ja', currency: 'JPY', currencySymbol: '¥',
      timezone: 'Asia/Tokyo',
    },
  }

  // Detect. Anything not in the map (localhost, *.workers.dev preview) falls
  // back to FR, so local dev and the preview URL keep working unchanged.
  var host = (window.location && window.location.hostname) || ''
  var region = HOST_REGION[host] || 'FR'

  window.JJ_REGION = region
  window.JJ_CONFIG = REGION_CONFIG[region]
})()
