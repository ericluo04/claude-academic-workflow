---
name: research-talk
description: Author a Quarto reveal.js deck for a research talk (seminar, conference, job talk, brown bag, reading group) on the Editorial theme, from a full paper, from analyses plus an outline, or from someone else's paper the user presents. Plans clicks by hand, builds derivations one term per line, and puts backup slides behind buttons with fixed-return Back links. TRIGGER on "slides for my talk", "seminar deck", "job talk", "turn this paper into slides", "reading group deck", "present this paper", "add a backup slide", "export a handout". Classroom material is teaching-lecture; auditing an existing deck is slide-review.
---

# Research talk decks

This skill builds a `.qmd` that renders to a reveal.js deck on the Editorial
theme. The audience is other researchers following an argument, so the slide
carries the exhibit and the speaker carries the argument.

The Editorial theme is a white page with one vermilion accent, one sans family
(Schibsted Grotesk), and hairline rules. Its flow is fixed:

1. A title slide.
2. Content slides, each with its title in a fixed band above a full-width rule.
3. A full-bleed accent section slide before each part, carrying one word or a
   short phrase and no number.
4. A thin accent progress line at the bottom edge that fills from the title to
   the closing slide.
5. A Takeaways slide that closes the talk: the numbered claims, then a contact
   line.
6. A Backup divider that lists what follows, the backup slides, and the
   references.

There is no label above any slide title (no kicker, no eyebrow), no outline
slide, and no Thank you slide.

Out of scope: classroom lectures (`teaching-lecture`), auditing a deck you did
not write (`slide-review`), and LaTeX Beamer (`compile-latex`).

## Where things live

`$SLIDES` below is this repository's `slide-tooling/` directory, wherever you
installed it (SETUP.md has the copy step). It holds:

- `_extensions/editorial/`: the `editorial-revealjs` format (`_extension.yml`,
  `editorial.scss`, `head.html`, `after.html`, the font, and a copy of the
  filter);
- `stage-slide.lua`: the filter (jump buttons, fixed-return Back, reference
  pagination, opt-in staging);
- `deck-check.mjs` and `stage-check.mjs`: the gates;
- `mathjax/` and `fonts/`: the self-hosted copies every deck directory needs;
- `README.md`: the machinery reference. Where it and the source disagree, the
  source wins.

The head of `editorial.scss` documents every class. The deck at
`examples/research-talk/talk.qmd` uses every pattern in this file.

## Read next to this file

- `references/narrative.md`: the arc, what goes on a slide, the three input
  cases (your paper, analyses plus an outline, someone else's paper), notation,
  and first drafts.
- `references/staging.md`: the click map, the step equation, the derivation
  chain, swap in place, gray-out, overflow, buttons, and Back.
- `references/closing-slide.md`: the Takeaways slide, the Backup divider, and
  how the progress line ends.
- `references/figures-and-code.md`: figure sizing, figure palette, tables, code,
  and two columns.
- `references/citations.md`: citing on the slide and the reference list.
- `style/house.md`: the author's own values (author line, contact line, button
  diction, density).
- `assets/editorial-template.qmd`: copy it to start a deck.

## Before drafting anything

Do not open the `.qmd` until these four are pinned down. Ask the user. Do not
guess, and do not infer them from the paper.

1. Audience and venue. A marketing seminar, an NBER session, and a reading group
   want different amounts of setup and notation.
2. The one-sentence claim. Write it down verbatim. It becomes the title and the
   first item on the Takeaways slide.
3. The time slot, and whether it is protected.
4. What is already built: the paper, the `.tex`, existing figures, the scripts
   that make the exhibits. Reuse them. Do not redraw a figure whose script
   exists.

Then write the title list, with the section words, before any slide body, and
read it back to the user. Fixing the argument at that stage costs one message.

## Content doctrine

The slide is a prompt for the speaker. It carries at most three things: the
exhibit (a figure, a table, an equation), the line that names it, and the focal
number. The speaker says the setup, the intuition, the caveats, and the bridge
to the next slide. If the slide explains itself with the sound off, take words
off.

