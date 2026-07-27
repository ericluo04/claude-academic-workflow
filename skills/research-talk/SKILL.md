---
name: research-talk
description: Author a Quarto reveal.js deck for an academic research presentation: conference talk, seminar, job talk, brown bag, workshop. Restrained Yale talk theme, assertion titles, one argument per deck, exhibits from R or Python, deep appendix for questions. TRIGGER on "make slides for my talk", "build a seminar deck", "conference presentation", "job talk", "brown bag", "turn this paper into slides", "slides for my paper", "deck for the referee's question", "add an appendix slide", "export a handout". Use teaching-lecture for classroom material, and slide-review to audit a deck that already exists.
---

# Research talk decks

Builds a `.qmd` that renders to a reveal.js HTML deck for a seminar, conference
talk, job talk, or brown bag. The audience is other researchers who are reading
dense exhibits and following an argument, so the deck stays quiet and the
evidence carries the weight.

Out of scope: classroom lectures (use `teaching-lecture`, which has its own
theme, a larger root font for a lecture hall, and the pedagogy vocabulary),
auditing a deck you did not write (use `slide-review`), and LaTeX Beamer (use
`compile-latex`).

Shared theme and tooling live in `~/.claude/assets/quarto-yale/`.
`README.md` there is the machinery reference: what the filter rewrites, what
the gates assert, the reference packer, the progress-bar takeover, and the
settings that silently break a deck. Read it for any of that; where it and the
source disagree, the source wins. The head of `yale-talk.scss` carries the
theme's own reasoning about each class.

Deck architecture and the review-before-the-talk discipline are adapted from
the `slide-excellence` orchestrator and its review agents in Pedro Sant'Anna's
`pedrohcgs/claude-code-my-workflow`.

## Read next to this file

- `references/closing-slide.md`: the thank-you slide, the QR slot, how the
  progress bar and the slide numbers end.
- `references/staging.md`: fragments, beats, `.r-stack` layers, auto-animate,
  what a jump button costs.
- `references/figures-and-code.md`: figure sizing, code display, two columns,
  tables, R setup.
- `references/citations.md`: citing and the reference list.
- `style/house.md`: the author's wording and calibration (closing-slide text,
  the author line, button labels, density anchors, dates).
- `assets/starter-template.qmd`: copy it to start a deck; do not transcribe.
- The README above: tool internals and jump-button mechanics.

## Before drafting anything

Do not open the `.qmd` until these four are pinned down. Ask the user; do not
guess, and do not infer them from the paper.

1. Audience and venue. An NBER session, a marketing seminar, a psychology brown
   bag, and a CS lab meeting want different amounts of setup and different
   notation. Name the room.
2. The one-sentence claim. If the audience remembers one thing, what is it?
   Write it down verbatim. It becomes the title slide, the claim slide, and the
   closing slide.
3. Time slot, and whether it is protected. Fifteen minutes with interruptions
   is a different deck from fifty minutes uninterrupted.
4. What is already built. Point at the paper, the `.tex`, existing figures, the
   R or Python that produces the exhibits. Rebuilding a figure from scratch
   when the script exists wastes the time budget.

Then write the title list before any slide bodies, and read it back to the user
as a list of assertions. Fixing the argument at that stage costs one message;
fixing it after twenty slides exist costs an hour.

## Content doctrine

Titles are assertions. "Results" is a label; "Disclosure raises prices only
where search costs are high" is an assertion. Every content slide title states
its own takeaway, so a listener who tunes out for a minute can rejoin by
reading one line. One or two lines; if the title needs three, the point is not
sharp yet.

The deck is one argument. A paper has four contributions and a talk has one.
Pick the claim that can be defended in the slot and move the rest to the
appendix. Deciding what the talk is not about is most of the work. One idea per
slide; a slide with two jobs also tends to be the slide that overflows.

A narrated picture book, which is the house style and deliberate: the slide
carries the exhibit and the one line that names what it shows, and the speaker
carries the argument. A sparse slide is finished, so do not fill it in with
supporting sentences; err to the sparse side every time. Longer text is
welcome when it arrives as one block of full sentences, staged so it lands as
you say it; three sentences of prose land more easily than eight compressed
bullets, and what ruins a slide is overwhelming the room, with word count only
a proxy for that. The calibration numbers and their Beamer anchors are in
`style/house.md`. A slide that asserts one clause in two to five words carries
a turn in the argument on its own: `## {.center}` holding `::: {.r-fit-text}`
scales the line to the slide width (the starter template has one).

