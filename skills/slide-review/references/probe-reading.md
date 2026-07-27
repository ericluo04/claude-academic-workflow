# Reading the probe

How to read `probe.json` and its `figures` array, produced in stage 4 by
`scripts/probe.js` and `scripts/figure-ground.js`, and the ink the deck is
supposed to carry.

## What the deck is supposed to look like

The reference is the theme's own palette table, documented in the head of its
scss: each ink with its measured WCAG ratio against the ground, and a named
list of low-ratio values allowed for decoration only. The probe computes its
own ratios against the composited background, and the probe's number is the one
that goes in the report. A disagreement inside a point or so is rounding.
Anything larger is a finding, because it means the element is not sitting on
the background the theme intended.

The starter theme, which both example decks render on, is dark ink on a warm
paper ground `#faf7f2`:

| Role | Hex | Ratio | Where it belongs |
|---|---|---|---|
| body | `#33302b` | 12.3:1 | every run of text |
| muted | `#6b6157` | 5.7:1 | footer, slide number, `figcaption`, `.dim`, dates |
| quiet emphasis | `#4f463c` | 8.6:1 | h3, blockquotes, `.ygray`, citations, appendix headings |
| accent | `#7d3a5e` | 7.5:1 | links, `li::marker`, block labels, jump buttons |
| dark accent | `#54263f` | 11.4:1 | inline code, `.yblue`, `.takeaway` |
| good | `#38684a` | 6.0:1 | `.ygreen` |
| warning | `#7d5b12` | 5.8:1 | `.yamber` |
| bad | `#9c3b26` | 6.4:1 | `.yred`, the `.warning` label |
| decoration only | `#d9bccb` | 1.6:1 | hover underlines; never text |
| decoration only | `#ddd6c9` | 1.4:1 | hairlines and block frames; never text |

Everything the starter theme uses as text also holds 4.5:1 on its `#f2ede3`
panel tint, so a block ground never turns a passing ink into a failing one. The
two decoration rows are where a starter deck fails contrast: either value
carrying text is a finding. A deck on your own theme gets read against your
table the same way, and a dark theme's table lists ratios against its
near-black ground plus which low-ratio values are allowed as large marks (the
dark sections below).

The class inventory is the README's `Theme classes` section. Three visual facts
the review needs sit outside it, given here for the starter theme: the block
family (`.result`, the teaching boxes) is a hairline frame on the panel tint
with a small-caps label carrying the class's colour, and a block without a
label is a style choice, not a finding; the jump buttons are accent-coloured
links with a standing underline, joining the muted scheme on `.appendix` and
`.references` slides; `.prompt` is centred between double rules, `.aside-note`
sits behind a left rule, and `ol.steps` is a spaced numbered list.

## Font sizes, contrast, math, citations

Nothing here measures overflow. Stage 3 owns that, and its numbers go into the report unaltered.

`tiny.pctH` is the rendered font size as a percent of the 700px canvas height, which is the only
projector-independent way to talk about legibility. Thresholds, calibrated against the smallest sizes
the starter theme sets deliberately (figcaption 0.6em = 18px = 2.6%, table 0.72em = 21.6px = 3.1%):

| pctH | Deck px at H=700 | Severity |
|---|---|---|
| under 1.7% | under 12 | CRITICAL, not readable projected |
| 1.7 to 2.3% | 12 to 16 | MAJOR |
| 2.3 to 2.7% | 16 to 19 | MINOR, hard from the back row |
| 2.7% and up | 19 and up | fine |

A `div.csl-entry` reference list sits in the MINOR band by theme default (18px on the starter
theme). That is a real finding on a
slide the audience is meant to read and a non-finding on a parked bibliography, so say which it is.

`lowContrast.ratio` is a WCAG ratio against the composited background, alpha layers flattened. Under
3.0 is CRITICAL (a washed-out projector erases it), 3.0 to 4.5 is MAJOR. The ratio is symmetric, so
those two thresholds hold on both deck types; what changes is the ground the ratio is taken against,
and therefore which colours fail. On a light deck the failures are pale inks washing out: the
starter theme's two decoration values measure 1.4:1 and 1.6:1 on its paper ground, which is why the
theme confines them to hairlines and hover underlines. On a dark deck the failures are dark ink
drowning in the ground, and it is almost always ink that came from a light deck: measured on one
designed dark theme, a light theme's charcoal body ink landed at 1.02:1, its navy accent at 1.4:1,
and its dark red at 2.2:1, while the values the dark theme's own table held in the 3:1 to 4:1 band
were allowed for thick rules and large marks and forbidden as text.

