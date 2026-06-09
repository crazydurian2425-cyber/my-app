// ─────────────────────────────────────────────────────────────
// Basic Auth gate + email proxy.
//   • /superadmin999.html, /supercs999.html → Basic Auth required
//   • /api/send-approval                     → Basic Auth (admin only) + forwards to Resend
//   • everything else                        → static asset serving
//
// Single shared admin credential gates both pages. CS staff use the same
// password as admin — they have full access to /superadmin999.html too,
// so only share this password with people you'd trust at admin level.
// ─────────────────────────────────────────────────────────────

const PROTECTED_PATHS = ['/superadmin999.html', '/supercs999.html']

const CREDENTIALS = [
  { user: 'admin', pass: '168168', allow: ['/superadmin999.html', '/supercs999.html'] },
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
      return handleSendApproval(request)
    }

    // ── Create-planner endpoint (admin only) ──
    if (url.pathname === '/api/create-planner' && request.method === 'POST') {
      return handleCreatePlanner(request)
    }

    // ── Employment-letter endpoints ──
    if (url.pathname === '/api/send-employment-letter' && request.method === 'POST') {
      return handleSendEmploymentLetter(request, url)
    }
    if (url.pathname === '/api/letter' && request.method === 'GET') {
      return handleGetLetter(request, url)
    }
    if (url.pathname === '/api/letter/sign' && request.method === 'POST') {
      return handleSignLetter(request, url)
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

    if (env.ASSETS) return env.ASSETS.fetch(request)
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
async function handleCreatePlanner(request) {
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
  // `city` is NOT NULL on planners; default to 'Paris' for direct-create
  // accounts (admin can edit later via Manage planners → Edit).
  // `admin_created=true` flags this row so the admin UI can show a badge
  // distinguishing direct-create accounts from application-flow planners.
  const planRow = {
    id: userId,
    name,
    email,
    phone: phone || null,
    city: 'Paris',
    admin_created: true,
    is_subaccount: !!is_subaccount
  }
  const planResp = await fetch(`${SUPABASE_URL}/rest/v1/planners`, {
    method: 'POST',
    headers: { ...sbHeaders, 'Prefer': 'return=representation' },
    body: JSON.stringify(planRow)
  })
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
  'itinerary_items','messages','payouts','planner_applications','planners',
  'plans','platform_settings','set_assignments','sets','support_tickets',
  'travelers','wallet_adjustments','wallet_pending_payments','wallet_requests',
  // Best-effort cleanup targets (may not exist; wrapped in try/catch client-side)
  'wallet_ledger','chat_messages','typing_drafts',
])
const PROXY_ALLOWED_RPCS    = new Set(['postpone_all_travelers'])
const PROXY_ALLOWED_BUCKETS = new Set(['chat-media'])

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
async function handleSendApproval(request) {
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
  const { to, subject, html, text } = body
  if (!to || !subject || (!html && !text)) {
    return jsonResp(400, { error: 'Missing required fields: to, subject, html|text' })
  }
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
      // FORCE the verified sender — never honour a client-supplied `from`, so
      // this can't be used to spoof mail from the brand domain.
      from: 'Journey Junction <hello@thejourneyjunction.co.uk>',
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
async function handleSendEmploymentLetter(request, url) {
  const cred = checkAuth(request, null)
  if (!cred || cred.user !== 'admin') return challenge()
  if (!SUPABASE_SERVICE_KEY || !RESEND_API_KEY) {
    return jsonResp(500, { error: 'Worker secrets not configured' })
  }

  let body
  try { body = await request.json() } catch (_) { return jsonResp(400, { error: 'Invalid JSON' }) }
  const { planner_id, planner_name, planner_email, start_date } = body || {}
  if (!planner_id || !planner_name || !planner_email || !start_date) {
    return jsonResp(400, { error: 'Missing required fields' })
  }

  // 1. Insert the row (service role bypasses RLS)
  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  }
  const insertResp = await fetch(`${SUPABASE_URL}/rest/v1/employment_letters`, {
    method: 'POST',
    headers: sbHeaders,
    body: JSON.stringify({
      planner_id,
      planner_name,
      planner_email,
      start_date,
      created_by: cred.user
    })
  })
  if (!insertResp.ok) {
    const errText = await insertResp.text().catch(() => '')
    return jsonResp(insertResp.status, { error: 'DB insert failed: ' + errText })
  }
  const rows = await insertResp.json()
  const row = Array.isArray(rows) ? rows[0] : rows
  if (!row?.signing_token) {
    return jsonResp(500, { error: 'No signing token returned' })
  }

  // 2. Build the signing link (origin from the request URL)
  const signUrl = `${url.protocol}//${url.host}/sign-letter.html?token=${row.signing_token}`

  // 3. Email the planner (Resend) — French (primary) + English
  const emailHtml = `
    <div style="font-family:'DM Sans','Helvetica Neue',Arial,sans-serif;max-width:520px;margin:0 auto;padding:32px;background:#f5f4f0;">
      <div style="background:#fff;border-radius:12px;padding:32px;border:1px solid rgba(0,0,0,0.08);">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:24px;">
          <img src="https://journeyjunctionplanner.com/jj.jpg?v=2" alt="JJ" width="32" height="32" style="border-radius:50%;display:block;">
          <div style="font-size:20px;color:#1a1a18;font-family:Georgia,serif;">Journey<span style="color:#1a7a5e;font-style:italic;">Junction</span></div>
        </div>
        <h2 style="font-family:Georgia,serif;color:#1a1a18;margin:0 0 14px;">Confirmez votre contrat de prestation</h2>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 12px;">Bonjour ${escapeForEmail(planner_name)},</p>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 12px;">Merci de votre candidature et de votre inscription en tant que planificateur de voyages chez Journey Junction.</p>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 22px;">Veuillez consulter votre contrat de prestation via le lien ci-dessous, puis le signer et nous le retourner. Ce lien vous est personnel — merci de ne pas le partager.</p>
        <p style="text-align:center;margin:28px 0;">
          <a href="${signUrl}" style="display:inline-block;padding:12px 28px;background:#1a7a5e;color:#fff;text-decoration:none;border-radius:8px;font-family:'DM Sans',sans-serif;font-weight:600;font-size:14px;">Consulter et signer le contrat</a>
        </p>
        <p style="color:#7a7a74;line-height:1.6;font-size:12px;margin:22px 0 0;">Si le bouton ne fonctionne pas, copiez-collez ce lien dans votre navigateur :<br><a href="${signUrl}" style="color:#1a7a5e;word-break:break-all;">${signUrl}</a></p>
        <hr style="border:none;border-top:1px solid rgba(0,0,0,0.08);margin:24px 0;">
        <p style="color:#9a9890;line-height:1.6;font-size:12px;margin:0;"><strong style="color:#7a7a74;">English</strong> — Thank you for joining Journey Junction as a travel planner. Please review your service agreement using the button above, then sign and return it. This link is personal to you; please don't share it.</p>
      </div>
      <p style="text-align:center;color:#9a9890;font-size:11px;margin-top:18px;">Journey Junction · hello@thejourneyjunction.co.uk</p>
    </div>
  `
  const resendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'Journey Junction <hello@thejourneyjunction.co.uk>',
      to: planner_email,
      subject: 'Journey Junction — Votre contrat de prestation à signer',
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
  const resp = await fetch(
    `${SUPABASE_URL}/rest/v1/employment_letters?signing_token=eq.${encodeURIComponent(token)}&select=id,planner_name,planner_email,start_date,status,signed_at,signature_image_url`,
    { headers: sbHeaders }
  )
  if (!resp.ok) return jsonResp(500, { error: 'DB lookup failed' })
  const rows = await resp.json()
  const letter = rows?.[0]
  if (!letter) return jsonResp(404, { error: 'Letter not found' })
  return jsonResp(200, letter)
}

