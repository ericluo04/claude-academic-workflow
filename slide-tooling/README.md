# Slide tooling

Shared tooling for Quarto reveal.js decks: a Pandoc filter, two render-time
quality gates, an offline checker, a starter theme, and the vendored assets
that keep a deck self-hosted. Used by the `research-talk`, `teaching-lecture`,
`slide-review`, and `course-site` skills, which expect this directory
installed at `~/.claude/assets/quarto-yale/` (see SETUP.md at the repo root).

This file is the machinery reference: what each file does, what the filter
rewrites, what the gates assert, and the settings that break a deck without
saying so. How sparse a slide should be, what a title should say, how to pace
a lecture, and which block class means what all live in the skills.

The rendered decks under `docs/` are the example sources rendered with
`starter-theme.scss`, a light editorial theme (warm paper ground, Literata
display headings over IBM Plex Sans text, plum accent) that implements every
hook the filter and the gates expect, with comments marking where taste goes.
Where a concrete number helps, this file cites measurements taken on a
two-theme setup built on the same hooks (a talk theme and a lecture theme).
Everything below about divider classes, the progress bar, jump buttons,
citations, and the reference list holds for the starter theme too.

## Files

| File | What it is |
|---|---|
| `starter-theme.scss` | A plain light theme implementing every hook. Restyle it into your own. |
| `_extensions/starter/` | A Quarto extension format (`starter-revealjs`) wiring the theme, the filter, and the verified defaults together. `quarto add` this directory. |
| `stage-slide.lua` | Pandoc filter, six jobs. Read its header comment before changing any of them. |
| `deck-check.mjs` | The fit gate, and the handout exporter. |
| `stage-check.mjs` | The staging gate: asserts nothing but the heading is visible before a slide is advanced. |
| `check-offline.py` | Verifies a rendered deck fetches nothing at display time. For the offline variant only. |
| `mathjax/` | Vendored MathJax 2.7.9 (Apache 2.0), copied next to each deck so math is self-hosted. |
| `fonts/` | The theme's two faces as woff2 (both OFL 1.1), copied next to each deck the way `mathjax/` is: `literata/` for display, `ibm-plex-sans/` for text. Each family is one variable roman covering 400-700 plus one static italic, 434 KB in total. |

If you run a two-theme setup (say, a talk theme and a lecture theme on the
same hooks), duplicate the
palette and the shared rules across both files on purpose: Quarto compiles
theme SCSS from a temp directory, so a relative `@import` cannot resolve.

## The recipe

The short form is the extension: `quarto add <this directory> --no-prompt`
installs `_extensions/starter/`, `cp -R <this directory>/{mathjax,fonts} .`
gives the deck its math and its type, and the front matter is just
`format: starter-revealjs` plus
the title block. The manual recipe, for a deck that wires things itself:

```yaml
bibliography: talk-refs.bib   # only on a deck that cites
citeproc: false               # stage-slide.lua runs citeproc itself
refs-fit: starter             # the preset measured for starter-theme.scss
format:
  revealjs:
    theme: [default, starter-theme.scss]
    html-math-method: mathjax
    highlight-style: a11y              # a11y-dark on a dark theme
    slide-number: c/t
    incremental: true
filters:
  - ~/.claude/assets/quarto-yale/stage-slide.lua
```

```bash
quarto render deck.qmd --to revealjs
node ~/.claude/assets/quarto-yale/deck-check.mjs fit deck.html  # must print DECK-FITS: YES
node ~/.claude/assets/quarto-yale/stage-check.mjs deck.html     # must print STEP-0-CLEAN: YES
```

Give the filter an absolute path in `filters:`. The `.scss` is different:
copy it next to the `.qmd`, or give an absolute path there too. The extension
route sidesteps both, which is why the skills use it.

MathJax is the default engine because it does what KaTeX cannot: `\eqref` and
`\label`, `\DeclareMathOperator`, `mathtools`, and `physics`. It loads from a CDN
at display time, so the default recipe assumes a network, which covers a lecture
hall and almost every talk.

The two gates are mandatory. Overflow is silent no matter where the math comes
from, and so is a block that arrives with the heading instead of waiting.

### The offline variant

For a room with no wifi, swap the math engine and embed everything:

```yaml
    embed-resources: true
    html-math-method: katex     # bare string; the object form leaves a loader
    self-contained-math: true
```

Then `check-offline.py deck.html` must end on `OFFLINE-SAFE       : YES`. The
field is padded, so a grep for `OFFLINE-SAFE: YES` never matches; grep the label
and read the verdict. Run that check only on a deck built this way. Under the
default MathJax recipe an external reference is expected, so the offline check
reports every deck as broken. KaTeX also gives up `\eqref`, `\label`, and
`\DeclareMathOperator`, so equation cross-references have to go through Quarto's
`@eq-` mechanism instead.

### Math macros

Define them at pandoc level, at top level of the document outside any math
block:

```markdown
\newcommand{\E}{\mathbb{E}}
\newcommand{\bx}{\mathbf{x}}
\DeclareMathOperator*{\argmin}{arg\,min}
```

These are expanded at parse time, before any renderer sees the math, so they
work under KaTeX even though KaTeX itself cannot do `\DeclareMathOperator`. Do
not put them in a MathJax config header or a ` ```{=tex} ` block.

## What stage-slide.lua does

Six jobs. A deck wants all of them, so keep the filter in the list even where it
wants no staging and use `{.no-stage}` per slide instead.

1. Stages every top-level block on a content slide, so the slide opens as its
   heading alone.
2. Numbers the `.section-break` dividers, writing `data-section-number` and
   `data-section-total` on each heading.
3. Meters and segments the progress bar, taking the appendix and the references
   out of the denominator.
4. Rewrites `.jump` and `.jump-back` spans into anchors and emits the handler
   that drives them.
5. Runs citeproc and cuts the reference list across as many slides as it needs.
6. Retargets Quarto's citation tooltip from the year anchor to the whole
   citation span. This one is unconditional and needs nothing in the deck.

Front-matter keys it reads: `bibliography` or `references` (only to decide
whether to run citeproc), `refs-fit`, `refs-lines`, `refs-chars-per-line`. It
also reads `PANDOC_WRITER_OPTIONS.incremental` and the `STAGE_REFS_DEBUG`
environment variable. `citeproc: false` never reaches the filter, because Quarto
consumes it as a command-line flag and strips it from the metadata, so a missing
one cannot be detected in Lua.

It emits two stderr warnings an author can hit: a `.jump` span with no `target=`
is left as plain text and named, and a deck that cites with no `#refs` div is
told its citation links will not resolve.

## Staging: the title appears alone, always

With `stage-slide.lua` in the filter list, every content slide opens as its
heading and nothing else, then reveals its blocks one beat at a time. That holds
for a figure as much as for a paragraph.

A slide is staged unless its heading is level 1, carries `{.no-stage}`, or
carries `.references`. The dividers need no exemption of their own: a
`.section-break`, `.appendix-break`, or `.references-break` slide carries only
its title, so there is nothing on it to stage. Appendix content slides are
staged like any other.

Inside a staged slide, some blocks pass through instead of taking a beat:
speaker notes, the footer, `.aside`, `{visibility="hidden"}` material, anything
already carrying `.fragment`, and anything that renders nothing at all. Empty
trailing divs are in that last category, which is why Quarto's own end-of-document
blocks do not each cost a keypress.

