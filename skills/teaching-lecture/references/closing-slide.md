# The lecture closing slide

A lecture does not end on a thank-you slide. The last two slides of the class
are the synthesis pair: the agenda with every item `.done`, then a closing slide
carrying the one `.keyidea` you want them to leave with and a `.dim` line naming
what next week does. After that comes the appendix divider, which the class only
sees if a question sends you there. The thank-you slide belongs to
`research-talk`, where the closing slide invites contact and carries the email
and a QR code to the paper. The students already have your email and the deck
itself on the course site, so the last slide they look at is worth spending on
the idea they will be tested on.

## The markup

Give it `.closing-slide` and wrap everything below the heading in one
`.together` div:

```markdown
## For next time {#next-steps .closing-slide}

:::: {.together}
::: {.steps}
1. The reading, with pages and what to bring to class.
2. The problem set, with its deadline in the line.
3. The one hands-on task that sets up next week.
:::

[One aside, if the slide needs one.]{.dim}
::::
```

The heading and the wording register for this slide are yours and live in
`style/house.md`.

## Heading, then one beat

The heading stands alone at step 0, and one press brings everything below at
once: the numbered steps, the `.dim` line, and any aside note, in a single beat.
The author's reason: students should not be flashed everything at once while the
instructor is wrapping up. The heading lands first, then the homework arrives
whole on one keypress, still one photographable slide, with no item-by-item
build of a list nobody is arguing about.

Two classes are doing two jobs. `.closing-slide` is where the progress bar
fills: `stage-slide.lua` knows the name, so the appendix and the references stay
out of the denominator and the bar reads 100% here. `.together` is the filter's
one-beat grouping: the whole div gets a single fragment wrapper, and the
filter's `solidify` marks any list inside it `.nonincremental` on its own, so
the items do not re-stage themselves and the list needs no `.nonincremental` of
yours. Pandoc consumes that wrapper, so `.steps` keeps its `ol` as a direct
child and the numbered circles still draw.

The heading stays, unlike the talk's titleless thank-you slide. It is the one
thing on the slide a student reads first, and for one beat it is the only thing
on the wall.

## How the gate classifies it

`stage-check.mjs` passes this slide without asserting on it. Its `kind` ladder
maps `.thanks-slide` and `.closing-slide` alike to `closing` and skips both,
which the talk's slide requires: the thank-you slide stays fully unstaged and
titleless, so read as content it would come back `LEAKS AT STEP 0` plus
`NO FRAGMENTS ON A CONTENT SLIDE`. The lecture's closing slide would now come
close to passing the content test, but the exemption is `.closing-slide` by name
either way, so the gate does not verify the heading-then-one-beat staging; check
it in the browser when it matters.

`{.no-stage}` is not one of the gate's kinds: it opts a slide out of the filter
and not out of the gate, so an unstaged slide still has to be classified as
something other than content.
