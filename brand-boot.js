/* ─────────────────────────────────────────────────────────────
   Brand bootstrap — CLIENT-SIDE white-label skin, keyed by hostname.

   Loaded from every page's <head>. Static files are served directly by
   Cloudflare's asset layer (the Worker only runs for /api/*), so the skin
   is applied here, not in the Worker.

   • Journey Junction host   → no-op (site byte-for-byte unchanged).
   • Vacations by Design host → palette + Space Grotesk wordmark + favicon
     (Phase 1, pre-paint) and a full text/attribute rewrite that ALSO
     re-runs on DOM changes (Phase 2 + MutationObserver), so dynamically
     rendered content (hero, modals, chat, i18n language switches) is fixed.

   Only public brand info here. Email identity stays server-side (_worker.js).
   ───────────────────────────────────────────────────────────── */
(function () {
  var HOST = (location.hostname || '').toLowerCase().replace(/^www\./, '');

  // Keyed by brand KEY (not hostname) so it can be resolved from the logged-in
  // planner's record as well as from the domain.
  var BRANDS = {
    vbd: {
      key: 'vbd',
      name: 'Vacations by Design',
      icon: '/vbd-app-icon.svg',
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
      // Ordered, literal find→replace applied to every text node + key attributes.
      // Longest / most specific FIRST. Case-specific name variants included.
      // Company facts we don't have for VBD (incorporation date, director) are
      // stripped rather than shown wrong.
      replace: [
        ['Flat 2, 64 Heathmere Drive, Birmingham, West Midlands, B37 5EU, United Kingdom', '9 Sharmans Close, Digswell, Welwyn, Hertfordshire, AL6 0AR'],
        ['Flat 2, 64 Heathmere Drive, Birmingham, B37 5EU, United Kingdom', '9 Sharmans Close, Digswell, Welwyn, Hertfordshire, AL6 0AR'],
        ['JOURNEY JUNCTION', 'VACATIONS BY DESIGN'],
        ['Journey Junction', 'Vacations by Design'],
        ['JourneyJunction', 'Vacations by Design'],
        ['15791277', '03039047'],
        ['hello@thejourneyjunction.co.uk', 'hello@thevacationsbydesign.co.uk'],
        ['journeyjunctionplanner.com', 'itinerarydesignhub.com'],
        // Incorporation date + director → VBD's real Companies House details.
        ['20 June 2024', '29 March 1995'],
        ['2024年6月20日', '1995年3月29日'],
        ['Midhun Peter', 'Mathilde Gilberte Renee Robert'], // NBSP variant (letter signature)
        ['Midhun Peter', 'Mathilde Gilberte Renee Robert']
      ]
    }
  };

  // Which brand key applies?
  //   • Dashboard (logged in) → the PLANNER's own brand, from the record cached
  //     at login. So a Journey Junction planner never sees Vacations by Design
  //     (or vice-versa), even if they open the other brand's domain.
  //   • Public pages (login / apply / legal …) → the viewing domain, so a NEW
  //     applicant sees the brand of the site they're actually on. (We must NOT
  //     read a stale cached planner brand here.)
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
    // Wordmark in Space Grotesk; portal tag / slogan uppercase + letterspaced.
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

    if (B.icon) {
      var links = document.querySelectorAll('link[rel~="icon"]');
      for (var i = 0; i < links.length; i++) links[i].parentNode.removeChild(links[i]);
      var ic = document.createElement('link');
      ic.rel = 'icon'; ic.type = 'image/svg+xml'; ic.href = B.icon;
      head().appendChild(ic);
    }
  } catch (e) {}

  // ── Text-replacement engine ──
  // No pre-filter: each rule self-guards with indexOf (cheap), and a pre-filter
  // risks skipping date-only / lowercase-email / JP-only text nodes.
  function rewrite(s) {
    if (!s) return s;
    var out = s, r = B.replace;
    for (var i = 0; i < r.length; i++) {
      if (out.indexOf(r[i][0]) > -1) out = out.split(r[i][0]).join(r[i][1]);
    }
    return out;
  }

  var ATTRS = ['title', 'alt', 'placeholder', 'aria-label', 'value', 'content'];

  function swapTextNode(t) {
    var v = rewrite(t.nodeValue);
    if (v !== t.nodeValue) t.nodeValue = v;
  }

  function swapAttrsOne(el) {
    if (!el.getAttribute) return;
    for (var i = 0; i < ATTRS.length; i++) {
      if (!el.hasAttribute(ATTRS[i])) continue;
      var a = el.getAttribute(ATTRS[i]);
      var b = rewrite(a);
      if (b !== a) el.setAttribute(ATTRS[i], b);
    }
  }

  // Replace the JJ logo image with the brand icon.
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
        var withAttr = el.querySelectorAll('[title],[alt],[placeholder],[aria-label],[value],[content]');
        for (var j = 0; j < withAttr.length; j++) swapAttrsOne(withAttr[j]);
      }
      swapLogosIn(el);
    } catch (e) {}
  }

  function apply() {
    if (rewrite(document.title) !== document.title) document.title = rewrite(document.title);
    // head meta (description / og:*)
    var metas = document.querySelectorAll('meta[content]');
    for (var i = 0; i < metas.length; i++) swapAttrsOne(metas[i]);
    swapEl(document.body);

    // Self-heal: re-apply to anything added later (loop-safe — we only edit text/
    // attributes, which don't add nodes, so our own edits never retrigger this).
    try {
      var obs = new MutationObserver(function (muts) {
        for (var a = 0; a < muts.length; a++) {
          var added = muts[a].addedNodes;
          for (var b = 0; b < added.length; b++) {
            var node = added[b];
            if (node.nodeType === 1) swapEl(node);
            else if (node.nodeType === 3) swapTextNode(node);
          }
        }
      });
      obs.observe(document.body, { childList: true, subtree: true });
    } catch (e) {}

    // Some pages (the letter) set document.title via JS after load — re-fix it
    // when it changes. Loop-safe: only reassign when the value actually changes.
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