`incremental: true` alone gets nowhere near this. It stages list items and
nothing else, so a slide mixing prose and a list opens half-built, and a knitr
figure with a source note under it opens fully drawn. The filter reads the
writer option: with `incremental: false` nobody stages a list, so the filter
wraps it as one beat.

Three author-facing classes control the beats. `.together` on a div makes its
contents one beat and turns off item-by-item staging for any list inside it.
`.with-previous` puts a block on the beat of the block above it. `{.no-stage}`
on a heading turns staging off for that slide. The filter judges every other
container by what is inside it and not by its class name, which is why a
`.steps` list needs no special case.

### Addenda

A block that annotates the block above it should not cost a keypress. Five
classes arrive on the previous block's beat: `.aside-note`, `.citation`,
`.cite`, `.caption`, and `.with-previous`, which is the opt-in for anything
else. A source line under a list joins the last bullet; one under a figure joins
the figure.

One case cannot have it both ways. An addendum under a lone image on a slide the
filter could not number costs its own keypress, because the image's fragment is
the image itself and a block cannot be appended to an inline.

### Fragment indices

reveal sorts every fragment carrying `data-fragment-index` ahead of every
fragment that has none, and pandoc writes `<li class="fragment">` with no index.
So numbering the blocks on a slide that also has a staged list would push its
bullets to the end of the slide: a slide of paragraph, list, paragraph reveals
as 0, 2, 3, 1. The filter therefore adds explicit indices only when it can
account for every fragment on the slide, meaning no staged list, no `.fragment`
of your own, and none of `.r-stack`, `.r-hstack`, `.r-vstack`,
`.quarto-layout-panel`, or a cell with `output-location: fragment`. Otherwise it
leaves the indices off and lets DOM order decide. Your own `fragment-index` is
never touched.

Hand-numbering a slide is all or nothing. Indexed fragments sort ahead of
unindexed ones, so one indexed block on an otherwise unnumbered slide jumps to
the front, and if the filter's own wrapper is the unindexed one the first press
reveals a hidden child and paints nothing. Index every fragment on the slide or
none of them. Where that is worth doing is a build that DOM order cannot
express: equal indices fire together, so a container and its first child can
open on one press, and two blocks in different columns can arrive on the same
beat. Both example decks use it for exactly that.

### Fragment variants

reveal's variants (`fade-up`/`down`/`left`/`right`, `fade-in-then-out`,
`fade-in-then-semi-out`, `grow`, `shrink`, `strike`, the `highlight-*` family)
are available, and the two gates reject some of them for reasons worth knowing
before you reach for one. Measured on a probe deck against this theme.

A variant that starts visible leaks. `grow`, `shrink`, `strike`, `semi-fade-out`
and every `highlight-*` are `opacity: 1; visibility: inherit` until they are
advanced, which is the point of them, so a top-level block carrying one is on
screen at step 0 and `stage-check.mjs` reports `LEAKS AT STEP 0`. Put them on a
span or a nested div instead, where the enclosing beat hides them until it
opens. `fade-in-then-out` and `fade-in-then-semi-out` start hidden and are safe
as top-level blocks.

A variant that changes only colour is a dead step. The gate's signature is the
visible elements with their text and their boxes, so reveal's own
`highlight-red` / `highlight-green` / `highlight-blue` and `strike` (a text
decoration) advance the deck without changing what the room sees. The theme's
`.highlight-accent` passes because it also takes the weight to 600, which
widens the box. `grow` on a plain span is a dead step for a different reason:
transforms do not apply to a non-replaced inline element, so nothing moves
until the span carries `style="display: inline-block"`.

`fade-in-then-semi-out` passes both gates and still costs contrast on a light
ground. The dimmed state is the ink at half opacity, which on this theme's
paper is 2.9:1, under the 3:1 large-text floor. The contrast audit will not
catch it, because forcing every fragment visible also makes it
`.current-fragment`, which is the undimmed state.

`auto-animate` reaches the heading and nothing else. The morph runs on the slide
change, and on the arriving slide every block under the heading is an unadvanced
fragment, so the elements being tweened are `visibility: hidden` and none of the
motion is seen. What the pair does buy is real: reveal drops the slide
transition between the two, and identical headings hold still instead of
sliding, so the pair reads as one slide changing state rather than two slides.
When the morph itself is the point, put the two states in one slide under an
`.r-stack` and fade the second layer in over the first.

### Figures and tables

Quarto's `auto-stretch` is a DOM pass in the revealjs writer (`applyStretch`),
not a Lua filter. On a slide holding exactly one image it adds `.r-stretch` to
the image and then hoists the image out to be a direct child of the `<section>`,
because reveal only ever sizes `section > .r-stretch`. It refuses to touch an
image with an ancestor carrying `.fragment`, `.column`, or `.quarto-layout-panel`.

So a figure cell cannot be wrapped. The filter stages a computed cell whose only
visible content is one image by putting `.fragment` on the image itself, and the
hoisted `<img class="fragment r-stretch">` comes out both staged and stretched
at the size it had before (measured on the sample talk: 864x454 before, 864x454
after). Anything else in the cell means the hoist would leave content behind, so
the whole cell is wrapped and the stretch is lost.

A caption is the case worth knowing. Quarto builds a captioned cell figure as a
custom AST node (`__quarto_custom_type = "FloatRefTarget"`), which the filter
drops when it checks whether anything else is in the cell, so the stretch still
runs and the caption lands as a sibling `<p class="caption">`. That only happens
when the cell is labelled for cross-reference: the chunk needs
`#| label: fig-something` as well as `#| fig-cap:`. A `fig-cap` on a cell whose
label does not start with `fig-` gives a plain pandoc figure, the filter wraps
the cell, and the image renders at its authored width. The fit gate does not
catch that, because a smaller figure still fits.

A bare `![](fig.png)` is left to the wrapper on purpose. reveal sizes each
`section > .r-stretch` as the canvas height minus the parent height measured
with that one element zeroed, so a second stretched element in the same section
is sized against a parent that still counts the first one and comes out starved.
One stretched element per section is the only safe arrangement.

Tables are always one beat. Raw `<table>` HTML is the case that bit: pandoc
parses it into one block per tag with every cell as a separate block, so a naive
wrapper staged a specification table one number at a time. The filter collapses
a run of raw HTML that opens a container into one unit.

### Checking it

```bash
node ~/.claude/assets/quarto-yale/stage-check.mjs deck.html   # must print STEP-0-CLEAN: YES
```

`stage-check.mjs` drives reveal rather than guessing. `Reveal.slide(h, v, -1)`
puts each slide in its unadvanced state, and then every text run and every
graphic outside the heading has to be invisible. Element visibility is the part
to get right: a `.fragment` is `opacity: 0; visibility: hidden`, and
`visibility` inherits while `opacity` does not, so the test is the element's own
computed `visibility` and `display`, its rendered size, then a walk up its
ancestors for `display`, `visibility`, and an opacity under 0.02.

It classifies each slide by class and checks only the ones that come out as
`content`, printing the rest with the reason it skipped them:

| kind | how it decides |
|---|---|
| `title` | `#title-slide` or `.title-slide` |
| `closing` | `.thanks-slide` or `.closing-slide` |
| `section divider` | `.section-break` |
| `appendix divider` | `.appendix-break` |
| `references divider` | `.references-break` |
| `reference list` | `.references` |
| `hidden` | `data-visibility="hidden"` |
| `no heading` | no direct-child `h1`, `h2`, or `h3` |
| `content` | everything else, and the only kind checked |

