---
name: slide-review
description: Audit a Quarto reveal.js deck that already exists: render it, screenshot every slide in a browser, and report overflow, unreadable type, low contrast, broken figures, failed math, and a weak argument. TRIGGER on "review my slides", "check my deck", "pre-talk check", "am I ready to present", "are my slides readable", "is anything cut off". Authoring a new deck is research-talk or teaching-lecture.
argument-hint: "[deck.qmd|deck.html] [--preflight] [--type=talk|lecture] [--slides=1-12] [--goal=\"...\"]"
---

# slide-review

Render the deck, gate it on a headless-Chrome fit check, screenshot every slide, then hand those PNGs to
reviewer subagents that judge from pixels. The predecessor skill read `.tex` source and guessed at
overflow by counting characters, which is how a deck reaches the podium with its last bullets below the
bottom edge. Nothing here infers layout from source. A browser measures it and the reviewers look at it.

Same loop as `compile-latex --figures`: render, rasterize, let an agent with eyes judge the image,
report exact fixes. This skill reports and does not edit, because a deck revision is the author's call.

Descends from the `slide-excellence` orchestrator, the `create-lecture` workflow, and its four review
agents in [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow).

## Where things live

The stages stay here; the detail sits in files this skill reads on demand. Paths are relative to
this skill's directory. `$ASSETS` is `~/.claude/assets/quarto-yale`, and its `README.md` is the
toolchain's own manual: gate internals, filter behaviour, theme classes, the offline recipe. Facts
that README owns are cited below, never restated.

| File | What it holds |
|---|---|
| `scripts/probe.js` | The stage 4 probe. Read the file and paste the whole function into `browser_evaluate`. |
| `scripts/figure-ground.js` | The stage 4 figure-ground pass. Same usage. |
| `references/probe-reading.md` | The theme ink tables with measured ratios, the font-size and contrast thresholds, the four math-failure kinds, the dark-deck defect classes. |
| `references/reviewer-prompts.md` | The four reviewer prompts, the settled-decisions paragraph reviewers receive, and the reply contract. |
| `references/failure-taxonomy.md` | The full failure table. The eight commonest rows are inline below. |
| `style/house.md` | This author's expectations: the closing-slide contact block, density calibration by deck type, settled design decisions, the author line. A public fork swaps this file. |

## One browser, so serialize it

There is a single shared Playwright instance on this machine. Two agents driving it will hijack each
other's page mid-capture. So all Playwright work happens here, in one place, sequentially. Never spawn
parallel subagents that navigate or screenshot. Fan out only after the PNGs are on disk, where the
reviewers read image files and touch no browser.

Playwright also blocks `file://`, so the deck has to be served over HTTP.

The stage 3 gate is exempt from all of this. `deck-check.mjs` launches its own headless Chrome over CDP,
so it cannot be hijacked and needs no server. That is why the measurements live there and Playwright is
kept for the things only it can do: the deck's ground colour, contrast against composited backgrounds,
the math-engine signals, and the screenshots.

## Inputs

| Argument | Default | Meaning |
|---|---|---|
| positional | required | A `.qmd` to render, or an already-rendered `.html` to review as-is. |
| `--preflight` | off | Stages 0 to 4 only (type, render, fit, probe, and the offline check if the deck asked for it), no reviewer fanout. Use in the hour before a talk. |
| `--type=talk\|lecture` | detected | Which lenses to run and which contrast expectations apply. Detection in stage 0. |
| `--slides=1-12` | all | Capture and review a range only. 1-based, matches the on-slide number. |
| `--goal="..."` | none | What the deck should accomplish. Passed to the argument reviewer verbatim. |

If the positional is a bare filename, `Glob` for it under the current project before asking. No config
file is read.

## Setup

```bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
ASSETS="$HOME/.claude/assets/quarto-yale"
RUN="$HOME/.claude/state/slide-review/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN/shots"
PORT=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
```

