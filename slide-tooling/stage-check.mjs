#!/usr/bin/env node
//
// Assert the staging invariant on a rendered Quarto reveal.js deck: on every
// content slide, nothing but the heading is visible before any fragment is
// advanced. Reports every slide, and exits 1 if any of them leaks.
//
//   node stage-check.mjs deck.html
//
// Companion to deck-check.mjs, which gates overflow. This gates the reveal order,
// which is just as silent: a figure that lands with the heading looks fine in a
// screenshot of the finished slide and wrong in the room.
//
// It drives reveal rather than guessing: `Reveal.slide(h, v, -1)` puts each slide
// in its unadvanced state, and then every text run and every graphic outside the
// heading has to be invisible. Visibility is the part to get right. A `.fragment`
// is `opacity: 0; visibility: hidden`, `visibility` inherits and `opacity` does
// not, so the test is the element's own computed `visibility` plus a walk up the
// ancestors for `opacity` and `display`.
//
// Slides that carry no content by construction are reported and skipped: the title
// slide, `.section-break`, `.appendix-break`, a `{visibility="hidden"}` slide, and
// a heading-less slide. reveal's own furniture and Quarto's (speaker notes, the
// footer, the slide number, the progress bar) are not content.
//
// `.thanks-slide` and `.closing-slide` are skipped as well. The talk's thank-you
// slide is titleless and fully unstaged, so read as content it would fail the test
// twice over: there is no heading standing alone at step 0, and there are no
// fragments to advance. The lecture's closing slide keeps its heading and stages as
// heading then one beat (a `.together` div): the heading lands first, and a single
// press brings the whole body, so students are not flashed everything while the
// instructor wraps up and the slide is still photographable in one state. The gate
// asserts on neither; the exemption is the class name. `.thanks-slide` used to
// borrow `.title-slide` to get past this, which held only for as long as nobody
// wrote a rule against that class.
//
// `.references-break` and `.references` are skipped too. The divider carries only
// its title, and a reference list is deliberately unstaged: there is no argument
// being built on it, and clicking through eight entries one at a time in front of a
// room is the wrong eight keypresses. stage-slide.lua puts the class on every page
// of the list it generates, so this covers the continuation slides as well.
//
// DEAD STEPS. Step 0 is only half the invariant. A press that reveals a wrapper
// painting nothing advances the deck without changing anything on the wall, and
// every assertion above is about the state before the first press, so none of them
// can see it. That is a real bug this gate missed: a `.steps` div got a fragment
// wrapper around an already-staged list, `visibility: hidden` kept the items' layout
// boxes, and the first press turned an empty box visible on two slides of the sample
// lecture. So each content slide is now walked forward one press at a time and every
// step has to change what the room sees.
//
// Four things that walk has to get right, each found the hard way:
//
//   * Read every state settled. A step sampled 30ms in returns a point on the
//     easing curve, which already caused one wrong diagnosis on this deck. The
//     stylesheet injected below stamps `transition` and `animation` off, which is
//     cheaper than sleeping past reveal's 200ms fragment fade and its
//     `auto-animate-duration` on every step of every slide.
//   * Leave the heading out of the signature. An `auto-animate` pair morphs the
//     `h2` between two slides, and the morph is still running when the first press
//     is sampled, so a heading in the signature makes step 1 look alive on exactly
//     the slides where it is least likely to be.
//   * Compare DOM ink, not pixels: the visible elements carrying text of their own,
//     plus the graphics, each with its box. Walking the slide's own `<section>`
//     excludes reveal's furniture for free, where a screenshot would first have to
//     hide the progress bar and the slide number, both of which redraw on every
//     `fragmentshown`.
//   * Put the slide back to `f = -1` when the walk is done, before anything reads
//     step 0, so the assertions above see the state they have always seen.
//
// Same CDP plumbing as deck-check.mjs (node 22 WebSocket, no npm install, a
// headless Chrome of its own).

import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { homedir, tmpdir } from "node:os";

