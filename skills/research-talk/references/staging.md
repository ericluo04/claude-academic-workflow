# Staging: clicks, the step equation, swaps, buttons, and Back

Content arrives as the speaker says it. On `editorial-revealjs` the author plans
every click by hand: the format sets `incremental: false` and `auto-stage:
false`, so nothing is a fragment unless the source says so. Reveals are instant
(no fade), as Beamer overlays are, because a fade pulls the eye to the motion.

`examples/research-talk/talk.qmd` has each pattern below in a slide that
renders and passes both gates. The slide ids are named with each pattern.

## The click map

Every slide that builds gets a click map in an HTML comment at its top. It
lists the clicks in the order the speaker will talk:

```markdown
## Prices move at adoption, and stay moved {#event-study}

<!-- Clicks: 0 title only; 1 the figure and the estimate; 2 the reading and the
     pre-trend test. -->
```

Write the map before the markup, then give each fragment an explicit
`fragment-index` that matches it. When the order changes, edit the map and the
indices together.

The rules for a click map:

1. One click per idea, in speaking order.
2. Group what belongs together into one click. An image and its caption, or two
   things that are compared, arrive together.
3. A slide that opens a new visual build may start on its title alone.
4. A continuation slide arrives whole. The second and later slides of a run
   show their content on entry.
5. A button arrives on the click of the thing it qualifies.
6. Nothing already on screen moves when something new arrives, within a slide
   or across consecutive slides.

## Fragment indices

Write `fragment-index` on every fragment. Equal indices fire together. In raw
HTML the attribute is `data-fragment-index`.

reveal renumbers the indices from 0 in sorted order, so number clicks 1, 2, 3
without gaps. reveal also sorts every fragment with an index ahead of every
fragment without one. A list that Quarto stages item by item (`::: {.incremental}`)
has no indices, so do not mix it with indexed fragments on one slide. Where a
list must build item by item next to other fragments, wrap each item in its own
indexed div, as `#threats` does.

## Opt-in staging

The filter can still stage every top-level block of a slide, one click each,
with the title alone at click 0. Turn it on for one slide with `{.stage}` on
the heading, for a simple slide whose blocks arrive top to bottom with no
grouping. `stage-check.mjs` then holds that slide to the title-alone rule.

## Patterns

### The step equation (`#id-equation`)

An equation that gains terms is built as layers in one `.eq-stack`. Each layer
is the whole equation with every term in its final place. Terms not yet
entered are wrapped in `\class{hid}{...}`. Layer 1 is a plain div. Each later
layer is an `.eq-layer` fragment with the next index. Every layer has the same
box, so no term moves when the next one appears.

```markdown
::: {.eq-stack}
::: {}
$$\log p_{jmt} = \beta_1 A_{jt}
 \class{hid}{{}+ \class{ac}{\beta_2 \bigl(A_{jt} \times \Rival_{mt}\bigr)}}
 \class{hid}{{}+ \class{gr}{\gamma_j + \delta_{mt}}}$$
:::
::: {.eq-layer .fragment fragment-index=1}
$$\log p_{jmt} = \beta_1 A_{jt}
 {}+ \class{ac}{\beta_2 \bigl(A_{jt} \times \Rival_{mt}\bigr)}
 \class{hid}{{}+ \class{gr}{\gamma_j + \delta_{mt}}}$$
:::
::: {.eq-layer .fragment fragment-index=2}
$$\log p_{jmt} = \beta_1 A_{jt}
 {}+ \class{ac}{\beta_2 \bigl(A_{jt} \times \Rival_{mt}\bigr)}
 {}+ \class{gr}{\gamma_j + \delta_{mt}}$$
:::
:::
```

`\class{hid}` sets `visibility: hidden`, so the hidden term keeps the exact
layout of the real one. Do not use `\phantom`: MathJax spaces a relation or a
binary operator next to a `\phantom` differently from the same operator next
to the real term, and the visible terms shift between clicks. Put the operator
inside the hidden group with an empty group in front, `\class{hid}{{}+ ...}`,
so it keeps its binary spacing.

