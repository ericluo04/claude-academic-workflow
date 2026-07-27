#!/usr/bin/env node
//
// Fit gate and handout exporter for a rendered Quarto reveal.js deck.
//
//   node deck-check.mjs fit     deck.html [--json]     # exits 1 on overflow, a dangling jump target, or an unpaginated bibliography
//   node deck-check.mjs handout deck.html out.pdf      # print view, honors pdf-separate-fragments
//
// Drives headless Chrome over CDP using node 22's global WebSocket, so there is
// no npm install and no Playwright MCP involved (the MCP browser is shared
// across agents and concurrent runs steal each other's page).
//
// Chrome is found in the Playwright cache, then /Applications. Override with
// CHROME_BIN.

import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { homedir, tmpdir } from "node:os";

const [cmd, file, arg3] = process.argv.slice(2).filter((a) => !a.startsWith("--"));
const asJson = process.argv.includes("--json");
if (!["fit", "handout"].includes(cmd) || !file) {
  console.error("usage: deck-check.mjs fit deck.html [--json]");
  console.error("       deck-check.mjs handout deck.html out.pdf");
  process.exit(2);
}
if (cmd === "handout" && !arg3) { console.error("handout needs an output pdf path"); process.exit(2); }

function findChrome() {
  if (process.env.CHROME_BIN) return process.env.CHROME_BIN;
  const pw = resolve(homedir(), "Library/Caches/ms-playwright");
  if (existsSync(pw)) {
    for (const d of readdirSync(pw).filter((x) => x.startsWith("chromium"))) {
      for (const c of [
        `${pw}/${d}/chrome-headless-shell-mac-arm64/chrome-headless-shell`,
        `${pw}/${d}/chrome-mac/Chromium.app/Contents/MacOS/Chromium`,
      ]) if (existsSync(c)) return c;
    }
  }
  for (const c of [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
  ]) if (existsSync(c)) return c;
  throw new Error("no Chrome found; set CHROME_BIN");
}

// reveal's ?print-pdf view is what respects pdf-separate-fragments. The live
// view cannot be printed: chrome --print-to-pdf on it yields a blank page.
const url = "file://" + resolve(file) + (cmd === "handout" ? "?print-pdf" : "");

// One throwaway profile per run, removed in done(). The disk cache is the
// exception and is shared across runs, so MathJax comes off disk instead of
// the CDN every time the gate opens a deck.
const profileDir = `${tmpdir()}/deck-check-${process.pid}`;
const cacheDir = `${homedir()}/.claude/cache/deck-gate-chrome`;
mkdirSync(cacheDir, { recursive: true });

const proc = spawn(findChrome(), [
  "--headless=new", "--remote-debugging-port=0", "--window-size=1050,700",
  "--no-first-run", "--no-default-browser-check", "--disable-gpu", "--hide-scrollbars",
  `--user-data-dir=${profileDir}`, `--disk-cache-dir=${cacheDir}`, url,
], { stdio: ["ignore", "pipe", "pipe"] });

const wsURL = await new Promise((ok, bad) => {
  let buf = "";
  const t = setTimeout(() => bad(new Error("chrome never reported a debug port")), 20000);
  proc.stderr.on("data", (c) => {
    buf += c;
    const m = buf.match(/ws:\/\/[^\s]+/);
    if (m) { clearTimeout(t); ok(m[0]); }
  });
});

// The browser-level socket cannot evaluate JS, so attach to the page target.
const port = new URL(wsURL).port;
let pageWS = null;
for (let i = 0; i < 60 && !pageWS; i++) {
  const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  pageWS = list.find((t) => t.type === "page")?.webSocketDebuggerUrl;
  if (!pageWS) await new Promise((r) => setTimeout(r, 250));
}
const ws = new WebSocket(pageWS);
await new Promise((ok) => (ws.onopen = ok));

let seq = 0;
const pending = new Map();
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
};
const send = (method, params = {}) => new Promise((ok) => {
  const i = ++seq; pending.set(i, ok);
  ws.send(JSON.stringify({ id: i, method, params }));
});
const evaluate = async (expression) => {
  const r = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails).slice(0, 600));
  return r.result?.result?.value;
};
const done = (code) => {
  ws.close();
  // Chrome leaves the profile behind otherwise, and it has to be gone before the
  // removal walk starts: a SIGTERM'd Chrome is still writing shutdown state, and
  // racing it ends in ENOTEMPTY. So wipe on the child's exit event, with a
  // timeout in case the signal is ignored and retries for straggler writes.
  const wipe = () => {
    try { rmSync(profileDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 }); } catch {}
    process.exit(code);
  };
  if (proc.exitCode !== null) return wipe();
  proc.once("exit", wipe);
  // Under a loaded machine (a full quarto render) SIGTERM can take seconds, so
  // escalate before the last-resort wipe races a still-writing Chrome.
  setTimeout(() => { try { proc.kill("SIGKILL"); } catch {} }, 1500).unref();
  setTimeout(wipe, 4000).unref();
  proc.kill();
};