Alpha compositing is what makes tinted-block numbers come out right, so keep it. A theme that
grounds its blocks in an rgba accent tint over the deck ground (the usual dark-theme pattern; the
starter theme uses an opaque panel tint instead) composites to something barely lighter than the
ground itself, and the label inside is the full accent. Measured that way, label and body text both
clear their thresholds. Measured against an assumed white page the same label reads near 1.5:1, and
the probe would report every teaching block in the deck as CRITICAL.

`mathFailures` has four kinds. Which ones can fire depends on the engine, which `deck.engine` reports:
`katex` for the offline variant, `mathjax` for the default. Verified against MathJax 4.1.3 as Quarto
loads it, and KaTeX 0.16:

| kind | What the engine did | Selector |
|---|---|---|
| `parse-error` | KaTeX: whole expression failed (unbalanced brace, unknown environment). Renders the raw TeX in red, message in `title`. | `.katex-error` |
| `mathjax-error` | MathJax: expression failed. Renders the message itself, red on yellow (`rgb(255, 0, 0)` on `rgb(255, 255, 0)`), inside `mjx-merror`. | `mjx-merror` |
| `undefined-macro` | Undefined control sequence. The rest of the expression renders fine and the bad command alone is painted red, with no error node anywhere. KaTeX uses `#cc0000`, MathJax uses `red`. | computed color `rgb(204, 0, 0)` or `rgb(255, 0, 0)`, outermost red element only |
| `raw-tex-visible` | A backslash command survived into the visual layer. | `\\[a-zA-Z]{2,}` in `.katex-html` or `mjx-math` text |

Verified under KaTeX: `\frac{1}{2` and `\begin{bogus}` produce `.katex-error` with a parse message;
`\frobenius{X}` and `\notarealmacro{z}` produce zero `.katex-error` nodes and red tokens instead.
Checking only `.katex-error` misses every mistyped or undefined macro, which is the common case in a
deck ported from Beamer where the author's preamble macros no longer exist.

Verified under MathJax, and the split is different: `\begin{bogus}` is the only one of the four that
produces `mjx-merror`, and its message is the element's own text ("Unknown environment 'bogus'") with
`title` unset, so read `title` first and fall back to the text. `\frobenius{X}`,
`\notarealmacro{z}`, and `\undefinedmacro` produce no `mjx-merror` at all; they render the literal
command in red inside `mjx-math`, which is what the other two kinds catch. MathJax puts every glyph in
its own element, so the scan keeps the outermost red one and reports `\frobenius` once instead of
eleven times, once per letter. `\frac{1}{2` with the brace
left open produces no `mjx-container` whatsoever, and the raw `\(\frac{1}{2\)` stays in the paragraph
as plain text, so nothing in this probe sees it. That case belongs to stage 3's `UNRENDERED MATH`
token, which is why both signals are needed. All four kinds are CRITICAL.

Scope the raw-TeX regex to the visual element and never to the whole subtree. Under KaTeX,
`.katex-mathml` carries an `<annotation>` with the original TeX, so a `.katex` subtree regex flags
every correct equation. MathJax has the same trap: when assistive MathML is on, `mjx-container` also
holds a hidden `<mjx-assistive-mml>` copy of the expression, so match `mjx-math` and not
`mjx-container`. On the sample lecture deck the assistive copy is absent (17 containers, 0
`mjx-assistive-mml`), which is exactly the case where a whole-container regex would look safe and
then fire on the next deck that has it.

`citations` lists keys that are unresolved. Verified shape for a bad key:
`{key: "ghostcite2019", keyVisible: true, hasEntry: false, shown: "(ghostcite2019?)"}`. Pandoc prints
the key with a trailing `?` in bold, so `keyVisible` true means the audience sees the raw key. CRITICAL.
`hasEntry` false with `keyVisible` false only means the deck has no bibliography slide, which is fine
if deliberate.


