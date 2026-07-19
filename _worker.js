// ─────────────────────────────────────────────────────────────
// Basic Auth gate + email proxy.
//   • /superadmin999.html, /supercs999.html, /supermentor999.html → Basic Auth required
//   • /api/send-approval                     → Basic Auth (admin only) + forwards to Resend
//   • everything else                        → static asset serving
//
// Single shared admin credential gates both pages. CS staff use the same
// password as admin — they have full access to /superadmin999.html too,
// so only share this password with people you'd trust at admin level.
// ─────────────────────────────────────────────────────────────

const PROTECTED_PATHS = ['/superadmin999.html', '/supercs999.html', '/supermentor999.html', '/superapi999.html']

const CREDENTIALS = [
  { user: 'admin', pass: '168168', allow: ['/superadmin999.html', '/supercs999.html', '/supermentor999.html', '/superapi999.html'] },
]

// Resend API key — loaded from the Worker secret `env.RESEND_API_KEY`
// at the top of fetch(). Set in production via
//   npx wrangler secret put RESEND_API_KEY
// and in local dev via the RESEND_API_KEY line in .dev.vars (gitignored).
// No hardcoded fallback — the key must never live in committed source.
let RESEND_API_KEY = ''

// Supabase project — service-role / secret key kept server-side only.
// Used by the /api/sb proxy + /api/create-planner. Loaded ONLY from the Worker
// secret env.SUPABASE_SERVICE_KEY (set in the Cloudflare dashboard). The old
// literal that used to live here was committed to git (compromised) and has
// been removed; the legacy service_role key it held should be disabled in
// Supabase. If the secret is unset the handlers fail loud with a 500.
const SUPABASE_URL = 'https://hjchyqafkpbryzlqhpxc.supabase.co'
let SUPABASE_SERVICE_KEY = ''

// Canonical public site URL used in outbound emails. Hardcoded (not derived
// from the request host) so signing/login links always point at the branded
// domain — never the raw *.workers.dev host the admin panel may be opened on.
const PUBLIC_SITE_URL = 'https://journeyjunctionplanner.com'

// ─────────────────────────────────────────────────────────────
// Multi-brand (white-label) config, keyed by request hostname.
// Both custom domains hit this one Worker + one Supabase project
// (shared data). The hostname just picks a skin: logo, colours,
// company name, and the outbound-email identity.
//   journeyjunctionplanner.com → Journey Junction   (default)
//   itinerarydesignhub.com     → Vacations by Design (Sage & Poppy)
// Journey Junction's values equal the previously-hardcoded ones, so
// nothing about the live JJ site or its emails changes. This Worker uses
// the brand only for the outbound-email identity (email handlers below);
// the VISUAL skin is applied client-side by /brand-boot.js, since static
// pages are served directly by the asset layer and never reach this Worker.
// ─────────────────────────────────────────────────────────────
const BRANDS = {
  'journeyjunctionplanner.com': {
    key: 'jj',
    name: 'Journey Junction',
    emailFrom: 'Journey Junction <hello@thejourneyjunction.co.uk>',
    supportEmail: 'hello@thejourneyjunction.co.uk',
    siteUrl: 'https://journeyjunctionplanner.com',
    accent: '#1a7a5e',
    // JJ email header uses a raster round logo + the "Journey<i>Junction</i>" lockup.
    emailLogoImg: 'https://journeyjunctionplanner.com/jj.jpg?v=2',
    wordmarkLead: '',            // '' → template falls back to Journey<i>Junction</i>
    wordmarkAccent: '',
    footer: 'Journey Junction Ltd · Birmingham, United Kingdom · Company No. 15791277',
  },
  'itinerarydesignhub.com': {
    key: 'vbd',
    name: 'Vacations by Design',
    legalName: 'Vacations by Design Ltd',
    slogan: 'Your journey, by design.',
    emailFrom: 'Vacations by Design <hello@thevacationsbydesign.co.uk>',
    // INTERIM: thevacationsbydesign.co.uk has NO MX records (no mailbox), so
    // internal notices (signed letters) route to the JJ inbox until a real VBD
    // mailbox exists — then set this back to hello@thevacationsbydesign.co.uk.
    supportEmail: 'hello@thejourneyjunction.co.uk',
    siteUrl: 'https://itinerarydesignhub.com',
    icon: '/vbd-app-icon.svg',
    accent: '#3A5647',           // Sage Forest (primary)
    pop: '#EE6C3A',              // Poppy
    // Design-token overrides injected into <head> for this host — reskins every
    // var(--green*) colour app-wide without touching the page source.
    green: '#3A5647', greenDark: '#2E4639', greenMid: '#7FA187', greenLight: '#E9EFEA',
    // Email header: raster PNG (email clients strip SVG) — the rounded VBD
    // app-icon tile, shown as a round 32px logo beside the wordmark.
    emailLogoImg: 'https://itinerarydesignhub.com/vbd-app-icon.png',
    wordmarkLead: 'Vacations ',
    wordmarkAccent: 'by Design',
    footer: 'Vacations by Design Ltd · 9 Sharmans Close, Digswell, Welwyn, Hertfordshire, AL6 0AR · Company No. 03039047',
  },
}

// Resolve the brand for a request host. Strips port + leading www., and
// defaults to Journey Junction for anything unknown (workers.dev preview,
// localhost, apex/www variants not explicitly listed).
function brandFor(host) {
  const h = String(host || '').toLowerCase().replace(/:\d+$/, '').replace(/^www\./, '')
  return BRANDS[h] || BRANDS['journeyjunctionplanner.com']
}

// Resolve a brand by its key ('jj' / 'vbd') — used to brand a letter/email by
// the PLANNER's stored brand rather than the admin's viewing domain. Unknown /
// missing key → Journey Junction.
function brandByKey(key) {
  for (const h in BRANDS) if (BRANDS[h].key === key) return BRANDS[h]
  return BRANDS['journeyjunctionplanner.com']
}

// NOTE: the visual skin is applied CLIENT-SIDE by /brand-boot.js, not here.
// On this project's Cloudflare setup static files (.html/images) are served
// directly by the asset layer and never invoke this Worker (it only runs for
// /api/*), so Worker-side HTML injection / asset-swap can't work. The Worker's
// brand role is limited to the outbound-email identity below (brandFor + the
// email handlers), which ARE /api/* routes.

