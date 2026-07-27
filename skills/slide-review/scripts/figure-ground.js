async () => {
  const lum = c => { const m = c.match(/[\d.]+/g); if (!m) return null;
    const f = m.slice(0,3).map(v => { v = v/255; return v <= 0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); });
    return 0.2126*f[0] + 0.7152*f[1] + 0.0722*f[2]; };
  const GL = lum(getComputedStyle(document.querySelector('.reveal-viewport') || document.body).backgroundColor);
  const secs = [...document.querySelectorAll('.reveal .slides > section')]
    .flatMap(s => { const k = [...s.querySelectorAll(':scope > section')]; return k.length ? k : [s]; });
  const figs = [];
  for (let i = 0; i < secs.length; i++) {
    for (const img of secs[i].querySelectorAll('img')) {
      const src = img.getAttribute('src') || img.getAttribute('data-src') || '';
      let edge = null, note = null;
      try {
        const im = new Image(); im.src = src; await im.decode();
        const S = 48, c = document.createElement('canvas'); c.width = S; c.height = S;
        const x = c.getContext('2d', { willReadFrequently: true });
        x.drawImage(im, 0, 0, S, S);
        const d = x.getImageData(0, 0, S, S).data;
        let t = 0, n = 0;
        for (let py = 0; py < S; py++) for (let px = 0; px < S; px++) {
          if (px > 3 && px < S-4 && py > 3 && py < S-4) continue;
          const k = (py*S+px)*4; if (d[k+3] < 128) continue;
          t += lum('rgb(' + d[k] + ',' + d[k+1] + ',' + d[k+2] + ')'); n++; }
        edge = n ? Math.round(t/n*1000)/1000 : null;
        if (!n) note = 'border fully transparent';
      } catch (e) { note = 'unmeasurable: ' + String(e).slice(0,80); }
      figs.push({ slide: i, edgeLum: edge, groundLum: Math.round(GL*1000)/1000, note,
                  lightbox: edge !== null && edge > GL + 0.35,
                  alt: (img.getAttribute('alt')||'').slice(0,40) });
    }
  }
  return figs;
}