## Figure grounds

An image cannot be measured in the main probe's pass. Reveal lazy-loads slide images from `data-src`
and only assigns `src` when the slide comes into view, so off-screen `<img>` elements report
`naturalWidth` 0 and a zero-size box, and forcing the section visible does not change that. Verified
on `w03-evaluation.html`, where all three figures read as unloaded in the main probe.
`scripts/figure-ground.js` loads each one into a detached `Image` and samples the border band
instead. Append the result to `$RUN/probe.json` as `figures`. The image is drawn into a 48x48 canvas and
`edgeLum` is the mean relative luminance of that canvas's outer 4px ring, so the band is about the
outer 8% of the figure on each side. Pixels under 0.5 alpha are skipped, so a transparent PNG edge does
not count. The `lightbox` rule is one-sided on purpose: an image lighter than the ground by 0.35 is a
finding, and one darker than the ground is not, since a dark plot panel on a light deck is a design
choice. The same rule is then correct on both deck types with no branch. Verified on light and dark
renders of the example decks: against a light ground near 1.0 the figures flag nothing, and against
a dark ground of luminance 0.011 three white-panel figures measuring 0.74 to 0.98 all flag.

`note` carrying `unmeasurable` means the canvas read was refused. Say so in the report and fall back
to human review of the PNG for those figures. Do not describe an unmeasured figure as measured.

### Reading the probe

## Dark deck defects

Four classes that only apply when `deck.dark` is true. Skip all four on a light deck.

Pure white body text. `whiteBody` lists elements computing to `rgb(255, 255, 255)` that are not
headings. On a projector, pure white on near-black blooms, and the halation eats the letterforms of
running text at body size. MAJOR, with the fix being the theme's own off-white body ink. Headings,
`strong`, `.prompt`,
`.hero`, and `.label` are exempt in the selector because a dark theme may set pure white there on
purpose.
The common real cause is a `background-color` attribute on a slide: reveal adds `has-dark-background`
and Quarto's `$dark-bg-text-color` then repaints that slide's body text pure white. Verified on a
doctored copy of the sample lecture, where a dark navy `background-color` attribute on a
`{.section-break}` heading repaints that slide's paragraph to `rgb(255, 255, 255)`. Check
`slides[].bgAttr` before blaming the author's markup.

A figure that is a lightbox. `figures[].lightbox` true means the image's border band is lighter than
the slide ground by more than 0.35 in relative luminance, which on a dark deck is a white panel
glowing on a dark wall. MAJOR, and the fix is to redraw the exhibit on the deck ground. If `note` says
`unmeasurable`, say that the pixels could not be read and that those figures went to human review, and
name the slides. Never write a luminance number you did not measure.

Ink copied from an older light deck. A saturated brand colour that reads as authority on white can
measure under 1.5:1 on a near-black ground, which is invisible; a designed dark theme's table names
its own inks and the ratios they hold. Stray ink arrives in a deck two ways, so check both: the
probe reports it as a `lowContrast` entry with the offending `fg`, and the source carries it as a
literal hex. CRITICAL either way.

```bash
grep -nE '#[0-9a-fA-F]{6}|background-color="#|style="[^"]*color: *#' deck.qmd
```

Compare every hex that grep finds against the theme's palette table. That also catches the divider
case from stage 0, since a hard-coded `background-color` on a `{.section-break}` heading is the most
common way stray ink gets into a lecture deck.

A light code card. The syntax theme paints the code block's own background, so a light
`highlight-style` puts a white card in the middle of a dark slide. A dark deck expects a dark
companion style (`a11y-dark`), which its theme's pinned code-block ground assumes.
Stage 0's front matter grep already has the value: anything else, or nothing at all, is MAJOR with
the fix being `highlight-style: a11y-dark`. Do not judge it by the name alone, because Quarto swaps
light and dark variants for some styles. `lightPanel` is the measurement, and it flags any element
whose composited background is lighter than the ground by more than 0.35, so a white code card shows
up there with its luminance. `.demo-tag` is exempt where the theme sets its chip deliberately. A
`lightPanel` hit outside a code block usually means a callout or table was copied from a light deck
with its light fill attached.
