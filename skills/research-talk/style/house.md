# House style (stub)

Your house style lives here: your palette rationale, closing-slide wording and
contact block, density calibration, author line, button diction. The skill
reads this file for values; fill it in. The private original carried the
author's own versions of the sections below and is not published.

## The theme's register

One paragraph on what your theme is for and how loud it is allowed to be. The
shipped Editorial theme is quiet on purpose: a white page, one vermilion
accent used once or twice per slide, gray for asides, and accent fills only on
the section slides. If you restyle it, the head of `editorial.scss` carries the
reasoning per class.

## Density calibration

Your anchor for how much text a slide carries. Useful forms: an average bullet
count from decks you already liked, a words-per-slide ceiling, or a named
sample deck that sits at the bound you want. Quarto's own reveal demo runs
about 30 words a slide and is a reasonable public reference point.

## The author line

`author: "Your Name"`, in the exact form you want on every title slide, plus
`institute:` if you use one.

## Dates

The format sets `date-format: long` (September 18, 2026). Change it here if
you want another form.

## The Takeaways slide

The wording of your contact line, the `.contact` div at the bottom of the
Takeaways slide: your email, your site, and where the paper and the
replication files live, in the order you want them. The mechanics are in
`../references/closing-slide.md`; the words are yours.

## Button labels

Your diction for `.jump` labels. A workable default: name the destination in
one or two words, no terminal period, and leave `[]{.jump-back}` empty so
the filter renders it as Back.

## Section words

Your diction for the section slides: one word or a short phrase, no number
("Setting", "Identification", "Estimates", "Mechanism", "Policy").
