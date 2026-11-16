---
name: teaching-lecture
description: Author a Quarto reveal.js lecture deck for a class meeting. TRIGGER on "build a lecture", "slides for my class", "teaching deck", "lecture on X", "course slides", "make a lecture for week 3", "add a discussion slide". Conference and seminar decks are research-talk, the site around the decks is course-site, auditing an existing deck is slide-review.
---

# Teaching lecture decks

Builds a `.qmd` that renders to a reveal.js HTML deck for a class meeting, and
organizes a semester of them into one published course site.
Students are seeing the ideas for the first time, they are taking notes, they
will reread the deck a week later, and their attention resets every fifteen
minutes. That drives every choice here: bigger type, staged reveals, a visible
roadmap, a worked example after every formal idea, and questions they have to
answer out loud.

Out of scope: research presentations (use `research-talk`, which shares this
toolchain but has its own format and stays quiet and dense), auditing a deck you did
not write (use `slide-review`), and LaTeX Beamer (use `compile-latex`). The
`course-site` skill owns everything around the decks: the landing page, the week
table, the site theme, publishing.

The lecture format is Dark lab, the Quarto extension in
`slide-tooling/_extensions/darklab/` of this repository. Below, `$TOOLING`
stands for wherever SETUP.md installed your copy of `slide-tooling/`.
`$TOOLING/README.md` is the machinery reference: the filter, what the gates
assert, and the settings that silently break a deck. Read it for any of that;
where it and the source disagree, the source wins. The head of
`_extensions/darklab/darklab.scss` carries the palette table, and its CLICK
MECHANICS block documents every build class. This skill does not restate what `research-talk`
already covers (`output-location` for code chunks, how `pdfread.py` works);
read that skill where the two overlap. The pointer map at the end of this file
says which reference file holds what.

## The theme: Dark lab

Dark lab is built for a lecture hall with the lights down: a charcoal ground,
Manrope for text, JetBrains Mono for labels, numbers and wayfinding, and teal
and amber as the only two accents. The canvas is 1280x720 (16:9, which matches
current projectors), and the theme pads every slide itself, so nothing is
centred by reveal. Every ink is measured against the ground with a WCAG 2.1
checker, and the table sits at the head of `darklab.scss`:

| Role | Hex | Notes |
|---|---|---|
| Ground | `#16191d` | Every slide, dividers included. Nothing changes it. |
| Surface | `#1f2328` | Box and code grounds; every text ink below holds 4.5:1 here too. |
| Line | `#2f353d` | 1.4:1. Rules and frames. Never text. |
| Text | `#e9e6df` | 14.2:1. Running text, just off white, because pure white halates on a projector. |
| White | `#ffffff` | 17.6:1. Headings and `<strong>` only. |
| Crumb | `#b4bbc4` | 9.1:1. The breadcrumb and table headers. |
| Muted | `#9ba3ad` | 6.9:1. `.dim`, `.ygray`, asides, captions, done agenda items. |
| Teal | `#3fd6c1` | 9.7:1. The accent: key ideas, list marks, numerals, the step being built. |
| Amber | `#f4b860` | 10.0:1. The second accent: warnings, questions, the backup hint. |
| Card | `#f4f1ea` | The light card behind a figure that only exists on white. |

Any hex copied out of an older deck gets checked against the table before it
ships. Your own palette rationale goes in `style/house.md`.

Wayfinding is the breadcrumb at the bottom left of every slide: the number and
title of the section the slide belongs to, in 19px mono at 9.1:1, read off the
`.section-break` dividers so nothing is written per slide. The progress bar,
the slide number, the menu, and reveal's arrow controls are all off. Pair the
theme with `highlight-style: a11y-dark` (the format sets it) so code does not
arrive on a white card, and draw figures on the deck ground
(`references/figures-dark.md` has the recipe), because a white-panel figure is
a lightbox on a dark wall.

## Before drafting anything

Ask, do not guess.