That is how a divider which has quietly become a content slide shows up. Note
that `{.no-stage}` is not one of the kinds: it opts a slide out of the filter and
not out of the gate, so an unstaged slide still has to be classified as something
else. The two closing archetypes are the case that forced that, which is why both
are named in the `closing` arm: a titleless unstaged slide otherwise fails both
halves of the content test at once.

On a content slide it fails with `LEAKS AT STEP 0` and the visible text, with
`N FRAGMENT ALREADY VISIBLE`, with `HEADING NOT VISIBLE`, or with
`NO FRAGMENTS ON A CONTENT SLIDE`. It also walks the slide forward one fragment
at a time and fails a `DEAD STEP`, a press after which the visible ink on the
slide is byte-for-byte what it was before: an empty wrapper around an
already-staged list is what produces one. The final line is `STEP-0-CLEAN: YES`
followed by the slide counts, and it exits 1 on any flag. `CHROME_BIN` is its
only environment variable.

Run it with the fit gate. Reveal order is as silent a failure as overflow: a
figure that lands with the heading looks right in a screenshot of the finished
slide and wrong in the room.

## The fit gate

```bash
node ~/.claude/assets/quarto-yale/deck-check.mjs fit deck.html [--json]
node ~/.claude/assets/quarto-yale/deck-check.mjs handout deck.html out.pdf
```

`deck-check.mjs` drives headless Chrome over CDP (node 22's built-in WebSocket,
so no npm install, and it does not touch the shared Playwright browser). It
navigates slide by slide, forces every fragment visible, waits on
`MathJax.startup.promise` and `document.fonts.ready`, then measures. It finds
Chrome in the Playwright cache, then `/Applications`, and honours `CHROME_BIN`.
It measures the canvas off `.reveal .slides` and prints it in the header line as
`canvas 1050x700, N slides`.

Six per-slide conditions fail the gate:

| flag | condition |
|---|---|
| `OVERFLOW +Npx` | `scrollHeight` over the canvas by more than 5px |
| `TOO WIDE +Npx` | `scrollWidth` over the canvas by more than 5px |
| `N MISSING IMG` | an `<img>` that loaded with `naturalWidth === 0` |
| `N CRUSHED FIG` | an image rendered under 24px tall |
| `FIG SHRUNK TO Npx` | natural width 1200px or more rendering under 600px, which is auto-stretch shrinking a figure instead of overflowing |
| `N UNRENDERED MATH` | a `.math` element with no `.katex`, no `mjx-container`, and no `math` child |

`NEARLY EMPTY` is a warning and does not fail: under 25 characters, no images,
and not a divider. A macro block outside a hidden slide produces exactly that.

It also fails on a dangling jump target, a `[…]{.jump target="x"}` whose id
resolves to no slide, printing `DANGLING TARGET  #x  "label"`. That belongs in a
mechanical gate rather than a review step: the target is an id an author typed,
heading ids move when a heading is reworded, and reveal fails an unresolved hash
silently by landing on the title slide, so the defect surfaces mid-question in
front of the room. A jump target with no `.jump-back` inside it prints as a
warning and does not fail.

The last failure is an unpaginated bibliography, a `div#refs` that still holds
`.csl-entry` children. It names the fix in the output.

`--json` prints the raw numbers including per-image geometry and suppresses the
whole human report, `DECK-FITS: YES` included. The exit code is the same either
way.

A one-pass probe that does not navigate always reports zero overflow, because
reveal sets `display: none` on every slide that is not current so `scrollHeight`
reads 0. That is why this is a tool rather than a snippet.

## Citations and the reference list

Four lines of front matter, two slides at the end, and the list paginates
itself.

```yaml
bibliography: talk-refs.bib
citeproc: false      # stage-slide.lua runs citeproc itself
refs-fit: starter    # the preset measured for starter-theme.scss
```

```markdown
## References {.references-break background-color="var(--references-ground)"}

## References {.references}

::: {#refs}
:::
```

Put that at the very end, after the appendix. Cite with `[@key]` for the
parenthetical form and `@key` for the narrative one. Blocks written before the
`#refs` div stay on page one and blocks after it go to the last page, which is
where a back button belongs.

### The parentheses come from the CSL, never from CSS

The themes put two properties on a citation, size and colour. The brackets are
Pandoc's default chicago-author-date, which needs no `csl:` and ships no file:

| you write | you get |
|---|---|
| `[@key]` | (Author 2020) |
| `@key` | Author (2020) |
| `[@a; @b]` | (A 2020; B 2021) |
| `[see also @key]` | (see also Author 2020) |
| `[-@key]` | 2020 |

That is the output the source Beamer deck got from `\usepackage[round]{natbib}`
plus `\setcitestyle{aysep={}}`: round parentheses, no comma before the year. A
different `csl:` changes the brackets (`apa` adds the comma, `ieee` gives `[1]`),
so the style is where to change them. Do not fake a paren in CSS: a `::before`
on `span.citation` also wraps a narrative cite, and "Author (2020) shows" comes
out "(Author (2020)) shows".

Sizes and colours, as the starter theme sets them; a citation is a size step
down in a muted ink with a measured ratio, and your theme picks its own values:

| | starter |
|---|---|
| root | 30px |
| `.citation` | 0.88em = 26.4px |
| colour | `$muted-dark` #4f463c, 8.6:1 on the paper ground |
| hover | `$accent` #7d3a5e, 7.5:1 |
| inside `.aside-note`, `figcaption`, `.footer` | 1em (no compounding) |
| `div.csl-entry` | 0.6em = 18px |

0.88em is a step the eye reads as subordinate without turning the cite into a
footnote; pick your own and keep it on both the span and the anchor.

Both rules colour the span and the anchor inside it. Quarto renders a citation as
`(<a role="doc-biblioref">Author 2020</a>)`, so `.reveal a` was winning on the
anchor and a citation came out as a gray parenthesis around blue text. The hover
hangs off `span.citation:hover` for the same reason: Quarto puts only the year in
that anchor on a narrative cite, so an anchor rule lights half the citation.

Quarto binds its reference-preview tippy to that year-only anchor as well, and no
theme rule can move a tooltip. The filter's `cite_hover_script` retargets it
with `a._tippy.setProps({ triggerTarget: span })` on window load, retrying up to
twenty times at 100ms because Quarto's own script builds the instances late. It
is emitted on every deck and does nothing on a deck with no citations.

A multi-cite span (`[@a; @b]` is ONE `span.citation` with one anchor per work)
is handled differently: retargeting its first anchor to the whole span made the
second year fire two popups at once. The script instead wraps each citation's
run in a `span.cite-seg` (split at the `;` separators, parentheses left
outside), stamps `.cite-multi` on the span, retargets each anchor's tippy to
its own segment, and narrows each popup to that anchor's entry (Quarto's own
contentFn renders every key in `data-cites` into one combined popup). Both
themes cancel the whole-span hover on `.cite-multi` and highlight
`span.cite-seg:hover` instead, so hovering anywhere in one citation, on either
line when it wraps, previews and underlines exactly that citation.

### How the list paginates