What goes on the slide: the assertion title, the exhibit, the focal number, and
any formal statement whose exact wording has to be on the wall. What the
speaker says: the setup, the intuition, the caveats, and the sentence that
connects this slide to the one before it. A line that exists so the audience
can follow along later belongs in `::: {.notes}` or in the paper. Write
speaker notes on every slide that carries a step in the argument; they are
what make a sparse slide safe to present from. `::: {.notes}` goes to
reveal's speaker view (press `S`), written as the sentences you intend to say
out loud, and appears in neither PDF export, so anything a handout reader
needs stays in the slide body.

Every exhibit needs an interpretation next to it: the exhibit on the left, the
reading on the right (two columns, in `references/figures-and-code.md`), and
the focal number annotated in the exhibit itself so the point survives being
read cold.

Ghost-deck check, run before writing bodies and again before the talk: read
only the titles, in order; they should compose into the argument. A title that
could sit anywhere in the sequence is either misplaced or unnecessary.

State the claim early. The audience decides in the first three minutes whether
to engage or read email, so the claim gets its own slide by slide three,
before methods. End on the conclusion slide, which carries the claim and the
headline estimate, then the thank-you slide (`references/closing-slide.md`).

Build the appendix as you go: every cut for time and every anticipated
question is an appendix slide. Mark them `{.appendix}` so they run on the gray
scheme and you can spot them while scrolling under pressure, and open the run
with an `{.appendix-break}` divider. A job talk wants ten to twenty of these.

Cite on the slide where the borrowed thing appears, in the small gray style
the theme gives `.aside-note` and `.citation`; do not make the audience wait
for a references slide to learn whose figure they are looking at. The full
list still goes at the end, after the appendix (`references/citations.md`).

## Deck architecture

A workable spine for empirical work: title, motivation (one or two), the
claim, setting and data, identification or method, results (one finding per
slide), mechanism or heterogeneity, the main threat and what answers it,
conclusion, thank you, then appendix. Theory talks substitute setup,
assumptions, main proposition, intuition for the proof, comparative statics.

Budget roughly one slide per minute of speaking, and leave the last slide up.
Twenty-minute conference talk: fifteen to eighteen content slides.
Ninety-minute job talk: forty to fifty, plus a deep appendix. Build the
appendix past the budget on purpose.

## Front matter, via the extension

The deck uses the `yale-talk-revealjs` extension format. Adopt it once per
deck directory:

```bash
cd <deck dir>
quarto add ~/.claude/assets/quarto-yale --no-prompt
cp -R ~/.claude/assets/quarto-yale/mathjax .
mkdir -p fonts && cp -R ~/.claude/assets/quarto-yale/fonts/inter fonts/
```

```yaml
format: yale-talk-revealjs
bibliography: talk-refs.bib   # only on a deck that cites
```

The format carries the whole verified recipe: the theme layered on `default`,
`stage-slide.lua`, `citeproc: false` with `refs-fit: talk`, self-hosted
MathJax 2.7.9 pinned to its own TeX webfonts, the Inter `@font-face` block,
`highlight-style: a11y`, `slide-number: c/t`, `date-format: long`,
`incremental: true`, `fig-align: center`, `auto-animate-duration: 0.4`, and
`echo`/`warning`/`message` off. Its `_extension.yml` says why each line is
there.

The `mathjax/` copy is why math needs no CDN: the format points MathJax at the
deck's own `mathjax/MathJax.js`, resolved by the browser relative to the
rendered page, and `fonts/inter/` resolves the same way. Writing
`html-math-method: mathjax` as a bare string instead loads pandoc's MathJax 4
from jsDelivr at display time (README). MathJax is the engine because a formal
talk needs what KaTeX cannot do: `\eqref` and `\label`,
`\DeclareMathOperator`, `mathtools`, and `physics`.