Titles are one or two lines. A title that needs three means the point is not
sharp yet. Assertion titles ("Automation raises prices only where rivals
automate too") let a listener who drifted rejoin by reading one line. Short
labels put the claim in the voice-over. Ask which the deck wants. The ghost-deck
check reads only the titles in order: they should tell the story.

The deck is one argument. Pick the claim the slot can defend and move the rest
to the backup slides. One idea per slide. A slide with two jobs is usually also
the slide that overflows.

Cite on the slide where the borrowed thing appears, in the `.aside-note` at
the bottom. Never type a reference by hand. Every author, year, and title comes
out of a verified `.bib` (`references/citations.md`), and the `bibcheck` skill
audits it before the talk.

Never change a number or the author's wording on your own. Copy every number
from the paper, the analysis output, or the author's message, and name the
source in the slide's comment. When a number disagrees with its source, report
it.

## Front matter

Adopt the format once per deck directory:

```bash
cd <deck dir>
quarto add "$SLIDES" --no-prompt          # installs _extensions/editorial/ (and the others)
cp -R "$SLIDES"/mathjax "$SLIDES"/fonts .
```

```yaml
format: editorial-revealjs
bibliography: talk-refs.bib   # only on a deck that cites
```

The format carries the whole recipe, and `_extension.yml` says why each line is
there:

- a 1280x720 canvas with no margin, so every length in the theme is a canvas
  pixel;
- no slide transition and no fragment fade (reveals are instant);
- reveal's progress bar, slide number, menu, and controls off, with the
  progress line and a page number drawn by `after.html`;
- `incremental: false` and `auto-stage: false`, so clicks are planned by hand;
- `back-returns: fixed`, so Back returns to the click the jump came from;
- `stage-slide.lua` with `citeproc: false` and a reference budget measured for
  this theme;
- self-hosted MathJax 2.7.9, including `extensions/TeX/HTML.js` for `\class`.

The `mathjax/` and `fonts/` copies are why the deck needs no network. The page
loads them relative to the rendered HTML. Writing `html-math-method: mathjax`
as a bare string instead loads MathJax from a CDN at display time.

Unknown or misspelled YAML keys are ignored and the render still exits 0.
`quarto inspect deck.qmd` prints the resolved format.

## Math and macros

Define macros as bare raw LaTeX on a hidden slide at the top, as the template
does (`## Notation {visibility="hidden"}`). Wrapping them in `$$ ... $$` fails:
pandoc consumes them and every later use errors.

Write the symbol list in a comment at the top of the deck before any figure is
drawn. One symbol means one quantity on every slide and figure.

`\class{name}{...}` puts a CSS class on a term. The theme defines four:

| Class | For |
|---|---|
| `\class{ac}{...}` | The term the slide is about, in the accent. |
| `\class{bl}{...}` | A second term role, only when two roles must be told apart. |
| `\class{gr}{...}` | A constant or absorber that does not change the story, in gray, moved to the end. |
| `\class{hid}{...}` | A term not yet entered: laid out exactly and drawn invisibly. |

Use one colour per term role on every equation and figure of the deck. Without
`mathjax/extensions/TeX/HTML.js` in the deck's copy every `\class` term renders
red, so copy `mathjax/` from `$SLIDES`, never from an older deck.

Display math is set at 36px through its container and left-aligned. Do not set
`font-size` on `span.MathJax`: it overrides the size MathJax measured with and
leaves a gap after inline math.

## Theme classes

All defined in `editorial.scss`. Use Quarto div and span syntax.

| Class | For |
|---|---|
| `.section-break` | On a heading: the full-bleed accent section slide. One word or a short phrase, no number. |
| `.closing-slide` | On the Takeaways heading: numbered claims, then a `.contact` div. The progress line is full here. |
| `.appendix-break` | On the Backup heading. Its body is a short list of the backup slides' titles. |
| `.references-break`, `.references` | The references divider and the list (the filter paginates the list). |
| `.em` | The phrase the room keeps, in the accent. Once or twice per slide. |
| `.gray` (alias `.dim`) | An aside said in passing. |
| `.aside-note` | A source line or caveat, pinned above the bottom edge in small gray type. |
| `.result` | A framed estimate with a `[Estimate]{.label}` span first. |
| `.assumption` `.proposition` `.theorem` `.lemma` `.definition` | Formal statements on the tint, with a `[Proposition 1.]{.label}` span. |
| `.proof` | Gray, with a QED square on its last element. |
| `.takeaway` | The slide's one claim, on a hairline under the content. |
| `.regtable` | On a div around a regression table: every second body row (the standard errors) is gray. |
| `.spec` | A wide specification table, set smaller. |
| `.num` | Right-align a numeric column. |
| `.eq-stack`, `.eq-layer` | The step equation (`references/staging.md`). |
| `.chain` | On an `.eq-stack`: a derivation chain with a label column, math at 28px. |
| `.eq-notes` | Notes under an equation, one per line, with an accent bar drawn per visible line. |
| `.swap`, `.swap-in` | Swap one block for another in place. |
| `.dim-past` | On a list built item by item: earlier items gray as the next arrives. |
| `.li-dim` | On a fragment: gray only while its own click is the current one. |
| `.highlight-accent` | A fragment that turns a phrase to the accent on cue. |
| `.reserve`, `.ph` | Reserved space, invisible (Beamer's `\invisible`). |
| `.tight-math` | On a slide or div: smaller display-math margins. |
| `.shrink-98` to `.shrink-85` | On a heading: scale the body under the rule (overflow). |
| `.jump`, `.jump-back` | Buttons to a backup slide and back (`references/staging.md`). |
| `.btn-corner` | A div that puts a button in the bottom-right corner. |
| `.stage` | On a heading: let the filter stage this slide block by block. |

## Build and verify

The render exits 0 whether or not the deck is presentable, so run the gates
every time and again before the talk. Put the sequence in a `build.sh` next to
the deck on day one.

```bash
cd <deck dir>
quarto render deck.qmd 2>&1 | tee /tmp/render.log
grep '\[WARNING\]' /tmp/render.log           # duplicate ids and unclosed divs warn here

node "$SLIDES"/deck-check.mjs fit deck.html  # must print DECK-FITS: YES
node "$SLIDES"/stage-check.mjs deck.html     # must print STEP-0-CLEAN: YES
```

The fit gate visits every slide with every fragment shown and fails on
overflow, excess width, missing or crushed images, unrendered math, a dangling
`.jump` target, and an unpaginated bibliography. It does not see two absolutely
positioned blocks touching (an `.aside-note` under a long body), so look at the
slides too.

On this format `stage-check.mjs` reports each slide as `hand-planned`. It does
not require the title alone at click 0, because a hand-planned slide may open
with content. It walks every click and fails a click that changes nothing on
screen (`DEAD STEP`). A `{.stage}` slide is still held to the title-alone rule.

Section headings get auto ids from their words, so a section called "Setting"
and a slide with `{#setting}` collide. The render warns `Duplicate identifier`;
rename the slide id.

### Looking at the slides

Read the pictures, not the markup. Export the slide under edit with decktape at
the canvas size and look at it:

```bash
npx -y decktape@latest reveal --size 1280x720 --slides 9 "file://$PWD/deck.html" one.pdf
```

Check every click of a slide that builds, and check that nothing on screen moves
between clicks or between consecutive slides that share content.

### Handout

decktape gives one page per slide with every fragment shown. Hyperlinks do not
survive PDF export: buttons print as small outlined labels, so keep the backup
slides reachable by page number too.

## Traps

- Overflow, missing images, and unknown YAML keys all fail at exit 0. Run the
  fit gate.
- A bare macro block before the first `##` becomes a blank counted slide. Put
  it on a `{visibility="hidden"}` slide.
- A chunk label that starts with `fig-` adds a "Figure 1" caption under the
  exhibit, with or without `fig-cap`. Use a plain label on a talk figure.
- `\phantom` changes the spacing of the relation next to it. Hide a term with
  `\class{hid}`.
- A `<style>` block parked on a hidden slide is dropped silently. Deck CSS goes
  in its own file loaded with `include-in-header:`.
- reveal renumbers fragment indices from 0 in the order they sort, so a
  `fragment-index=2` with no index 1 on the slide behaves as the first click.
  Number the clicks without gaps.
- An `.incremental` list puts fragments with no index on its items, and reveal
  sorts those after every indexed fragment. Do not mix an `.incremental` list
  with indexed fragments on one slide.
- reveal's own `.reveal section img` rule outranks a `.myclass img` rule, so a
  nested figure ignores your sizing. Set `fig-width` and `fig-height`, or an
  inline `style="height:..."`.
- Do not switch the math engine to `mathml` or `plain`. Chrome misaligns
  `aligned` blocks under MathML, and `plain` strips the markup.