Quarto puts the whole bibliography in one `div#refs`, which overflows one slide
while `quarto render` exits 0. Its own answer, `handleRefs`, stamps
`smaller scrollable` on that slide, and `.scrollable` is a defeat: a scroll box
on a projector, it breaks `auto-stretch`, and reveal's print view does not
scroll. `refs-location` is an HTML-format option and does nothing in revealjs. So
`stage-slide.lua` cuts the list into slides, each a copy of the references
heading, with continuation ids of the form `references-p2`.

Two things had to be worked around, both documented in the filter.

Citeproc runs from inside the filter. Quarto runs pandoc's citeproc after its
whole Lua chain, including the `post-quarto` entry point, so a user filter always
sees `#refs` with zero children. Listing `citeproc` in `filters:` is a
plain-pandoc feature Quarto does not implement: it tries to exec a binary of that
name and dies with a FATAL error. The filter calls `pandoc.utils.citeproc(doc)`
itself, which is why the deck needs `citeproc: false`.

An empty `#refs` stays behind, on the divider. `handleRefs` points every
`a[role=doc-biblioref]` at the slide holding `#refs`, and with no `#refs`
anywhere it sets them all to `href=""` and `onclick="return false;"`. So the
marker is parked on the `.references-break` divider: the citation links land on
the References title slide, one press before the list, and the two unwanted
classes land on a slide holding one word, where both themes cancel them.

Forgetting `citeproc: false` is caught mechanically. Pandoc's second run fills
the empty marker instead of appending a new div, and `deck-check.mjs fit` fails a
deck whose `#refs` has entries in it.

### How many entries fit

Each preset was measured against its own theme, in headless Chrome at
1050x700 with `offsetHeight`, not
`getBoundingClientRect`: reveal scales the canvas with a CSS transform, so every
rect comes back multiplied by about 0.9 and a two-line talk entry measures
43.9px instead of its layout 48.7px.

| | talk | lecture | starter |
|---|---|---|---|
| entry line-height | 24.3px | 27.54px | 24.3px |
| list starts at | y = 75 | y = 76 | y = 70 |
| room left | 625px = 25.72 lines | 624px = 22.66 lines | 630px = 25.93 lines |
| `lines` preset | 25.7 | 22.6 | 25.9 |
| chars per line, bracketed | 124.6 to 127.7 | 112.6 to 119.2 | 133.7 to 140.3 |
| `cpl` preset | 125 | 113 | 134 |
| `hang` preset | 0.026 | 0.029 | 0.026 |
| entries per slide, in practice | 6 to 7 | 5 to 6 | 9 to 10 |

The budgets are the measured room and nothing else. An earlier pair took about
45px off each as clearance over the slide number and the progress bar, and that
clearance bought nothing: both sit outside the 700px canvas, in the margin
reveal leaves around the scaled slide (in canvas coordinates the slide number's
box starts at y = 698.9 and the progress bar spans y = 734.4 to 738.9), so
nothing the list does inside the canvas reaches either.

The packer works in rendered lines, not entries, because entries run from one
line to four. An entry costs `1 + ceil((chars - cpl) / (cpl * (1 - hang)))`
lines: the first line gets the full measure and every continuation line is
narrowed by the hanging indent, with `chars` counted in codepoints
(`utf8.len`), not bytes, since citeproc's curly quotes and en dashes run three
bytes each. Entries on the same page are separated by 0.46 of a line
(`margin-bottom` 0.62em over `line-height` 1.35em), and a page of n entries
pays n-1 gaps, because the margin under the last entry falls outside the block's
height.

Packing is greedy: fill page one, start the next, repeat, and the last page
carries the remainder however short that leaves it. There is no balancing pass
any more. An even split costs a page whenever the remainder would have fitted,
and a reference list is read off the wall one page at a time, so nobody compares
the pages.

`cpl` is bracketed rather than averaged, because what matters is where an entry
gains a line: on the talk the longest two-line entry ran 246 characters and the
shortest three-line one 252, and on the lecture the same pair was 222 and 235.
Every preset sits at the low end of its bracket, so the model rounds a line up
before it rounds one down. The lecture root is 13% larger while its line
holds only 10% fewer characters, because Source Sans Pro is a narrower face than
the one the talk led with when the presets were measured. The `starter` bracket
was taken on the two example decks in `docs/`, which share the one theme: the
longest two-line entry and the shortest three-line one both run 246 characters,
because two entries of the same length can break differently, so the preset
takes 124 and rounds the ambiguous one up. Starter holds fewer characters than
the talk preset at the same 18px because its body face is the vendored IBM Plex
Sans, which is wider than the system stack the talk resolves to. At 124 the
model is exact on the talk and over-predicts the lecture by one line.

`refs-fit: starter | talk | lecture` picks the preset, because the theme cannot
be read from a filter: Quarto compiles the SCSS into a temp bundle and rewrites
the metadata to its hash before any user filter runs (measured:
`theme = quarto-760b0d5cd483963edc939aa138f6e90a` on a deck whose front matter
names a real `.scss`). In this repo the starter extension's `_extension.yml`
carries `refs-fit: starter`, so a deck on `format: starter-revealjs` names
nothing and that yml line is the knob. An unrecognised value falls back to
`lecture` silently. Forgetting the line costs an under-filled slide and never an
overflow, because the default is the tightest preset. `refs-lines` and
`refs-chars-per-line` override the preset outright for a restyled theme, which
computes its own `hang` as `1.5 * 0.6 * root / 1050`.
`STAGE_REFS_DEBUG=1 quarto render deck.qmd` prints what the packer decided: the
entry count, the budget, `cpl` and `hang`, the entries per page, how many lines
each page filled against the budget, and each entry's character count with its
modelled lines.

Both themes also take back a double hanging indent. Pandoc's HTML writer puts
`.hanging-indent div.csl-entry { margin-left: 2em; text-indent: -2em }` in the
document head and Quarto's revealjs template adds
`div.hanging-indent { margin-left: 1em; text-indent: -1em }` on the body on top
of it; measured, the entry box started 66px right of the text rail with the
indent applied twice. The themes replace both with `padding-left: 1.5em;
text-indent: -1.5em` at three classes of specificity, so no `!important` is
involved. Both also set `div.csl-entry a { color: inherit }` so a DOI is not
blue, and the lecture theme adds the same for `div.csl-entry em` so citeproc's
italicized journal names are not pale blue.

### The references slides

`.references-break` is the appendix divider again: same unnumbered ring, same
gray or slate, same ground. The two grounds are deliberately equal
(`$references-ground: $appendix-ground`) because both slides mean the same thing
to the room, and each is published under its own name so a deck asks for the
ground of the thing it is opening. Like the appendix divider it is live-view
only: `?print-pdf` builds zero `.slide-background` elements, so in a handout the
divider reads on its ring and its lone title.

There is no REFERENCES pill on the reference pages, and both themes say why in a
comment: the heading is already the word References, so a label above it repeats
the heading. The standing pill belongs to `.appendix` alone.

The filter writes `data-refs-page` and `data-refs-pages` on each references
heading, drawn by neither theme, exactly like `data-section-total`.

Nothing on a references slide is staged. `stage-check.mjs` reports them as
`reference list` and skips them.

## Jump buttons

Beamer's `\hyperlink` plus `\beamerbutton`, in two words of markdown. Give the
appendix slide an id, then name it from the main slide:

```markdown
## Robustness to the sample window {.appendix #ap-window}
```

```markdown
::: {.aside-note}
Standard errors clustered by market throughout.
:::

::: {.with-previous}
[Sample Windows]{.jump target="ap-window"}
:::
```