Preflight `quarto`, `python3`, and the Playwright MCP tools. Missing quarto or python3, surface
`SETUP_MISSING:<tool>` and stop. Missing the browser, fall back to the capture path in stage 5 rather
than reading the source, which is the failure this skill replaces. node 22 and Chrome are
needed for the stage 3 gate, which is not optional.

There is no Homebrew on this machine, so no `pdftoppm`, no `pdftotext`, no ImageMagick. Do not reach for
them. Every PDF goes through `~/.claude/assets/bin/pdfread.py` (see stage 5), including any
PDF you need to look at, because `Read` cannot open one here.

`mkdir` the shots directory before any screenshot. Playwright returns a bare `ENOENT` if the parent
directory does not exist, and it does not create it.

## Stage 0: deck type and ground

Settle this before running anything, because the whole review branches on it. Deck type picks
the lens list (a lecture gets the pedagogy reviewer, a talk does not), the text-density standard
(deliberately opposite targets per type; `style/house.md`), and the closing-slide expectation
(stage 3c). The ground branches the contrast arithmetic: the shipped starter theme is dark ink on a
paper ground, and a deck on a designed dark theme flips the ground every contrast number is taken
against, so ink that is correct on one is invisible on the other.

Read the theme and the other front matter facts in one pass. In a Quarto website the format block
usually sits in a `_metadata.yml` beside the `.qmd`, so search both:

```bash
grep -nE '^\s*format:|^\s*theme:|html-math-method|embed-resources|self-contained-math|highlight-style|stage-slide' \
  deck.qmd _metadata.yml "$(dirname deck.qmd)/_metadata.yml" 2>/dev/null
```

For a rendered `.html` with no source, fingerprint the class names, since the two deck types use
mostly distinct vocabularies:

```bash
grep -coE 'class="[^"]*\b(assumption|proposition|lemma|takeaway|result|thanks-slide|ymid)\b' deck.html   # talk
grep -coE 'class="[^"]*\b(keyidea|definition|question|prompt|agenda|steps|demo-tag|hero|ypale)\b' deck.html # lecture
```

Whichever count is higher wins. A tie, or zero both ways, means ask. The root font size is a
second signal when the themes in play differ, since a lecture theme typically runs a larger root
than a talk theme (the starter theme serves both types at 30px). The stage 4 probe reports the root
size and the deck's ground colour, so confirm the answer there before writing the report. A deck
reporting pure white when its theme sets a tinted or dark ground means the theme did not load,
which is CRITICAL on its own.

What the deck's ink should measure, hex by hex, comes from the theme's own palette table;
`references/probe-reading.md` opens with the starter theme's. The class vocabulary is the README's
`Theme classes` section; a cheap single fingerprint is that talk sources use `.ymid` where
lecture sources use `.ypale` (the starter theme styles both).

`.section-break` styling is per theme, so old advice about it goes stale, and
the README's `Things that will silently break the deck` section has the current rule: no
`background-color` attribute on a section divider, whatever the theme. On a dark deck the attribute
is also a defect
the probe can see, because reveal's `has-dark-background` then forces that slide's body text to pure
white (verification in `references/probe-reading.md`, dark defects). Do not carry an old
hard-coded `background-color` fix forward from memory.

## Stage 1: render

```bash
cd "$(dirname deck.qmd)" && quarto render deck.qmd --to revealjs 2>&1 | tee "$RUN/render.log"
```

On non-zero exit, extract the error from the log, surface `RENDER_FAILED:<message>`, and stop. Never
review a stale HTML from a previous render.

Then mine the log, because pandoc reports two classes of defect that no amount of looking at pixels
will reveal:

```bash
grep -nE '^\[WARNING\]|^ERROR|Could not fetch|not found' "$RUN/render.log"
```

Verified output on a deck citing a key absent from the `.bib` and embedding a missing figure:

```
[WARNING] Citeproc: citation ghostcite2019 not found
[WARNING] Could not fetch resource figures/does-not-exist.png
```

Both are CRITICAL. An unresolved citation prints the raw bibtex key on the wall.