// POST /api/letter/sign — public. Body: { token, signature_data_url, user_agent }
// Validates the token, uploads the signature PNG to storage, updates the row,
// emails support@. Single round-trip from the sign page.
async function handleSignLetter(request, url) {
  if (!SUPABASE_SERVICE_KEY || !RESEND_API_KEY) {
    return jsonResp(500, { error: 'Worker not configured' })
  }
  let body
  try { body = await request.json() } catch (_) { return jsonResp(400, { error: 'Invalid JSON' }) }
  const { token, signature_data_url, user_agent } = body || {}
  if (!token || !signature_data_url) return jsonResp(400, { error: 'Missing token or signature' })
  // Cap the inline signature (stored in a text column + emailed as an attachment)
  // to ~1.5 MB of data-URL — a drawn signature is only a few KB, so this stops
  // storage-bloat / payload abuse on this public endpoint.
  if (typeof signature_data_url !== 'string' || signature_data_url.length > 1_500_000) {
    return jsonResp(413, { error: 'Signature too large' })
  }

  const sbHeaders = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }

  // 1. Validate the letter exists and is pending
  const fetchResp = await fetch(
    `${SUPABASE_URL}/rest/v1/employment_letters?signing_token=eq.${encodeURIComponent(token)}&select=id,planner_name,planner_email,start_date,status`,
    { headers: sbHeaders }
  )
  if (!fetchResp.ok) return jsonResp(500, { error: 'DB lookup failed' })
  const rows = await fetchResp.json()
  const letter = rows?.[0]
  if (!letter)                       return jsonResp(404, { error: 'Letter not found' })
  if (letter.status === 'signed')    return jsonResp(409, { error: 'Already signed' })
  if (letter.status === 'cancelled') return jsonResp(410, { error: 'Letter cancelled' })
  // Positively require 'pending' — don't allow signing a letter in any other/
  // unknown/null state (e.g. a future 'expired'/'revoked').
  if (letter.status !== 'pending')   return jsonResp(409, { error: 'Letter is not awaiting signature' })

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

  // 4. Update the letter row
  const signedAt = new Date().toISOString()
  const updateResp = await fetch(
    `${SUPABASE_URL}/rest/v1/employment_letters?id=eq.${letter.id}`,
    {
      method: 'PATCH',
      headers: { ...sbHeaders, 'Prefer': 'return=minimal' },
      body: JSON.stringify({
        status: 'signed',
        signed_at: signedAt,
        signature_image_url: imageUrl,
        signed_user_agent: (user_agent || '').slice(0, 500),
        signed_ip: request.headers.get('cf-connecting-ip') || null
      })
    }
  )
  if (!updateResp.ok) {
    console.error('letter sign update failed:', await updateResp.text().catch(() => ''))
    return jsonResp(500, { error: 'Could not record signature' })
  }

  // 5. Email support@ with the signed details
  const signedDateHuman = new Date(signedAt).toLocaleString('en-GB')
  const html = `
    <div style="font-family:Georgia,serif;max-width:520px;margin:0 auto;padding:32px;background:#f5f4f0;">
      <div style="background:#fff;border-radius:12px;padding:32px;border:1px solid rgba(0,0,0,0.08);">
        <h2 style="font-family:Georgia,serif;color:#1a1a18;margin:0 0 14px;">Engagement letter signed</h2>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Planner:</strong> ${escapeForEmail(letter.planner_name)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Email:</strong> ${escapeForEmail(letter.planner_email)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 8px;"><strong>Start date:</strong> ${escapeForEmail(letter.start_date)}</p>
        <p style="color:#3a3a36;line-height:1.6;font-size:14px;margin:0 0 18px;"><strong>Signed at:</strong> ${escapeForEmail(signedDateHuman)}</p>
        <div style="margin:18px 0;padding:14px;background:#faf9f6;border:1px solid rgba(0,0,0,0.06);border-radius:8px;text-align:center;">
          <div style="font-size:11px;color:#7a7a74;text-transform:uppercase;letter-spacing:0.08em;margin-bottom:8px;">Signature</div>
          <div style="font-size:13px;color:#3a3a36;">Attached as <strong>signature.png</strong> · view in admin for the on-page copy.</div>
        </div>
        <p style="color:#7a7a74;font-size:12px;margin-top:18px;">View in admin: <a href="${url.protocol}//${url.host}/superadmin999.html" style="color:#1a7a5e;">${url.host}/superadmin999.html</a></p>
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
        from: 'Journey Junction <hello@thejourneyjunction.co.uk>',
        to: 'hello@thejourneyjunction.co.uk',
        subject: `Engagement letter signed by ${letter.planner_name}`,
        html,
        attachments: [{ filename: 'signature.png', content: b64 }]
      })
    })
  } catch (_) { /* swallow — letter is signed regardless */ }

  return jsonResp(200, { ok: true, signature_url: imageUrl })
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
// Body: { text, source_lang?, target_lang? }   (defaults: french -> english)
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

  const source_lang = String(body?.source_lang || 'french').toLowerCase()
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
