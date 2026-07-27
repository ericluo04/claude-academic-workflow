# Reading the probe

How to read `probe.json` and its `figures` array, produced in stage 4 by
`scripts/probe.js` and `scripts/figure-ground.js`, and the ink each theme is
supposed to carry.

## What each deck is supposed to look like

Light talk deck: ground `#ffffff`, ink `#1a1a1a`, headings and accent Yale blue `#00356b`. Body text
measures 17.4:1 and Yale blue 12.2:1, so the quiet grays are the only ink near the floor. `.dim`
(`#978d85`, 3.25:1 on white, verified on the sample talk deck) is where a talk deck fails contrast.

Dark lecture deck: ground `#1a1c1e`, raised surface `#24272a` for code cards, hairlines
`#33373b`. The ink, with the ratio against that ground:

| Role | Hex | Ratio | Where it belongs |
|---|---|---|---|
| body | `#e8e6e3` | 13.7:1 | every run of text |
| headings | `#ffffff` | 17.1:1 | h1 and h2, `.prompt`, `strong` |
| links, accent | `#63aaff` | 7.1:1 | links, `.yblue`, `.hero`, `li::marker` |
| pale accent | `#a8ceff` | 10.5:1 | h3, `em`, table headers, `.ypale` |
| inline code | `#ffa07a` | 8.6:1 | `code`, `.yred` |
| warning | `#f4c95d` | 10.9:1 | `.warning`, `.yamber` |
| example | `#7ec699` | 8.5:1 | `.example`, `.ygreen` |
| muted | `#9aa0a6` | 6.5:1 | footer, slide number, `figcaption`, `.ygray`, `.dim` |
| rules only | `#286dc0` | 3.3:1 | 4px heading rules and step circles, never text |
| appendix slate | `#6f7a85` | 3.9:1 | marks, rules, and rings on `.appendix` slides, never text |

Those are the theme file's own numbers. The probe computes its own against the composited
background, and the probe's number is the one that goes in the report. A disagreement inside a
point or so is rounding. Anything larger is a finding, because it means the element is not
sitting on the background the theme intended.

The class inventory both themes define is the README's `Theme classes` section. Three visual facts
the review needs sit outside it: the five teaching blocks are each a 5px accent rule plus
`rgba(accent, 0.10)` over the ground, one hue per block so the vocabulary is learnable across a
semester; the jump buttons are outlined links in the theme's accent, switching to the appendix
scheme's gray or slate on an `.appendix` slide; and each block takes a `[Label]{.label}` span
painted in the block's own accent, where a block without one is a style choice, not a finding.
Descriptors the README elides: `.prompt` is centred, `.aside-note` sits behind a left rule, and
`ol.steps` draws numbered circles.

## Font sizes, contrast, math, citations

Nothing here measures overflow. Stage 3 owns that, and its numbers go into the report unaltered.

`tiny.pctH` is the rendered font size as a percent of the 700px canvas height, which is the only
projector-independent way to talk about legibility. Thresholds, calibrated against the smallest sizes
the Yale themes set deliberately (figcaption 0.6em = 18px = 2.6%, table 0.72em = 21.6px = 3.1%):

| pctH | Deck px at H=700 | Severity |
|---|---|---|
| under 1.7% | under 12 | CRITICAL, not readable projected |
| 1.7 to 2.3% | 12 to 16 | MAJOR |
| 2.3 to 2.7% | 16 to 19 | MINOR, hard from the back row |
| 2.7% and up | 19 and up | fine |

A `div.csl-entry` reference list trips MAJOR at 14.3px by theme default. That is a real finding on a
slide the audience is meant to read and a non-finding on a parked bibliography, so say which it is.

`lowContrast.ratio` is a WCAG ratio against the composited background, alpha layers flattened. Under
3.0 is CRITICAL (a washed-out projector erases it), 3.0 to 4.5 is MAJOR. The ratio is symmetric, so
those two thresholds hold on both deck types; what changes is the ground the ratio is taken against,
and therefore which colours fail. On a talk deck the failures are pale grays washing out on white:
`.dim` `#978d85` and `$accent-amber` `#b8860b` both land at 3.25:1. On a lecture deck the failures are
dark ink drowning in `#1a1c1e`, and it is almost always ink that came from the light theme. Measured
against the dark ground: `#1a1a1a` 1.02:1, Yale blue `#00356b` 1.4:1, `$yale-gray-dark` `#4a4a4a`
1.93:1, `$accent-red` `#9b2226` 2.16:1, `$accent-green` `#16794c` 3.15:1, and `$yale-mid` `#286dc0`
3.3:1, which the theme allows for 4px rules and step circles and forbids as text.