On the appendix slide, a button back:

```markdown
::: {.aside-note}
Nothing here moves the estimate by half a standard error.
:::

::: {.with-previous}
[]{.jump-back}
:::
```

A button goes on its own line, after a bordered or indented block and never
inside one. Every block that draws a rule, a ground, or an indent has the same
problem: an `.aside-note` draws a rule down its left edge, so a button written
inside the note has that rule running down alongside it and reads as the note's
last line. On the talk theme that means `.result`, `.takeaway`, `.assumption`,
the `.theorem` family, and `.proof`; on the lecture theme the five teaching
boxes, the numbered `.theorem` family, `.proof`, `.prompt`, and a `.steps` list.
Close the block, then write the button as a sibling under it.

Wrapping it in `::: {.with-previous}` is what keeps the button on the preceding
block's beat instead of costing a keypress. `.with-previous` is one of the
filter's five addendum classes, so the button takes the fragment index of the
block above it.

Buttons are right-aligned by the theme, not by the filter. Both themes carry
`.reveal .slides section p:has(> a.jump-btn) { text-align: right; line-height: 1;
margin: -0.25em 0 0 }`, which also takes the body leading off the line and
collapses the gap above it. Two buttons in one paragraph group at the right on
one line, the way `\hfill\hyperlink{a}{}\hyperlink{b}{}` does. Leave a button at
the end of a sentence and the whole sentence goes right with it.

A forward label names the destination in one to three words ("Sample Windows",
"Paired Standard Error"). No terminal period. A return button is `[]{.jump-back}`
with an empty span, and the filter renders the word `Back`; content in the span
still wins.

Both spans become an `<a class="jump-btn">`, styled by each theme to match its
ground and switching to the appendix scheme's gray or slate on an `.appendix` or
`.references` slide. The chevrons are CSS `::after` and `::before`. The forward
button carries `href="#ap-window"`, which is reveal's own named-slide target, so
it still navigates if the script never runs, and `target=` is rewritten to
`data-jump` because `target` is a real attribute on `<a>` and would otherwise
open the slide in a new browsing context. `to=` is accepted as an alias for
`target=`, and a leading `#` on either is stripped.

The jump lands the target fully revealed, since an appendix slide is a reference
exhibit pulled up under a question and clicking through its staging in front of
the room is the wrong three keypresses.

Back returns to the exact slide and fragment step the jump started from, not to
a hardcoded slide and not to whatever was on screen before. There is one stored
origin per deck, so any `.jump-back` returns to it, which means the same button
works whichever appendix slide you have wandered onto and one appendix slide can
serve two callers. With no stored origin (you walked into the appendix rather
than jumping), Back goes to the last slide of the main deck, found through the
same `pastMain` predicate the progress bar uses.

Things that will break a target, all silently, all reveal's doing. An all-digits
id (`{#2024}`) is parsed as a slide index rather than a name. A
`{visibility="hidden"}` slide is deleted from the DOM at init. And
`auto-stretch` strips the id off a lone image, so put the id on the heading,
which is where these examples have it.

### Why the handler captures on the way down

reveal 5 binds its own click listener on the `.slides` element
(`onSlidesClicked`), which resolves any `a[href^="#"]` through
`getIndicesFromHash` and navigates. `.slides` is a descendant of `document`, so
it receives a bubbling click before a document-level listener does. The obvious
implementation, a bubble-phase listener on `document`, therefore reads
`Reveal.getState()` after reveal has already moved: measured before the fix,
jumping from slide 5 stored `{indexh: 21, indexv: 0, indexf: -1}`, the appendix
slide, and Back did nothing. The filter captures on `document` instead and calls
`stopPropagation()`, so the origin is read before anything navigates and the jump
navigates exactly once.

The state itself comes from `Reveal.getState()` rather than `getIndices()`,
because it carries `indexf` and `setState()` feeds it straight back to
`slide(h, v, f)`. Note that `getIndices(slide)` with an argument returns
`f === undefined` by design, which is why the forward jump computes the target's
last fragment step separately. Two other things that look like they would work
and do not: `Reveal.getPreviousSlide()` is the slide shown immediately before the
current one, so one arrow press after arriving loses the way back, and the
browser history is no better, because Quarto sets `history: true` and reveal
writes an entry per slide, so Back walks the wander instead of undoing the jump.

Nothing published does this. `quarto-revealjs-clean` supplies the `.button` class
that the Quarto Beamer-button idiom comes from, and the themes that copied it,
and every one of them links back to a literal slide id. Beamer cannot do it
either: each of its navigation macros, `\hyperlinkappendixstart` included,
expands to a compile-time page destination, so `\beamerreturnbutton` has to name
the origin overlay by hand.

### The href form: `#id`, and Quarto adds the slash

Write `#ap-window`. reveal's documented form is `#/ap-window` and emitting that
from a filter produces `#//ap-window`, because Quarto's revealjs writer inserts
the slash itself; reveal then parses an empty name and resolves it to the title
slide. Verified in the rendered deck. The plain form is what reveal's parser
wants anyway: `getIndicesFromHash` strips `#` plus an optional slash, and
hakimel's own instruction in reveal.js#55 is the slash-free one. Keeping the
slash out also keeps the link clear of Quarto's crossref filter, which claims
`#fig-`, `#tbl-`, `#eq-` and `#sec-`, so do not name a jump target with one of
those prefixes.

## The progress bar

The filter emits one script that does two jobs on reveal's bottom bar. Cuts are
drawn only when a deck has two or more `.section-break` dividers. The script
itself is emitted whenever the deck has two or more dividers, an appendix, a
references section, or a named closing slide, because any of those on its own
needs the denominator rewritten.

Cut positions cannot be computed at build time, since reveal deletes
`data-visibility="hidden"` slides, counts the title slide, and skips `.stack`
wrappers. The script reads them off `Reveal.getSlides()` at load and writes them
onto the `.progress` element as `--section-cuts` plus `--section-cut-1 .. -N`,
then adds the class `segmented`. A theme that wants a segmented bar draws them,
for instance as background slabs in the page ground with a `$progress-cuts`
loop over the `--section-cut-i` variables, so the bar reads as one dash per
block with the ones behind you filled. A theme with no rule for the properties
is unaffected, which is the starter theme's case: it leaves the bar one plain
fill and only fixes the colours.

Every theme also has to fix reveal's default colours.
reveal ships `color: #fff` over an `rgba(0, 0, 0, 0.2)` track, so on a
near-black ground the track is invisible and only the filled part can be
seen, and on a light ground the fill is white on white and only the track
can be seen. Set both properties for your ground: the starter theme fills with
`$accent` over a track of `rgba($ink, 0.12)`, and a dark theme makes the
opposite move, a pale fill over a lightened track.

### The appendix, the references, and the closing slide

The appendix and the references are outside the bar, through one predicate.
`pastMain` in the emitted scripts and `leaves_main` in the Lua walk name the same
four classes: `appendix-break`, `appendix`, `references-break`, `references`.
Extend those, never a copy.