export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // Load secrets from the Worker environment into the module-level
    // vars the handlers read. Set via `wrangler secret put RESEND_API_KEY`.
    // Falls back to empty string — handlers already guard with a 500 when
    // the key is missing, so a forgotten secret fails loud, not silent.
    if (env.RESEND_API_KEY) RESEND_API_KEY = env.RESEND_API_KEY
    // Prefer the rotated service-role key from the Worker secret over the
    // committed fallback. Once the secret is set in production this is the
    // only key in use; the literal above can then be deleted.
    // .trim() — a stray newline/space from pasting the value into the
    // Cloudflare secret box would make Headers.set('Authorization', …) throw
    // (an invalid header character), crashing the proxy with a 1101.
    if (env.SUPABASE_SERVICE_KEY) SUPABASE_SERVICE_KEY = String(env.SUPABASE_SERVICE_KEY).trim()

    // Which brand is this request for? (hostname → skin + email identity)
    const brand = brandFor(url.hostname)

    // ── Supabase API proxy (admin/CS only — gates the service-role key) ──
    // Browser-side Supabase clients in superadmin999.html / supercs999.html
    // point at `/api/sb` instead of the real Supabase URL. Every request is
    // re-authenticated against Basic Auth and re-signed server-side with the
    // service-role key — the key never leaves the worker.
    //
    //   /api/sb/rest/v1/<table>          → Supabase PostgREST
    //   /api/sb/auth/v1/admin/users/<id> → Supabase auth admin (delete user)
    //   /api/sb/storage/v1/<bucket>/<…>  → Supabase storage
    if (url.pathname.startsWith('/api/sb/')) {
      return handleSupabaseProxy(request, url)
    }

    // ── Email-proxy endpoint (admin only) ──
    if (url.pathname === '/api/send-approval' && request.method === 'POST') {
      return handleSendApproval(request, brand)
    }

    // ── Create-planner endpoint (admin only) ──
    if (url.pathname === '/api/create-planner' && request.method === 'POST') {
      return handleCreatePlanner(request, brand)
    }

    // ── Employment-letter endpoints ──
    if (url.pathname === '/api/send-employment-letter' && request.method === 'POST') {
      return handleSendEmploymentLetter(request, url, brand)
    }
    if (url.pathname === '/api/letter' && request.method === 'GET') {
      return handleGetLetter(request, url)
    }
    if (url.pathname === '/api/letter/sign' && request.method === 'POST') {
      return handleSignLetter(request, url, brand)
    }

    // ── Branded password-reset email (public) ──
    if (url.pathname === '/api/send-reset' && request.method === 'POST') {
      return handleSendReset(request)
    }

    // ── Translation endpoint (CS console JA→EN) ──
    if (url.pathname === '/api/translate' && request.method === 'POST') {
      return handleTranslate(request, env)
    }

    // ── Static page Basic Auth gate ──
    // Cloudflare Pages serves /superadmin999.html ALSO at /superadmin999
    // (extension stripped). Normalize both forms so the gate isn't bypassable
    // by hitting the extensionless URL. checkAuth still gets the canonical
    // .html form so the credential allow-list keeps matching.
    const normalizedPath = url.pathname.replace(/\.html$/, '').replace(/\/$/, '')
    const protectedNormalized = PROTECTED_PATHS.map(p => p.replace(/\.html$/, ''))
    if (protectedNormalized.includes(normalizedPath)) {
      if (!checkAuth(request, normalizedPath + '.html')) return challenge()
    }

    if (env.ASSETS) {
      const assetResp = await env.ASSETS.fetch(request)
      // Always revalidate HTML so a fresh deploy shows up immediately instead of
      // the browser serving a stale cached page (the recurring "I changed it but
      // still see the old one"). The browser still caches, but must check with a
      // conditional request first — unchanged files come back as a cheap 304;
      // only genuinely new HTML is re-downloaded. Non-HTML assets (images, etc.)
      // keep their normal long-lived caching.
      if ((assetResp.headers.get('content-type') || '').includes('text/html')) {
        const h = new Headers(assetResp.headers)
        h.set('Cache-Control', 'no-cache')
        return new Response(assetResp.body, { status: assetResp.status, statusText: assetResp.statusText, headers: h })
      }
      return assetResp
    }
    return new Response('Static assets binding missing.', { status: 500 })
  }
}

// Supabase API proxy. Forwards `/api/sb/<…>` to `<SUPABASE_URL>/<…>` after
// substituting the apikey/Authorization headers with the server-held
// service-role key. Pure 1:1 forward — same status, body, and (most) headers
// — so the Supabase JS client doesn't know it's proxied.
//
// Auth model: we accept either
//   (a) a Referer header from one of the protected pages (browser sets this
//       automatically on same-origin fetch — only users who passed the
//       page-level Basic Auth can load those pages), OR
//   (b) Basic Auth credentials directly (for curl/server-to-server use).
//
// Returning 401 with WWW-Authenticate on every Supabase XHR triggered the
// browser to re-prompt for credentials on each request — using Referer
// avoids that re-prompt while still gating direct external access.
async function handleSupabaseProxy(request, url) {
  if (!isProxyAuthorized(request, url)) {
    // 403 (no challenge) — don't trigger a Basic-Auth prompt for in-page calls
    return jsonResp(403, { error: 'Forbidden' })
  }

  if (!SUPABASE_SERVICE_KEY || SUPABASE_SERVICE_KEY.startsWith('PASTE_')) {
    return jsonResp(500, { error: 'Supabase service-role key not configured in worker' })
  }

  // /api/sb/rest/v1/foo  →  /rest/v1/foo
  const targetPath = url.pathname.replace('/api/sb', '')

  // Allowlist — even an authorized caller can only reach the tables / RPCs /
  // buckets the admin + CS consoles actually use, and the one auth-admin op
  // (delete user). This caps the blast radius of the service-role key: a forged
  // request can't hit arbitrary tables, create auth users, or call /auth, /functions.
  if (!isProxyTargetAllowed(request.method, targetPath)) {
    return jsonResp(403, { error: 'Forbidden target' })
  }

  const targetUrl  = SUPABASE_URL + targetPath + url.search

  // Clone request headers, swap auth, strip browser-only ones. Guard the
  // header set: an invalid character in the key (e.g. a pasted newline) makes
  // Headers.set throw — return a clean 500 instead of an opaque 1101 crash.
  const fwdHeaders = new Headers(request.headers)
  try {
    fwdHeaders.set('apikey', SUPABASE_SERVICE_KEY)
    fwdHeaders.set('Authorization', `Bearer ${SUPABASE_SERVICE_KEY}`)
  } catch (e) {
    return jsonResp(500, { error: 'Service key is malformed (check the Worker secret for stray whitespace/newline)' })
  }
  fwdHeaders.delete('host')
  fwdHeaders.delete('cookie')
  fwdHeaders.delete('cf-connecting-ip')
  fwdHeaders.delete('cf-ray')
  fwdHeaders.delete('cf-visitor')
  fwdHeaders.delete('x-forwarded-for')
  fwdHeaders.delete('x-forwarded-proto')
  fwdHeaders.delete('x-real-ip')
  // Strip browser-fingerprint headers. Supabase's NEW secret keys (sb_secret_)
  // are rejected with UNAUTHORIZED_INVALID_API_KEY_TYPE ("Forbidden use of secret
  // API key in browser") when the request carries browser markers like Origin /
  // Sec-Fetch-* / a web x-client-info. This proxy IS a trusted server-side caller,
  // so remove those markers (and the page Referer/UA) before forwarding so the
  // secret key is accepted as a server credential.
  fwdHeaders.delete('origin')
  fwdHeaders.delete('referer')
  fwdHeaders.delete('sec-fetch-site')
  fwdHeaders.delete('sec-fetch-mode')
  fwdHeaders.delete('sec-fetch-dest')
  fwdHeaders.delete('sec-fetch-user')
  fwdHeaders.delete('sec-ch-ua')
  fwdHeaders.delete('sec-ch-ua-mobile')
  fwdHeaders.delete('sec-ch-ua-platform')
  fwdHeaders.delete('x-client-info')
  fwdHeaders.set('user-agent', 'journey-junction-worker')

  // Forward body for non-GET/HEAD. ArrayBuffer preserves binary uploads
  // (storage multipart) without forcing a string conversion.
  let body
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    body = await request.arrayBuffer()
  }

  let upstream
  try {
    upstream = await fetch(targetUrl, { method: request.method, headers: fwdHeaders, body })
  } catch (e) {
    return jsonResp(502, { error: 'Upstream Supabase fetch failed: ' + (e?.message || 'unknown') })
  }

  // Pass response 1:1, but strip any upstream CORS/cookies that don't apply.
  const respHeaders = new Headers(upstream.headers)
  respHeaders.delete('access-control-allow-origin')
  respHeaders.delete('access-control-allow-credentials')
  respHeaders.delete('set-cookie')

  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: respHeaders
  })
}