await send("Page.enable");
await send("Runtime.enable");
for (let i = 0; i < 80; i++) {
  if (await evaluate(`!!(window.Reveal?.isReady?.() && document.querySelector('.reveal .slides section'))`)) break;
  await new Promise((r) => setTimeout(r, 250));
}
// Math and fonts have to settle before anything is measured. MathJax attaches
// `window.MathJax` only once its script arrives (the self-hosted 2.7.9 copy the
// yale formats ship, or a CDN on an unmigrated deck), so a fixed sleep
// undershoots, and a wait guarded by `window.MathJax &&` skips entirely and
// reports phantom UNRENDERED MATH. Poll up to 5s for either engine's ready
// hook: v2 exposes Hub.Queue (a callback queued behind the initial Typeset
// fires when it drains), v3+ exposes startup.promise. Skip cleanly when the
// deck's reveal config carries no math block (the KaTeX offline variant).
await evaluate(`(async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const wantsMathJax = !!(window.Reveal?.getConfig?.().math) || !!window.MathJax;
  if (wantsMathJax) {
    for (let i = 0; i < 50 && !(window.MathJax?.startup?.promise || window.MathJax?.Hub?.Queue); i++) await sleep(100);
    try {
      if (window.MathJax?.Hub?.Queue) await new Promise(r => window.MathJax.Hub.Queue(r));
      else if (window.MathJax?.startup?.promise) await window.MathJax.startup.promise;
    } catch (e) {}
  }
  try { await document.fonts.ready; } catch (e) {}
  return 1;
})()`);

if (cmd === "handout") {
  const r = await send("Page.printToPDF", {
    printBackground: true, preferCSSPageSize: true,
    marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0,
  });
  if (!r.result?.data) { console.error("printToPDF failed:", JSON.stringify(r).slice(0, 400)); done(1); }
  writeFileSync(arg3, Buffer.from(r.result.data, "base64"));
  console.log(`wrote ${arg3}`);
  done(0);
}

// Every rect below is read settled: transitions and animations are stamped off,
// the same stylesheet stage-check.mjs injects, so the per-slide settle can be a
// paint tick instead of a sleep past reveal's 200ms fragment fade.
await evaluate(`(() => {
  const st = document.createElement("style");
  st.textContent = "*, *::before, *::after { transition: none !important; animation: none !important; }";
  document.head.appendChild(st);
  return 1;
})()`);

// Non-current slides are display:none, so scrollHeight reads 0 on them. Visit
// each slide, force its fragments visible, then measure.
const report = await evaluate(`(async () => {
  const R = window.Reveal, sleep = ms => new Promise(r => setTimeout(r, ms));
  // A frame is enough between navigation and measurement once nothing animates:
  // two rAFs guarantee a style recalc and a paint have happened.
  const settle = () => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
  // MathJax typesets asynchronously, and KaTeX renders on DOMContentLoaded.
  // Measure only once the math engine and the webfonts have settled, or slides that
  // lost the race report phantom unrendered math and wrong element heights. The
  // caller has already waited on the engine's ready hook, so this is a second belt.
  try {
    if (window.MathJax && window.MathJax.Hub && window.MathJax.Hub.Queue) await new Promise(r => window.MathJax.Hub.Queue(r));
    else if (window.MathJax && window.MathJax.startup && window.MathJax.startup.promise) await window.MathJax.startup.promise;
  } catch (e) {}
  try { if (document.fonts && document.fonts.ready) await document.fonts.ready; } catch (e) {}
  await sleep(250);
  const box = document.querySelector('.reveal .slides');
  const vh = box.clientHeight, vw = box.clientWidth, all = R.getSlides();
  const out = [];
  for (let i = 0; i < all.length; i++) {
    const idx = R.getIndices(all[i]);
    R.slide(idx.h, idx.v);
    await settle();
    const s = R.getCurrentSlide();
    s.querySelectorAll('.fragment').forEach(f => f.classList.add('visible', 'current-fragment'));
    await settle();
    const imgs = [...s.querySelectorAll('img')].map(im => ({
      w: Math.round(im.getBoundingClientRect().width),
      h: Math.round(im.getBoundingClientRect().height),
      nat: im.naturalWidth + 'x' + im.naturalHeight,
      natW: im.naturalWidth,
      missing: im.complete && im.naturalWidth === 0,
    }));
    out.push({
      n: i + 1,
      title: (s.querySelector('h1,h2,h3')?.textContent || '(no heading)').trim().slice(0, 58),
      over: s.scrollHeight - vh,
      wide: s.scrollWidth - vw,
      missing: imgs.filter(im => im.missing).length,
      crushed: imgs.filter(im => !im.missing && im.h < 24).length,
      // auto-stretch is on by default and converts overflow into silent
      // shrinkage: a slide with too much text next to a figure does not
      // overflow, the figure just scales down until its axis labels are
      // unreadable. A figure authored large (natural width >= 1200px, which is
      // any knitr figure wider than about 6 inches at 192 dpi) that renders
      // under 600px was shrunk, not authored small.
      tiny: imgs.filter(im => !im.missing && im.natW >= 1200 && im.w < 600).length,
      // Only pandoc's own wrappers count. MathJax 2 output nests an internal
      // span whose class is also "math" inside the rendered span.MathJax, so a
      // bare '.math' query counts every typeset equation as unrendered.
      // Rendered evidence: KaTeX, MathJax 3+ (mjx-container), assistive or
      // native MathML (math), or MathJax 2 (span.MathJax).
      rawmath: [...s.querySelectorAll('span.math.inline, div.math.display, span.math.display')].filter(m =>
        !m.querySelector('.katex') && !m.querySelector('mjx-container') &&
        !m.querySelector('math') && !m.querySelector('.MathJax')).length,
      chars: s.innerText.replace(/\\s+/g, ' ').trim().length,
      divider: s.classList.contains('section-break') ||
               s.classList.contains('appendix-break') ||
               s.classList.contains('references-break'),
      imgs,
    });
  }
  // Jump buttons. A jump target is an id an author typed, and heading ids move when
  // a heading is reworded, so a stale target is the likeliest defect here. It is
  // also the worst: reveal fails an unresolved hash silently and lands on the title
  // slide, which is discovered mid-question in front of the room.
  // No backticks in this comment: the whole block is a JS template literal, so one
  // would end the string and the error arrives as a syntax error 40 lines earlier.
  const jumps = [...document.querySelectorAll('a.jump-btn[data-jump]')].map(a => {
    const id = a.getAttribute('data-jump');
    const el = document.getElementById(id);
    const sec = el && el.closest ? el.closest('.slides section') : null;
    return {
      label: a.textContent.trim().slice(0, 40),
      target: id,
      resolves: !!sec,
      hasBack: !!(sec && sec.querySelector('a.jump-btn.jump-back')),
    };
  });
  // stage-slide.lua paginates the bibliography and leaves an EMPTY div#refs
  // behind as a marker. A #refs with entries in it means pandoc ran citeproc a
  // second time, which happens when the deck sets a bibliography and forgets
  // citeproc: false in the front matter, and the whole reference list is then
  // duplicated onto one unpaginated slide. It is a one-line mistake with a wall of
  // overlapping text as its only symptom, so it belongs in the gate.
  // No backticks anywhere in here: this block is a JS template literal.
  const refsDiv = document.getElementById('refs');
  const strayRefs = refsDiv ? refsDiv.querySelectorAll('.csl-entry').length : 0;
  return { vh, vw, slides: out, jumps, strayRefs };
})()`);