There is no post-processing step. A correctly configured deck comes out of `quarto render` ready to
review, and any offline claim gets confirmed in stage 2. Skip stage 1 entirely when handed an `.html`.

## Stage 2: offline check, only when the deck asked for it

This used to be a mandatory gate and is not one any more. Decks now default to MathJax loaded from a
CDN, so an external MathJax reference is the expected state of a correct deck, and reporting it as a
defect sends the author after a bug that is not there. Offline is an opt-in variant, declared in
front matter as `embed-resources: true` together with `html-math-method: katex`. Run the check only
in that case, using the facts stage 0 already read:

```bash
python3 "$ASSETS/check-offline.py" deck.html; echo "exit=$?"    # opt-in decks only
```

Say which branch ran, in the report, on its own line. A default deck gets
`Offline-safe: not checked (CDN MathJax variant, offline not requested)`. An opt-in deck gets the
output quoted verbatim near the top, because a deck that loses its math on a conference room
projector with no wifi is the worst outcome this skill exists to prevent. A pass lists external
hosts and both runtime loader fields as `none` and ends `OFFLINE-SAFE       : YES` (the field is
padded, so grep the label and read the verdict, per the README).

On an opt-in deck, exit 1 with `OFFLINE-SAFE : NO` is CRITICAL, and the report names the specific
cause. Two causes account for nearly all of them, and the README's `Things that will silently break
the deck` section owns the mechanics of both:

- Any `cdn.jsdelivr` hit or leftover katex runtime loader means `html-math-method` was written in
  the object form, which Quarto's katexPostProcessor silently ignores. The fix is the README's
  offline recipe: the bare string `katex` plus `self-contained-math: true` under
  `embed-resources: true`. With that, Quarto embeds KaTeX and its fonts itself; verified at 4.95 MB
  with no external hosts, no runtime loaders, and no post-processing of any kind.
- The base theme was swapped off `default` onto one of the eight built-in reveal themes that
  `@import` Google Fonts, which no Quarto setting can make offline-safe; the README names the eight
  and the four clean ones. CRITICAL, with the fix being a return to `[default, <your-theme>.scss]`
  (the starter extension layers `starter-theme.scss` on `default`).

Run this grep on every deck, offline variant or not, because a swapped base theme also changes the
variables the deck's own SCSS layers onto, and it can quietly undo the ground the
rest of this review measures against:

```bash
grep -nE '^\s*theme:|fonts\.googleapis|fonts\.gstatic' deck.qmd deck.html
```

Ignore the `unconverted math` count. Quarto's katex mode leaves `<span class="math">` in the file on
purpose and converts it in the browser, so a non-zero count there is normal and not a finding.

## Stage 3: fit gate

Run this on every deck, before touching the browser. It is the one mandatory gate, whatever the theme
and whatever the math engine. It owns every geometric finding in the report.

```bash
node "$ASSETS/deck-check.mjs" fit deck.html; echo "exit=$?"
node "$ASSETS/deck-check.mjs" fit deck.html --json > "$RUN/fit.json"
node "$ASSETS/stage-check.mjs" deck.html; echo "exit=$?"
```

The second gate is the step-0 check: every content slide must open as its heading alone, and every
press must change visible ink. A clean deck prints `STEP-0-CLEAN: YES` and exits 0. It fails with
`LEAKS AT STEP 0` on content visible before the first press, and with
`DEAD STEP: press 2 changes nothing` or `DEAD STEPS: presses 2, 4 change nothing` on a press the
room cannot see, presses counted from 1. Both are CRITICAL. Name every slide it lists, and quote the
press numbers: the fix is per press, not per slide. Nothing else in this review can find either, and
the walk adds about two seconds. Mechanics, slide-kind classification, and what produces a dead
step are the README's staging section, under `Checking it`.

`deck-check.mjs fit` prints the canvas, one line per slide, then a verdict, and exits 1 whenever the
verdict is `NO`, so the gate composes: `node "$ASSETS/deck-check.mjs" fit deck.html || <report>`.
Verified output on a deck whose third slide is overstuffed, where `quarto render` had exited 0 in
silence:

```
canvas 1050x700, 5 slides
   1  ok   Deliberately Broken Test Deck
   2  ok   Motivation
   3  OVERFLOW +547px   Results
   4  ok   A formal result
   5  ok   Conclusion

