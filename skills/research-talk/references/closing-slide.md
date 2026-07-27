# The closing thank-you slide

Every academic talk ends on one. It is the last slide of the main body: it comes
after the final content section, which is the conclusion slide, and before the
`{.appendix-break}` divider, with the appendix after that and the references
last of all. It carries the invitation to ask, the two addresses, and a QR code
to the paper, and it is what the room looks at while the questions come; one
arrow back puts the claim on screen again when a question needs it.

It is a terminal slide, so it has to read as the talk having ended: no frame
title, and everything centred on both axes. The wording and the addresses are
yours and live in `../style/house.md`. The shape:

```markdown
## {.thanks-slide .center .no-stage}

::: {.thanks-title}
<closing line>
:::

::: {.thanks-invite}
<invitation line>
:::

::: {.thanks-contact}
[<email>](mailto:<email>)

[<website>](https://<website>)
:::

::: {.qr-slot}
Paper
:::
```

The email and the website go on their own lines as live links, the email
opening a compose window and the site opening the page. The example theme sets
both in its mono face; yours styles `.thanks-contact` however it likes.

The heading is empty on purpose and all three classes are load-bearing.

| class | what it does |
|---|---|
| `.thanks-slide` | The archetype. The theme sizes and spaces the four blocks off it. It also tells `stage-check.mjs` that the slide carries no argument: the gate asserts that a content slide shows nothing but its heading at step 0 and carries at least one fragment, and a titleless unstaged slide fails both halves, so the gate classifies it as `closing` and skips it. |
| `.center` | reveal's per-slide vertical centring, which is what `\vfill ... \vfill` means. reveal writes an inline `top` on the section and Quarto's `.reveal .slide:not(.center) { height: 100% }` steps aside for the same class, so the slide shrink-wraps its content and floats to the middle. The print view runs the same test, so the handout page is centred too. |
| `.no-stage` | Turns `stage-slide.lua` off for this one slide, so it arrives whole. |

Pandoc emits a real empty `<h2>` for a titleless heading, which would otherwise
paint the blue heading mark across the top. Both themes hide it with
`section > h2:empty { display: none }`, so any titleless archetype gets the
same treatment, including the `## {.center}` plus `.r-fit-text` full-bleed
quote slide (README, "Things that will silently break the deck").

An earlier build borrowed `.title-slide` here to get past the gate, on the
reasoning that no rule in the compiled stylesheet matches it without an `h1` or
`.subtitle` child. That held only for as long as nobody wrote such a rule.
`.thanks-slide` is a named case in the gate now, so do not add `.title-slide`
back.

## Rhythm

The theme owns the vertical rhythm between the four blocks; the gaps are house
values, so they live in your theme, and the constraint that disciplines them is
the fit gate. The QR slot is large, so the gaps have to be tighter than a
paper-page instinct suggests: on the example theme the whole slide measures
649px at 1050x700, and reveal writes `top: 25.5px`, so it floats with air above
and below. Set the block margins in the theme (Quarto's default `<p>` margin
must go to zero on this slide or the centring silently fails; the example
theme's compiled CSS shows the fix).

Nothing on the slide is staged and nothing should be. The argument is over, and
making the room watch an email address arrive is a keypress spent on nothing.
`stage-check.mjs` reports the slide as `closing` and skips it.

## The QR slot

`.qr-slot` renders a 320px dashed placeholder square with its label under it,
so the slide reads as finished before the code exists. Fill it by adding the
image above the label, with a blank line between, and keep the label:

```markdown
::: {.qr-slot}
![](qr.png)

Paper
:::
```

The slot drops its dashed placeholder border on its own through `:has(img)`
once an image is present, and the placeholder was already the image's
footprint, so nothing else on the slide moves: measured both ways, 649px tall
with 25.5px of air. Generate the code from the paper's landing page or its PDF.
Quarto's auto-stretch leaves the image alone, because it hoists only out of a
`<p>`, a `div.quarto-figure`, a `div.cell`, or a div that opted in with
`.stretch`, and `.qr-slot` is none of those.

Export the code between 640 and 1199px square, and 800 is a good default. The
range comes out of the gate's own arithmetic. `deck-check.mjs fit` flags an
image whose natural width is 1200px or more AND which renders under 600px,
reading it as a figure auto-stretch crushed. The slot pins the rendered width
to 320px, which the gate sees as 274px after reveal's canvas transform, so the
second half of that test is always true here and the natural width is the only
lever: 1199px passes, 1200px fails, and there is nothing in between to tune.
Measured with a QR-sized PNG in the slot: at 800px square the deck gives
`DECK-FITS: YES` and exit 0, and the same code at 1200px square gives
`19 FIG SHRUNK TO 274px` and exit 1. The floor is the slot itself, since a
code under 320px is upscaled into blur, and a projector scales the canvas up,
so twice the slot is the practical bottom of the range. A QR code is square
line art and loses nothing at 800px.

## How the bar and the numbers end

The theme paints reveal's progress bar as the mid blue filled against a faint
warm-gray track, cut into one segment per `.section-break` so a glance says
which block of the talk this is; the cuts appear only in a deck with two or
more dividers. The closing slide takes no numbered section disc and cuts the
bar no new segment, because both belong to `.section-break` alone. It does
stay inside the progress denominator, so this is where the bar reads full.

The appendix and the references are both outside the bar: neither is in the
denominator and neither gets a segment, so the bar is full at your last main
slide and stays full through both. A twelve-slide appendix plus three slides
of references would otherwise leave the closing slide at about half and tell
the room you were nowhere near done. This needs nothing in the deck beyond the
two dividers those sections already have. Measured on the sample talk (19
main, 4 appendix, 3 references): 94.44% on the conclusion slide, `scaleX(1)`
on the thank-you slide, and flat at 100% across all seven slides behind it.
The fill creeps within a slide, because reveal weights the fragments already
shown, but the last step is reserved for the closing slide: the fill is capped
at `(last - 1) / last`, so the conclusion slide holds at 94.44% however many
of its own blocks are up instead of creeping to 99.44% and reading as finished
a slide early.

The slide number is cut at the same place, off the same boundary, so the two
cannot disagree. Out of the box the `t` in `slide-number: c/t` is every slide
in the document, so a 19-slide argument with an appendix and a reference list
behind it opens at 1/26 and closes at 19/26, which reads as two thirds of the
way through a talk that is over. The filter's script hands reveal a
`slideNumber` function running off the same boundary the progress bar uses, so
the main body counts 1/19 to 19/19 and ends here, and the appendix and the
references share one run of their own behind it, 1/7 to 7/7. Measured on the
sample talk, correct on first paint with no navigation. The handout is on a
different path and is untouched: reveal's print view builds its own
`.slide-number-pdf` per page from a running counter and never asks for a
number, so a printed page carries a bare sequential number with no
denominator. How the takeover works (the detached span, `pastMain`,
`isClosing`, click-to-seek) is in the README under "The progress bar".

A teaching lecture gets no thank-you slide. `teaching-lecture` closes on the
synthesis pair (the completed agenda, then the key idea with a line naming
what next week does), and the students already have the email and the deck
from the course site.