if (asJson) { console.log(JSON.stringify(report, null, 2)); }

const fail = (s) => s.over > 5 || s.wide > 5 || s.missing || s.crushed || s.tiny || s.rawmath;
const bad = report.slides.filter(fail);
// A dangling jump target fails the gate. A jump target with no way back is a
// warning: a one-way button is a choice an author can defend.
const dangling = (report.jumps || []).filter((j) => !j.resolves);
const stray = report.strayRefs || 0;
const oneWay = (report.jumps || []).filter((j) => j.resolves && !j.hasBack);
// A transition slide carries only a heading on purpose, so it is not "empty".
const empty = (s) => s.chars < 25 && !s.imgs.length && !s.divider;
const thin = report.slides.filter(empty);

if (!asJson) {
  console.log(`canvas ${report.vw}x${report.vh}, ${report.slides.length} slides`);
  for (const s of report.slides) {
    const flags = [
      s.over > 5 ? `OVERFLOW +${s.over}px` : null,
      s.wide > 5 ? `TOO WIDE +${s.wide}px` : null,
      s.missing ? `${s.missing} MISSING IMG` : null,
      s.crushed ? `${s.crushed} CRUSHED FIG` : null,
      s.tiny ? `FIG SHRUNK TO ${Math.min(...s.imgs.filter(im => im.natW >= 1200).map(im => im.w))}px` : null,
      s.rawmath ? `${s.rawmath} UNRENDERED MATH` : null,
      empty(s) ? "NEARLY EMPTY" : null,
    ].filter(Boolean);
    console.log(`  ${String(s.n).padStart(2)}  ${flags.length ? flags.join(", ") : "ok"}   ${s.title}`);
  }
  if (thin.length) {
    console.log(`\nnearly empty (warning, not a failure): ${thin.map((s) => s.n).join(", ")}`);
    console.log("  a macro block outside a hidden slide produces exactly this");
  }
  if (report.jumps?.length) {
    console.log(`\n${report.jumps.length} jump button(s)`);
    for (const j of dangling) {
      console.log(`  DANGLING TARGET  #${j.target}  "${j.label}"`);
    }
    if (dangling.length) {
      console.log("  reveal fails an unresolved hash silently and lands on the title slide");
    }
    for (const j of oneWay) {
      console.log(`  no [.jump-back] on #${j.target} (warning, not a failure)`);
    }
  }
  if (stray) {
    console.log(`\nUNPAGINATED BIBLIOGRAPHY: div#refs holds ${stray} entries`);
    console.log("  add `citeproc: false` to the front matter; stage-slide.lua runs citeproc itself");
  }
  console.log(`\nDECK-FITS: ${bad.length || dangling.length || stray ? "NO" : "YES"}`);
}
done(bad.length || dangling.length || stray ? 1 : 0);