DECK-FITS: NO
```

The status tokens, and what each one is worth in the report:

| Token | Meaning | Severity |
|---|---|---|
| `ok` | Slide fits. | none |
| `OVERFLOW +Npx` | Content past the bottom edge. Gone from the screen. | CRITICAL |
| `TOO WIDE +Npx` | Content past the right edge. | CRITICAL |
| `N MISSING IMG` | An `<img>` that resolved to nothing. | CRITICAL |
| `N CRUSHED FIG` | A figure scaled down far enough to be unreadable. | MAJOR |
| `FIG SHRUNK TO Npx` | A figure authored at 1200px or wider that `auto-stretch` scaled under 600px. | MAJOR |
| `N UNRENDERED MATH` | A `span.math` the engine never touched. Raw TeX on the wall. | CRITICAL |
| `NEARLY EMPTY` | Effectively blank slide. Prints "nearly empty (warning, not a failure)" and does not fail the gate. | MAJOR |
| `DANGLING TARGET #id` | A `.jump` button whose target id resolves to no slide. Reveal lands on the title slide instead, silently. Fails the gate. | CRITICAL |
| `UNPAGINATED BIBLIOGRAPHY` | `div#refs` holds entries, which means the deck set a `bibliography:` and forgot `citeproc: false`, so pandoc rendered a second copy of the whole reference list onto one slide. Fails the gate. | CRITICAL |
| `no [.jump-back] on #id` | A jump target with no way back. Warning; leaves the exit code alone. | MAJOR |

The exact measurement condition behind each token is the README's fit-gate table. `UNRENDERED MATH`
works under either engine and is what catches broken math delimiters, which under MathJax leave the
literal `\(...\)` in the paragraph and produce no container at all for the stage 4 probe to find.
The tokens are separate and a slide can carry more than one (`4  1 MISSING IMG` and
`5  TOO WIDE +308px` on the same run, verified). Carry each token and its number into the report
verbatim; never re-derive either.

`NEARLY EMPTY` is the one token that leaves the exit code at 0. A blank slide is still a defect the
audience sees, so report it, but do not describe the gate as failing on it. The common cause is a
bare macro block before the first `##`; the fix is `## Notation {visibility="hidden"}`, per the
README's `Things that will silently break the deck`.

`deck-check.mjs` drives its own headless Chrome over CDP on node 22, needs no `npm install`, honours
`CHROME_BIN`, and navigates slide by slide with fragments forced visible, which is the only way the
numbers come out right (README, fit-gate section). Do not write your own overflow probe: the obvious
one-pass snippet reads `scrollHeight` 0 off every non-present slide and reports a broken deck as
clean, as the README explains. `deck-check.mjs handout deck.html out.pdf` exports a PDF; offer it
when the user wants a handout, and use it as the capture fallback in stage 5.

### Stage 3b: jump buttons and the progress bar

The staging filter gives every deck two behavioural features no static screenshot can check, and both fail silently.
Run this only on a deck that has an appendix or `.jump` spans. It needs its own headless Chrome
rather than the shared Playwright browser, because it navigates and clicks:

```bash
grep -c 'class="jump-btn' deck.html          # 0 means skip the jump half
grep -c 'appendix-break\|section .*appendix' deck.html
```

What has to be true, and what each failure means:

