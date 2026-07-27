# House expectations (stub)

Your house style lives here: the closing-slide contact block the review checks
for, density calibration by deck type, your settled design decisions, the
author line. The skill reads this file for expected values; fill it in. The
private original carried the author's own versions and is not published.

## The author line

The exact `author:` front matter every deck should carry.

## The closing slide

What your research talks end on (for the example decks: a thank-you slide with
an invitation, a contact block, and a QR slot, ahead of the appendix divider,
references last) and what your lectures end on instead. Include the greps the
review runs to confirm presence and position, e.g.:

```bash
grep -nE '\.thanks-slide|\.closing-slide' deck.qmd
grep -nE 'mailto:' deck.qmd
grep -niE 'qr' deck.qmd
grep -nE '\.appendix-break|\.references-break|\{\.appendix' deck.qmd
```

## Text density, by deck type

Your targets per deck type, stated so a reviewer cannot apply the talk
standard to a lecture or the reverse. The operative question is whether the
text on screen overwhelms the audience, never a word count; `slides[].words`
from the probe describes a slide and is not a threshold.

## Settled design decisions

The list of choices a reviewer must not relitigate (for the example decks:
assertion titles, staged reveals, the numbered dividers and segmented progress
bar, the appendix outside the bar). A reviewer proposing a change to a settled
decision has produced a false finding; drop it in synthesis.