1. Which course, which week, and how long the class is. 50 and 75 minutes are
   different decks, not the same deck at a different pace.
2. What last week ended on. Every lecture opens by closing that loop, and the
   agenda slide needs it.
3. Who is in the room, and what they can be assumed to know. A business-school
   AI class can draw MBAs, undergrads, and CS or econ PhD students in one section. A
   business student reads a figure faster than an equation and a CS student the
   reverse, so ask the mix, then give both with the picture first. Naming the
   prerequisite is what decides whether a formal definition can appear at all.
4. What already exists: the paper the lecture is built on, prior years' slides,
   the R that makes the figures.

Then write the slide titles and read them back as a list before any bodies
exist. A lecture title may be a topic label where a research title may not
("What a loss function is" is fine), but each block of three or four slides
under it carries one claim, and the claims in order are the lecture.

## The verified front matter

The format is a Quarto extension, `darklab-revealjs`. Adopt it once per deck
directory (or once at the project root):

```bash
cd <deck dir>
quarto add $TOOLING --no-prompt                          # installs every format in _extensions/, darklab among them
cp -R $TOOLING/_extensions/darklab/vendor/{mathjax,fonts} .     # MathJax (with HTML.js) and both faces at relative urls
```

A standalone deck then needs only:

```yaml
title: "Prediction is not a decision"
subtitle: "What a loss function is for"
author: "Your Name"       # exact form; see style/house.md
course: "AI and Economic Decisions"   # the title slide's mono line
lecture: "Week 3"
date: 2026-09-16
format: darklab-revealjs
engine: knitr             # only if the deck has R chunks; R is the default here for figures
bibliography: lecture-refs.bib   # only on a deck that cites
```

`course:` and `lecture:` are read by the format's own title-slide partial,
which sets them with the date in one mono line under a teal rule, the author
on the left. Any of the three may be left out.

The format carries, so the deck must not repeat: the theme layered on `default`
(eight of the twelve built-ins `@import` Google Fonts at display time), the
1280x720 canvas with `margin: 0` and `center: false`, `transition: none`,
`progress`, `slide-number`, `menu` and `controls` all off,
`stage-slide.lua` in `filters:`, `citeproc: false` (harmless on a deck that does
not cite), the reference-list budget (`refs-lines: 18`,
`refs-chars-per-line: 124`, measured for this theme),
`highlight-style: a11y-dark`, `incremental: true`,
`date-format: "D MMMM YYYY"`, `fig-align: center`,
`auto-animate-duration: 0.4`, `echo/warning/message: false`, `lab.html` (the
breadcrumb, the backup hint, backup nesting, the key remap, and equation
builds), and self-hosted MathJax (`method: mathjax, url: mathjax/MathJax.js`)
pinned to MathJax's own TeX webfonts so the metrics match on every machine and
the fit gate's certification transfers. The comments in `_extension.yml` say
why per key.

In a course project the per-course choices live once in `lectures/_metadata.yml`
and cover the whole semester. The verified working copy, from the example
course this repo's `examples/` lecture comes from:

```yaml
format:
  darklab-revealjs:
    # These lectures render to docs/lectures/<name>.html and the site's MathJax
    # copy is at docs/assets/mathjax/ (a `resources` entry in _quarto.yml keeps
    # it there across renders), so the url is the path from the rendered page
    # to that copy.
    html-math-method:
      method: mathjax
      url: ../assets/mathjax/MathJax.js
engine: knitr
```

`bibliography:` stays out of it, in the one lecture that cites.

`stage-slide.lua` opens each content slide as its title alone and then reveals
its blocks in turn, which `incremental: true` does for list items only; its six
jobs are in the README under "What stage-slide.lua does", and its header comment
is the reference before changing how a slide stages. A deck with dividers needs
it or the divider numerals come out empty.

MathJax handles `\eqref`, `\label`, `\DeclareMathOperator`, `mathtools`, and
`physics`, none of which KaTeX can do. Do not switch to `mathml` or `plain`; a
room with no network takes the offline variant, which gives up `\eqref` and
friends (README, "The offline variant"). The `highlight-style` is the theme's
companion: the format's `a11y-dark` (a light style paints a white code card on
this ground), and a misspelled style name fails silently at exit 0.

