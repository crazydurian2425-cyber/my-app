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

  // Detect from the hostname. Anything not in the map (localhost,
  // *.workers.dev preview) falls back to FR, so dev + preview work unchanged.
  var host = (window.location && window.location.hostname) || ''
  var region = HOST_REGION[host] || 'FR'

  // ── Preview override (dev / QA) ──────────────────────────────────────
  // Visit ?market=JP (or ?market=FR) to preview that market's PRESENTATION
  // — language, currency, branding — on ANY domain, with no domain to buy.
  // Persisted per browser tab so it survives navigation (login → dashboard).
  // Reset with ?market=clear.
  //
  // Changes LOOK ONLY. What data a user can access stays enforced server-side
  // by the planner's real `region` + RLS — a preview cannot leak another
  // market's data.
  var preview = false
  try {
    var qs = new URLSearchParams(window.location.search)
    if (qs.has('market')) {
      var m = (qs.get('market') || '').toUpperCase()
      if (m === 'FR' || m === 'JP') sessionStorage.setItem('jj_market_preview', m)
      else sessionStorage.removeItem('jj_market_preview')   // ?market=clear / empty resets
    }
    var stored = sessionStorage.getItem('jj_market_preview')
    if (stored === 'FR' || stored === 'JP') { region = stored; preview = true }
  } catch (e) {}

  window.JJ_REGION  = region
  window.JJ_CONFIG  = REGION_CONFIG[region]
  window.JJ_PREVIEW = preview   // true when overridden via ?market=
})()
