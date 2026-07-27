# Staging the reveal

Content should arrive as you say it. Beamer's `\pause` is a hard cut because it
renders separate pages; reveal fades in place, and both themes slow every
fragment variant to 0.45s on a decelerating curve and give the plain
`.fragment` a 0.3em rise, so a line settles onto the slide instead of blinking
on.

`incremental: true` (the format sets it) stages every list one bullet at a
time, which is the pacing a seminar wants. Tag the exceptions, which are
usually the agenda and the references:

```markdown
::: {.nonincremental}
- Setting and data
- Identification
- Results
:::
```

## What the filter stages

`incremental: true` stages lists and nothing else, so a slide holding a
paragraph and a callout lands half-built: the prose and the box arrive with the
heading while only the bullets wait. The format's `stage-slide.lua` fixes
that. It stages every top-level block on a content slide, so the slide opens as
its title alone and the blocks arrive top to bottom, one keypress each.
Nothing in the markdown changes.

The invariant is that the title always appears alone, on every content slide,
including a slide whose only content is a figure. The exemptions are the
divider classes, which carry nothing but a title anyway, a slide you opted out
with `{.no-stage}`, and material that is not content: speaker notes, the
footer, a `{visibility="hidden"}` slide. The filter's internals are in the
README under "Staging: the title appears alone, always"; below is what to know
when writing a slide.

A figure cell is staged on the image itself rather than in a wrapper, because
Quarto's auto-stretch refuses to size an image that has a `.fragment` ancestor
and would leave a wrapped one behind when it hoists the image up to the
section. So the figure both waits for its keypress and fills the slide, at the
same size it had before it was staged. The exception is a cell holding more
than the image, an echoed chunk or a second figure, where the whole cell is
wrapped and the stretch is lost; the figure then renders at its authored width
and the fit gate is what tells you whether that fits.

A caption is not that exception, as long as the cell is labelled for
cross-reference. With `#| label: fig-something` and `#| fig-cap:`, the figure
stays stretched and the theme rides the caption on the image's own fragment
state, so the figure and its caption arrive together on one keypress and the
caption prints in the handout. Measured on the sample talk, slide 7: two
fragments on the slide (the figure and the source note), the caption hidden at
step 0 and visible after one press, and the figure still stretched at 813x427.
A `fig-cap` on a cell whose label does NOT start with `fig-` is the losing
case: the filter has to wrap the cell and the stretch goes (README, "Figures
and tables", has the mechanism).

A table is always one beat, and its cells are never staged. That covers a
table written as raw `<table>` HTML, which pandoc parses into one block per
tag; the filter collapses the whole raw run into a single fragment.

A note that annotates the block above it arrives on the same beat as that
block, so it costs no keypress. That covers `.aside-note`, `.citation`,
`.cite`, `.caption`, and `.with-previous`, which is the opt-in for anything
else. A source line under a list arrives with the last bullet, and one under a
figure arrives with the figure. The single case where it costs a keypress of
its own is a note under a figure on a slide that also has a staged list, where
the filter has no index to group them with.

`.together` makes a group of blocks one beat, for the two paragraphs or the
paragraph plus box that should land at once. A list inside it stops staging
itself item by item:

```markdown
::: {.together}
The level effect is a wash.

The interaction is not.
:::
```

`{.no-stage}` on a heading turns the whole thing off for one slide, for the
rare slide that should arrive complete.

## Fragment indices

One caveat, which is why the filter numbers some slides and not others. reveal
sorts every fragment carrying `data-fragment-index` ahead of every fragment
that has none, and pandoc writes `<li class="fragment">` with no index. So
numbering the blocks on a slide that also has a staged list would push its
bullets to the end of the slide. Verified: a slide of paragraph, list,
paragraph reveals as 0, 2, 3, 1. The filter therefore adds explicit indices
only when it can account for every fragment on the slide, and falls back to
document order otherwise. Your own `fragment-index` is never touched, so the
manual form below keeps working; just do not mix it with an incremental list
on the same slide.

`fragment-index` reorders the beats, and equal indices fire together, so an
annotation and the bullet it belongs to can arrive on one keypress. The
attribute is `fragment-index`; `data-fragment-index` is the reveal HTML
attribute and is not what Quarto reads:

```markdown
[0.29 log points]{.fragment fragment-index=1} in the top quartile,
[0.06 elsewhere]{.fragment fragment-index=1}.
```

## Variants and patterns

`.fade-in-then-semi-out` is the best variant for a talk. Each point stays
legible once the next arrives and recedes to 50%, so the audience keeps its
place in the list and still has the earlier lines to refer to:

```markdown
::: {.fragment .fade-in-then-semi-out}
Prices rise where search costs are high.
:::
```

Build a layered exhibit with `.r-stack` and `.fragment` children. Scatter,
then the fitted line, then the counterfactual, each on its own beat, and
nothing on the slide moves as they land:

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

Give each layer the same explicit `width`, since nothing inside an `.r-stack`
can be stretched and the layers have to agree or they will not sit on top of
each other. Mark every layer `.fragment`, including the base. Leave the base
plain and the filter wraps the whole stack instead, which still keeps it off
the title beat but spends a keypress before the overlays start.

`auto-animate` is for a thing that changes, not a thing that appears. Two
consecutive slides with the same heading and `auto-animate="true"` tween
between them, which is how an equation rearranges or an estimate moves in
place. The format sets `auto-animate-duration: 0.4`; reveal's 1.0 default is
long enough that you end up waiting on it mid-sentence.

A custom fragment class has to restore `opacity: 1; visibility: inherit` in
CSS, because reveal hides every fragment that is not `.custom`. The theme's
`.highlight-yale` does this already; a hand-rolled one that skips it never
appears.

## Jump buttons and beats

Wrap a `.jump` or `.jump-back` button in `::: {.with-previous}` so it keeps
the beat of the block above it. A bare paragraph holding a button is a block
like any other to the filter, and it would spend a keypress of its own;
`.with-previous` hands it the preceding block's fragment index instead, so the
button arrives with the note under the exhibit it belongs to. The jump lands
the appendix slide fully revealed, which is what you want with a hand up in
the third row.

Markup, placement after bordered blocks, right-alignment, the Back semantics
(exact slide and fragment step, one stored origin per deck), and the ways a
target silently breaks are in the README under "Jump buttons"; label diction
is in `../style/house.md`. Target ids prefixed `ap-` read well and stay clear
of the crossref prefixes Quarto claims (`#fig-`, `#tbl-`, `#eq-`, `#sec-`).

Measured on the sample talk: a button written as a sibling after an
`.aside-note` sits with the note's rule ending 5.8px above the button's box,
and the button's right edge lands on the slide's content right edge to the
pixel. The button owns a line the slide did not own before, so run the fit
gate after adding one. The theme takes the body leading off that line and
collapses the gap above it (measured on the talk: 31.7px of line where body
leading reserves 43.5px, and a 4.1px gap instead of 12px), but on a slide
already near the canvas that line is still what tips it over. Cut a sentence,
do not shrink the type.
