// ─────────────────────────────────────────────────────────────
// region.js — single source of truth for WHICH MARKET a page serves.
//
// Loaded by every page BEFORE its main script. The market is decided from the
// hostname the browser is on, so ONE set of files serves both the France domain
// and the Japan domain.
//
// IMPORTANT — this drives PRESENTATION only (language, currency, branding).
// Data isolation is enforced server-side by each row's `region` + RLS (planners
// only ever see their own rows) and by admin/login region-scoping. NEVER trust
// the browser's hostname for deciding what data a user may access.
//
// Exposes:
//   window.JJ_REGION   → 'FR' | 'JP'
//   window.JJ_CONFIG   → the active region's presentation config (below)
//   window.JJ_PREVIEW  → true when overridden via ?market=
// ─────────────────────────────────────────────────────────────
(function () {
  // hostname → region. Add the Japan domain here once it is registered.
  var HOST_REGION = {
    'journeyjunctionplanner.com':     'FR',
    'www.journeyjunctionplanner.com': 'FR',
    // 'journeyjunctionjapan.com':    'JP',   // ← uncomment when the JP domain is live
    // 'www.journeyjunctionjapan.com':'JP',
  }

  // Per-region presentation config. Currency, locale, timezone are DERIVED from
  // region here — one source of truth, no separate DB column to drift.
  var REGION_CONFIG = {
    FR: {
      region: 'FR', countryCode: 'FR',
      defaultLocale: 'fr', currency: 'EUR', currencySymbol: '€',
      timezone: 'Europe/Paris',
      gateways: ['Paris', 'Nice'],
      cityPlaceholder: 'Paris, Lyon, Marseille',
    },
    JP: {
      region: 'JP', countryCode: 'JP',
      defaultLocale: 'ja', currency: 'JPY', currencySymbol: '¥',
      timezone: 'Asia/Tokyo',
      gateways: ['Tokyo', 'Osaka'],
      cityPlaceholder: 'Tokyo, Kyoto, Osaka',
    },
  }

  // Detect from the hostname. Anything not in the map (localhost, *.workers.dev
  // preview) falls back to FR, so dev + preview keep working unchanged.
  var host = (window.location && window.location.hostname) || ''
  var region = HOST_REGION[host] || 'FR'

  // ── Preview override (dev / QA) ──────────────────────────────────────
  // Visit ?market=JP (or ?market=FR) to preview that market's PRESENTATION on
  // ANY domain, before the Japan domain exists. Persisted per browser tab so it
  // survives navigation (login → dashboard). Reset with ?market=clear.
  // Changes LOOK ONLY — data access stays governed server-side.
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
  window.JJ_PREVIEW = preview
})()