Students locate themselves off the breadcrumb, which names the section on every
slide, and off the agenda slide repeated at each block boundary. Dark lab has
no progress bar and no slide number; a student who wants to ask about a slide
later names its section and its title. Details: `references/staging.md`.

Leave `chalkboard` off: with `embed-resources: true` it is a hard render error,
and annotation happens on the room's own boards. Misspelled YAML keys are
ignored silently at exit 0; `quarto inspect deck.qmd` prints the resolved
format.

## Math macros

Park them on a hidden slide at the top of the file:

```markdown
## Notation {visibility="hidden"}

\newcommand{\E}{\mathbb{E}}
\DeclareMathOperator*{\argmin}{arg\,min}
```

A bare macro block before the first `##` becomes its own completely blank
slide, counted in navigation and printed into the handout; `visibility="hidden"`
drops the slide from navigation, the count, and the PDF, and the macros still
resolve everywhere after it. Macros expand at parse time, before any renderer
sees the math, so the same block works under MathJax and under the offline
KaTeX variant; wrapping the definitions in `$$ ... $$` fails.

Number a result you will refer back to, which a lecture does more than a talk
does: `$$ ... $$ {#eq-bayes}`, then `@eq-bayes` in prose. Quarto's `@eq-` form
is the portable one; raw `\label` plus `\eqref` also works under MathJax and
breaks under the offline variant.

Math inside a raw HTML block works, because pandoc's `markdown_in_html_blocks`
is on by default, so `$a^\star = \argmin_a \E[L(a,y)\mid s]$` typesets
correctly inside a raw `<ol class="steps">` item.

To build an equation term by term, hide the terms that are not there yet with
`\class{hid bK}{...}` (never `\phantom`): see "Click mechanics" below.

## The teaching vocabulary

| Class | One line |
|---|---|
| `.keyidea` | The one thing to remember. At most three per deck. |
| `.definition` | New vocabulary. |
| `.example` | The concrete case. |
| `.warning` | The common error. |
| `.question` | A check the student answers; the answer goes on the next slide as a `.fragment`. |
| `.prompt` | Large centered discussion question, sized to fill a slide while students talk. |
| `.hero` | One number that should land hard. |
| `.full-bleed` | On a heading whose slide is one image, edge to edge, height-capped under the heading. |
| `.demo-tag` | Live-coding marker: `## Live demo [demo]{.demo-tag}`. |
| `.aside-note` | Muted caveat under a hairline; arrives on the previous block's beat. |
| `.num` | Right-align a numeric table column (mono numerals). |
| `{.backup}` | On a heading: the slide hangs under the slide above it, one press of the down arrow away. |
| `ul.agenda` | Roadmap list: `.done` muted with a filled ring, `.now` in teal and bold, the rest plain. |
| `ol.steps` | Worked-example steps, four or five to a list, numbered in teal mono rings. |
| `#thm-` family | Numbered theorem environments: `references/theorems.md`. |
| `.yblue` `.ygreen` `.teal` / `.yamber` `.yred` `.amber` / `.ygray` `.dim` | Colour spans: teal, amber, muted. The theme folds the older names onto its two accents. |
| `.hid` `.build` `.swap` `.gray-out` `.shrink-NN` | The click mechanics below. |
| `.fig-card` | The light card for a figure that exists only on white. |
| `.next-week` | On the closing slide: the line about next week, under a teal rule. |

`ul.agenda` and `ol.steps` work both as raw HTML lists and as fenced divs
(`::: {.agenda}` / `::: {.steps}` around the list); the theme styles both
forms. The five teaching boxes each take a `[Label]{.label}` span, and the
label text is yours:

```markdown
::: {.keyidea}
[Key idea]{.label}
A predictor is only useful once you say what decision it feeds.
:::
```