// POST /api/create-planner — admin-only direct planner-account creation.
// Bypasses application/approval flow. Uses service-role key to create the
// auth user (email pre-confirmed, no signup verification email) and insert
// a matching row in the `planners` table.
async function handleCreatePlanner(request, brand) {
  const cred = checkAuth(request, null)
  if (!cred || cred.user !== 'admin') return challenge()

  if (!SUPABASE_SERVICE_KEY || SUPABASE_SERVICE_KEY.startsWith('PASTE_')) {
    return jsonResp(500, { error: 'Supabase service-role key not configured in worker' })
  }

  let body
  try { body = await request.json() } catch (_) {
    return jsonResp(400, { error: 'Invalid JSON' })
  }
  const { name, email, phone, password, is_subaccount } = body || {}
  if (!name || !email || !password) {
    return jsonResp(400, { error: 'Missing required fields: name, email, password' })
  }
  if (String(password).length < 8) {
    return jsonResp(400, { error: 'Password must be at least 8 characters' })
  }

  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }

  // Step 1 — create the auth user (email auto-confirmed)
  const authResp = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: sbHeaders,
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, phone: phone || null }
    })
  })
  const authJson = await authResp.json().catch(() => ({}))
  if (!authResp.ok) {
    return jsonResp(authResp.status, { error: authJson?.msg || authJson?.error_description || authJson?.message || 'Auth user creation failed' })
  }
  const userId = authJson?.id || authJson?.user?.id
  if (!userId) {
    return jsonResp(500, { error: 'No user ID returned from auth API' })
  }

  // Step 2 — insert the planner row keyed by the auth user id.
  // `city` is NOT NULL on planners; default to 'Tokyo' for direct-create
  // accounts (admin can edit later via Manage planners → Edit).
  // `admin_created=true` flags this row so the admin UI can show a badge
  // distinguishing direct-create accounts from application-flow planners.
  const planRow = {
    id: userId,
    name,
    email,
    phone: phone || null,
    city: 'Tokyo',
    admin_created: true,
    is_subaccount: !!is_subaccount,
    // Direct-created planners take the brand of the admin console they were
    // created from (jj / vbd).
    brand: brand.key
  }
  let planResp = await fetch(`${SUPABASE_URL}/rest/v1/planners`, {
    method: 'POST',
    headers: { ...sbHeaders, 'Prefer': 'return=representation' },
    body: JSON.stringify(planRow)
  })
  if (!planResp.ok) {
    // Maybe the `brand` column isn't migrated yet — retry without it before
    // giving up (and before the orphan-user cleanup below).
    const noBrand = Object.assign({}, planRow); delete noBrand.brand
    planResp = await fetch(`${SUPABASE_URL}/rest/v1/planners`, {
      method: 'POST',
      headers: { ...sbHeaders, 'Prefer': 'return=representation' },
      body: JSON.stringify(noBrand)
    })
  }
  if (!planResp.ok) {
    const errText = await planResp.text().catch(() => '')
    // Best-effort cleanup: delete the orphan auth user so admin can retry
    await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'DELETE',
      headers: sbHeaders
    }).catch(() => {})
    return jsonResp(planResp.status, { error: 'Planner row insert failed: ' + errText })
  }

  return jsonResp(200, { ok: true, planner_id: userId, email })
}

// Authorize a Supabase proxy request. Allows:
//   1. Same-origin requests whose Referer points at one of the protected
//      pages — these can only originate from a browser tab that already
//      passed the page-level Basic Auth gate.
//   2. Requests carrying valid Basic Auth (for curl, server-to-server, or
//      the rare browser that strips Referer).
// Tables / RPCs / buckets the admin + CS consoles legitimately touch through
// the proxy. Derived by scanning every sb.from()/rpc()/storage.from() call in
// superadmin999.html + supercs999.html (incl. the best-effort planner-deletion
// cleanup loop and the postpone dev tool). Anything else is denied.
const PROXY_ALLOWED_TABLES = new Set([
  'audit_log','conversations','cs_quick_replies','employment_letters',
  'itinerary_items','item_images','legal_docs','messages','payouts','planner_applications','planners',
  'plans','platform_settings','set_assignments','sets','support_tickets',
  'travelers','wallet_adjustments','wallet_pending_payments','wallet_requests',
  // Mentor tracker (/supermentor999.html — see docs/schema/supermentor-tracker.sql)
  'planner_problems','planner_problem_steps','planner_remarks',
  // Best-effort cleanup targets (may not exist; wrapped in try/catch client-side)
  'wallet_ledger','chat_messages','typing_drafts',
  // Per-planner API usage console (/superapi999.html — docs/schema/api-usage-tracking.sql)
  'api_usage_daily',
])
const PROXY_ALLOWED_RPCS    = new Set(['postpone_all_travelers'])
const PROXY_ALLOWED_BUCKETS = new Set(['chat-media', 'letter-ids'])

