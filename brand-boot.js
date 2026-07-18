/* ─────────────────────────────────────────────────────────────
   Brand bootstrap — CLIENT-SIDE white-label skin, keyed by hostname.

   Loaded from every page's <head> as a normal (render-blocking) script.
   Static files are served directly by Cloudflare's asset layer (the Worker
   only runs for /api/*), so the skin MUST be applied here, not in the Worker.

   • Journey Junction host  → this file no-ops (site byte-for-byte unchanged).
   • Vacations by Design host → applies palette + favicon (Phase 1, before the
     body paints, so no colour flash) and logo + wordmark + name (Phase 2, on
     DOM ready).

   Public brand info only (name, palette, logo). Email identity stays server-side.
   ───────────────────────────────────────────────────────────── */
(function () {
  var HOST = (location.hostname || '').toLowerCase().replace(/^www\./, '');

  var BRANDS = {
    'itinerarydesignhub.com': {
      key: 'vbd',
      name: 'Vacations by Design',
      icon: '/vbd-app-icon.svg',
      wordmarkLead: 'Vacations by ',
      wordmarkAccent: 'Design',
      // Sage & Poppy → the app's existing design tokens (both --green-dark and
      // --green-d spellings are used across pages, so set both).
      tokens: {
        '--green': '#3A5647',
        '--green-dark': '#2E4639',
        '--green-d': '#2E4639',
        '--green-mid': '#7FA187',
        '--green-light': '#E9EFEA',
        '--brand-accent': '#3A5647',
        '--brand-pop': '#EE6C3A'
      }
    }
  };

  var B = BRANDS[HOST];
  if (!B) return;               // default host (Journey Junction) → untouched
  window.__BRAND__ = B;

  // ── Phase 1 — colours + favicon (synchronous, during <head> parse) ──
  try {
    var css = ':root{';
    for (var k in B.tokens) {
      if (!B.tokens.hasOwnProperty(k)) continue;
      // !important so it wins over each page's own :root token; --brand-* are new
      // (no existing declaration) so they don't need it.
      var imp = k.indexOf('--brand-') === 0 ? '' : ' !important';
      css += k + ':' + B.tokens[k] + imp + ';';
    }
    css += '}';
    var st = document.createElement('style');
    st.id = 'brand-override';
    st.textContent = css;
    (document.head || document.documentElement).appendChild(st);

    if (B.icon) {
      var links = document.querySelectorAll('link[rel~="icon"]');
      for (var i = 0; i < links.length; i++) links[i].parentNode.removeChild(links[i]);
      var ic = document.createElement('link');
      ic.rel = 'icon'; ic.type = 'image/svg+xml'; ic.href = B.icon;
      (document.head || document.documentElement).appendChild(ic);
    }
  } catch (e) {}

  // ── Phase 2 — title, wordmark, name text, logo images (needs the DOM) ──
  var FROM = 'Journey Junction';
  var LEAD = (B.wordmarkLead || 'Vacations by ').replace(/\s+$/, '') + ' ';
  var ACC  = B.wordmarkAccent || 'Design';

  // Replace a word in an element's FIRST direct text node only (nested nodes,
  // e.g. the sidebar live-status dot, are preserved).
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

  // Two-tone brand lockup. Both shapes:
  //   inline:  Journey<span>Junction</span>                       (prev = text)
  //   stacked: <span>Journey</span><span>Junction <dot/></span>   (prev = element)
  function swapLockups(root) {
    var els = root.querySelectorAll('span,i,em,b,strong,div');
    for (var i = 0; i < els.length; i++) {
      var acc = els[i];
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

  function swapText(root) {
    try {
      var w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
      var n, list = [];
      while ((n = w.nextNode())) list.push(n);
      for (var i = 0; i < list.length; i++) {
        var v = list[i].nodeValue;
        if (v.indexOf(FROM) > -1)              v = v.split(FROM).join(B.name);
        if (v.indexOf('JourneyJunction') > -1) v = v.split('JourneyJunction').join(B.name);
        if (v !== list[i].nodeValue) list[i].nodeValue = v;
      }
    } catch (e) {}
  }

  function swapAttrs(root) {
    var alts = root.querySelectorAll('img[alt*="Journey Junction"]');
    for (var i = 0; i < alts.length; i++) alts[i].alt = B.name;
    if (B.icon) {
      var logos = root.querySelectorAll('img[src*="jj.jpg"],img[src*="jjlogo"]');
      for (var j = 0; j < logos.length; j++) logos[j].src = B.icon;
    }
  }

  function apply() {
    if (document.title.indexOf(FROM) > -1)      document.title = document.title.split(FROM).join(B.name);
    else if (/^\s*Journey\s*Junction\s*$/i.test(document.title)) document.title = B.name;
    swapLockups(document.body);
    swapText(document.body);
    swapAttrs(document.body);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', apply);
  else apply();
})();