| Check | Failure means |
|---|---|
| `.progress` carries `metered` when the deck has an appendix | The filter's script did not run, so the appendix is back in the denominator. MAJOR. |
| `.progress` carries `segmented` when the deck has two or more `.section-break` dividers | Same cause. MINOR on its own. |
| `--section-cut-N` values equal `100 * i / (main - 1)` for each divider at flattened index `i`, where `main` is the index of the first appendix slide | A cut in the wrong place, which is worse than no cuts. MAJOR. |
| The fill span's `scaleX` is 1 on the last main slide and on every appendix **and references** slide | The exclusion is not working. MAJOR, and the symptom the feature exists to prevent. |
| Every `a.jump-btn[data-jump]` target resolves to a slide | A dangling target lands the presenter on the title slide mid-question. CRITICAL. |
| Every appendix slide reachable by a jump carries a `.jump-back` | A one-way trip. MAJOR. |
| A jump then a back returns to the origin's `{indexh, indexv, indexf}` exactly | The handler is not capturing the origin before reveal navigates. CRITICAL. |

**Stage 3 already ran the dangling-target check**: `deck-check.mjs fit` fails on
`DANGLING TARGET #id "label"` and warns on a jump target with no `.jump-back`, so read its
jump-button block before doing this by hand, and carry its label and id into the report verbatim.
The equivalent in the browser, if you need it on an HTML you were handed:

```
browser_evaluate: () => [...document.querySelectorAll('a.jump-btn[data-jump]')].map(a => {
  const id = a.getAttribute('data-jump'), el = document.getElementById(id);
  const sec = el && el.closest('.slides section');
  return { label: a.textContent.trim(), target: id,
           resolves: !!sec, isAppendix: !!(sec && sec.classList.contains('appendix')),
           hasBack: !!(sec && sec.querySelector('a.jump-btn.jump-back')) };
})
```

Report `resolves: false` as CRITICAL with the label and the target id. `hasBack: false` is MAJOR:
the presenter can get there and not back. `isAppendix: false` is not a finding; a jump to a main
slide is legitimate.

The round-trip check needs interaction, so it belongs in one evaluate that drives reveal itself:
put the origin slide at a known fragment step, read `Reveal.getState()`, dispatch a bubbling `click`
on the button, dispatch one on the `.jump-back` it lands next to, and compare `Reveal.getState()` to
what you stored. A synthetic bubbling click is the right tool here: the handler is delegated, and a
real mouse click cannot reach a button whose fragment is still hidden.

Four behaviours are correct and must not be reported as defects. A jump lands the target with
**all** its fragments visible, on purpose. The bar stays full while you are inside the appendix or
the references, also on purpose, because the main deck really is over. A references slide has zero
fragments, because a reference list is not an argument being built. And an empty `<div id="refs">`
on the references divider is the marker that keeps citation links alive, not leftover markup: what
fails the gate is a `#refs` with entries in it.

### Stage 3c: the closing slide

How a deck ends is settled per type, so this check branches the way stage 0 does. Run it on every
deck. A research talk ends on a closing slide carrying the contact block; a teaching lecture ends on
content, with no closing slide. The expected contents, their position relative to the appendix and
references dividers, and the concrete presence greps are in `style/house.md`; state each finding
against that file's values. Handed a rendered `.html` with no source, take the ordered title list
from `fit.json` and the per-slide `classes` from `probe.json` after stage 4 has run, and read the
same positions off those.

| Deck type | State | Severity |
|---|---|---|
| talk | No closing slide anywhere | MAJOR. The talk stops instead of closing, and the room leaves with no address to write to. |
| talk | Closing slide sits inside the appendix, or after it, or after the references | MAJOR. The audience meets the appendix before the invitation. The fix is to move it ahead of the `.appendix-break` divider. |
| talk | Closing slide with no contact line and no invitation to get in touch | MINOR. Name the line that is missing. |
| talk | No QR slot on the closing slide | MINOR. |
| talk | QR slot present, image resolves to nothing | CRITICAL, and stage 3 has already printed `MISSING IMG` for that slide. Carry its token. |
| lecture | A thank-you slide is present | MINOR. It belongs on a talk; the lecture's own closing slide is the one idea to leave with. |

The bar reads full on the closing slide, since it is the last main-body slide. That is stage 3b's
fill check and not a second finding here.