Notes under the equation go in an `.eq-notes` div, one line per variable or
term, each line a fragment on the click of its term. The accent bar is drawn
per line, so at every click it spans only the lines on screen:

```markdown
::: {.eq-notes}
::: {}
$A_{jt} \in \{0,1\}$ marks automation; $\beta_1$ is the level effect.
:::
::: {.fragment fragment-index=1}
$\beta_2$ is how the effect grows with the share of rivals already automated.
:::
:::
```

### The derivation chain

A derivation that runs over several lines or slides is a chain of steps. Each
step is a step equation whose lines are the rows of one `aligned` block, with a
label column on the right. The rules:

1. Start each step from an equation the room has already seen, and say which
   one in the label column.
2. Replace one term per line. The label says what was replaced and where the
   replacement comes from.
3. Open each step with a one-line recap at click 0 that names the earlier
   result it starts from.
4. A prediction shows the term that produces it: regroup the expression and put
   a brace under that term with its reading.
5. Define the variables as bullets under the equation (`.eq-notes`), one per
   line, never inline in a sentence.
6. Keep brace labels short and spaced so neighbouring labels do not touch.
7. One colour per term role on every equation and figure: `\class{ac}` for the
   term the step is about, `\class{bl}` for a second role, and `\class{gr}` for
   a constant or absorber, grayed and moved to the end.
8. No step tags (assumption, identity, approximation) and no caveats on the
   step. Caveats go to a backup slide behind one button.

The repricing talk's estimating equation, derived from the pooled comparison
the room saw on the claim slide. A chain with a label column goes in
`::: {.eq-stack .chain}`, which sets the math at 28px so the equation and its
labels fit the measure. The recap line sits above the stack at click 0. The
second layer, with lines 3 and 4 still hidden:

```markdown
Start from the pooled comparison on the claim slide.

::: {.eq-stack .chain}
...
::: {.eq-layer .fragment fragment-index=1}
$$\begin{aligned}
\log p_{jmt} &= \alpha + \beta A_{jt}
  && \text{pooled comparison} \\
&{}= \alpha + \class{ac}{(\beta_1 + \beta_2 \Rival_{mt})} A_{jt}
  && \beta \to \beta_1 + \beta_2 \Rival_{mt} \\
&\class{hid}{{}= \beta_1 A_{jt} + \class{ac}{\beta_2 A_{jt} \Rival_{mt}} + \class{gr}{\gamma_j + \delta_{mt}}}
  &&\class{hid}{\alpha \to \text{fixed effects}} \\
&\class{hid}{{}= \underbrace{\beta_1 A_{jt}}_{\text{level}} + \underbrace{\class{ac}{\beta_2 A_{jt} \Rival_{mt}}}_{\text{rises with rival share}} + \class{gr}{\gamma_j + \delta_{mt}}}
  &&\class{hid}{\text{regroup}}
\end{aligned}$$
:::
...
:::
```

Line 2 replaces the single slope with one that depends on the rival share,
which is the claim. Line 3 replaces the intercept with the two sets of fixed
effects, grayed and moved to the end. Line 4 regroups and puts a brace under
the term that carries the prediction. Each later layer unwraps one more line.
The relation goes inside the hidden group (`&\class{hid}{{}= \dots}`), so the
label column never moves. Measured on the 1280x720 canvas: this block fits at
28px with its labels. At the default 36px, a draft of the same chain with an
error term on every line ran 458px past the slide.

A step that runs past `.shrink-85` follows the overflow rule below.

### Swap in place (`#composition`)

To replace one block with another at the same click, keep both in the flow at
the same size:

```markdown
::: {.swap}
::: {.fragment .fade-out fragment-index=1}
A regulator could be asked to observe the pricing algorithms, which are private.
:::
::: {.swap-in .fragment fragment-index=1}
This test asks for the share of a market already automated.
:::
:::
```

The old block stays in the flow after it fades out, so it keeps its space. The
`.swap-in` block sits absolutely over it on an opaque ground. Everything below
the pair keeps its place. Make the new block no taller than the old one.