The closing slide is where the bar completes, and it says so by name:
`.thanks-slide` on a talk, `.closing-slide` on a lecture. `isClosing` is the
second spliced predicate, `is_closing` its Lua twin. The denominator is the
index of the last closing slide before the tail, plus one, so the bar reads
exactly 100% there and stays full through everything after it. With no closing
slide the denominator falls back to the first slide past the main deck, and on a
deck with neither the takeover does not happen at all. Naming the slide
rather than inferring it from what follows buys two things. A slide added after
the closing one no longer moves the point where the bar completes, and the last
step is reserved: the fill is capped at `(last - 1) / last`, so a staged slide
one press short of the closing slide holds there instead of creeping to full on
its own fragments and reading as finished a slide early.

A twelve-slide appendix plus three slides of references would otherwise leave the
closing slide at about half and tell the room the talk was nowhere near over.
Past that line the bar stays full, which is the honest reading: the main deck
really is finished, and a bar that receded on entering the appendix would be
worse than one that sits at 100%. Both dividers are still boundaries; they keep
their own ground and ring and simply get no cut, which would land on the right
edge anyway.

reveal's `getProgress()` counts every slide in the document and cannot be patched
from here. Its Progress controller calls `this.Reveal.getProgress()` on the deck
instance, and `window.Reveal` is a copy of that instance's own properties, so
reassigning the method on the copy changes nothing. What works is detaching the
controller's `<span>`: its `scaleX` writes then land on an element no longer in
the document, and an identical clone in its place inherits
`.reveal .progress span` including the transition. The script marks the bar
`.metered` when it has done this, which is how to check in a browser. Neither
theme styles `.metered`; it exists as that marker. Reveal's own click-to-seek is
remapped at the same time, because it maps a click across every slide in the deck
and no longer matches what the bar draws.

Read the bar settled or not at all. `.reveal .progress span` carries
`transition: transform 800ms cubic-bezier(.26,.86,.44,.985)`, and the substituted
span is a clone of it, so a probe that drives `Reveal.slide()` and reads
`getComputedStyle(...).transform` a tenth of a second later samples a point on
that curve. It comes back as a smooth asymptote across the whole deck, which
looks exactly like reveal's native `getProgress()` and reads as though the
takeover never happened. Either sleep past 800ms per slide or stamp
`transition: none` on the span before driving the deck.

## Things that will silently break the deck

`html-math-method` must be the bare string `katex` in the offline variant. The
object form (`method: katex, url: ...`) looks equivalent and is not: Quarto's
revealjs `katexPostProcessor` only fires on the literal string, so the object
form leaves a runtime loader (`script.src = ".../katex.min.js"`) that
`embed-resources` cannot inline, and the deck loses all its math with no network.

Only four built-in themes are offline-clean: `default`, `dark`, `serif`,
`dracula`. The other eight (sky, moon, beige, league, simple, blood, night,
solarized) `@import` Google Fonts. Always layer onto `default`.

The default math engine is not offline. Quarto revealjs loads MathJax from
jsDelivr through reveal's plugin via a runtime
`document.createElement('script')`, so Pandoc's embedder never sees it and
`self-contained-math` does not help it. KaTeX is the only engine that embeds,
which is why the offline variant uses it.

The other math methods are worse. `mathml` is offline but Chrome's typography is
poor (lost operator spacing, mispositioned subscripts, `aligned` blocks that do
not align) and it silently leaves math unconverted when it meets an unknown
macro. `plain` strips the markup outright, so `p^*` renders as `p *`.

`chalkboard: true` is a hard render error together with `embed-resources`.

A `:has(section…present)` rule leaks across every page of a handout. reveal's
print view marks EVERY section `.present` at once (measured on the sample talk:
1 in the live view, 26 in print) and gives every printed page its own
`div.slide-number.slide-number-pdf`, so a rule shaped like
`.reveal:has(section.appendix-break.present) .slide-number { … }` matches on all
of them and recolours every slide number in the PDF to the divider's value. Both
themes had exactly that bug and both now guard the rule with
`html:not(.print-pdf)`. The class to test is `print-pdf`; reveal sets
`reveal-print` at the same time, and its own `@media print` block keys off
`print-pdf`.

One console exception in every deck built this way is not yours. The engine is
pandoc's MathJax 4: writing `html-math-method: mathjax` explicitly replaces
Quarto's pinned MathJax 2.7.9 default with pandoc's floating `mathjax@4` URL.
reveal's bundled math plugin still runs its MathJax-2 path against it and calls
`MathJax.Hub.Config`, which throws once at load. The math still typesets and both
gates still pass. Do not go looking for it in the filter.

Content overflow is silent. The canvas is a fixed 1050x700 and reveal scales it,
so a slide overflowing by hundreds of pixels can look fine on a laptop and clip
on the projector. `quarto render` exits 0 with no warning, and there is no
`allowframebreaks` equivalent. Missing image files and misspelled YAML keys also
fail silently at exit 0. Run `deck-check.mjs fit`, which is the gate for this.

Do not hand-roll a probe. The obvious one-pass version, iterating sections and
comparing `scrollHeight` to the canvas height, always reports zero overflow:
reveal sets `display: none` on every slide that is not current, so `scrollHeight`
reads 0 for all of them. A working probe has to either navigate with
`Reveal.slide(n)` or force each section visible before measuring, restoring the
style afterwards. `deck-check.mjs` does the former.

A macro block before the first `##` becomes a blank slide, counted in the slide
numbers and printed into the PDF. Park the definitions under a hidden heading
instead:

```markdown
## Notation {visibility="hidden"}

\newcommand{\E}{\mathbb{E}}
```

The slide drops out of navigation, the count, and the export, and the macros
still resolve everywhere after it.

A titleless heading needs no special handling. Pandoc emits a real empty `<h2>`
for `## {.center}` or `## {.thanks-slide ...}`, and the heading rule would
otherwise paint its mark across the top of a slide with no title. Both themes
carry `.reveal .slides section > h2:empty { display: none }`, which covers every
titleless archetype.

`.section-break` must not carry a background attribute. An early design needed
one (`## Part II {.section-break background-color="..."}`), because reveal paints
the real backdrop on a separate `.slide-background` element that theme CSS cannot
reach, so a coloured class alone gave a coloured block inside a page-ground
border. The dividers are now composed on the page ground and an attribute would
paint over that composition; on a dark theme a dark brand colour there is also a
nearly invisible panel. A section
divider also comes round four or five times, so a ground change there is noise.
The class alone is the whole contract.

The appendix divider is the one slide that does take a background, because it
happens once and it means the main deck is over:

```markdown
## Appendix {.appendix-break background-color="var(--appendix-ground)"}
```

The theme publishes `--appendix-ground` and `--references-ground` on `:root`,
so the hex lives
in the theme and the deck asks for it by name. The starter theme keeps both on
the page ground; a theme that wants a tinted back matter (a warm light gray on
a light theme, a slate on a dark one) changes only those two values. reveal assigns
`data-background-color` straight to the background element's inline style, and
when the value is not a colour it can parse it reads the painted result back off
`getComputedStyle`, so the variable both paints and still gets classified as a
light or dark background. A theme without the variable leaves the property
invalid and the divider falls back to the page ground.

Forgetting the attribute is not silent. reveal copies the section's whole class
list onto the `.slide-background` element it generates, so both themes carry
`.reveal .slide-background.appendix-break { background-color: … }` and the
matching `.references-break` rule as a fallback, and
`## Appendix {.appendix-break}` alone paints the same ground. The attribute still
wins when it is there, because reveal writes it to that element's inline style.
With no attribute, `getContrastClass` falls back to reading the background
element's computed colour, so the light/dark classification survives and the ring
still steps up to its higher-contrast value.

