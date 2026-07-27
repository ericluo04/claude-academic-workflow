# Staging, animation, and the deck machinery

This is where a lecture deck earns its keep. Beamer's `\pause` is a hard cut
because it renders separate pages; reveal fades in place, and both themes slow
every fragment variant to 0.45s on a decelerating curve and give the plain
`.fragment` a 0.3em rise, so a line settles onto the slide instead of blinking
on. Content should arrive as you say it.

The invariant `stage-slide.lua` holds is that the title appears alone: nothing
but the heading is visible before you advance, on every content slide, including
a slide whose only content is a figure. Say what the slide is about, then bring
in the thing you are about to talk through. The exemptions, the addendum
classes, the fragment-index rules, and how a figure cell is staged on the image
itself are in the README under "Staging: the title appears alone, always". Two
consequences worth carrying while writing: a staged figure still fills the
slide, and an `.aside-note` under a block arrives on that block's beat rather
than costing a keypress of its own.

A container div is judged by what is inside it and not by its class name, so
`::: {.steps}` around a list that already stages itself costs no beat of its
own. `.together` is the one exception, since it means one beat by author
instruction. The rule used to be an allowlist of container classes with `.steps`
not on it, and the wrapper it added painted nothing while `visibility: hidden`
kept the items' layout boxes, so the first press on two slides of the sample
deck turned an empty box visible and the slide did not move. `stage-check.mjs`
now fails that as a dead step.

## Incremental lists, and the exceptions

`incremental: true` (set by the format) is the setting to start from, because
most lists in a lecture are a chain the student should walk down with you, and
it is fewer keystrokes than tagging each list. Tag the exceptions with
`::: {.nonincremental}`: the agenda, a reference list, and
any list the student needs whole to compare across (a taxonomy, a two-column
contrast), where staging just hides half of the comparison. A `.nonincremental`
list is still one beat of its own, so it arrives after the title rather than
with it.

```markdown
::: {.nonincremental}
- Bias
- Variance
- Irreducible noise
:::
```

## Fragment variants

`.fade-in-then-semi-out` is the best variant for a taught list. Each point stays
legible once the next arrives and recedes to 50%, so the student tracks position
in the list without losing the earlier lines:

```markdown
::: {.fragment .fade-in-then-semi-out}
A model gives you a posterior.
:::
```

The other variants worth using: plain `.fragment` for the answer after a
question, `.fade-up` for a punchline, `.highlight-yale` (a theme class) to turn
a term `#63aaff` on cue, `.semi-fade-out` to dim a line you have finished with
while keeping it readable. Avoid `.grow` and `.shrink`, which read as a
rendering bug from the back of a room, and avoid `.highlight-red`, whose
saturated red is both off-palette and the colour family this theme gives
`.question`.

A custom fragment class has to restore `opacity: 1; visibility: inherit` in
CSS, because reveal hides every fragment that is not `.custom`. The theme's
`.highlight-yale` does this already; a hand-rolled one that skips it never
appears at all.

## Layered exhibits with `.r-stack`

`.r-stack` with `.fragment` children is the right tool for a layered exhibit,
because nothing on the slide jumps as each layer lands. Scatter, then the fitted
line, then the counterfactual:

```markdown
::: {.r-stack}
::: {.fragment}
![](fig/scatter.png){width=900}
:::
::: {.fragment}
![](fig/scatter-fit.png){width=900}
:::
::: {.fragment}
![](fig/scatter-cf.png){width=900}
:::
:::
```

Give every layer the same explicit `width`. Nothing inside an `.r-stack` can be
stretched (see `references/figures-dark.md`), and layers at different sizes do
not sit on top of each other. Mark every layer `.fragment`, including the base:
leave the base plain and the filter wraps the whole stack instead, which still
keeps it off the title beat but spends a keypress before the overlays start.

## Ordering beats

`fragment-index` reorders the beats, and equal indices fire together, so an
annotation and the bullet it belongs to arrive on one keypress. The Quarto
attribute is `fragment-index`; `data-fragment-index` is the underlying reveal
HTML attribute and Quarto does not read it:

```markdown
[Same accuracy]{.fragment fragment-index=1},
[different consequences]{.fragment fragment-index=1}.
```

## `auto-animate` is for a thing that changes

