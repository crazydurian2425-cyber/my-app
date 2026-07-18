/* ─────────────────────────────────────────────────────────────
   Brand skin applier — loaded ONLY on non-default hostnames
   (e.g. itinerarydesignhub.com → Vacations by Design).

   The Worker injects, into <head> BEFORE this file:
     • window.__BRAND__      — the public brand config
     • <style id="brand-override"> — redefines the --green* design
       tokens to the brand palette (handles all var()-based colour)
     • <link rel="icon">     — brand favicon
   This file finishes the client-side reskin that CSS can't reach:
     • page <title>
     • the "Journey Junction" two-tone wordmark lockup
     • plain "Journey Junction" text + alt attributes
     • any absolute-URL jj logo <img> (relative ones are already
       rewritten to the brand icon by the Worker)

   Journey Junction pages NEVER load this file — nothing is injected
   for the default host, so its behaviour is byte-for-byte unchanged.
   ───────────────────────────────────────────────────────────── */
(function () {
  var B = window.__BRAND__;
  if (!B || B.key === 'jj') return;

  var FROM = 'Journey Junction';
  var LEAD = B.wordmarkLead || 'Vacations by ';   // unstyled leading part of the lockup
  var ACC  = B.wordmarkAccent || 'Design';        // styled/italic part of the lockup

  // Plain-text nodes: "Journey Junction" (and the no-space wordmark) → brand name.
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

  // Replace a whole word inside an element's FIRST matching direct text node only
  // (leaves nested elements — e.g. the sidebar's live-status dot — untouched).
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

  // Two-tone brand lockup. Covers both shapes seen in the app:
  //   • inline:  Journey<span>Junction</span>                      (prev = text node)
  //   • stacked: <span>Journey</span><span>Junction <dot/></span>  (prev = element)
  // The "Junction" half is any element whose trimmed text is exactly "Junction";
  // the "Journey" half is its preceding text node or element sibling. We rewrite
  // in place so styling (and nested nodes like the live-dot) survive.
  function swapLockups(root) {
    var lead = LEAD.replace(/\s+$/, '') + ' ';   // "Vacations by "
    var els = root.querySelectorAll('span,i,em,b,strong,div');
    for (var i = 0; i < els.length; i++) {
      var acc = els[i];
      if ((acc.textContent || '').trim() !== 'Junction') continue;
      var done = false;
      var ps = acc.previousSibling;
      if (ps && ps.nodeType === 3 && (ps.nodeValue || '').trim() === 'Journey') {
        ps.nodeValue = ps.nodeValue.replace('Journey', lead);
        done = true;
      } else {
        var pe = acc.previousElementSibling;
        if (pe && (pe.textContent || '').trim() === 'Journey') done = setFirstText(pe, 'Journey', lead);
      }
      if (done) setFirstText(acc, 'Junction', ACC);
    }
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