Alpha compositing is what makes the dark numbers come out right, so keep it. The teaching blocks are
`rgba(accent, 0.10)` over the ground, which composites to something barely lighter than the ground
itself (`.keyidea` lands on `#212a34`), and the label inside is the full accent. Measured that way a
`.keyidea` label reads about 6.0:1 and its body text about 11.7:1, both fine. Measured against an
assumed white page the same label reads near 1.5:1, and the probe would report every teaching block
in the deck as CRITICAL.

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
instead. The image is drawn into a 48x48 canvas and
Append the result to `$RUN/probe.json` as `figures`. The image is drawn into a 48x48 canvas and
`edgeLum` is the mean relative luminance of that canvas's outer 4px ring, so the band is about the
outer 8% of the figure on each side. Pixels under 0.5 alpha are skipped, so a transparent PNG edge does
not count. The `lightbox` rule is one-sided on purpose: an image lighter than the ground by 0.35 is a
finding, and one darker than the ground is not, since a dark plot panel on a white deck is a design
choice. The same rule is then correct on both deck types with no branch. Verified: on the light talk
deck the two figures measure 0.935 and 0.939 against a ground of 1.0 and flag nothing; on the dark
lecture deck the three figures measure 0.966, 0.975, and 0.739 against a ground of 0.011 and all three
flag.

`note` carrying `unmeasurable` means the canvas read was refused. Say so in the report and fall back
to human review of the PNG for those figures. Do not describe an unmeasured figure as measured.

### Reading the probe

## Dark deck defects

Four classes that only apply when `deck.dark` is true. Skip all four on a talk deck.

Pure white body text. `whiteBody` lists elements computing to `rgb(255, 255, 255)` that are not
headings. On a projector, pure white on near-black blooms, and the halation eats the letterforms of
running text at body size. MAJOR, with the fix being `#e8e6e3`. Headings, `strong`, `.prompt`,
`.hero`, and `.label` are exempt in the selector because the theme sets pure white there on purpose.
The common real cause is a `background-color` attribute on a slide: reveal adds `has-dark-background`
and Quarto's `$dark-bg-text-color` then repaints that slide's body text pure white. Verified on a
doctored copy of the sample lecture, where `{.section-break background-color="#00356b"}` paints the
slide Yale blue and its paragraph computes to `rgb(255, 255, 255)`. Check `slides[].bgAttr` before
blaming the author's markup.

A figure that is a lightbox. `figures[].lightbox` true means the image's border band is lighter than
the slide ground by more than 0.35 in relative luminance, which on a dark deck is a white panel
glowing on a dark wall. MAJOR, and the fix is to redraw the exhibit on the deck ground. If `note` says
`unmeasurable`, say that the pixels could not be read and that those figures went to human review, and
name the slides. Never write a luminance number you did not measure.

Ink copied from an older light deck. Yale blue `#00356b` as text on `#1a1c1e` measures 1.4:1, which is
invisible, and the theme file says as much in its own comment. It arrives in a deck two ways, so check
both: the probe reports it as a `lowContrast` entry with `fg: "rgb(0, 53, 107)"`, and the source
carries it as a literal hex. CRITICAL either way.

```bash
grep -nE '#00356b|background-color="#|style="[^"]*color: *#' deck.qmd
```

That also catches the divider case from stage 0, since `{.section-break background-color="#00356b"}`
is the most common way the hex gets into a lecture deck.

A light code card. The syntax theme paints the code block's own background, so a light
`highlight-style` puts a white card in the middle of a dark slide. Lecture decks expect
`highlight-style: a11y-dark`, which is what the theme's pinned `$code-block-bg: #24272a` assumes.
Stage 0's front matter grep already has the value: anything else, or nothing at all, is MAJOR with
the fix being `highlight-style: a11y-dark`. Do not judge it by the name alone, because Quarto swaps
light and dark variants for some styles. `lightPanel` is the measurement, and it flags any element
whose composited background is lighter than the ground by more than 0.35, so a white code card shows
up there with its luminance. `.demo-tag` is exempt, since its green chip is deliberate. A
`lightPanel` hit outside a code block usually means a callout or table was copied from a talk deck
with its light fill attached.