function isProxyTargetAllowed(method, targetPath) {
  const m = (method || 'GET').toUpperCase()
  // PostgREST: /rest/v1/<table>  or  /rest/v1/rpc/<fn>
  const rpc = targetPath.match(/^\/rest\/v1\/rpc\/([a-zA-Z0-9_]+)/)
  if (rpc) return m === 'POST' && PROXY_ALLOWED_RPCS.has(rpc[1])
  const rest = targetPath.match(/^\/rest\/v1\/([a-zA-Z0-9_]+)/)
  if (rest) {
    return PROXY_ALLOWED_TABLES.has(rest[1]) &&
           ['GET','HEAD','POST','PATCH','DELETE'].includes(m)
  }
  // Auth admin: ONLY delete-user (DELETE /auth/v1/admin/users/<id>). Block
  // create/list and every other /auth path.
  if (targetPath.startsWith('/auth/v1/admin/users')) return m === 'DELETE'
  // Storage: ONLY object operations on an allowed bucket. Parse the actual
  // bucket SEGMENT (the part right after object/[public|sign|info|upload|
  // authenticated]/) instead of a loose substring match — a substring check
  // like includes('/chat-media/') let a crafted path target a different bucket
  // by smuggling the literal into an object key. This also blocks the
  // bucket-management API (/storage/v1/bucket).
  const stor = targetPath.match(
    /^\/storage\/v1\/object\/(?:(?:public|sign|info|authenticated|upload|list)\/)*([a-z0-9][a-z0-9._-]*)(?:\/|$)/i)
  if (stor) return PROXY_ALLOWED_BUCKETS.has(stor[1])
  return false
}

function isProxyAuthorized(request, url) {
  // Require a shared secret token that the gated admin/CS consoles send on every
  // /api/sb request (header `x-jj-proxy`), OR explicit Basic Auth (curl/server).
  //
  // The token equals the admin/CS password, which is ONLY obtainable by someone
  // who already passed the page-level Basic Auth gate to load the console HTML.
  // The previous check trusted the `Referer` header — which any caller can forge
  // — so an unauthenticated stranger could drive the service-role key with a
  // one-line curl. Referer trust is removed; a forged Referer alone no longer
  // grants access. (`url` kept for signature compatibility.)
  const tok = request.headers.get('x-jj-proxy') || ''
  if (tok && CREDENTIALS.some(c => safeEqual(tok, c.pass))) return true
  return !!checkAuth(request, null)
}

// Verify the request carries valid Basic Auth for the given path.
// Returns the matching credential entry on success, null on failure.
function checkAuth(request, pathname) {
  const auth = request.headers.get('Authorization') || ''
  if (!auth.startsWith('Basic ')) return null
  let decoded
  try { decoded = atob(auth.slice(6)) } catch (_) { return null }
  const idx = decoded.indexOf(':')
  if (idx < 0) return null
  const user = decoded.slice(0, idx)
  const pass = decoded.slice(idx + 1)

  for (const c of CREDENTIALS) {
    if (safeEqual(c.user, user) && safeEqual(c.pass, pass)) {
      // If a path is given, also enforce the allow-list for that path.
      if (pathname && !c.allow.includes(pathname)) continue
      return c
    }
  }
  return null
}

// POST /api/send-approval — admin-only proxy to Resend
async function handleSendApproval(request, brand) {
  // Require Basic Auth, restricted to the 'admin' credential.
  const cred = checkAuth(request, null)
  if (!cred || cred.user !== 'admin') return challenge()

  if (!RESEND_API_KEY || RESEND_API_KEY.startsWith('PASTE_')) {
    return jsonResp(500, { error: 'Resend API key not configured in worker' })
  }

  let body
  try { body = await request.json() } catch (_) {
    return jsonResp(400, { error: 'Invalid JSON' })
  }
  const { to, subject, html, text, brand: bodyBrand } = body
  if (!to || !subject || (!html && !text)) {
    return jsonResp(400, { error: 'Missing required fields: to, subject, html|text' })
  }
  // The approval email is branded by the APPLICANT's brand (superadmin sends it
  // as `brand`), not the admin's viewing domain — so a Vacations by Design
  // applicant's welcome comes from the VBD sender. brandByKey only ever maps to
  // a verified sender ('jj'/'vbd'), so honouring it can't spoof an arbitrary from.
  const sendBrand = bodyBrand ? brandByKey(bodyBrand) : brand
  // Validate recipients are well-formed addresses (string or array). Stops this
  // authed endpoint from being abused as a generic relay with junk targets.
  const _emailRe = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  const _recips  = Array.isArray(to) ? to : [to]
  if (!_recips.length || !_recips.every(r => typeof r === 'string' && _emailRe.test(r.trim()))) {
    return jsonResp(400, { error: 'Invalid recipient address' })
  }

  const resendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      // FORCE a verified sender (the applicant's brand) — never honour a raw
      // client-supplied `from` string, so this can't be used to spoof mail.
      from: sendBrand.emailFrom,
      to,
      subject,
      html,
      text
    })
  })

  const respText = await resendResp.text()
  return new Response(respText, {
    status: resendResp.status,
    headers: { 'Content-Type': 'application/json' }
  })
}

function jsonResp(status, obj) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' }
  })
}