The five boxes share one shape on Dark lab (the surface ground, a 4px left
edge, a mono label) and differ by colour: `.keyidea` and `.definition` take the
teal edge, `.keyidea` also a faint teal ground; `.example` the text-ink edge;
`.warning` the amber edge; `.question` a full amber frame.

The template exercises all five boxes, the agenda, the steps, `.hero`,
and `.prompt`. Keep the class-to-meaning mapping fixed for the whole semester
(`references/pedagogy.md` says why). Two blocks per slide is the limit, and it
is physical as well as pedagogical: at a lecture-hall root, three blocks of two
lines each fill nearly the whole canvas.

## Click mechanics

Dark lab defines five build tools in `darklab.scss` (the CLICK MECHANICS block)
and `lab.html`. They work under the filter's staging, so the title still
appears alone first.

1. Step equation. Write the whole equation once and hide each later term with
   `\class{hid bK}{...}`. Term K enters on the K-th element carrying `.build`
   on the slide, and it is drawn in teal on the press that brings it. A hidden
   term keeps its box, so the equation never shifts. `\phantom` is wrong here:
   it can never be shown, and it changes spacing.

   ```markdown
   ::: {.eq}
   $$\Sh = \frac{1}{n}\sum_i x_i \class{hid b1}{{}, \qquad \se(\Sh) = \sqrt{S(1-S)/n}}$$
   :::

   :::: {.fragment .build}
   ::: {.aside-note}
   The note that explains the new term arrives with it.
   :::
   ::::
   ```

   The marker can be empty (`[]{.fragment .build}`) when the term arrives on
   its own; a marker that carries a block is better, because a press that
   only changes colour inside math is close to a dead step. The handout prints
   every term.

2. Swap in place. `.swap` stacks its children in one grid cell: `.swap-out`
   shows until the `.fragment` beside it arrives, then hides. Use it for a
   sentence that the next exhibit layer contradicts.

3. Gray-out. `[text]{.fragment .gray-out fragment-index=3}` recedes to the
   muted ink on cue. It starts visible, so it goes on a span or a nested div
   (a top-level one leaks at step 0), and it shares its index with whatever
   arrives on that press, because a colour change alone is a `DEAD STEP` to
   `stage-check.mjs`.

4. Shrink. `{.shrink-90}` (or 95, 85, 80, 75) on a heading sets everything
   under it at that share of the root, for the one table or code block that
   has to stay whole. Splitting the slide is the first fix; this is the second.

5. Vertical backups. `## Title {.backup}` hangs the slide under the slide
   above it. The bottom-right hint reads "↓ backup" on the parent and "↑ back"
   on the backup. The right arrow and the clicker skip backups: `lab.html`
   maps Space, PageDown and N to the right arrow's behaviour, which steps
   fragments and then moves to the next main slide. There are no jump buttons
   and no Back buttons.

## Dividers, backups, references

The section divider is a two-digit teal mono numeral over a short teal rule
over the title, set on the left rail at mid-height:

```markdown
## How much a leaderboard can move {.section-break}
```

The number comes from `stage-slide.lua`, so nothing is hand-numbered and the
dividers renumber on the next render. The same number and title then label
every slide of the section in the breadcrumb. A divider carries its title and
nothing else, no background attribute. Why a CSS counter is wrong here is in
the README under "Things that will silently break the deck"; divider title
diction is in `style/house.md`.

Extra material goes in vertical backups, not an appendix. A derivation, a
robustness table, or a proof sits directly under the slide that raises it,
written as the next slide with `{.backup}` on its heading:

```markdown
## A score is an estimate {#estimator}

...

## Where the interval comes from {.backup #ap-se}
```