## Stage 4: serve and probe

The browser handles what only it can: the deck's real ground colour, contrast against composited
backgrounds, the math-engine failure signals, unresolved citations, and the PNGs the reviewers look
at. Geometry is already settled by stage 3, so this probe no longer measures it, which keeps the hold
on the shared browser short.

```bash
cd "$(dirname deck.html)" && nohup python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
sleep 2 && curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:$PORT/deck.html"
```

Anything but `200` means the server did not come up; check the port and retry once. Kill it at the end
of the run, on every exit path including failure:

```bash
lsof -ti tcp:$PORT | xargs -r kill
```

Navigate with `browser_navigate` to `http://127.0.0.1:$PORT/deck.html`, then size the viewport so the
render scale is exactly 2.0, which makes every later measurement trivial to convert:

```
browser_resize  width=2334  height=1556
```

Reveal computes `scale = min(0.9 * innerW / 1050, 0.9 * innerH / 700)` at the Quarto default margin of
0.1, so 2334x1556 gives scale 2.000 against the 1050x700 logical canvas. Verified. One screenshot
pixel is half a deck pixel, and the reviewers are told so.

Collapse animation so one capture per slide is the whole slide:

```
browser_evaluate: () => { Reveal.configure({fragments: false, transition: 'none', autoAnimate: false}); Reveal.layout(); return {total: Reveal.getTotalSlides(), scale: Reveal.getScale()}; }
```

`fragments: false` is what makes staged content measurable, and it has to stay. Decks run
`stage-slide.lua`, which wraps nearly every top-level block on a content slide in a `.fragment` so
the slide opens as its heading alone. A staged block is present in the DOM from the start and only
hidden, so it is content, not missing content. Never report a slide as empty or a point as absent
because it arrives on a later keypress, and tell the reviewers the same, since the screenshots are
taken with fragments off and show the fully revealed slide.

Then run the probe: read `scripts/probe.js` and paste the whole function into one
`browser_evaluate`, and save the returned JSON to `$RUN/probe.json`. It forces each section visible
in turn and restores the inline style afterwards, because Reveal sets `display: none` on off-screen
sections and a hidden element reports no computed geometry and no client rects. It measures font
size and contrast against the composited background, reads the deck's own ground colour instead of
assuming white, and re-bases per slide on a `data-background-color`, because reveal paints that
backdrop on a separate `.slide-background` element that is nowhere in the text's ancestor chain;
without the re-base, the probe measures a divider slide's text against the deck ground while the
audience sees it on the attribute's colour.

Images cannot be measured in that pass: reveal lazy-loads them from `data-src`, so off-screen
`<img>` elements report `naturalWidth` 0 and a zero-size box, and forcing the section visible does
not change that (verification in `references/probe-reading.md`). So run `scripts/figure-ground.js`
the same way: it loads each image into a detached `Image` and samples the border band. Append the
result to `$RUN/probe.json` as `figures`.

Read both against `references/probe-reading.md`: the font-size and contrast thresholds, the
`figures[].lightbox` rule with its verified calibrations, the four math-failure kinds and how each
engine shows them, the unresolved-citation shape, and the four dark-deck defect classes, which apply
only when `deck.dark` is true and are all skipped on a talk deck.

## Stage 5: capture

For each slide index `n` from 0 to `total - 1`, two calls, in order:

```
browser_evaluate: () => { Reveal.slide(N); Reveal.layout(); return Reveal.getIndices(); }
browser_take_screenshot: filename=$RUN/shots/slide-NN.png  type=png  scale=css
```

`Reveal.slide(n)` is the only navigation that works reliably. URL fragments do not, and arrow keys
drift on decks with vertical stacks. Zero-pad `NN` so the files sort.

The capture is a viewport screenshot, so content past the canvas edge is cut off in the image exactly
as the projector will cut it. A bullet sliced through its x-height in the PNG is the defect, not an
artifact of the capture.