`stage-slide.lua` does six jobs (staging, divider numbering, the progress and
slide-number takeover, jump buttons, reference pagination, citation-tooltip
retargeting; the README lists them), so keep the format even on a deck that
wants no staging and use `{.no-stage}` per slide instead. `slide-number: c/t`
out of the box counts every slide in the `t`, so a 19-slide argument with an
appendix behind it would close at 19/26; the filter re-meters it so the main
body runs 1/19 to 19/19 and the appendix and references share a tail run
(`references/closing-slide.md`).

Unknown or misspelled YAML keys are ignored silently and the render still
exits 0. When an option seems not to have taken, `quarto inspect deck.qmd`
prints the resolved format as JSON.

### Variant: one self-contained file

For a room where nothing can be counted on, build a single HTML file that
opens from a thumb drive, an email attachment, or behind a hotel wifi captive
portal, which is the case that ruins talks. Swap the math engine and embed
everything:

```yaml
format:
  yale-talk-revealjs:
    embed-resources: true
    html-math-method: katex      # bare string, never the object form
    self-contained-math: true
```

The object form (`{method: katex, url: ...}`) leaves a runtime loader that
`embed-resources` cannot inline, so the deck loses all its math the moment
there is no network; KaTeX is the only engine Quarto embeds, and it has no
`\eqref`, `\label`, or `\DeclareMathOperator` of its own, so numbered
equations in this variant go through Quarto's `@eq-` cross-references,
resolved before KaTeX sees the math (README, "The offline variant"). With the
KaTeX fonts inlined a normal talk lands between 5 and 6 MB.
`check-offline.py` is the gate for this variant, and only for this variant.

## Math and macros

Define macros as bare raw LaTeX at the top level of the document, outside any
math block, parked on a hidden `## Notation {visibility="hidden"}` slide as
the starter template does. They expand at parse time, so the same definitions
work under MathJax and under the KaTeX variant. Wrapping them in `$$ ... $$`
fails: pandoc consumes them and every later use errors with "unexpected
control sequence". A MathJax config header or a ```` ```{=tex} ```` block does
not work either (README, "Math macros").

Numbered equations: tag the display block `$$ ... $$ {#eq-main}` and reference
it with `@eq-main`. That form survives a rebuild as the self-contained
variant; raw `\label` plus `\eqref` also works under MathJax and dies under
KaTeX. `mathtools` and `physics` commands are available under MathJax.

## Theme classes

From `yale-talk.scss`. Use Quarto div and span syntax.

| Class | For |
|---|---|
| `.result` | A framed estimate. Put `[Estimate]{.label}` on its own line first. |
| `.takeaway` | The slide's one claim, on a rule under the content. Once per slide at most. |
| `.assumption` | An identification assumption or formal condition. |
| `.theorem` `.proposition` `.lemma` | Formal statements, with a `[Proposition 1]{.label}` span. |
| `.proof` | Gets an automatic QED square on its last element. |
| `.appendix` | On the slide heading: `## Robustness {.appendix}`. Gray appendix scheme plus a standing APPENDIX pill. |
| `.thanks-slide` | The closing slide of the main body. See `references/closing-slide.md`. |
| `.section-break` | Numbered section divider. Number, title, vertical middle. |
| `.appendix-break` | The same divider with no number, in gray. Goes before the first `.appendix` slide, with `background-color="var(--appendix-ground)"`. |
| `.references-break` | That divider again, at the very end, with `background-color="var(--references-ground)"`. |
| `.references` | On the reference-list heading. The filter copies it onto every continuation page, so you write it once. |
| `.aside-note` | Muted caveat or scope condition. Arrives with the block above it. |
| `.jump` | A button to a named appendix slide, on its own line and outside any bordered block: `[Sample Windows]{.jump target="ap-window"}`. |
| `.jump-back` | The button back, to the exact slide and step the jump started from. Leave the span empty and it reads Back: `[]{.jump-back}`. |
| `.together` | On a div, so everything inside it arrives on one keypress. |
| `.with-previous` | On a div, so it arrives on the beat of the block above it. |
| `.no-stage` | On a heading, so the slide arrives whole. |
| `.spec` | On a wide specification table, so it shrinks instead of clipping. |
| `.num` | Right-align a numeric table column. |
| `.highlight-yale` | A fragment variant that turns a term blue on cue. |
| `.yblue` `.ymid` `.ygray` `.ygreen` `.yamber` `.yred` `.dim` | Inline color spans. |

