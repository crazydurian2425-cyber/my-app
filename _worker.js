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

// Supabase project — service role key kept server-side only.
// Used by /api/create-planner to create auth users + insert planner rows.
const SUPABASE_URL = 'https://hjchyqafkpbryzlqhpxc.supabase.co'
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqY2h5cWFma3Bicnl6bHFocHhjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTM1NDg5MSwiZXhwIjoyMDk0OTMwODkxfQ.tn2ovF385cdAtjyyKfEYE5HkLQUkUbpKKp8Hc4LFEcg'

export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // Load secrets from the Worker environment into the module-level
    // vars the handlers read. Set via `wrangler secret put RESEND_API_KEY`.
    // Falls back to empty string — handlers already guard with a 500 when
    // the key is missing, so a forgotten secret fails loud, not silent.
    if (env.RESEND_API_KEY) RESEND_API_KEY = env.RESEND_API_KEY

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
  const targetUrl  = SUPABASE_URL + targetPath + url.search

  // Clone request headers, swap auth, strip browser-only ones.
  const fwdHeaders = new Headers(request.headers)
  fwdHeaders.set('apikey', SUPABASE_SERVICE_KEY)
  fwdHeaders.set('Authorization', `Bearer ${SUPABASE_SERVICE_KEY}`)
  fwdHeaders.delete('host')
  fwdHeaders.delete('cookie')
  fwdHeaders.delete('cf-connecting-ip')
  fwdHeaders.delete('cf-ray')
  fwdHeaders.delete('cf-visitor')
  fwdHeaders.delete('x-forwarded-for')
  fwdHeaders.delete('x-forwarded-proto')
  fwdHeaders.delete('x-real-ip')

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
function isProxyAuthorized(request, url) {
  const referer = request.headers.get('referer') || ''
  if (referer) {
    try {
      const r = new URL(referer)
      const sameOrigin = (r.protocol === url.protocol && r.host === url.host)
      if (sameOrigin) {
        // Cloudflare Pages serves /superadmin999.html at /superadmin999 (extension
        // stripped), so accept either form. We only need to confirm the request
        // came from one of the gated admin/CS pages.
        const path = r.pathname.replace(/\.html$/, '')
        const allowedPrefixes = PROTECTED_PATHS.map(p => p.replace(/\.html$/, ''))
        if (allowedPrefixes.includes(path)) return true
      }
    } catch (_) { /* malformed — fall through */ }
  }
  // Fallback: explicit Basic Auth (for non-browser callers)
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
  const { to, subject, html, text, from } = body
  if (!to || !subject || (!html && !text)) {
    return jsonResp(400, { error: 'Missing required fields: to, subject, html|text' })
  }

  const resendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: from || 'Journey Junction <support@thejourneywise.com>',
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

  // 3. Email the planner (Resend) — Japanese only
  const emailHtml = `
    <div style="font-family:'Noto Sans JP','Hiragino Sans','Yu Gothic',sans-serif;max-width:520px;margin:0 auto;padding:32px;background:#f5f4f0;">
      <div style="background:#fff;border-radius:12px;padding:32px;border:1px solid rgba(0,0,0,0.08);">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:24px;">
          <img src="https://thejourneywise.com/jj.jpg?v=2" alt="JJ" width="32" height="32" style="border-radius:50%;display:block;">
          <div style="font-size:20px;color:#1a1a18;font-family:Georgia,serif;">Journey<span style="color:#1a7a5e;font-style:italic;">Junction</span></div>
        </div>
        <h2 style="font-family:'Noto Serif JP',Georgia,serif;color:#1a1a18;margin:0 0 14px;">業務委託契約書のご確認</h2>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 12px;">${escapeForEmail(planner_name)} 様</p>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 12px;">この度はJourney Junctionのトラベルプランナーにご応募・ご登録いただき、誠にありがとうございます。</p>
        <p style="color:#3a3a36;line-height:1.7;font-size:14px;margin:0 0 22px;">下記リンクより業務委託契約書をご確認のうえ、ご署名・ご返送をお願いいたします。本リンクはお客様専用のため、第三者と共有しないようご注意ください。</p>
        <p style="text-align:center;margin:28px 0;">
          <a href="${signUrl}" style="display:inline-block;padding:12px 28px;background:#1a7a5e;color:#fff;text-decoration:none;border-radius:8px;font-family:'Noto Sans JP','DM Sans',sans-serif;font-weight:600;font-size:14px;">契約書を確認・署名する</a>
        </p>
        <p style="color:#7a7a74;line-height:1.6;font-size:12px;margin:22px 0 0;text-align:center;">ボタンが動作しない場合は、下記のURLをコピーしてブラウザに貼り付けてください：<br><a href="${signUrl}" style="color:#1a7a5e;word-break:break-all;">${signUrl}</a></p>
      </div>
      <p style="text-align:center;color:#9a9890;font-size:11px;margin-top:18px;">Journey Junction · support@thejourneywise.com</p>
    </div>
  `
  const resendResp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'Journey Junction <support@thejourneywise.com>',
      to: planner_email,
      subject: '【Journey Junction】業務委託契約書のご確認',
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

  // 2. Decode base64 PNG (data URL: "data:image/png;base64,xxx")
  const m = signature_data_url.match(/^data:image\/png;base64,(.+)$/)
  if (!m) return jsonResp(400, { error: 'Signature must be PNG data URL' })
  const binStr = atob(m[1])
  const bytes = new Uint8Array(binStr.length)
  for (let i = 0; i < binStr.length; i++) bytes[i] = binStr.charCodeAt(i)

  // 3. Upload to storage bucket (service role)
  const path = `${token}.png`
  const uploadResp = await fetch(
    `${SUPABASE_URL}/storage/v1/object/employment-letter-signatures/${path}`,
    {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'image/png',
        'x-upsert': 'true'
      },
      body: bytes
    }
  )
  if (!uploadResp.ok) {
    const errText = await uploadResp.text().catch(() => '')
    return jsonResp(500, { error: 'Signature upload failed: ' + errText })
  }
  const imageUrl = `${SUPABASE_URL}/storage/v1/object/public/employment-letter-signatures/${path}`

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
    const errText = await updateResp.text().catch(() => '')
    return jsonResp(500, { error: 'Row update failed: ' + errText })
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
          <img src="${escapeForEmail(imageUrl)}" style="max-width:300px;height:auto;background:#fff;">
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
        from: 'Journey Junction <support@thejourneywise.com>',
        to: 'support@thejourneywise.com',
        subject: `Engagement letter signed by ${letter.planner_name}`,
        html
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