For a layered exhibit with no swap-out (a still, then the still with more drawn
on it), an `.eq-stack` of image layers works the same way as the step equation.

### Gray-out (`#intro`, `#threats`)

`.dim-past` on a list built item by item grays every item already said, so the
current item is the only one in full ink. On a list-only slide,
`::: {.incremental .dim-past}` is enough. Next to other fragments, wrap each
item in an indexed fragment div inside one `.dim-past` div.

`.li-dim` on a fragment grays that block only while its own click is current.
It is on screen in full ink before and after. Two `.li-dim` blocks with
consecutive indices gray one column of a comparison, then the other, then
return both to full ink on the next click.

### A phrase takes the accent (`#claim`)

`[6.2 log points]{.fragment .highlight-accent fragment-index=1}` turns the
phrase to the accent on its click. It is on screen from click 0. The accent is
a colour change only, never a weight change, so the line does not reflow.

### Reserved space

`.reserve` (a div) or `.ph` (a span or table cell) is `visibility: hidden`,
Beamer's `\invisible`. Use it for a table column that fills in on later clicks.

### Revisiting a slide

To come back to an earlier slide, repeat it exactly, then change one thing in
place on a click. The repeat must be identical to the state the room last saw.

### Fixed geometry across a run

Consecutive slides that share content keep the same positions: the same image
height, the same column widths, the same top of the body. Put the shared sizes
in one deck-local class used by every slide in the run.

## Overflow

On overflow, shrink the slide body and keep the slide whole:

1. `.tight-math` reduces the display-math margins.
2. `.shrink-98`, `.shrink-95`, `.shrink-92`, `.shrink-90`, `.shrink-88`, or
   `.shrink-85` on the heading scales everything under the rule.

Never change the title band or the title size, and never split one topic across
two slides. Past `.shrink-85`, cut content and ask the author which line goes.

## Buttons

A jump button names its destination in one or two words. It is
`[Measurement]{.jump target="ap-measure"}`. Target ids prefixed `ap-` stay clear
of the cross-reference prefixes Quarto claims (`#fig-`, `#tbl-`, `#eq-`,
`#sec-`).

The button arrives on the click of the content it qualifies, so put it inside
that content's fragment. Three placements:

1. Inline at the end of a list line (`#queue`).
2. On its own line under a block, which right-aligns it (`#robustness`).
3. In the bottom-right corner, in a `::: {.btn-corner}` div.

## Back

Every backup slide has a Back button. Write it as an empty span on its own
line; the filter renders it as Back and the theme puts it in the bottom-right
corner:

```markdown
[]{.jump-back}
```

Back returns are fixed at build time (`back-returns: fixed`). The filter finds
the main-talk slide whose button leads into the backup slide. Back lands there
at the click where that button appears, whatever was visited in between. A
backup slide reached from another backup slide returns through the chain to
the main-talk slide.

Overrides:

1. `data-jump-land="start"` on a backup heading makes a jump land at click 0,
   so the slide's own clicks play. By default a jump lands fully revealed.
2. `[]{.jump-back data-return="slide-id" data-return-step="last"}` sets the
   return by hand, for a backup slide that no button leads to.
3. A target linked from two main slides returns to the first in talk order. The
   render warns about it. Give the second slide its own target if that matters.

Backup slides are static by default.

To test the returns, open the rendered deck in a browser, put each main slide
at the click where its button shows, click the button, move one slide away and
back, click Back, and check the slide and the click. On the example talk all
three buttons return to their slide and click.

## Retired slides

A slide that leaves the talk goes into a raw comment block with a dated note.
Pandoc drops the block, and the slide comes back by removing the two fence
lines:

`````markdown
<!-- 2026-11-04: cut for time; the full table is a backup slide. -->
````{=comment}
## Old slide title {#old-id}
...
````
`````

## Ids

Every slide that a button, a CSS rule, or a click map refers to gets an explicit
`#id`. Never key anything on an id that Pandoc generated (`#section-1`): those
ids move when a slide is inserted. A section slide gets an auto id from its
words, so do not reuse that word as a slide id.
