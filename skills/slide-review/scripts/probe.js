() => {
  const cfg = Reveal.getConfig(), S = Reveal.getScale(), DW = cfg.width, DH = cfg.height;
  const CHROME = '.slide-number,.footer,.progress,.controls';
  const lum = c => { const m = c.match(/[\d.]+/g); if (!m) return null;
    const f = m.slice(0,3).map(v => { v = v/255; return v <= 0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); });
    return 0.2126*f[0] + 0.7152*f[1] + 0.0722*f[2]; };
  const asRGB = v => { if (!v) return null; const d = document.createElement('span');
    d.style.color = v; document.body.appendChild(d);
    const m = getComputedStyle(d).color.match(/[\d.]+/g); d.remove();
    return m ? [+m[0], +m[1], +m[2]] : null; };
  const GROUND = (() => { let n = document.querySelector('.reveal-viewport') || document.body;
    while (n) { const m = getComputedStyle(n).backgroundColor.match(/[\d.]+/g);
      if (m && (m.length > 3 ? parseFloat(m[3]) : 1) >= 1) return [+m[0], +m[1], +m[2]];
      n = n.parentElement; }
    return [255,255,255]; })();
  const GL = lum('rgb(' + GROUND.join(',') + ')'), DARK = GL < 0.2;
  let BASE = GROUND;
  const bgOf = (el, top) => { const st = []; let n = el;
    while (n && n !== document.documentElement) {
      const m = getComputedStyle(n).backgroundColor.match(/[\d.]+/g);
      if (m) { const a = m.length > 3 ? parseFloat(m[3]) : 1;
        if (a > 0) { st.push([+m[0], +m[1], +m[2], a]); if (a >= 1) break; } }
      if (n === top) break;
      n = n.parentElement; }
    st.push([...BASE, 1]);
    let o = st[st.length-1].slice(0,3);
    for (let i = st.length-2; i >= 0; i--) { const [r,g,b,a] = st[i];
      o = [r*a+o[0]*(1-a), g*a+o[1]*(1-a), b*a+o[2]*(1-a)]; }
    return 'rgb(' + o.map(v => Math.round(v)).join(', ') + ')'; };
  const ratio = (a,b) => { const [x,y] = [lum(a), lum(b)]; if (x == null || y == null) return null;
    return Math.round(((Math.max(x,y)+0.05)/(Math.min(x,y)+0.05))*100)/100; };
  const WHITE_OK = 'h1,h2,h3,h4,strong,b,em,.prompt,.hero,.label,.demo-tag,.title,.subtitle,#title-slide';
  const secs = [...document.querySelectorAll('.reveal .slides > section')]
    .flatMap(s => { const k = [...s.querySelectorAll(':scope > section')]; return k.length ? k : [s]; });
  const slides = secs.map((s, i) => {
    const saved = s.style.cssText;
    s.style.display = 'block'; s.style.visibility = 'visible'; s.style.opacity = '1';
    BASE = asRGB(s.getAttribute('data-background-color')) || GROUND;
    const tiny = [], lowC = [], glare = [], pale = [];
    s.querySelectorAll('*').forEach(el => {
      if (el.closest(CHROME) || !el.getClientRects().length) return;
      const cs = getComputedStyle(el);
      const tag = el.tagName.toLowerCase() + (el.className ? '.' + String(el.className).trim().split(/\s+/)[0] : '');
      if (![...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim().length > 1)) return;
      const fs = parseFloat(cs.fontSize);
      if (fs < 19) tiny.push({ px: Math.round(fs*10)/10, pctH: Math.round(fs/DH*1000)/10, sel: tag, text: el.textContent.trim().slice(0,40) });
      const bg = bgOf(el, s), cr = ratio(cs.color, bg);
      if (cr !== null && cr < 4.5) lowC.push({ ratio: cr, fg: cs.color, bg, sel: tag, text: el.textContent.trim().slice(0,40) });
      if (DARK && cs.color === 'rgb(255, 255, 255)' && !el.matches(WHITE_OK) && !el.closest(WHITE_OK))
        glare.push({ sel: tag, px: Math.round(fs), bg, text: el.textContent.trim().slice(0,40) });
      if (DARK && lum(bg) > GL + 0.35 && !el.closest('.demo-tag'))
        pale.push({ sel: tag, bg, bgLum: Math.round(lum(bg)*1000)/1000, text: el.textContent.trim().slice(0,40) });
    });
    s.style.cssText = saved;
    return { n: i, title: ((s.querySelector('h1,h2')||{}).textContent||'(no heading)').trim(),
      classes: s.className || '', words: (s.textContent.match(/\S+/g)||[]).length,
      bgAttr: s.getAttribute('data-background-color') || null, base: 'rgb(' + BASE.join(', ') + ')',
      tiny: tiny.slice(0,3), lowContrast: lowC.slice(0,3),
      whiteBody: glare.slice(0,3), lightPanel: pale.slice(0,3) };
  });
  const math = [];
  document.querySelectorAll('.katex-error').forEach(e => math.push({ kind: 'parse-error',
    msg: (e.getAttribute('title')||'').slice(0,140), tex: e.textContent.trim().slice(0,60) }));
  document.querySelectorAll('mjx-merror').forEach(e => math.push({ kind: 'mathjax-error',
    msg: (e.getAttribute('title') || e.textContent).trim().slice(0,140),
    tex: (e.closest('mjx-container')||e).textContent.trim().slice(0,60) }));
  document.querySelectorAll('.katex span, mjx-container *').forEach(e => { const c = getComputedStyle(e).color;
    if ((c !== 'rgb(204, 0, 0)' && c !== 'rgb(255, 0, 0)') || !e.textContent.trim() || e.closest('mjx-merror')) return;
    if (e.parentElement && getComputedStyle(e.parentElement).color === c) return;
    math.push({ kind: 'undefined-macro', tex: e.textContent.trim().slice(0,60) }); });
  document.querySelectorAll('.katex-html, mjx-math').forEach(e => { if (/\\[a-zA-Z]{2,}/.test(e.textContent))
    math.push({ kind: 'raw-tex-visible', tex: e.textContent.trim().slice(0,60) }); });
  const seen = new Set();
  const cites = [...document.querySelectorAll('.citation')].flatMap(e =>
    (e.getAttribute('data-cites')||'').split(/\s+/).filter(Boolean).map(k => ({ key: k,
      keyVisible: e.textContent.includes(k), hasEntry: !!document.getElementById('ref-'+k),
      shown: e.textContent.trim().slice(0,50) })));
  return { deck: { W: DW, H: DH, scale: S, total: Reveal.getTotalSlides(),
                   root: getComputedStyle(document.querySelector('.reveal')).fontSize,
                   ground: 'rgb(' + GROUND.join(', ') + ')', groundLum: Math.round(GL*1000)/1000, dark: DARK,
                   engine: document.querySelector('mjx-container') ? 'mathjax'
                         : (document.querySelector('.katex') ? 'katex' : 'none') },
           mathFailures: math.filter(m => { const k = m.kind+'|'+m.tex; return seen.has(k) ? false : (seen.add(k), true); }),
           citations: cites.filter(c => c.keyVisible || !c.hasEntry),
           slides };
}