A slide can carry several backups; each `{.backup}` slide joins the stack of
the nearest non-backup slide above it. The backup heading drops to the crumb
ink, the breadcrumb adds "backup", and nothing is added above the title (no
kicker label). Point at it in prose on the parent slide ("the derivation is
the backup under this slide"); the hint at the bottom right does the rest.

A lecture cites less than a seminar talk, and when it does the citation is a
pointer for the student taking notes rather than part of the argument. Cite
with `[@key]` or `@key`; the parentheses come from the citation style, never
from CSS. The reference list goes at the very end, after the closing slide,
and paginates itself:

```markdown
## References {.references-break background-color="var(--references-ground)"}

## References {.references}

::: {#refs}
:::
```

The format's `citeproc: false` is what lets `stage-slide.lua` run citeproc
itself and cut the list across slides, and the format's `refs-lines: 18` and
`refs-chars-per-line: 124` are the budget measured for Dark lab, packed
greedily, which is how the sample lecture packs 6 entries and then 3. The
model is conservative on this theme: page one of the sample has room for about
three more lines than the packer gives it.
`STAGE_REFS_DEBUG=1 quarto render deck.qmd` prints what the packer decided and
`refs-lines` overrides it. Never put `.scrollable` on a references slide. The
cite-form table, the hover and tooltip machinery, and the packing model are in
the README under "Citations and the reference list".

## Staging, in one paragraph

The invariant is that the title appears alone: every content slide opens as its
heading and reveals its blocks one beat at a time, a figure as much as a list.
`incremental: true` is the default to start from; opt lists out with
`::: {.nonincremental}`, group blocks into one beat with `::: {.together}`, put
an addendum on the previous beat with `::: {.with-previous}`, and opt a slide
out with `{.no-stage}`. Budget five to eight staged moments in a 75-minute deck
beyond the incremental lists. Fragment variants, `.r-stack` layers,
`fragment-index`, and `auto-animate` are in `references/staging.md`; the
filter's internals are in the README under "Staging: the title appears alone,
always".

## Pacing and structure

Every lecture opens with the same two slides. One slide of recap that ends on
the question this lecture answers, then the agenda as a `ul.agenda` with
`li.done` on last week and `li.now` on today's first block. Repeat that agenda
slide verbatim at each block boundary, moving `.now` down one, and close the
lecture with every item `.done`. Students use it to locate themselves and it
costs three slides.

A lecture does not end on a thank-you slide. The last two slides of the class
are the synthesis pair: the agenda with every item `.done`, then the
`.closing-slide`, which stages as heading, then one beat
(`references/closing-slide.md`). On Dark lab its heading runs larger and a
`.next-week` line sits under a teal rule at its foot. Only the references
follow it; extra material already sits in backups under the slides it
belongs to.

Segment budget for 75 minutes:

| Minutes | What | Slides |
|---|---|---|
| 0-5 | Recap, agenda, the question | 3 |
| 5-25 | Block 1: motivation, the formal idea, a worked example | 8-10 |
| 25-30 | Discussion prompt or a check for understanding | 1-2 |
| 30-50 | Block 2: the complication and how it is handled | 8-10 |
| 50-55 | Second prompt, or a live demo | 1-2 |
| 55-70 | Block 3: application, or a paper read together | 6-8 |
| 70-75 | Synthesis: the agenda all `.done`, plus what is next | 2 |

A 50-minute class is the same shape with Block 3 dropped and one prompt instead
of two, about 22 content slides. Roughly 1.5 to 2 minutes per content slide,
half the density of a research talk. Sixty slides for 75 minutes is a reading,
not a lecture. Where the prompts go and how to run them:
`references/pedagogy.md`.

## Build and verify

The render exits 0 whether or not the deck is presentable, so the gates are not
optional. Run them every time.

```bash
cd <deck dir>
quarto render lecture.qmd --to darklab-revealjs 2>&1 | tee /tmp/render.log
grep '\[WARNING\]' /tmp/render.log     # unclosed divs and missing images warn here, still exit 0

node $TOOLING/deck-check.mjs fit lecture.html   # must print DECK-FITS: YES
node $TOOLING/stage-check.mjs lecture.html      # must print STEP-0-CLEAN: YES

# only if this deck was built as the offline variant
$TOOLING/check-offline.py lecture.html           # must print OFFLINE-SAFE: YES
```

`deck-check.mjs fit` drives headless Chrome, visits every slide, forces its
fragments visible, and measures; it fails on overflow, excess width, missing
images, crushed or shrunk figures, unrendered math, a dangling `.jump` target,
and an unpaginated bibliography, and `--json` adds per-image geometry. A
single-pass DOM scan cannot do this, because reveal sets `display: none` on
every slide that is not current. `stage-check.mjs` puts every slide in its
unadvanced state and asserts nothing but the heading is visible, then walks
each content slide forward and fails a press that changes no visible ink
(`DEAD STEP`, presses counted from 1), at a cost of about two seconds a deck. It
skips slides by class (the dividers, the reference pages, the closing slide
under either archetype name); `{.no-stage}` is not on that list. It is the
filter's opt-out and the gate has never read it, so an unstaged slide still has
to be classified as something other than content. Both gates walk vertical
backups as well as main slides, and both size their window to the deck's
1280x720 canvas. Both are in the README in full. The sample lecture measures
zero dead steps.

`check-offline.py` runs only on a deck built as the offline variant. On a
default MathJax deck it reports the external MathJax reference and fails, which
is correct and is not a defect (README, "The offline variant").

Overflow matters more here than in a research deck. At a lecture-hall root, a
heading plus roughly ten single-line bullets fills the canvas, and the lines
past it are simply gone on the projector while the laptop preview looks fine,
so eight is the working limit. Dark lab reserves the bottom 78px for the
breadcrumb, and content that runs into that strip fails the fit gate. Fixes, in
order: split the slide (almost always right, since a slide that does not fit is
doing two jobs), move the delivery lines into `::: {.notes}` while the substance
stays in the body where the handout keeps it, or add `{.smaller}` to the
heading, kept for a table or a code block because shrinking type defeats a
lecture-sized root. `panel-tabset` is not a fix (only its first tab prints) and
`.scrollable` slides always fail the gate; split instead. A slide that is
complete but over the limit can also move its second half into a `{.backup}`
under it.

To look at slides rather than measure them, use decktape and `pdfread.py` per
the README ("Looking at a rendered deck"). The Read tool cannot open a PDF on
this machine.

## Course site and handout

The `course-site` skill owns the site in full; read it before touching
`_quarto.yml`, `index.qmd`, or anything else outside `lectures/`. A semester of
lectures lives in one Quarto website project per course
(the example lecture in this repo's `examples/` directory comes from one), each deck a
`lectures/wNN-slug.qmd` holding content only, with the shared config once in
`lectures/_metadata.yml` as shown above. While drafting, render one lecture:
`quarto render lectures/w03-slug.qmd`.

The site's week table links a `pdf` next to every deck, and the handout has to
be built by the render itself: a render prunes everything in `docs/` that it did
not produce, which deletes any PDF put there by hand. Build it in a
`post-render` hook, which runs after the prune; the script walks the decks
Quarto just rendered (`QUARTO_PROJECT_OUTPUT_FILES`, so rendering one lecture
rebuilds only that handout) and calls the exporter on each:

```bash
node $TOOLING/deck-check.mjs handout \
  docs/lectures/w03-slug.html docs/lectures/w03-slug.pdf
```

A workable `scripts/build-handouts.sh` skips with a warning when node or the exporter is missing, exits nonzero when
an export actually fails, and needs no change when a lecture is added. With
`pdf-separate-fragments` at its false default the print view collapses each
slide's build steps onto one fully revealed page (27 slides came out 27 pages),
which is the student handout;
set it true for a page per build step, a lecturer's cue printout that runs long
under `incremental: true`. decktape is the fallback exporter, speaker notes
appear in neither PDF, and `panel-tabset` prints only its first tab (README,
"PDF handouts").

## The template

`assets/darklab-template.qmd` is the starting deck: recap and agenda, the five
boxes, an equation built term by term, a worked example with its derivation in
a vertical backup, an `auto-animate` pair, a `.prompt`, a gray-out and a swap,
the synthesis pair, and the closing slide. It renders standalone, and passes
both gates, with `_extensions/darklab/` installed beside it; it needs no
`_metadata.yml`. Math and type at display time additionally need the
`mathjax/` and `fonts/` copies from `_extensions/darklab/vendor/` beside the
rendered HTML.

## Traps, all verified on this machine

| Symptom | Cause | Fix |
|---|---|---|
| Content clipped on the projector, clean on the laptop | reveal scales a fixed 1280x720 canvas and render exits 0 | `deck-check.mjs fit`, then split the slide |
| Figure axis labels unreadable, gate says the slide is ok | `auto-stretch` shrank the figure instead of overflowing | read `--json` per-image `w`, move the text into a column |
| A blank slide in the count and the handout | macro block before the first `##` | `## Notation {visibility="hidden"}` |
| `\argmin` errors as an unexpected control sequence | macros wrapped in `$$ ... $$` | bare raw LaTeX under the hidden slide |
| Section divider carries a stray coloured panel | a `background-color` attribute copied from another deck or theme | drop the attribute; `{.section-break}` alone is the contract |
| Divider numeral is missing | `stage-slide.lua` not running: a deck off the extension with no `filters:` line | use the extension format, or add the filter by absolute path |
| A figure or a note appears with the heading instead of waiting | the filter is not running, or the heading carries `{.no-stage}` | `stage-check.mjs` names the slide |
| Math unrendered even with wifi | the format's self-hosted `mathjax/MathJax.js` url resolves to nothing next to the rendered HTML | copy `$TOOLING/_extensions/darklab/vendor/mathjax/` beside the deck, or override the url as the course project does |
| `\class{hid ...}` term never appears, or MathJax prints `\class` | a `mathjax/` copy without `extensions/TeX/HTML.js`, or no `.build` element on the slide | copy the darklab `mathjax/`, which carries HTML.js; add the `.build` marker |
| Type looks wider than the fit gate measured | no `fonts/` copy next to the deck, so both faces fell back to the system stacks | copy `$TOOLING/_extensions/darklab/vendor/fonts/` beside the deck, or override the three @font-face urls |
| Breadcrumb missing on every slide | no `.section-break` dividers, or the filter is missing so the dividers carry no number | add the dividers; keep the filter |
| A backup slide shows up in the lecture's path | its heading lacks `{.backup}`, or the clicker sends a key `lab.html` does not remap | add the class; check the clicker's key in the browser |
| The class walks into a backup on Space | `lab.html` did not load (a deck off the extension) | use the format, or add `include-after-body: lab.html` |
| Dividers numbered 1, 2, 2, 2 | a CSS counter, which `display: none` slides do not increment | the attribute plus `content: attr(...)`, which the theme already does |
| A paragraph on a divider slide lands under the title | the divider centres a full-height flex `h2` | put the sentence on the next slide |
| `pdf` link on the course site 404s after a render | a render prunes `docs/` of anything it did not build | build the handout in a `post-render` hook |
| Some text or a figure line is invisible on the wall | ink from another palette, measuring near 1:1 against the deck ground | check the hex against the theme's contrast table and swap in one of its inks |
| Code block renders with no highlighting at all | misspelled `highlight-style` (`solarized-dark` and `printing-dark` do not exist) | the format's `a11y-dark` |
| Figure panel is a white rectangle on the dark wall | ggplot default theme, or a figure lifted from a paper | the ground-matched `deck_theme()` in `references/figures-dark.md`; `.fig-card` when there is no source to redraw |
| Title slide is top-aligned instead of centred | a `top: 0 !important` rule was added to the theme | remove it; it also disables `{.center}` |
| Figure inside a column or an `.r-stack` renders tiny or overflows | `auto-stretch` only ever sizes a direct child of the section, and `.r-stretch` by hand only removes the size cap | set `fig-width`/`fig-height`, or `width=` on a file image |
| Handout is missing most of a slide's content | `panel-tabset` prints its first tab only | separate slides |
| Math gone in a room with no network | MathJax loads at display time (self-hosted or CDN) | build the offline variant, or ship the `mathjax/` copy with the deck |
| Offline variant loses its math anyway | the `{method:, url:}` object form left a runtime loader | bare `html-math-method: katex` plus `self-contained-math: true` |
| `\eqref` prints as literal text | the deck was built as the offline KaTeX variant | Quarto `@eq-` cross-references |
| Render fails, `RevealChalkboard is not compatible` | `chalkboard` with `embed-resources` | leave chalkboard off |
| Video slide shows "No compatible source was found" | `{{< video >}}` writes a `<source>` with no `type` | raw `<video src="...">` |
| plotly figure 403s in class | plotly.py 6.x emits a module import of cdn.plot.ly | add `plotly-connected: false` to the front matter |
| Choropleth blank with no network | plotly fetches topojson at display time | use a static image of the map |
| Regression table columns read `1.` and `2.` | pandoc parses `(1)` as an ordered-list marker | rename the columns |
| Blank image on a slide, render exited 0 | missing file, only a buried `[WARNING] Could not fetch resource` | the gate reports `MISSING IMG` |
| A YAML key silently does nothing | Quarto ignores unknown reveal keys | `quarto inspect deck.qmd` |
| Every asset 404s on GitHub Pages | Jekyll dropped the `_files` directories | `touch docs/.nojekyll` and commit it |
| Handout collapses every build step onto one page | `pdf-separate-fragments` defaults to false and decktape ignores it | that collapsed export is the student handout; for a page per build step set `pdf-separate-fragments: true` and use `deck-check.mjs handout` |
| A second, unpaginated bibliography on the last slide | `bibliography:` on a deck without `citeproc: false` (the extension format carries it) | use the extension, or add the line; the fit gate fails the deck for it |
| Reference list runs off the bottom | the budget in the format does not match a restyled theme | `STAGE_REFS_DEBUG=1 quarto render` prints the packer's decision; `refs-lines` overrides it |
| A slide number appears at the bottom right | `stage-slide.lua` turns reveal's slide number back on at load | nothing to fix while `darklab.scss` hides `.slide-number`; keep that rule |
| Citation renders as a literal `@key` | `citeproc: false` with the filter absent from `filters:` | put the filter back |

## Where the detail lives

| File | What it holds |
|---|---|
| `references/pedagogy.md` | The density doctrine, prompts and checks for understanding (Mazur), speaker notes, the semantic vocabulary rule, the pattern audit table. |
| `references/theorems.md` | The numbered theorem family, `#thm-` crossrefs, the `#def-`/`#exm-` guard, the proof in a vertical backup, the harmless citeproc warning. |
| `references/figures-dark.md` | Figure geometry on the 1280x720 canvas, the ground-matched `deck_theme()` in the Dark lab palette, the light card, captioned figures, the silent-shrink trap, plotly, video, `.full-bleed`. |
| `references/closing-slide.md` | The closing slide: markup, heading-then-one-beat with `.together`, the rationale, how the gate classifies it. |
| `references/staging.md` | Fragment variants, `.r-stack`, `fragment-index`, `auto-animate`, the animation budget, the breadcrumb and backup navigation, layout numbers. |
| `style/house.md` | Your values, separated from the mechanisms: palette rationale, density calibration, the author line, dates, button diction, closing wording. A stub in the public repo; fill it in. |
| `assets/darklab-template.qmd` | The starting deck, rendering clean under `darklab-revealjs`. |
| `$TOOLING/_extensions/darklab/` | The format: `_extension.yml` (every key commented), `darklab.scss` (palette table, click mechanics), `lab.html`, `title-slide.html`, and `vendor/` (fonts, MathJax) to copy beside each deck. |
| `$TOOLING/README.md` | The machinery: the filter's six jobs, staging internals, both gates, citations and refs packing, the silent breakers, handouts. |
