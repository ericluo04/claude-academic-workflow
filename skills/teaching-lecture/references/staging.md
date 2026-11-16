# Staging, animation, and the deck machinery

This is where a lecture deck earns its keep. Beamer's `\pause` is a hard cut
because it renders separate pages; reveal fades each fragment in place, so a
line settles onto the slide instead of blinking on. Dark lab turns slide
transitions off (`transition: none`) and leaves fragment fades at reveal's
default. Content should arrive as you say it.

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
question, `.fade-up` for a punchline, `.highlight-accent` (a theme class) to
turn a term teal and bold on cue, and the theme's `.gray-out` to send a line
you have finished with to the muted ink while a new block arrives on the same
press. Avoid `.grow` and `.shrink`, which read as a rendering bug from the
back of a room, and avoid `.highlight-red`, whose saturated red is off-palette.

A custom fragment class has to restore `opacity: 1; visibility: inherit` in
CSS, because reveal hides every fragment that is not `.custom`. The theme's
`.highlight-accent` and `.gray-out` do this already; a hand-rolled one that
skips it never appears at all.

Dark lab's own build tools (the step equation with `\class{hid bK}`, `.swap`,
`.gray-out`, `.shrink-NN`, and vertical backups) are documented in the skill
under "Click mechanics" and in the CLICK MECHANICS block of `darklab.scss`.

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
sliding from 0.50 to 0.09, an equation rearranging, a bar growing. The
template does the threshold. The format sets `auto-animate-duration: 0.4`; the
1.0 default is long enough that the class waits on it and so do you,
mid-sentence.

## The animation budget

Budget five to eight staged moments in a 75-minute deck beyond the incremental
lists. More and the class waits for the animation instead of the argument.
Hidden fragments still occupy layout space, so a staged slide cannot overflow at
the last step without overflowing at the first.

## The breadcrumb and backup navigation

Dark lab has no progress bar and no slide number. Students locate themselves off
the breadcrumb at the bottom left of every slide: the section's number in teal
and its title in 19px mono at 9.1:1 against the ground, which reads from the
back of a room. `lab.html` builds it at load from the `.section-break`
dividers, which `stage-slide.lua` numbers, so nothing is written per slide. The
title slide, the dividers, the closing slide, and the reference pages carry no
crumb, and neither do the recap and agenda before the first divider.

A backup is a vertical child of the slide it supports. `## Title {.backup}`
written after a slide hangs it there; `lab.html` moves each backup into a
vertical stack before reveal builds its index, so the gates, the hash, and the
overview all see the stack. The bottom-right hint reads "↓ backup" on a slide
with a backup under it and "↑ back" on the backup, and the breadcrumb adds
"backup".

The lecture's path skips backups. The right arrow already does in reveal's
default navigation mode, and `lab.html` maps Space, PageDown and N to the same
behaviour (PageUp and P to the left arrow), because reveal would otherwise send
those keys, and most clickers, down into the stack. Measured on the sample
lecture: PageDown at the last fragment of the estimator slide lands on the next
section divider, and the down arrow lands on the backup at step 0.

A backup is staged like any content slide. That costs a press or two when a
question sends you there, and it keeps the stage gate's invariant whole.

## Vertical alignment and the heading gap

Content slides are top-aligned (`center: false`, which the format sets), and
every slide pads itself: 52px at the top, 76px at each side, and 78px at the
foot, where the breadcrumb sits. The heading gap is the `h2`'s 28px bottom
margin. The sample lecture places its sparse slides (the hero interval, the
discussion prompt) with a top margin on the block; `{.center}` has not been
checked on this theme.