const file = process.argv[2];
if (!file) { console.error("usage: stage-check.mjs deck.html"); process.exit(2); }

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

// One throwaway profile per run, removed in done(). The disk cache is the
// exception and is shared across runs, so MathJax comes off disk instead of
// the CDN every time the gate opens a deck.
const profileDir = `${tmpdir()}/stage-check-${process.pid}`;
const cacheDir = `${homedir()}/.claude/cache/deck-gate-chrome`;
mkdirSync(cacheDir, { recursive: true });

const proc = spawn(findChrome(), [
  "--headless=new", "--remote-debugging-port=0", "--window-size=1050,700",
  "--no-first-run", "--no-default-browser-check", "--disable-gpu", "--hide-scrollbars",
  `--user-data-dir=${profileDir}`, `--disk-cache-dir=${cacheDir}`, "file://" + resolve(file),
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
  if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails).slice(0, 900));
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
// Math and fonts have to settle before anything is read. MathJax attaches
// `window.MathJax` only once its script arrives (the self-hosted 2.7.9 copy
// the starter format ships, or a CDN on an unmigrated deck), so a fixed sleep
// undershoots. Poll up to 5s for either engine's ready hook: v2 exposes
// Hub.Queue (a callback queued behind the initial Typeset fires when it
// drains), v3+ exposes startup.promise. Skip cleanly when the deck's reveal
// config carries no math block (the KaTeX offline variant).
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

// Every reading below is a settled reading. See the dead-step note in the header.
await evaluate(`(() => {
  const st = document.createElement("style");
  st.textContent = "*, *::before, *::after { transition: none !important; animation: none !important; }";
  document.head.appendChild(st);
  return 1;
})()`);