Style the background element, never `section.appendix-break` itself. Sections are
absolutely positioned with auto height above the background layer, so a
background on the section paints a band the height of its content rather than a
page.

Neither route reaches the PDF. reveal's `?print-pdf` view builds no
`.slide-background` elements at all (measured on the sample talk: 26 in the live
view, 0 in print) and leaves the section transparent, so the appendix divider
prints on the page ground whichever way the ground was set. In a handout the divider reads on its
ring and its lone title instead.

Only the divider takes it. The appendix content slides keep the page ground on
purpose: they carry tables and prose that get read under question-time pressure,
and a tinted ground would cost contrast on every one of them for a boundary the
divider has already marked. They are marked instead by the appendix scheme and by
a standing APPENDIX pill above every heading, white on the appendix gray or on
slate.

A `.section-break` number comes from `stage-slide.lua`, which writes
`data-section-number` and `data-section-total` on the heading, so do not
hand-number the dividers and do not drop the filter from a deck that uses them.
Both themes draw the number in the disc with `content: attr(data-section-number)`.
Neither draws "of N" from the total any more: at 16.8px on a projector it was not
worth the room, and the progress bar answers the same question along the bottom
of every slide and answers it continuously. `data-section-total` stays on the
heading anyway, since a theme might want it again. The progress-bar segments do
not use it; they count `.section-break` slides in the DOM. A CSS counter is the
obvious implementation and it is wrong: reveal sets `display: none` on every
slide outside its `viewDistance` (3), a `display: none` element does not
increment a counter, and four dividers came out numbered 1, 2, 2, 2.

Both divider archetypes centre themselves vertically with `height: 100%` on the
section plus a full-height flex `h2`. Do not switch them to `display: flex` on
the section, because reveal writes `display: block` and `display: none` inline as
it shows and hides slides and the `!important` needed to win would also break the
hiding. A paragraph written after a divider heading lands under the title, so
put the sentence on the next slide.

`auto-stretch` turns overflow into silent shrinkage. It is on by default, so an
oversized figure does not overflow, it scales down until it is illegible and the
overflow check reports zero. `deck-check.mjs` fails a figure crushed under 24px
tall and one whose natural width is 1200px or more rendering under 600px; a
figure merely shrunk to illegibility between those bounds it does not catch, so
read `--json` per-image geometry when a slide holds a figure and anything else.

`auto-stretch` also refuses to touch a nested image, and hoists the one it does
stretch. So do not add `.r-stretch` by hand inside a fragment or a column. It is
not a workaround for the nesting rule: reveal never sizes a nested element, and
`.r-stretch` also clears the `max-width`/`max-height` that were holding the image
inside the canvas, so the image comes out at natural size and overflows.
Measured: a 1400x1400 PNG in a fragment overflowed the canvas by 424px with the
class and fit without it. Size a nested figure with `fig-width`/`fig-height` and
let `deck-check.mjs fit` confirm it.

A captioned figure needs `#| label: fig-something` as well as `#| fig-cap:`.
With `fig-cap` alone the label does not make the cell a crossref target, the
filter has to wrap the cell, and the stretch is lost, so the image renders at its
authored width. Nothing flags it, because a smaller figure still fits.

Python plotly fetches from a CDN unless you turn it off. plotly.py 6.x emits
`<script type="module">import "https://cdn.plot.ly/..."</script>`, and the URL is
inside JS so `embed-resources` cannot rewrite it. Add `plotly-connected: false`
to the front matter; Quarto's Jupyter setup then sets
`pio.renderers.default = "notebook"` itself. Do not write that line by hand. The
schema claims the option defaults to false but the runtime default is true, so
set it explicitly, and clear `_freeze/` afterwards if the project caches.

KaTeX cannot do `\eqref`, `\label`, or `\DeclareMathOperator`, which is the cost
of the offline variant. Equation cross-references go through Quarto's `@eq-`
mechanism, which is resolved before KaTeX sees the math. `\newcommand` and
`\DeclareMathOperator` work in a deck built this way only because pandoc expands
them at parse time, which is why they have to be bare top-level raw LaTeX.

Raw HTML is the video form that works: `<video src="clip.mp4" width="900"
controls></video>`. The `{{< video >}}` shortcode is broken under
`embed-resources`: `video.lua` hardcodes `<source src="{src}">` with no `type`
attribute, and video.js infers the MIME type by matching a file extension off
`src`, which a base64 payload does not have, so the slide shows a "No compatible
source was found" modal. Separately, `## Slide {background-video="clip.mp4"}` is
not embedded at all and stays a relative path.

A numbered theorem goes through Quarto's own crossref machinery. Write
`::: {#thm-name}` with the statement and nothing else, and use `@thm-name` to
refer back; the number is written into the HTML at render time, so it renumbers
itself and survives into the handout. `#thm-`, `#prp-`, `#lem-`, and `#cor-` each run their own counter,
and `#def-` and `#exm-` arrive as `.theorem.definition` and `.theorem.example`,
which the example lecture theme guards so they keep the teaching box they
already have and take only the numbered label. The example talk theme and the
starter theme style the hand-written
`.theorem` / `.proposition` / `.lemma` divs instead and expects a
`[Proposition 1]{.label}` span, so a native `#thm-` block on those themes gets
the left border with an unstyled title. Quarto gives theorem divs no styling in
revealjs on its own, which is why a theme has to supply it. Do not put a `#thm-` id
on a callout div: two filters both process it and the title duplicates.

## Why check-offline.py decodes before searching

Quarto inlines CSS as a percent-encoded `data:` URI, so a plain grep for
`cdn.jsdelivr` misses `cdn%2Ejsdelivr` and returns a false negative.
`check-offline.py` percent-decodes every data URI first, then looks for external
hosts, runtime `script.src` / `link.href` assignments, module imports, CSS
`url()`, fetch and XHR calls, plotly's `topojsonURL`, and reveal's math config,
which builds its script tag from a URL that never sits next to a `.src`. It
takes any number of decks and exits nonzero if any one of them is not
self-contained. There are no flags.

It excuses hostnames that are inert inside a bundle, and it excuses the plotly
bundle's own attribution and map-icon hosts when a plotly bundle is present. A
module import is never excused. Its `math` line reporting client-rendered spans
under KaTeX is the expected state, since KaTeX keeps the raw TeX in the document
and typesets it in the browser.

Run it before every talk built as the offline variant. A deck that loses its math
on stage is the worst failure available.

## Looking at a rendered deck

Chrome `--headless --print-to-pdf` produces a blank PDF. decktape works:

```bash
npx -y decktape@latest reveal --size 1050x700 "file://$PWD/deck.html" deck.pdf
~/.claude/assets/bin/pdfread.py png deck.pdf --pages 3 --dpi 110 --out /tmp/s
# then Read /tmp/s-3.png
```

This setup assumes the agent's Read tool cannot open PDFs directly (no
poppler installed), so it always rasterizes first; adjust to your machine. `pdfread.py text` pulls
text out of long documents and `pdfread.py pages` gives the count.

Playwright MCP can drive a real browser, but there is one shared instance and
concurrent agents hijack each other's page, so serialize browser work. Playwright
also blocks `file://`, so serve the deck (`python3 -m http.server`) before
navigating.

## PDF handouts

```bash
node ~/.claude/assets/quarto-yale/deck-check.mjs handout deck.html handout.pdf
```