function challenge() {
  return new Response('Authentication required', {
    status: 401,
    headers: {
      'WWW-Authenticate': 'Basic realm="Journey Junction Admin", charset="UTF-8"',
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  })
}

// POST /api/send-employment-letter — admin only.
// Body: { planner_id, planner_name, planner_email, start_date }
// Creates the employment_letters row + emails the planner with a signing link.
async function handleSendEmploymentLetter(request, url, brand) {
  const cred = checkAuth(request, null)
  if (!cred || cred.user !== 'admin') return challenge()
  if (!SUPABASE_SERVICE_KEY || !RESEND_API_KEY) {
    return jsonResp(500, { error: 'Worker secrets not configured' })
  }

  let body
  try { body = await request.json() } catch (_) { return jsonResp(400, { error: 'Invalid JSON' }) }
  const { planner_id, planner_name, planner_email, start_date, letter_type, custom_body } = body || {}
  if (!planner_id || !planner_name || !planner_email || !start_date) {
    return jsonResp(400, { error: 'Missing required fields' })
  }

  // The letter's identity follows the PLANNER (their stored brand), NOT the
  // admin's viewing domain — so a Journey Junction planner always gets a Journey
  // Junction contract even if issued from the VBD console, and vice-versa. This
  // reassignment flows through every brand.* use below (email from/footer/
  // wordmark, signing-link domain, and the stored letter.brand). Falls back to
  // the request-domain brand if the lookup fails or the brand column is absent.
  try {
    const pr = await fetch(
      `${SUPABASE_URL}/rest/v1/planners?id=eq.${encodeURIComponent(planner_id)}&select=brand`,
      { headers: { apikey: SUPABASE_SERVICE_KEY, Authorization: `Bearer ${SUPABASE_SERVICE_KEY}` } }
    )
    if (pr.ok) {
      const pj = await pr.json().catch(() => null)
      const bk = pj && pj[0] && pj[0].brand
      if (bk) brand = brandByKey(bk)
    }
  } catch (e) { /* keep the request-domain brand as fallback */ }

  // Three letter kinds share this endpoint:
  //   'employment'         — fixed contract body (no custom_body)
  //   'guarantee'          — admin-edited 保証書 body
  //   'final_confirmation' — admin-edited 最終確認書 body + ID upload on signing
  const isGuarantee = letter_type === 'guarantee'
  const isFinalConfirm = letter_type === 'final_confirmation'
  const isEditable = isGuarantee || isFinalConfirm
  if (isEditable && (!custom_body || !String(custom_body).trim())) {
    return jsonResp(400, { error: 'Letter body is required' })
  }

  // 1. Insert the row (service role bypasses RLS). letter_type / custom_body are
  //    ONLY sent for an editable letter — an employment letter inserts exactly
  //    the original fields, so it is unaffected even if the guarantee migration
  //    (add-guarantee-letters.sql) has not been run yet.
  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  }
  const insertRow = {
    planner_id,
    planner_name,
    planner_email,
    start_date,
    created_by: cred.user,
    // Which company issued this letter (jj / vbd). Stored per-letter so the
    // contract ALWAYS renders its issuing brand, never the viewing domain — an
    // existing Journey Junction contract can never be reskinned to another brand.
    brand: brand.key
  }
  if (isEditable) {
    insertRow.letter_type = isFinalConfirm ? 'final_confirmation' : 'guarantee'
    insertRow.custom_body = String(custom_body)
  }
  let insertResp = await fetch(`${SUPABASE_URL}/rest/v1/employment_letters`, {
    method: 'POST',
    headers: sbHeaders,
    body: JSON.stringify(insertRow)
  })
  // Defensive: if the `brand` column doesn't exist yet (add-letter-brand.sql not
  // run), retry without it so letter creation never breaks. Such a letter then
  // reads back as Journey Junction (the default) — run the migration to brand
  // VBD letters correctly.
  if (!insertResp.ok) {
    const noBrand = Object.assign({}, insertRow); delete noBrand.brand
    insertResp = await fetch(`${SUPABASE_URL}/rest/v1/employment_letters`, {
      method: 'POST',
      headers: sbHeaders,
      body: JSON.stringify(noBrand)
    })
  }
  if (!insertResp.ok) {
    const errText = await insertResp.text().catch(() => '')
    return jsonResp(insertResp.status, { error: 'DB insert failed: ' + errText })
  }
  const rows = await insertResp.json()
  const row = Array.isArray(rows) ? rows[0] : rows
  if (!row?.signing_token) {
    return jsonResp(500, { error: 'No signing token returned' })
  }

  // 2. Build the signing link — canonical branded domain, clean URL (no .html).
  //    The site serves /sign-letter and 308-redirects /sign-letter.html while
  //    preserving the ?token, so this is the tidy form planners see.
  const signUrl = `${brand.siteUrl}/sign-letter?token=${encodeURIComponent(row.signing_token)}`
  const firstName = escapeForEmail((planner_name || '').trim().split(/\s+/)[0] || planner_name || '')
  // Brand-derived bits for the email template (JJ values reproduce the original output).
  const bAccent = brand.accent || '#1a7a5e'
  const bName   = brand.name
  const bFooter = brand.footer || 'Journey Junction Ltd · Birmingham, United Kingdom · Company No. 15791277'
  // Header identity: a raster round logo when the brand supplies one (JJ), else a
  // text wordmark (email clients strip SVG, so brands with only an SVG mark get text).
  const bLogoCell = brand.emailLogoImg
    ? `<td style="vertical-align:middle;padding-right:10px;"><img src="${brand.emailLogoImg}" alt="${bName}" width="32" height="32" style="display:block;border-radius:50%;border:0;outline:none;text-decoration:none;"></td>`
    : ''
  const bWordmark = brand.wordmarkLead
    ? `${brand.wordmarkLead}<span style="color:${bAccent};font-style:italic;">${brand.wordmarkAccent}</span>`
    : `Journey<span style="color:${bAccent};font-style:italic;">Junction</span>`
  // Per-type email copy. Employment strings are unchanged; guarantee uses the
  // approved 保証書 copy; final_confirmation uses 最終確認書 + an ID-upload note.
  const docName   = isFinalConfirm ? '最終確認書' : isGuarantee ? '保証書' : '業務委託契約書'
  const docNameEn = isFinalConfirm ? 'final confirmation letter' : isGuarantee ? 'letter of guarantee' : 'service agreement'
  const headingSuffix = isEditable ? 'のご確認およびご署名のお願い' : 'ご確認のお願い'
  const signVerb      = isEditable ? '確認・署名する' : '確認して署名する'
  const introJa = isFinalConfirm
    ? `このたび、${bName}より最終確認書を発行いたしました。内容をご確認のうえ、ご本人確認書類（身分証明書）の添付とご署名をお願いいたします。`
    : isGuarantee
    ? `このたび、${bName}より保証書を発行いたしました。内容をご確認のうえ、ご署名をお願いいたします。`
    : `この度は、${bName} の訪日旅行プランナーへご応募・ご登録いただき、誠にありがとうございます。`
  const linkPrivacyJa = isEditable
    ? 'このリンクはご本人様専用となっておりますので、第三者への共有はお控えください。'
    : 'このリンクはご本人様専用ですので、第三者と共有されないようお願いいたします。'
  const bodyEn = isFinalConfirm
    ? `${bName} has issued your Final Confirmation Letter. Please review it, attach your identity document, and sign using the button above. This link is personal to you. Please do not share it with anyone else.`
    : isGuarantee
    ? `${bName} has issued your Guarantee Letter. Please review and sign it using the button above. This link is personal to you. Please do not share it with anyone else.`
    : `Thank you for joining ${bName} as a Japan Inbound Travel Planner. Please review and sign your ${docNameEn} using the button above. This link is personal to you; please do not share it.`

  // 3. Email the planner (Resend) — Japanese (primary) + English.
  //    Chrome mirrors the approval email (buildApprovalEmailHtml in
  //    superadmin999.html): table-based layout (email-client safe — no flex),
  //    gradient divider, and the branded company-registration footer.
  const emailHtml = `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f5f4f0;padding:40px 20px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','DM Sans',Helvetica,Arial,sans-serif;">
  <tr><td align="center">
    <table role="presentation" width="480" cellpadding="0" cellspacing="0" border="0" style="background:#ffffff;border:1px solid rgba(0,0,0,0.06);border-radius:14px;overflow:hidden;">

      <tr><td style="padding:32px 36px 8px 36px;">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0">
          <tr>
            ${bLogoCell}
            <td style="vertical-align:middle;font-family:Georgia,'DM Serif Display',serif;font-size:22px;color:#1a1a18;letter-spacing:-0.4px;">
              ${bWordmark}
            </td>
          </tr>
        </table>
        <div style="height:1px;background:linear-gradient(90deg,transparent,rgba(176,138,62,0.35),transparent);margin-top:18px;"></div>
      </td></tr>

      <tr><td style="padding:24px 36px 4px 36px;">
        <h1 style="margin:0 0 12px;font-family:Georgia,'DM Serif Display',serif;font-size:24px;font-weight:400;color:#1a1a18;letter-spacing:-0.2px;">
          <em style="font-style:italic;color:${bAccent};">${docName}</em>${headingSuffix}
        </h1>
        <p style="margin:0 0 14px;font-size:14px;line-height:1.6;color:#5a554c;">${firstName} 様</p>
        <p style="margin:0 0 14px;font-size:14px;line-height:1.6;color:#5a554c;">${introJa}</p>
        <p style="margin:0 0 22px;font-size:14px;line-height:1.6;color:#5a554c;">下記のボタンより${docName}をご確認のうえ、ご署名をお願いいたします。${linkPrivacyJa}</p>
      </td></tr>

      <tr><td style="padding:0 36px 8px 36px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
          <tr><td align="center" style="padding:6px 0 14px;">
            <a href="${signUrl}" style="display:inline-block;background:${bAccent};color:#ffffff;text-decoration:none;padding:12px 26px;border-radius:8px;font-size:14px;font-weight:500;letter-spacing:0.02em;">${docName}を${signVerb} →</a>
          </td></tr>
        </table>
      </td></tr>

      <tr><td style="padding:0 36px 4px 36px;">
        <p style="margin:0;font-size:12px;line-height:1.6;color:#8c8678;">ボタンが動作しない場合は、以下のリンクをコピーしてブラウザに貼り付けてください：<br><a href="${signUrl}" style="color:${bAccent};word-break:break-all;">${signUrl}</a></p>
      </td></tr>

      <tr><td style="padding:18px 36px 28px 36px;">
        <div style="height:1px;background:rgba(0,0,0,0.06);margin-bottom:14px;"></div>
        <p style="margin:0;font-size:12px;line-height:1.55;color:#8c8678;"><strong style="color:#7a7a74;">English</strong> — ${bodyEn}</p>
      </td></tr>

      <tr><td style="background:#faf7ef;padding:18px 36px;border-top:1px solid rgba(0,0,0,0.05);">
        <p style="margin:0;font-size:11px;line-height:1.55;color:#8c8678;">
          ${bFooter}
        </p>
      </td></tr>
    </table>
  </td></tr>
</table>`
  const resendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: brand.emailFrom,
      to: planner_email,
      subject: `${bName} — ${docName}${isEditable ? 'のご確認およびご署名のお願い' : 'へのご署名のお願い'}`,
      html: emailHtml
    })
  })
  if (!resendResp.ok) {
    const errText = await resendResp.text().catch(() => '')
    // Email failed but row was inserted — return partial success
    return jsonResp(200, { ok: true, letter_id: row.id, signing_token: row.signing_token, email_warning: errText })
  }

  return jsonResp(200, { ok: true, letter_id: row.id, signing_token: row.signing_token, sign_url: signUrl })
}