Above about 40 slides this is 80 tool calls. Say so and offer `--slides=` before starting a long deck.
In `--preflight` mode, capture only the slides the probe flagged, plus the title slide.

### Fallback when the browser is contended

If another agent holds the browser, or the page keeps changing under you mid-capture, export the deck
to PDF and rasterize from there. Stage 3 has already run, so the geometry is in hand either way; what
this route gives up is stage 4's contrast and KaTeX signals, so get those from the browser first if you
can hold it even briefly.

```bash
node "$ASSETS/deck-check.mjs" handout deck.html "$RUN/deck.pdf"
```

That reuses the same headless Chrome the gate uses and needs nothing installed. decktape is the second
option if the handout export disagrees with what you saw on screen; the README's PDF sections carry
the exact `npx -y decktape@latest reveal` invocation. Both drive their own browser, so neither is
blocked by the shared Playwright instance, and `file://` is fine here because that restriction is
Playwright's. Chrome's `--headless --print-to-pdf` is not an alternative; it produces a blank PDF on
reveal decks.

### Reading any PDF

The `Read` tool cannot open PDFs on this machine. There is no poppler and so no `pdftoppm`, which is
what `Read` needs, and it fails on every `.pdf`. Route through `pdfread.py`, then `Read` the PNG:

```bash
~/.claude/assets/bin/pdfread.py png "$RUN/deck.pdf" --pages 3 --dpi 110 --out "$RUN/shots/s"
```

That writes `$RUN/shots/s-3.png`. `--pages` takes `3`, `1-5`, or `1,4,9`, 1-based. Raise `--dpi` to 150
when a reviewer needs to judge small type in a figure. This applies anywhere a PDF shows up, including
a deck the user hands over directly.

### If handed a PDF instead of a deck

Legacy Beamer, or a deck someone exported. No probe, no offline check, no browser, so the image
reviewers run alone and the report says which lenses were unavailable. Rasterize every page:

```bash
~/.claude/assets/bin/pdfread.py pages deck.pdf      # page count first
~/.claude/assets/bin/pdfread.py png deck.pdf --pages 1-24 --dpi 110 --out "$RUN/shots/slide"
```

Check `head -c 5 deck.pdf` is `%PDF-` first. A download that was actually an HTML error page will die
with `Unrecoverable error, exit code 1`, which reads like a rasterizer bug and is not one. Confirm the
pixel size with `sips -g pixelWidth -g pixelHeight`; under 1400 wide, re-render at `--dpi 150` so the
reviewers can judge small type. Correct once, do not loop. `gs` at `/usr/local/bin/gs` does the same job
if PyMuPDF is unavailable, and `pdfread.py --help` prints the equivalent invocation.

## Stage 6: fan out

Now the browser is idle and the PNGs are on disk, so this part parallelizes safely. One `Agent` call
per lens, all in one message, `subagent_type: "general-purpose"`. Every reviewer gets the deck facts
(canvas 1050x700, screenshots at scale 2.0, root font size, deck type, and the ground colour from
`deck.ground`) and absolute PNG paths, and every reviewer is told to read the images.

Two facts every reviewer needs, or they will report the theme as a bug. A lecture deck is dark on
purpose, so light text on a near-black ground is the design and not a rendering failure. And the deck
is staged by `stage-slide.lua`, so the screenshots show the fully revealed slide even though the
audience meets it one block at a time; a point that arrives on a later keypress is present, not
missing.

Every reviewer gets one more instruction. Before ruling on a candidate defect, crop that region out of
the full-resolution PNG and look at the crop enlarged. This setup assumes no ImageMagick, so the crop
goes through PIL; adjust to your machine. One crop per suspect region, written beside the screenshot it
came from:

```bash
python3 -c "from PIL import Image; im=Image.open('$RUN/shots/slide-07.png').crop((x0,y0,x1,y1)); im.resize((im.width*3,im.height*3), Image.LANCZOS).save('$RUN/shots/slide-07-crop1.png')"
```