`auto-animate` is for a thing that changes, not a thing that appears. Two
consecutive slides with the same heading and `auto-animate="true"` tween
between them, which is how you make a single quantity visibly move: a threshold
sliding from 0.50 to 0.09, an equation rearranging, a bar growing. The starter
template does the threshold. The format sets `auto-animate-duration: 0.4`; the
1.0 default is long enough that the class waits on it and so do you,
mid-sentence.

## The animation budget

Budget five to eight staged moments in a 75-minute deck beyond the incremental
lists. More and the class waits for the animation instead of the argument.
Hidden fragments still occupy layout space, so a staged slide cannot overflow at
the last step without overflowing at the first.

## The progress bar and the slide number

Students pace themselves off the bar, and "7 / 25" is what a student writes
down when they want to ask about a slide later. On this theme the bar is also
cut into one segment per section, so a glance says both how far the class has
gone and which block it is in: `stage-slide.lua` emits a script that reads the
divider positions off `Reveal.getSlides()` at load and hands them to the theme,
and it does that only when the deck has two or more `.section-break` dividers.
The bar mechanics (the takeover, the seek remap, the settled-read caveat) are in
the README under "The progress bar".

The same script rewrites the slide number, off the same boundary the bar uses,
so the two cannot disagree. Out of the box the `t` in `c/t` is every slide in
the document, so the sample lecture would open at 1/33 and reach its closing
slide at 25/33 with an appendix and a reference list still behind it. Instead
the class body counts 1/25 to 25/25 and ends on the `.closing-slide`, and the
appendix and the references share one run of their own after it, 1/8 to 8/8, one
denominator across both. Measured, and correct on first paint with no
navigation. The handout is on a different path and cannot be affected: reveal's
print view builds its own `.slide-number-pdf` per page from a running counter
and never asks for a number, so a printed page carries a bare sequential number
with no denominator.

The appendix and the references are both outside the bar. Neither is in the
denominator and neither gets a segment, so the bar is full at the last slide of
the class and stays full through both. A long appendix plus a page or two of
references would otherwise leave the closing slide at about half and tell the
room the class was nowhere near over, which is the opposite of what a pacing cue
is for. This needs nothing in the deck beyond the two dividers those sections
already have. Measured on the sample lecture (25 main slides, 5 appendix, 3
references): 95.83% one slide out, 100% on the `.closing-slide`, and 100% on
every slide after it. The 95.83% holds through that slide's own fragments,
because the fill is capped at `(last - 1) / last` and the last step of the bar
belongs to the closing slide.

## Jump buttons, measured on this theme

The button-writing rules (own line, after a bordered block and never inside one,
`.with-previous`, the silent target breakers) are in the README under "Jump
buttons"; the label diction is in `style/house.md`. What the lecture theme adds
is the measurement: on the sample lecture the note's rule ends 8.4px above the
button's box, and the button's right edge lands on the slide's content right
edge to the pixel. Out of the note the button also gets back the size this theme
designs it at, 21.1px instead of the roughly 15.2px an em inside an em compounds
to.

The button owns a line the slide did not own before, so run the fit gate after
adding one. The theme takes the body leading off that line and collapses the gap
above it (measured on the lecture: 35.3px of line where body leading reserves
49.3px, and a 6.8px gap instead of 16px), but on a slide already near the canvas
that line is still what tips it over. Cut a sentence, do not shrink the type.

## Vertical alignment and the heading gap

Content slides are top-aligned, which is Quarto's `center: false` default. The
theme used to force it with `top: 0 !important`; that rule is gone and must not
come back. It was redundant, and it silently killed title-slide centring,
because reveal centres the title slide by writing a normal inline `top` and an
`!important` author rule outranks an inline style.

With it gone, `{.center}` works per slide. Use it on any sparse slide (a hero
number, a single question, an assertion), which otherwise pools its whitespace
at the bottom and reads as half-finished:

```markdown
## {.center}

::: {.hero}
94%
:::
```

The heading mark under each `##` is 7rem wide and 4px thick. Tables sit flush
to the left text rail instead of being centred by reveal.

The gap between a heading and the first block under it lives in one place, the
mark's bottom margin (`1.6rem`, 25.6px measured), and the `h2` carries
`margin-bottom: 0` so there is no second margin to collapse into it. Turn that
one number if a deck wants more air; the previous arrangement had two competing
margins and the larger one won silently. Note that a `rem` in this theme is
16px: reveal sets its root size on `.reveal` and not on `html`, so `rem` is
canvas-absolute and has nothing to do with the 34px root.