// GET /api/letter?token=xxx — public. Returns minimal letter info needed for
// the sign page. Token IS the auth.
async function handleGetLetter(request, url) {
  if (!SUPABASE_SERVICE_KEY) return jsonResp(500, { error: 'Worker not configured' })
  const token = url.searchParams.get('token')
  if (!token) return jsonResp(400, { error: 'Missing token' })

  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
  }
  // Request the guarantee + brand columns too; if a migration hasn't run yet,
  // fall back progressively so the sign page still works. Missing letter_type →
  // treated as employment; missing brand → treated as Journey Junction.
  const base = `${SUPABASE_URL}/rest/v1/employment_letters?signing_token=eq.${encodeURIComponent(token)}&select=id,planner_name,planner_email,start_date,status,signed_at,signature_image_url`
  let resp = await fetch(base + ',letter_type,custom_body,brand', { headers: sbHeaders })
  if (!resp.ok) resp = await fetch(base + ',letter_type,custom_body', { headers: sbHeaders }) // brand column absent
  if (!resp.ok) resp = await fetch(base, { headers: sbHeaders })                              // guarantee columns absent too
  if (!resp.ok) return jsonResp(500, { error: 'DB lookup failed' })
  const rows = await resp.json()
  const letter = rows?.[0]
  if (!letter) return jsonResp(404, { error: 'Letter not found' })
  return jsonResp(200, letter)
}