A coordinate read off the crop gets the crop origin added back before the halving to deck px, so the
arithmetic in a finding is always full-image. A defect that resolves at full resolution in the crop is
not reported, and a finding that survives names its crop file next to its evidence line.

The lenses: layout, argument, and copy on every deck, pedagogy on a lecture only. The prompts, the
settled-decisions paragraph that opens each of them, and the reply contract are in
`references/reviewer-prompts.md`; send them as written. The density calibration and the settled
decisions they encode are `style/house.md`. Inputs per lens: layout gets all PNGs plus `fit.json`
and `probe.json`; argument gets all PNGs plus the ordered title list and `--goal` if provided;
pedagogy gets all PNGs; copy gets all PNGs plus the `.qmd` source path so fixes can be exact. Every
reviewer replies in the numbered contract, or `NONE` at its severity floor.

## Stage 7: synthesize

Do this in the main thread. Merge, drop duplicates (layout and copy will both find raw TeX in an
equation; keep the one with better evidence), and rank on two keys: severity first, then whether the
audience sees it. An unresolved citation printing `(smith2020?)` on the wall outranks an inconsistent
symbol in the appendix at the same severity. Drop reviewer findings that contradict the settled
decisions or the density calibration in `style/house.md`; the full drop rules are rows in
`references/failure-taxonomy.md`.

```markdown
# Slide review: deck.qmd
Type: research talk (light, ground #ffffff) | Slides: 24 | Captured: $RUN/shots/
Render: clean | 2 pandoc warnings
Math: MathJax from CDN | Offline-safe: not checked (offline not requested)
DECK-FITS: NO (2 slides)
Closing: thank-you slide at 22, ahead of the appendix divider

## Blocking (fix before presenting)
1. [CRITICAL] Slide 3 "Results" - OVERFLOW +547px.
   Bullets 9 to 14 and the specification table are off screen. Split the slide,
   or move the table to its own.
2. [CRITICAL] Slide 5 "A wide table" - TOO WIDE +308px.
   The rightmost three columns are off screen. Drop columns or mark the table `.spec`.
3. [CRITICAL] Slide 4 "A formal result" - `\frobenius` renders as red literal text.
   KaTeX has no such macro; it was a Beamer preamble definition. Replace with `\|X\|_F`.

## Worth fixing
4. [MAJOR] Slide 1 is blank (NEARLY EMPTY), counted in c/t and printed in the handout.
   A macro block sits before the first `##`. Retitle it `## Notation {visibility="hidden"}`.
   The gate passes this one, so it will not block a release.

## Minor
## Clean
Slides 2, 5 through 24 pass all mechanical checks.
```

Lead with the fit verdict and the count of blocking issues. If nothing blocks, say the deck is ready to
present in the first line, then list the rest. The offline line still appears, saying either the
verdict or that the deck did not ask for the check, so nobody reads its absence as a pass.

On a lecture deck the header line carries the deck type and the measured ground the same way, the
closing
line reads `Closing: no thank-you slide (correct for a lecture)`, and on a dark deck the report
says which dark checks ran and what each found, including the ones that found nothing. A figure whose
pixels could not be read is reported as sent for human review, with the slide numbers.

Finish with the run directory, the PNG paths, and the agent count.

## Failure taxonomy

Every symptom this skill has met, with the response to each, is the table in
`references/failure-taxonomy.md`. Read it when a stage exits non-zero or a tool behaves oddly, and
before reporting a tool failure as a finding.

## Out of scope

Editing the deck. This produces a report; the author decides.

Prescribing how the author should write. Legibility, correctness, and whether the argument is
followable are in bounds. Sentence length, tone, and diction are not. Text density is in bounds on
the terms `style/house.md` sets, which are per deck type and about what the audience is asked to
absorb.

Judging whether the research is right. That is `/review-paper`.

Authoring a deck from scratch. That is `/research-talk` for a seminar deck and `/teaching-lecture` for
classroom material. This skill audits a deck that already exists.

Beamer `.tex` source. A PDF exported from Beamer goes through the rasterize path for image review only.
