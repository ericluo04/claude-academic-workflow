#!/usr/bin/env node
//
// Stages 4 and 5 of slide-review: probe a rendered Quarto reveal.js deck and
// screenshot every slide, from a headless Chrome of its own over CDP.
//
//   node capture.mjs deck.html RUN_DIR [--slides=1-12|1,4,9] [--no-probe] [--no-shots]
//
// Writes RUN_DIR/probe.json (probe.js output with figure-ground.js appended as
// `figures`) and RUN_DIR/shots/slide-NN.png. The viewport is 2334x1556, which
// puts Reveal's scale at 2.0 against the 1050x700 canvas at Quarto's default
// margin, so one screenshot px is half a deck px. Fragments are switched off
// before anything is measured or shot, so each PNG is the fully revealed slide.
//
// Same CDP plumbing as deck-check.mjs (node 22 WebSocket, no npm install, a
// headless Chrome of its own). The deck opens over file://, so there is no
// server to start or kill. --allow-file-access-from-files is what lets
// figure-ground.js read pixels off a canvas: without it every file:// URL is
// its own origin and getImageData throws a SecurityError on the first figure.

import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { homedir, tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const positional = process.argv.slice(2).filter((a) => !a.startsWith("--"));
const flags = process.argv.slice(2).filter((a) => a.startsWith("--"));
const [file, runDir] = positional;
if (!file || !runDir) {
  console.error("usage: capture.mjs deck.html RUN_DIR [--slides=1-12|1,4,9] [--no-probe] [--no-shots]");
  process.exit(2);
}
if (!existsSync(file)) { console.error(`no such deck: ${file}`); process.exit(2); }
const wantProbe = !flags.includes("--no-probe");
const wantShots = !flags.includes("--no-shots");
const slidesArg = flags.find((f) => f.startsWith("--slides="))?.slice("--slides=".length);

// 1-based on-slide numbers, matching deck-check's numbering and the report.
function parseSlides(spec, total) {
  if (!spec) return [...Array(total).keys()];
  const out = new Set();
  for (const part of spec.split(",")) {
    const m = part.trim().match(/^(\d+)(?:-(\d+))?$/);
    if (!m) throw new Error(`bad --slides part: ${part}`);
    const a = +m[1], b = m[2] ? +m[2] : a;
    for (let n = a; n <= b; n++) {
      if (n < 1 || n > total) throw new Error(`--slides ${n} is outside 1-${total}`);
      out.add(n - 1);
    }
  }
  return [...out].sort((x, y) => x - y);
}

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

const here = dirname(fileURLToPath(import.meta.url));
const url = "file://" + resolve(file);
const shotsDir = resolve(runDir, "shots");
mkdirSync(shotsDir, { recursive: true });

// Viewport that yields scale 2.0: Reveal computes
// min(0.9 * innerW / 1050, 0.9 * innerH / 700) at margin 0.1, and both terms
// come out at 2.000 for 2334x1556. Verified in the skill's earlier MCP path.
const VW = 2334, VH = 1556;

const profileDir = `${tmpdir()}/slide-capture-${process.pid}`;
const cacheDir = `${homedir()}/.claude/cache/deck-gate-chrome`;
mkdirSync(cacheDir, { recursive: true });

const proc = spawn(findChrome(), [
  "--headless=new", "--remote-debugging-port=0", `--window-size=${VW},${VH}`,
  "--no-first-run", "--no-default-browser-check", "--disable-gpu", "--hide-scrollbars",
  "--allow-file-access-from-files",
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
  const wipe = () => {
    try { rmSync(profileDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 }); } catch {}
    process.exit(code);
  };
  if (proc.exitCode !== null) return wipe();
  proc.once("exit", wipe);
  setTimeout(() => { try { proc.kill("SIGKILL"); } catch {} }, 1500).unref();
  setTimeout(wipe, 4000).unref();
  proc.kill();
  // Exit happens on Chrome's exit event, so callers await this to stop here.
  return new Promise(() => {});
};

await send("Page.enable");
await send("Runtime.enable");
await send("Emulation.setDeviceMetricsOverride", { width: VW, height: VH, deviceScaleFactor: 1, mobile: false });
for (let i = 0; i < 80; i++) {
  if (await evaluate(`!!(window.Reveal?.isReady?.() && document.querySelector('.reveal .slides section'))`)) break;
  await new Promise((r) => setTimeout(r, 250));
}
if (!(await evaluate(`!!window.Reveal`))) { console.error("Reveal is not defined: not a reveal deck, or it never loaded"); await done(1); }

// Math and fonts settle before anything is measured; same wait as deck-check.mjs.
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

// Fragments off so a slide is measured and shot fully revealed; transitions
// off so a paint tick is a settled frame.
const setup = await evaluate(`(() => {
  const st = document.createElement("style");
  st.textContent = "*, *::before, *::after { transition: none !important; animation: none !important; }";
  document.head.appendChild(st);
  Reveal.configure({ fragments: false, transition: 'none', autoAnimate: false });
  Reveal.layout();
  const box = document.querySelector('.reveal .slides');
  return { total: Reveal.getTotalSlides(), scale: Reveal.getScale(), vw: box.clientWidth, vh: box.clientHeight };
})()`);
console.log(`canvas ${setup.vw}x${setup.vh}, scale ${setup.scale.toFixed(3)}, ${setup.total} slides`);
if (Math.abs(setup.scale - 2) > 0.01) console.log(`  WARNING: scale is ${setup.scale}, not 2.0; screenshot px / ${setup.scale} = deck px`);

let selection;
try { selection = parseSlides(slidesArg, setup.total); } catch (e) { console.error(String(e.message)); await done(2); }

if (wantProbe) {
  const probeSrc = readFileSync(resolve(here, "probe.js"), "utf8");
  const figSrc = readFileSync(resolve(here, "figure-ground.js"), "utf8");
  const probe = await evaluate(`(${probeSrc})()`);
  probe.figures = await evaluate(`(${figSrc})()`);
  const out = resolve(runDir, "probe.json");
  writeFileSync(out, JSON.stringify(probe, null, 2));
  const unreadable = (probe.figures || []).filter((f) => f.note).length;
  console.log(`probe: ${out} (${(probe.slides || []).length} slides, ${(probe.figures || []).length} figures${unreadable ? `, ${unreadable} unmeasurable` : ""})`);
}

if (wantShots) {
  const pad = Math.max(2, String(setup.total).length);
  let written = 0;
  for (const i of selection) {
    await evaluate(`(async () => {
      const R = window.Reveal, all = R.getSlides(), idx = R.getIndices(all[${i}]);
      R.slide(idx.h, idx.v); R.layout();
      await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
      await new Promise(r => setTimeout(r, 150));
      return R.getIndices();
    })()`);
    const shot = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
    if (!shot.result?.data) { console.error(`screenshot of slide ${i + 1} failed: ${JSON.stringify(shot).slice(0, 300)}`); await done(1); }
    writeFileSync(resolve(shotsDir, `slide-${String(i + 1).padStart(pad, "0")}.png`), Buffer.from(shot.result.data, "base64"));
    written++;
  }
  const first = String(selection[0] + 1).padStart(pad, "0"), last = String(selection.at(-1) + 1).padStart(pad, "0");
  console.log(`shots: ${written} -> ${shotsDir}/slide-${first}.png .. slide-${last}.png`);
}
await done(0);