// POST /api/letter/sign — public. Body: { token, signature_data_url, user_agent }
// Validates the token, uploads the signature PNG to storage, updates the row,
// emails support@. Single round-trip from the sign page.
async function handleSignLetter(request, url, brand) {
  if (!SUPABASE_SERVICE_KEY || !RESEND_API_KEY) {
    return jsonResp(500, { error: 'Worker not configured' })
  }
  let body
  try { body = await request.json() } catch (_) { return jsonResp(400, { error: 'Invalid JSON' }) }
  const { token, signature_data_url, id_image_data_url, user_agent } = body || {}
  if (!token || !signature_data_url) return jsonResp(400, { error: 'Missing token or signature' })
  // Cap the inline signature (stored in a text column + emailed as an attachment)
  // to ~1.5 MB of data-URL — a drawn signature is only a few KB, so this stops
  // storage-bloat / payload abuse on this public endpoint.
  if (typeof signature_data_url !== 'string' || signature_data_url.length > 1_500_000) {
    return jsonResp(413, { error: 'Signature too large' })
  }
  // ID photo (final confirmation only) is downscaled client-side to a JPEG, but
  // cap generously at ~6 MB of data-URL as an abuse guard.
  if (id_image_data_url != null && (typeof id_image_data_url !== 'string' || id_image_data_url.length > 6_000_000)) {
    return jsonResp(413, { error: 'ID image too large' })
  }

  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }

  // 1. Validate the letter exists and is pending. letter_type may be absent on
  //    old rows / pre-migration DBs — retry without it so signing still works.
  let fetchResp = await fetch(
    `${SUPABASE_URL}/rest/v1/employment_letters?signing_token=eq.${encodeURIComponent(token)}&select=id,planner_name,planner_email,start_date,status,letter_type`,
    { headers: sbHeaders }
  )
  if (!fetchResp.ok) {
    fetchResp = await fetch(
      `${SUPABASE_URL}/rest/v1/employment_letters?signing_token=eq.${encodeURIComponent(token)}&select=id,planner_name,planner_email,start_date,status`,
      { headers: sbHeaders }
    )
  }
  if (!fetchResp.ok) return jsonResp(500, { error: 'DB lookup failed' })
  const rows = await fetchResp.json()
  const letter = rows?.[0]
  if (!letter)                       return jsonResp(404, { error: 'Letter not found' })
  if (letter.status === 'signed')    return jsonResp(409, { error: 'Already signed' })
  if (letter.status === 'cancelled') return jsonResp(410, { error: 'Letter cancelled' })
  // Positively require 'pending' — don't allow signing a letter in any other/
  // unknown/null state (e.g. a future 'expired'/'revoked').
  if (letter.status !== 'pending')   return jsonResp(409, { error: 'Letter is not awaiting signature' })

  // A final confirmation letter MUST carry an identity document.
  const needsId = letter.letter_type === 'final_confirmation'
  if (needsId && !id_image_data_url) return jsonResp(400, { error: 'Identity document is required' })

  // 2. Validate it's a PNG data URL and keep the raw base64 (for the email
  //    attachment). data URL shape: "data:image/png;base64,xxx"
  const m = signature_data_url.match(/^data:image\/png;base64,(.+)$/)
  if (!m) return jsonResp(400, { error: 'Signature must be PNG data URL' })
  const b64 = m[1]

  // 3. Persist the signature INLINE as the data URL itself — no storage bucket.
  //    The `employment-letter-signatures` bucket isn't provisioned in the live
  //    project (schema drift from initial.sql), so an upload 404s with
  //    "Bucket not found". A drawn signature is only a few KB, well within a
  //    text column, and the sign page / admin render it straight from the
  //    data URL in an <img src>. This removes the bucket dependency entirely.
  const imageUrl = signature_data_url
  const signedAt = new Date().toISOString()

  // 3b. If an ID document was supplied (final confirmation), upload it to the
  //     PRIVATE 'letter-ids' bucket via the service role. Stored as a path only
  //     (bucket is private) — the admin console downloads it through the proxy.
  //     A failed upload must NOT silently drop the ID, so we hard-fail here.
  let idPath = null
  if (id_image_data_url) {
    const im = String(id_image_data_url).match(/^data:image\/(png|jpe?g|webp);base64,(.+)$/)
    if (!im) return jsonResp(400, { error: 'ID document must be a PNG/JPEG/WebP data URL' })
    const ext = im[1] === 'png' ? 'png' : im[1] === 'webp' ? 'webp' : 'jpg'
    const idBytes = Uint8Array.from(atob(im[2]), c => c.charCodeAt(0))
    idPath = `${letter.id}/id_${Date.now()}.${ext}`
    const upResp = await fetch(`${SUPABASE_URL}/storage/v1/object/letter-ids/${idPath}`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': `image/${im[1] === 'jpg' ? 'jpeg' : im[1]}`,
        'x-upsert': 'true'
      },
      body: idBytes
    })
    if (!upResp.ok) {
      console.error('ID upload failed:', await upResp.text().catch(() => ''))
      return jsonResp(500, { error: 'Could not store the identity document' })
    }
  }

  // 4. Update the letter row
  const updateFields = {
    status: 'signed',
    signed_at: signedAt,
    signature_image_url: imageUrl,
    signed_user_agent: (user_agent || '').slice(0, 500),
    signed_ip: request.headers.get('cf-connecting-ip') || null
  }
  if (idPath) { updateFields.id_image_url = idPath; updateFields.id_uploaded_at = signedAt }
  const updateResp = await fetch(
    `${SUPABASE_URL}/rest/v1/employment_letters?id=eq.${letter.id}`,
    {
      method: 'PATCH',
      headers: { ...sbHeaders, 'Prefer': 'return=minimal' },
      body: JSON.stringify(updateFields)
    }
  )
  if (!updateResp.ok) {
    console.error('letter sign update failed:', await updateResp.text().catch(() => ''))
    return jsonResp(500, { error: 'Could not record signature' })
  }

  // 5. Email support@ with the signed details
  const signedDateHuman = new Date(signedAt).toLocaleString('ja-JP')
  const docLabel = letter.letter_type === 'final_confirmation' ? 'Final confirmation letter'
                 : letter.letter_type === 'guarantee' ? 'Letter of guarantee'
                 : 'Engagement letter'
  const idLine = idPath
    ? `<p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Identity document:</strong> ✓ uploaded — view in admin (never shared by email).</p>`
    : ''
  const html = `
    <div style="font-family:Georgia,serif;max-width:520px;margin:0 auto;padding:32px;background:#f5f4f0;">
      <div style="background:#fff;border-radius:12px;padding:32px;border:1px solid rgba(0,0,0,0.08);">
        <h2 style="font-family:Georgia,serif;color:#1a1a18;margin:0 0 14px;">${docLabel} signed</h2>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Planner:</strong> ${escapeForEmail(letter.planner_name)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Email:</strong> ${escapeForEmail(letter.planner_email)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Start date:</strong> ${escapeForEmail(letter.start_date)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Signed at:</strong> ${escapeForEmail(signedDateHuman)}</p>
        ${idLine}
        <div style="margin:18px 0;padding:14px;background:#faf9f6;border:1px solid rgba(0,0,0,0.06);border-radius:8px;text-align:center;">
          <div style="font-size:11px;color:#7a7a74;text-transform:uppercase;letter-spacing:0.08em;margin-bottom:8px;">Signature</div>
          <div style="font-size:13px;color:#3a3a36;">Attached as <strong>signature.png</strong> · view in admin for the on-page copy.</div>
        </div>
        <p style="color:#7a7a74;font-size:12px;margin-top:18px;">View in admin: <a href="${url.protocol}//${url.host}/superadmin999.html" style="color:${brand.accent || '#1a7a5e'};">${url.host}/superadmin999.html</a></p>
      </div>
    </div>
  `
  // Email is best-effort; don't fail the signing if it bounces.
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: brand.emailFrom,
        to: brand.supportEmail,
        subject: `${docLabel} signed by ${letter.planner_name}`,
        html,
        attachments: [{ filename: 'signature.png', content: b64 }]
      })
    })
  } catch (_) { /* swallow — letter is signed regardless */ }

  return jsonResp(200, { ok: true, signature_url: imageUrl })
}

// Best-effort per-email cooldown (per Worker isolate) — a light guard against
// reset-email spamming. Robust rate limiting would need KV/Durable Objects.
const _resetCooldown = new Map()

