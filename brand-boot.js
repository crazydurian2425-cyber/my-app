/* ─────────────────────────────────────────────────────────────
   Brand bootstrap — CLIENT-SIDE white-label skin.

   Loaded from every page's <head>. Static files are served directly by
   Cloudflare's asset layer (the Worker only runs for /api/*), so the skin
   is applied here, not in the Worker.

   • Journey Junction  → no-op (site byte-for-byte unchanged).
   • Vacations by Design → palette + Space Grotesk wordmark + PNG favicon
     (Phase 1, pre-paint) and a text/attribute rewrite that re-runs on DOM
     changes (Phase 2 + MutationObserver) so dynamic content is fixed too.

   SAFETY (important): the brand NAME / email / domain are replaced on every
   page. The COMPANY FACTS (registered address, company number, incorporation
   date, director) are replaced ONLY on the legal/footer pages that actually
   show them — NEVER on data pages (dashboard / support), so a real travel date
   / number / person name that happens to equal a JJ company fact can't be
   corrupted. brand-boot only ever reads/writes DISPLAY text + a few attributes
   (never a form input's live .value), so autosave / wallet data is untouched.
   ───────────────────────────────────────────────────────────── */
(function () {
  var HOST = (location.hostname || '').toLowerCase().replace(/^www\./, '');

  // Keyed by brand KEY (not hostname) so it can be resolved from the logged-in
  // planner's record as well as from the domain.
  var BRANDS = {
    vbd: {
      key: 'vbd',
      name: 'Vacations by Design',
      icon: '/vbd-app-icon.png',       // rounded tile — used for the in-page sidebar logo
      favicon: '/vbd-icon.png',        // the mark alone — used for the browser-tab favicon
      wordmarkLead: 'Vacations',   // dark half
      wordmarkAccent: 'by Design', // sage half
      tokens: {
        '--green': '#3A5647',
        '--green-dark': '#2E4639',
        '--green-d': '#2E4639',
        '--green-mid': '#7FA187',
        '--green-light': '#E9EFEA',
        '--brand-accent': '#3A5647',
        '--brand-pop': '#EE6C3A'
      },
      // Brand name / email / domain — safe on EVERY page (specific strings,
      // negligible collision with user travel data).
      replace: [
        ['JOURNEY JUNCTION', 'VACATIONS BY DESIGN'],
        ['Journey Junction', 'Vacations by Design'],
        ['JourneyJunction', 'Vacations by Design'],
        ['hello@thejourneyjunction.co.uk', 'hello@thevacationsbydesign.co.uk'],
        ['journeyjunctionplanner.com', 'itinerarydesignhub.com']
      ],
      // Company facts — applied ONLY on legal/footer pages (see IS_LEGAL_PAGE).
      // These strings are real-world values (a date, an 8-digit number, a person
      // name) that could otherwise collide with genuine itinerary/wallet data,
      // so they must never run on data pages.
      replaceLegal: [
        ['Flat 2, 64 Heathmere Drive, Birmingham, West Midlands, B37 5EU, United Kingdom', '9 Sharmans Close, Digswell, Welwyn, Hertfordshire, AL6 0AR'],
        ['Flat 2, 64 Heathmere Drive, Birmingham, B37 5EU, United Kingdom', '9 Sharmans Close, Digswell, Welwyn, Hertfordshire, AL6 0AR'],
        ['15791277', '03039047'],
        ['20 June 2024', '29 March 1995'],
        ['2024年6月20日', '1995年3月29日'],
        ['Director: Midhun Peter', 'Director: Charalambos Andrew Kyrillou'],
        ['Midhun Peter', 'Charalambos Andrew Kyrillou']
      ]
    }
  };

  // Which brand key applies?
  //   • Dashboard (logged in) → the PLANNER's own brand, from the record cached
  //     at login, so a JJ planner never sees VBD (or vice-versa) even on the
  //     other brand's domain.
  //   • Public pages (login / apply / legal …) → the viewing domain, so a NEW
  //     applicant sees the brand of the site they're on. (Do NOT read a stale
  //     cached planner brand here.)
  function hostBrandKey() { return HOST === 'itinerarydesignhub.com' ? 'vbd' : 'jj'; }
  var key = null;
  try {
    if (/(^|\/)dashboard/i.test(location.pathname)) {
      var pj = JSON.parse(localStorage.getItem('jj_planner') || 'null');
      if (pj && pj.brand) key = pj.brand;
    }
  } catch (e) {}
  if (!key) key = hostBrandKey();

  var B = BRANDS[key];
  if (!B) return;                 // Journey Junction (default) → untouched
  window.__BRAND__ = B;

  // Company-fact replacements run ONLY on the legal/footer pages that show them.
  // Everything else (dashboard, support, reset, index, …) gets NAME-only, so
  // user data can never be rewritten.
  var IS_LEGAL_PAGE = /(login|apply|forgot|signup|privacy|terms)/i.test(location.pathname);
  var REPS = IS_LEGAL_PAGE ? B.replace.concat(B.replaceLegal) : B.replace;

  var FROM = 'Journey Junction';
  var LEAD = (B.wordmarkLead || 'Vacations') + ' ';
  var ACC  = B.wordmarkAccent || 'by Design';

  function head() { return document.head || document.documentElement; }

  // ── Phase 1 — palette, Space Grotesk wordmark, favicon (before body paints) ──
  try {
    var css = ':root{';
    for (var k in B.tokens) {
      if (!B.tokens.hasOwnProperty(k)) continue;
      var imp = k.indexOf('--brand-') === 0 ? '' : ' !important';
      css += k + ':' + B.tokens[k] + imp + ';';
    }
    css += '}';
    css += ".brand,.brand-name,.brand-line-1,.brand-line-2,.logo-mark,.brand-tag-text,.logo-sub{font-family:'Space Grotesk','DM Sans',sans-serif !important;}";
    css += '.brand-line-1,.brand-line-2,.logo-mark{font-weight:500 !important;letter-spacing:-0.01em;}';
    css += '.brand-tag-text,.logo-sub{text-transform:uppercase;letter-spacing:0.16em;}';
    css += '#rt-status-dot{background:#7FA187 !important;}';
    var st = document.createElement('style');
    st.id = 'brand-override';
    st.textContent = css;
    head().appendChild(st);

    var gf = document.createElement('link');
    gf.rel = 'stylesheet';
    gf.href = 'https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600&display=swap';
    head().appendChild(gf);

    var favicon = B.favicon || B.icon;
    if (favicon) {
      var links = document.querySelectorAll('link[rel~="icon"]');
      for (var i = 0; i < links.length; i++) links[i].parentNode.removeChild(links[i]);
      var ic = document.createElement('link');
      ic.rel = 'icon'; ic.type = 'image/png'; ic.href = favicon;
      head().appendChild(ic);
    }
    if (B.icon) { var pl = new Image(); pl.src = B.icon; }   // preload in-page logo swap

    // Anti-flash: hide ONLY the brand lockup (logo + wordmark) until Phase 2
    // rewrites it to VBD, so a refresh never shows a flash of the Journey
    // Junction logo/name. The sage palette already applied above (pre-paint), so
    // the rest of the page renders normally. Revealed in apply(); a safety timer
    // reveals regardless so the logo can never get stuck hidden.
    var hs = document.createElement('style');
    hs.id = 'brand-hide';
    hs.textContent = '.brand,.brand-lockup,.sidebar-logo,.logo{visibility:hidden !important;}';
    head().appendChild(hs);
    setTimeout(revealBrand, 1500);
  } catch (e) {}

  function revealBrand() {
    var h = document.getElementById('brand-hide');
    if (h && h.parentNode) h.parentNode.removeChild(h);
  }

  // ── Text-replacement engine (uses the page-scoped REPS) ──
  function rewrite(s) {
    if (!s) return s;
    var out = s;
    for (var i = 0; i < REPS.length; i++) {
      if (out.indexOf(REPS[i][0]) > -1) out = out.split(REPS[i][0]).join(REPS[i][1]);
    }
    return out;
  }

  // Attributes we rewrite. 'href' is included so mailto:/absolute JJ links follow
  // the brand (only name/email/domain reps run on data pages, so a link target
  // can't be corrupted). NOTE: 'value' is deliberately EXCLUDED — we must never
  // touch a form input's value (autosave / wallet read those).
  var ATTRS = ['title', 'alt', 'placeholder', 'aria-label', 'content', 'href'];

  // Opt-out: anything inside [data-brand-keep] is never rewritten. Used for
  // messages that must genuinely name the OTHER brand (e.g. the login brand
  // gate telling a Journey Junction planner to use the JJ site).
  function _kept(el) {
    return !!(el && el.closest && el.closest('[data-brand-keep]'));
  }

  function swapTextNode(t) {
    if (_kept(t.parentElement)) return;
    var v = rewrite(t.nodeValue);
    if (v !== t.nodeValue) t.nodeValue = v;
  }

  function swapAttrsOne(el) {
    if (!el.getAttribute || _kept(el)) return;
    for (var i = 0; i < ATTRS.length; i++) {
      if (!el.hasAttribute(ATTRS[i])) continue;
      var a = el.getAttribute(ATTRS[i]);
      var b = rewrite(a);
      if (b !== a) el.setAttribute(ATTRS[i], b);
    }
  }

  function swapLogosIn(el) {
    if (!B.icon) return;
    var logos = el.querySelectorAll ? el.querySelectorAll('img[src*="jj.jpg"],img[src*="jjlogo"]') : [];
    for (var j = 0; j < logos.length; j++) logos[j].src = B.icon;
    if (el.tagName === 'IMG' && /jj\.jpg|jjlogo/.test(el.getAttribute('src') || '')) el.src = B.icon;
  }

  // Replace a word in an element's FIRST direct text node only (nested nodes kept).
  function setFirstText(el, from, to) {
    for (var i = 0; i < el.childNodes.length; i++) {
      var c = el.childNodes[i];
      if (c.nodeType === 3 && c.nodeValue.indexOf(from) > -1) {
        c.nodeValue = c.nodeValue.replace(from, to);
        return true;
      }
    }
    return false;
  }

  // Two-tone wordmark lockup. Shapes:
  //   inline:  Journey<em|span>Junction</em|span>                (prev = text)
  //   stacked: <span>Journey</span><span>Junction <dot/></span>  (prev = element)
  function swapLockups(root) {
    var q = root.querySelectorAll ? root.querySelectorAll('span,em,i,b,strong,div') : [];
    for (var i = 0; i < q.length; i++) {
      var acc = q[i];
      if ((acc.textContent || '').trim() !== 'Junction') continue;
      var done = false;
      var ps = acc.previousSibling;
      if (ps && ps.nodeType === 3 && (ps.nodeValue || '').trim() === 'Journey') {
        ps.nodeValue = ps.nodeValue.replace('Journey', LEAD);
        done = true;
      } else {
        var pe = acc.previousElementSibling;
        if (pe && (pe.textContent || '').trim() === 'Journey') done = setFirstText(pe, 'Journey', LEAD);
      }
      if (done) setFirstText(acc, 'Junction', ACC);
    }
  }

  // Rewrite an element subtree (text + attributes + logos + lockups).
  function swapEl(el) {
    try {
      swapLockups(el);
      var w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null);
      var n, list = [];
      while ((n = w.nextNode())) list.push(n);
      for (var i = 0; i < list.length; i++) swapTextNode(list[i]);
      swapAttrsOne(el);
      if (el.querySelectorAll) {
        var withAttr = el.querySelectorAll('[title],[alt],[placeholder],[aria-label],[content],[href]');
        for (var j = 0; j < withAttr.length; j++) swapAttrsOne(withAttr[j]);
      }
      swapLogosIn(el);
    } catch (e) {}
  }

  function apply() {
    if (rewrite(document.title) !== document.title) document.title = rewrite(document.title);
    var metas = document.querySelectorAll('meta[content]');
    for (var i = 0; i < metas.length; i++) swapAttrsOne(metas[i]);
    swapEl(document.body);
    revealBrand();   // brand lockup is now VBD — un-hide it

    // Self-heal: re-apply to anything added later (loop-safe — we only edit text/
    // attributes, which don't add nodes, so our own edits never retrigger this).
    try {
      var obs = new MutationObserver(function (muts) {
        for (var a = 0; a < muts.length; a++) {
          var m = muts[a];
          // Attribute changed on an existing element (e.g. a title/aria-label
          // re-set by an i18n language toggle) — re-rewrite just that element.
          // Loop-safe: rewrite is idempotent, and swapAttrsOne only writes when
          // the value actually changes, so it can't retrigger itself.
          if (m.type === 'attributes') { swapAttrsOne(m.target); continue; }
          var added = m.addedNodes;
          for (var b = 0; b < added.length; b++) {
            var node = added[b];
            if (node.nodeType === 1) swapEl(node);
            else if (node.nodeType === 3) swapTextNode(node);
          }
        }
      });
      obs.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ATTRS });
    } catch (e) {}

    // Some pages set document.title via JS after load — re-fix without looping.
    try {
      var tEl = document.querySelector('title');
      if (tEl) {
        new MutationObserver(function () {
          var r = rewrite(document.title);
          if (r !== document.title) document.title = r;
        }).observe(tEl, { childList: true, characterData: true, subtree: true });
      }
    } catch (e) {}
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', apply);
  else apply();
})();
