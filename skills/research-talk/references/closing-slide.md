# The end of the talk: Takeaways, Backup, references

The main talk ends on a Takeaways slide. After it come the Backup divider, the
backup slides, the references divider, and the reference list. There is no
Thank you slide and no conclusion slide besides Takeaways.

## Takeaways

```markdown
## Takeaways {#takeaways .closing-slide}

1. Automated pricing has no single price effect. It raises prices by [6.2 log points]{.em}
   (s.e. 1.4) in the top quartile of rival exposure and by −0.4 (1.1) in the bottom.
2. The interaction is the comparative static a model with strategic complements predicts.
3. A regulator can test market composition, the share of a market already automated,
   which the platform already records and publishes.

::: {.contact}
[you@example.edu](mailto:you@example.edu)  ·  [your-site.example](https://your-site.example)  ·  Paper and replication files at example.edu/~presenter/repricing
:::
```

The claims are a numbered list with accent numerals. Two to four claims, each
one or two lines, each a sentence the room can dispute. The first claim is the
one-sentence claim of the talk with its headline number. The claims are not a
summary of the sections.

The contact line sits on a hairline at the bottom edge in small gray type: an
email, a site, and where the paper and the replication files live. The words
are the author's (`../style/house.md`).

The slide arrives whole. It stays up during questions, so it carries what the
room should copy down.

`.closing-slide` is the class the filter and the gates know. The progress line
is full on this slide, and `stage-check.mjs` reports it as `closing` and skips
it.

## The Backup divider

```markdown
## Backup {.appendix-break}

- Robustness to the sample window
- Why we do not instrument adoption with tier eligibility
- How automated pricing is measured
```

One word over a gray hairline, and under it the titles of the backup slides in
order, in gray. The list is how the speaker finds a slide by eye when a
question comes. Keep the titles identical to the backup slide headings. With
more than about eight backup slides, list their groups instead of every title.

The backup slides follow, in the order of the main talk. Each has a Back
(`staging.md`, "Back"). They need no class: the filter treats everything after
`.appendix-break` as backup when it wires the Back returns.

## The references

```markdown
## References {.references-break}

## References {.references}

::: {#refs}
:::
```

The divider has the same form as the Backup divider. The filter paginates the
list across as many slides as it needs (`citations.md`).

## How the progress line and the page number end

The progress line is drawn by `after.html`, not by reveal. It measures the main
talk only: it runs from the title to the `.closing-slide`, is full there, and
stays full through the backup slides and the references. A deck with no
`.closing-slide` ends the line on the slide before the Backup divider.

The page number in the bottom-right corner counts every visible slide. It is
blank on the title, the section slides, and the two dividers.