// POST /api/send-reset — PUBLIC. Body { email }.
// Sends a password-reset OTP email branded by the PLANNER's brand (looked up by
// email), replacing Supabase's single global recovery template. We generate the
// recovery OTP server-side via the admin API (which does NOT send an email),
// then send our own branded email via Resend. reset.html still verifies with
// sb.auth.verifyOtp({ type: 'recovery' }) exactly as before.
// Always returns { ok: true } so it can't be used to probe which emails exist.
async function handleSendReset(request) {
  if (!SUPABASE_SERVICE_KEY || !RESEND_API_KEY) return jsonResp(500, { error: 'Worker not configured' })
  let body
  try { body = await request.json() } catch (_) { return jsonResp(400, { error: 'Invalid JSON' }) }
  const email = String(body?.email || '').trim().toLowerCase()
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return jsonResp(400, { error: 'Invalid email' })

  // Light per-isolate cooldown (30s) — silently succeeds on rapid repeats.
  const now = Date.now()
  if (now - (_resetCooldown.get(email) || 0) < 30000) return jsonResp(200, { ok: true })
  _resetCooldown.set(email, now)

  const sbHeaders = {
    apikey: SUPABASE_SERVICE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }

  // Brand = the planner's own brand (by email); defaults to Journey Junction.
  let brand = brandByKey('jj')
  try {
    const pr = await fetch(`${SUPABASE_URL}/rest/v1/planners?email=eq.${encodeURIComponent(email)}&select=brand&limit=1`, { headers: sbHeaders })
    if (pr.ok) { const j = await pr.json().catch(() => null); const bk = j && j[0] && j[0].brand; if (bk) brand = brandByKey(bk) }
  } catch (e) {}

  // Generate a recovery OTP server-side (no email is sent by this call).
  let otp = ''
  try {
    const gl = await fetch(`${SUPABASE_URL}/auth/v1/admin/generate_link`, {
      method: 'POST', headers: sbHeaders,
      body: JSON.stringify({ type: 'recovery', email })
    })
    if (gl.ok) {
      const gj = await gl.json().catch(() => null)
      otp = (gj && (gj.email_otp || (gj.properties && gj.properties.email_otp))) || ''
    }
  } catch (e) {}
  // No OTP (email isn't a user / generate failed) → return ok without sending.
  if (!otp) return jsonResp(200, { ok: true })

  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: brand.emailFrom,
        to: email,
        subject: `${brand.name} — パスワード再設定コード`,
        html: buildResetEmailHtml(brand, otp)
      })
    })
  } catch (e) { /* swallow — still return ok */ }
  return jsonResp(200, { ok: true })
}

// Branded password-reset OTP email. Same table-based chrome as the letter email
// (email-client safe). Shows the 6-digit code prominently; no magic link (the
// OTP-only flow avoids inbox link-scanners consuming a one-time token).
function buildResetEmailHtml(brand, otp) {
  const accent = brand.accent || '#1a7a5e'
  const footer = brand.footer || 'Journey Junction Ltd · Birmingham, United Kingdom · Company No. 15791277'
  const logoCell = brand.emailLogoImg
    ? `<td style="vertical-align:middle;padding-right:10px;"><img src="${brand.emailLogoImg}" alt="${escapeForEmail(brand.name)}" width="32" height="32" style="display:block;border-radius:50%;border:0;outline:none;text-decoration:none;"></td>`
    : ''
  const wordmark = brand.wordmarkLead
    ? `${brand.wordmarkLead}<span style="color:${accent};font-style:italic;">${brand.wordmarkAccent}</span>`
    : `Journey<span style="color:${accent};font-style:italic;">Junction</span>`
  return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f5f4f0;padding:40px 20px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','DM Sans',Helvetica,Arial,sans-serif;">
  <tr><td align="center">
    <table role="presentation" width="480" cellpadding="0" cellspacing="0" border="0" style="background:#ffffff;border:1px solid rgba(0,0,0,0.06);border-radius:14px;overflow:hidden;">
      <tr><td style="padding:32px 36px 8px 36px;">
        <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
          ${logoCell}
          <td style="vertical-align:middle;font-family:Georgia,'DM Serif Display',serif;font-size:22px;color:#1a1a18;letter-spacing:-0.4px;">${wordmark}</td>
        </tr></table>
        <div style="height:1px;background:linear-gradient(90deg,transparent,rgba(176,138,62,0.35),transparent);margin-top:18px;"></div>
      </td></tr>
      <tr><td style="padding:24px 36px 4px 36px;">
        <h1 style="margin:0 0 12px;font-family:Georgia,'DM Serif Display',serif;font-size:24px;font-weight:400;color:#1a1a18;">パスワードの再設定</h1>
        <p style="margin:0 0 18px;font-size:14px;line-height:1.6;color:#5a554c;">下記の認証コードを再設定ページに入力してください。有効期限は1時間です。</p>
      </td></tr>
      <tr><td style="padding:0 36px 8px 36px;">
        <div style="background:#faf9f6;border:1px solid rgba(0,0,0,0.08);border-radius:10px;padding:18px;text-align:center;">
          <div style="font-family:'JetBrains Mono',Menlo,monospace;font-size:30px;font-weight:700;letter-spacing:0.35em;color:${accent};">${escapeForEmail(otp)}</div>
        </div>
      </td></tr>
      <tr><td style="padding:14px 36px 4px 36px;">
        <p style="margin:0;font-size:12px;line-height:1.6;color:#8c8678;">このメールに心当たりがない場合は、そのまま破棄してください。パスワードは変更されません。<br><strong style="color:#7a7a74;">English</strong> — Enter this code on the password-reset page. It expires in 1 hour. If you didn't request this, ignore this email.</p>
      </td></tr>
      <tr><td style="background:#faf7ef;padding:18px 36px;border-top:1px solid rgba(0,0,0,0.05);">
        <p style="margin:0;font-size:11px;line-height:1.55;color:#8c8678;">${escapeForEmail(footer)}</p>
      </td></tr>
    </table>
  </td></tr>
</table>`
}

// HTML-escape for safe embedding in email templates
function escapeForEmail(s) {
  return String(s ?? '')
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;').replace(/'/g,'&#39;')
}

// Constant-time string compare so an attacker can't brute-force letter by
// letter via response timing.
function safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return diff === 0
}

// POST /api/translate — Cloudflare Workers AI translation for the CS console.
// Body: { text, source_lang?, target_lang? }   (defaults: japanese -> english)
// Returns: { translated }
// Same-origin only: gated by isProxyAuthorized which already accepts a
// Referer from /supercs999 or admin Basic Auth.
async function handleTranslate(request, env) {
  const url = new URL(request.url)
  if (!isProxyAuthorized(request, url)) {
    return jsonResp(403, { error: 'Forbidden' })
  }
  if (!env.AI) {
    return jsonResp(500, { error: 'AI binding not configured in this Worker' })
  }
  let body
  try { body = await request.json() } catch (_) {
    return jsonResp(400, { error: 'Invalid JSON' })
  }
  const text = String(body?.text || '').trim()
  if (!text) return jsonResp(400, { error: 'Missing text' })
  if (text.length > 5000) return jsonResp(413, { error: 'Text too long (max 5000 chars)' })

  const source_lang = String(body?.source_lang || 'japanese').toLowerCase()
  const target_lang = String(body?.target_lang || 'english').toLowerCase()
  try {
    // m2m100 handles many language pairs; expects long-form names like 'japanese'.
    const result = await env.AI.run('@cf/meta/m2m100-1.2b', {
      text,
      source_lang,
      target_lang
    })
    const translated = result?.translated_text || result?.translation || ''
    if (!translated) return jsonResp(500, { error: 'No translation returned from AI' })
    return jsonResp(200, { translated })
  } catch (e) {
    return jsonResp(500, { error: 'Translation failed: ' + (e?.message || 'unknown') })
  }
}