That loads `deck.html?print-pdf` and prints through CDP `Page.printToPDF` with
`printBackground: true`, `preferCSSPageSize: true`, and zero margins.
`chrome --headless --print-to-pdf` against the live deck writes an empty PDF; do
not reach for it.

`pdf-separate-fragments` defaults to false in Quarto, the opposite of reveal.js's
own default, so out of the box the print view collapses each slide's build steps
onto one fully revealed page. That is the student handout. Set it true and the
same command gives a page per build step, which is a lecturer's cue printout and
runs long under `incremental: true`. The option does nothing under decktape,
which drives the live deck through reveal's API and never enters the print view;
decktape gives one page per slide and is the fallback if Chrome over CDP breaks.

A jump button prints as what it looks like, a small outlined label, and does
nothing: the whole mechanism is a click handler, and even the `href` fallback is
`#ap-window`, which no PDF reader resolves to a page. That is the right outcome
for a handout, where the appendix is a few pages further on. The progress bar
does not print either; reveal hides `.progress` in the print view. Speaker notes
appear in no PDF export, and `panel-tabset` prints only its first tab, so it
destroys a handout.

On clipping: reveal's own print view paginates an over-tall slide rather than
clipping it (`pdf-max-pages-per-slide` has no default, and its description says
such slides "expand onto multiple pages"). decktape instead screenshots the fixed
1050x700 canvas, so decktape is what clips. This only matters for a deck that
overflows, which `deck-check.mjs fit` is there to prevent. Setting
`pdf-max-pages-per-slide: 1` is what causes clipping in the print view.

## Publishing

`quarto publish gh-pages` renders to a `gh-pages` branch and pushes it, for a
single document or a whole website project alike. The `docs/` route with
`output-dir: docs` is still the recommendation here: the output stays on main,
there is no second branch to keep in step with the source, and publishing is
just a push, with no stored publish credential. `quarto publish gh-pages`
writes `.nojekyll` itself; the `docs/` route needs you to `touch .nojekyll`.
`course-site` owns the rest.

## Theme classes

Both example themes and the starter theme define these. Everything here is typed by the author except
`.references`, which the filter puts on every reference-list slide including the
continuation pages.

| Class | What it is |
|---|---|
| `.section-break` | Numbered section divider. |
| `.appendix-break` | The same divider unnumbered, opening the appendix, with `background-color="var(--appendix-ground)"`. |
| `.references-break` | That divider again, at the very end after the appendix, with `background-color="var(--references-ground)"`. |
| `.appendix` | On a content heading. The gray or slate appendix scheme, with a standing APPENDIX pill. |
| `.references` | Written by the filter, never typed. |
| `.aside-note` | Muted caveat. Arrives with the block above it. |
| `.citation`, `.cite` | Both a span and a block class; the block form is an addendum. |
| `.label` | The label span inside a block: `[Estimate]{.label}`. Styled only as a child of a block that takes one. |
| `.num` | Right-align a numeric table cell, with tabular figures. |
| 4+ column table | No class. Both themes stretch it to the full text column (`width: 100%` of the section) via `table:has(tr > :nth-child(4))`, padding scaled up, so its right edge lands where the aside note and the takeaway rule end; 2-3 column tables keep natural width. Quarto's inline `width:100%` (from `tbl-colwidths`) agrees with the rule. |
| `.jump`, `.jump-back` | The jump buttons above. Rendered by the filter as `a.jump-btn`. |
| `.highlight-yale` | A fragment variant that turns a term to the accent colour on cue (`.highlight-accent` is the starter theme's alias). |

Colour spans differ by theme. The example talk theme has `.yblue` `.ymid`
`.ygray` `.ygreen` `.yamber` `.yred` `.dim`; the example lecture theme swaps
`.ymid` for `.ypale`. The starter theme defines the union of both, mapped to
its neutral palette, so either example source renders; rename the vocabulary
to your own when you build a theme.

The example talk theme (and the starter theme) also defines `.result` (framed estimate), `.takeaway` (the
slide's one claim, on a rule under the content), `.assumption`, `.theorem` /
`.proposition` / `.lemma` (hand-labelled, so give each a `[Proposition 1]{.label}`
span), `.proof` (automatic QED square), `table.spec` for wide specification
tables, and the closing archetype `.thanks-slide` with its four children
`.thanks-title`, `.thanks-invite`, `.thanks-contact`, and `.qr-slot`.

The example lecture theme (and, in plainer form, the starter theme) also
defines the five teaching blocks `.keyidea`, `.definition`, `.example`,
`.warning`, `.question`, each a distinct colour so the vocabulary is learnable
over a semester; `.prompt` (large discussion question);
`.hero` (one number, 3.2em); `ol.steps` and `ul.agenda` with `li.now` and
`li.done`, each of which also works as `::: {.steps}` or `::: {.agenda}` around
the list; `section.full-bleed` on a heading; `.demo-tag`; the numbered `.theorem`
family with `.theorem-title`; and `.proof` with `.remark` and `.solution` as the
two variants that get no QED square. `.closing-slide` is a name with no CSS: the
filter and the gate both read it, and the theme leaves it alone.

`.together`, `.with-previous`, and `{.no-stage}` are staging directives with no
styling in either theme. They do nothing without `stage-slide.lua` in the filter
list.

Blocks take a label span:

```markdown
::: {.result}
[Estimate]{.label}
Adoption raises prices by 4.2% (s.e. 0.9).
:::

Inline emphasis: [this matters]{.yblue}
```

## Fonts

The starter theme runs on two vendored families: Literata for headings,
dividers, and display numbers, and IBM Plex Sans for everything else. Both are
under the SIL Open Font License 1.1 and both ship in `fonts/`, so nothing is
fetched at display time and the metrics are the same on every machine, which is
what lets the fit gate's certification transfer.

Each family is mastered as one variable roman covering weights 400 to 700 plus
one static italic, four woff2 files and two license files, 434 KB in total.
The variable roman is the smaller half of that trade: Literata's is 147 KB
against 175 KB for the two static weights it replaces, and Plex's is 125 KB
against 150 KB, and either one then also covers the weights in between. Both
were built from the upstream variable TTFs (Literata from
[googlefonts/literata](https://github.com/googlefonts/literata) by way of the
Google Fonts release, Plex from [IBM/plex](https://github.com/IBM/plex) the
same way), with the optical-size and width axes pinned and the weight axis
clamped to 400-700 before the woff2 conversion.

`fonts/` has to sit next to the rendered deck, the same rule the vendored
`mathjax/` copy follows, and the @font-face rules live in the format's
`header-includes` rather than in the theme, because theme SCSS compiles into
`<deck>_files/` and a `url()` there resolves against the wrong base; urls in
the header resolve against the rendered page. A deck that renders into a
subdirectory rewrites those four paths. Nothing warns you when this is wrong:
a missing `fonts/` copy just falls back to the system stacks behind each
family, and the deck still renders, a little wider and off its measured fit.
Eight of the twelve built-in reveal themes
`@import` Google Fonts, which is a display-time fetch and a different face
whenever the CDN misbehaves; layering onto `default` avoids that, and it is
also what keeps the offline variant possible.

## Execution engines

One engine per document. Mixing R and Python is done inside knitr via reticulate,
not by combining engines. `quarto inspect deck.qmd` prints the resolved format,
useful for checking an option actually took effect.