const report = await evaluate(`(async () => {
  const R = window.Reveal, sleep = ms => new Promise(r => setTimeout(r, ms));
  try {
    if (window.MathJax?.Hub?.Queue) await new Promise(r => window.MathJax.Hub.Queue(r));
    else if (window.MathJax?.startup?.promise) await window.MathJax.startup.promise;
  } catch (e) {}
  try { if (document.fonts?.ready) await document.fonts.ready; } catch (e) {}
  await sleep(250);

  // Chrome that is not content: reveal's own furniture and Quarto's.
  const chrome = el => !!el.closest('aside.notes, .footer, .slide-number, .progress, .controls, .quarto-auto-generated-content');

  const shown = el => {
    // visibility inherits, so a .fragment ancestor (visibility: hidden) hides
    // its whole subtree. opacity does not inherit, so walk up for that.
    const cs = getComputedStyle(el);
    if (cs.visibility === 'hidden' || cs.display === 'none') return false;
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) return false;
    for (let p = el; p && p.nodeType === 1; p = p.parentElement) {
      const s = getComputedStyle(p);
      if (s.display === 'none' || s.visibility === 'hidden') return false;
      if (parseFloat(s.opacity) < 0.02) return false;
      if (p.classList.contains('slides')) break;
    }
    return true;
  };

  const out = [];
  const all = R.getSlides();
  for (let i = 0; i < all.length; i++) {
    const idx = R.getIndices(all[i]);
    R.slide(idx.h, idx.v, -1);          // -1: no fragment advanced
    await sleep(80);
    const s = R.getCurrentSlide();
    const head = s.querySelector(':scope > h1, :scope > h2, :scope > h3');
    const kind =
      s.id === 'title-slide' || s.classList.contains('title-slide') ? 'title' :
      s.classList.contains('thanks-slide') ||
      s.classList.contains('closing-slide') ? 'closing' :
      s.classList.contains('section-break') ? 'section divider' :
      s.classList.contains('appendix-break') ? 'appendix divider' :
      s.classList.contains('references-break') ? 'references divider' :
      s.classList.contains('references') ? 'reference list' :
      s.getAttribute('data-visibility') === 'hidden' ? 'hidden' :
      !head ? 'no heading' : 'content';

    // What the room sees on this slide, as one string: every shown element inside
    // the section that carries ink of its own, with the box it occupies. The
    // heading is left out because an auto-animate pair morphs it between slides.
    const ink = () => {
      const parts = [];
      for (const el of s.querySelectorAll('*')) {
        if ((head && head.contains(el)) || chrome(el) || !shown(el)) continue;
        const own = Array.from(el.childNodes)
          .filter(n => n.nodeType === 3 && n.nodeValue.trim())
          .map(n => n.nodeValue.trim()).join(' ');
        const graphic = /^(IMG|SVG|CANVAS|VIDEO|IFRAME)$/.test(el.tagName);
        if (!own && !graphic) continue;
        const r = el.getBoundingClientRect();
        parts.push(el.tagName + '@' + Math.round(r.x) + ',' + Math.round(r.y) +
                   ',' + Math.round(r.width) + ',' + Math.round(r.height) + ':' + own);
      }
      return parts.join('\\n');
    };

    // Every fragment step, in the order the presenter presses forward. A step that
    // leaves the ink identical is a keypress the room cannot see. \`nextFragment\`
    // only ever moves within the slide and returns false when it runs out, so the
    // walk cannot wander onto the next one.
    const dead = [];
    if (kind === 'content') {
      let prev = ink();
      for (let k = 0; k < 60; k++) {
        if (R.nextFragment() === false) break;
        await sleep(30);
        const now = ink();
        if (now === prev) dead.push(k);
        prev = now;
      }
      // Back to the unadvanced state, before anything below reads it.
      R.slide(idx.h, idx.v, -1);
      await sleep(30);
    }

    const advanced = s.querySelectorAll('.fragment.visible').length;
    const leaks = [];
    if (kind === 'content') {
      // Every text run and every graphic in the slide, minus the heading.
      const walker = document.createTreeWalker(s, NodeFilter.SHOW_TEXT);
      for (let n = walker.nextNode(); n; n = walker.nextNode()) {
        if (!n.nodeValue.trim()) continue;
        const el = n.parentElement;
        if (!el || (head && head.contains(el)) || chrome(el)) continue;
        if (shown(el)) leaks.push(JSON.stringify(n.nodeValue.trim().slice(0, 60)));
      }
      for (const g of s.querySelectorAll('img, svg, canvas, video, iframe, table')) {
        if ((head && head.contains(g)) || chrome(g)) continue;
        if (shown(g)) leaks.push('<' + g.tagName.toLowerCase() + '>');
      }
    }
    out.push({
      n: i + 1, kind, advanced, dead,
      fragments: s.querySelectorAll('.fragment').length,
      headShown: head ? shown(head) : null,
      title: (head?.textContent || '(none)').trim().slice(0, 52),
      leaks,
    });
  }
  return out;
})()`);

let bad = 0;
for (const s of report) {
  const flags = [];
  if (s.kind === "content") {
    if (s.leaks.length) flags.push(`LEAKS AT STEP 0: ${[...new Set(s.leaks)].join(" ")}`);
    if (s.advanced) flags.push(`${s.advanced} FRAGMENT ALREADY VISIBLE`);
    if (s.headShown === false) flags.push("HEADING NOT VISIBLE");
    if (!s.fragments) flags.push("NO FRAGMENTS ON A CONTENT SLIDE");
    if (s.dead.length === 1) flags.push(`DEAD STEP: press ${s.dead[0] + 1} changes nothing`);
    else if (s.dead.length) flags.push(`DEAD STEPS: presses ${s.dead.map((k) => k + 1).join(", ")} change nothing`);
  }
  if (flags.length) bad++;
  console.log(
    `  ${String(s.n).padStart(2)}  ${s.kind.padEnd(18)} ${String(s.fragments).padStart(2)} frag  ` +
    `${flags.length ? flags.join("; ") : "clean"}   ${s.title}`
  );
}
console.log(`\nSTEP-0-CLEAN: ${bad ? "NO" : "YES"}  (${report.length} slides, ${report.filter((s) => s.kind === "content").length} of them content)`);
done(bad ? 1 : 0);