Use the theorem environments wherever the talk has formal content. A
proposition belongs in a box that says Proposition, carrying a
`[Proposition 1]{.label}` span and the statement worded exactly as you want it
read; the same goes for `.assumption` on an identification condition. A formal
statement is one of the few things that earns full sentences on the wall,
because the room has to be able to hold you to the wording. Quarto gives
theorem divs zero styling in reveal.js, which is why the theme supplies it.

### Dividers

Two archetypes, each a heading and nothing else, a circle beside the title at
the vertical middle, which is what makes them read as a turn in the talk:

```markdown
## Setting and identification {.section-break}

## Appendix {.appendix-break background-color="var(--appendix-ground)"}
```

`stage-slide.lua` numbers the `.section-break` dividers, so never hand-number
them: insert a section and the rest renumber on the next render. Copy the
appendix attribute exactly as written; forgetting it is no longer silent (the
theme paints the same warm gray as a fallback), and the references divider
takes `var(--references-ground)` the same way. Do not add `background-color`
to a `.section-break`: the ground is white now and a blue field would swallow
the circle. Appendix content slides stay white on purpose, marked by the gray
scheme and the pill instead. The print-view behaviour and the contrast
classification are in the README.

### Vertical alignment

Content slides are top-aligned, Quarto's `center: false` default. `{.center}`
works per slide and is the fix for a sparse slide, which otherwise pools all
its whitespace at the bottom and reads as half-finished: centre anything
carrying one line, one number, or one assertion, e.g.
`## The sign flips {.center}`.

## Staging in brief

Content arrives as you say it. The format's filter stages every top-level
block on a content slide, so the slide opens as its title alone and the blocks
arrive one keypress each; a note that annotates the block above it
(`.aside-note`, `.citation`, `.caption`, `.with-previous`) rides that block's
beat, `.together` makes a group one beat, and `{.no-stage}` turns staging off
for one slide. Everything else, and the caveats, are in
`references/staging.md`; the filter's internals are in the README.

## Build and verify

The render exits 0 whether or not the deck is presentable, so the gates are
not optional. Run them every time, and again before the talk.

```bash
cd <deck dir>
quarto render deck.qmd 2>&1 | tee /tmp/render.log
grep '\[WARNING\]' /tmp/render.log            # unclosed divs warn here and still exit 0

node ~/.claude/assets/quarto-yale/deck-check.mjs fit deck.html   # must print DECK-FITS: YES
node ~/.claude/assets/quarto-yale/stage-check.mjs deck.html      # must print STEP-0-CLEAN: YES

# self-contained variant only; verdict line is the padded label OFFLINE-SAFE
~/.claude/assets/quarto-yale/check-offline.py deck.html
```

The fit gate exists because the reveal canvas is a fixed 1050x700 that reveal
scales to the window: a slide overflowing by 345 px looks fine on a laptop and
gets cut off on the projector, and there is no `allowframebreaks` to save it.
On a real test the deck rendered at exit 0 with no warning, and the exported
PDF simply stopped mid-list with a figure and two paragraphs gone. The gate
visits every slide with fragments forced visible and fails on overflow, excess
width, missing images, crushed or shrunk figures, unrendered math, a dangling
`.jump` target, and an unpaginated bibliography; it warns on a nearly empty
slide (the stray macro block), and `--json` prints per-image geometry. On
overflow, cut content or split the slide; do not shrink the font, since the
30 px root is already calibrated for a seminar room.

`stage-check.mjs` asserts that nothing but the heading is visible before each
content slide is advanced, then walks the slide forward and fails any press
that changes no visible ink (`DEAD STEP`, presses counted from 1). It costs
about two seconds a deck; the sample talk measures zero dead steps. It skips
the slides it classifies as archetypes and reports which, so a divider that
has quietly become a content slide shows up. What each gate measures, and
how, is in the README.

`check-offline.py` decodes percent-encoded data URIs before searching, which a
plain grep for `cdn.jsdelivr` cannot do; the verdict lines are `fetchable
refs` and `external hosts`, and a nonzero `math` count under KaTeX is the
expected state. Run it only on the self-contained variant: a default build is
not self-contained and fails it by design.

### Looking at the slides

Read the pictures, not the markup:

```bash
npx -y decktape@latest reveal --size 1050x700 "file://$PWD/deck.html" deck.pdf
~/.claude/assets/bin/pdfread.py png deck.pdf --pages 3 --dpi 110 --out /tmp/s   # /tmp/s-3.png
# then Read /tmp/s-3.png
```

`--pages` takes `3`, `1-5`, or `1,4,9`; `pdfread.py text` pulls the wording
across many slides at once, and `pdfread.py pages` gives the count. Chrome's
own `--headless --print-to-pdf` writes a blank PDF on a live deck, and the
Read tool cannot open PDFs on this machine. Playwright MCP shares one browser
across agents; prefer decktape, and serialize if you must use it.

### Handout

decktape (the command above) gives one page per slide with every fragment
revealed, which is usually what a handout should be. For one page per build
step, set `pdf-separate-fragments: true` in the front matter and print through
reveal's print view (verified: a three-slide deck with three fragments came
out as six pages):

```bash
node ~/.claude/assets/quarto-yale/deck-check.mjs handout deck.html deck-handout.pdf
```

`pdf-separate-fragments` defaults to false in Quarto, the opposite of reveal's
own default, and decktape ignores it, since it drives the live deck through
reveal's API. Hyperlinks do not survive PDF export: jump buttons print as
small outlined labels that do nothing, which is right for a handout, but say
so when you build them and keep the appendix reachable by slide number too.

### Publishing

`quarto publish gh-pages` puts one document per repository, so a repo can host
one talk; for several, use one repo each or publish to `docs/` and manage the
paths yourself (the README weighs the two routes). Build the self-contained
variant whenever the room is uncertain.

## Traps, all verified on this machine

- Overflow, missing images, and unknown YAML keys all fail at exit 0 with no
  warning. Run the fit gate.
- A bare macro block before the first `##` becomes a blank counted slide. Put
  it on a `{visibility="hidden"}` slide.
- A block that appears with the heading instead of waiting means the deck is
  not on the extension format (so the filter never ran) or the heading carries
  `{.no-stage}`. `stage-check.mjs` names the slide.
- A misspelled `highlight-style` silently disables highlighting altogether;
  `solarized-dark` and `printing-dark` are not real names.
- `auto-stretch` stops applying once an image is nested in a fragment, a
  column, or any fenced div, and `.r-stretch` by hand only removes the size
  cap, so the image overflows instead. Set `fig-width` and `fig-height`
  (`references/figures-and-code.md`).
- A `fig-cap` on a chunk whose label does not start with `fig-` loses the
  stretch (README, "Figures and tables").
- `panel-tabset` prints only its first tab, so it destroys a handout. Use
  separate slides when the deck will be exported.
- Do not add `top: 0 !important` to a theme: it outranks the inline `top`
  reveal writes to centre the title slide and kills per-slide `{.center}`; the
  theme once carried it and title-slide centring died silently.
- Do not switch the engine to `mathml` (Chrome loses operator spacing,
  mispositions subscripts, and misaligns `aligned` blocks) or `plain` (strips
  the markup, so `p^*` comes out as `p *`).
- Eight of the twelve built-in reveal themes fetch Google Fonts; only
  `default`, `dark`, `serif`, and `dracula` are clean, and the theme layers on
  `default`.
- `chalkboard: true` plus `embed-resources: true` is a hard render error.
- A deck with `bibliography:` whose format lost `citeproc: false` renders a
  second, unpaginated bibliography onto one slide. The fit gate fails it and
  names the fix.
- `.scrollable` on a references slide hides the overflow from the gate, breaks
  `auto-stretch`, and does not print (`references/citations.md` has the budget
  override).
- Never hand-number `.section-break` dividers, and never put
  `background-color` on one.
- `stage-check.mjs` reads a titleless `## {.center}` quote slide as content:
  the empty `<h2>` pandoc emits counts as a heading and `h2:empty` hides it,
  so the gate reports `HEADING NOT VISIBLE`. Expect that one line on a quote
  slide; every other archetype is classified and skipped.
- Do not put a `#thm-` id on a callout div: two filters both process it and
  the title comes out twice.
