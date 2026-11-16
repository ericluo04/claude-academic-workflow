# Citations and the reference list

A seminar deck cites constantly, so the citation has to be visible and has to
stay under the claim. Cite on the slide where the borrowed thing appears; the
full list goes at the very end, after the backup slides, and paginates itself.

## Never type a reference by hand

Not into a slide, not into a tooltip, not into the `.bib`. An audit of a
finished deck found five entries with invented content: authors who were not on
the paper, a year off by two, a title assembled out of a citekey. Every one of
them was typed from memory while the deck was being written, and every one read
as plausible, in a deck for a room that included the authors being cited.

The rule that follows from it: the `.bib` is the only place reference text
exists, it is verified before the talk with the `bibcheck` skill, and anything
else that shows a reference is generated from it. A deck that wants hover
tooltips carrying the full entry keeps one hand-authored artifact, a
`label -> citekey` map, and a script that reads the `.bib` and rewrites the
matching spans. Nothing in the pipeline retypes an author or a year.

Two mechanics that pipeline needs. It has to strip its own previous wrapper
before re-wrapping, so it can run repeatedly without nesting. And it runs
AFTER any edit to the slide text, never before: once a phrase is wrapped in a
`<span>`, plain-string matching against the slide source stops finding it.
Editing text after a wrap pass and wondering why the tooltip vanished cost two
rounds in one session.

Entries cited only inside tooltips are invisible to citeproc, so they get
dropped from the list unless the front matter carries `nocite: |` with `@*`.

## Writing citations

Use Quarto's own syntax:

| you write | you get |
|---|---|
| `[@key]` | (Author 2020) |
| `@key` | Author (2020) |
| `[@a; @b]` | (A 2020; B 2021) |
| `[see also @key]` | (see also Author 2020) |
| `[-@key]` | 2020 |

The parentheses come from the citation style, and no theme rule touches them.
Pandoc's built-in chicago-author-date gives round parens with no comma before
the year, which is the same output as `\usepackage[round]{natbib}` plus
`\setcitestyle{aysep={}}`. It needs no `csl:` line and no file, so it is also
the offline-safe choice. Setting `csl: apa.csl` puts the comma back; a numeric
style gives `[1]`. Never fake a paren in CSS, because the same rule would wrap
a narrative cite and "Author (2020) shows" would come out
"(Author (2020)) shows".

Two habits worth carrying over from LaTeX. `\citealt` inside a paren you typed
yourself is `[e.g., @key]` here, which produces "(e.g., Author 2020)" with one
set of parens. A bare `\cite` used as a sentence subject is `@key`.

## How a citation renders

A citation takes the size of the text around it: body size in the body, the
small gray of an `.aside-note` in a note. The year is a link in the accent.
Hovering a citation pops its reference entry in a tooltip, and in a multi-cite
each citation previews its own entry. That retargeting is the filter's, runs on
every deck, and needs nothing in the front matter; the mechanics are in the
slide-tooling README under "Citations and the reference list".

## The reference list at the very end

```markdown
## Backup {.appendix-break}

... backup slides ...

## References {.references}

::: {#refs}
:::
```

`bibliography: talk-refs.bib` is the only front-matter line the deck adds. The
format already carries `citeproc: false` and the reference budget.

`citeproc: false` is not cosmetic. Quarto runs pandoc's citeproc after its
whole filter chain, so the only way a filter can see rendered entries and cut
them into slides is to run citeproc itself, which `stage-slide.lua` does. A
deck that loses the line renders a second, unpaginated bibliography, and
`deck-check.mjs fit` fails the deck and names the fix.

The Editorial format sets the budget outright, `refs-lines: 20` and
`refs-chars-per-line: 118`, for its 18px entries on the 1136px measure. On the
example talk the 13 entries pack as 7 and 6, and the first page ends at y=627
of the 656 px available. The packer is greedy: it fills each slide to the
budget and the last slide carries the remainder. `STAGE_REFS_DEBUG=1 quarto
render talk.qmd` prints what it decided. Forgetting the budget costs an
under-filled slide, never an overflow.

Nothing on the reference slides is staged, and `stage-check.mjs` reports them
as `reference list` and skips them.

Do not put `.scrollable` on a references slide. It hides overflow from the
gate and does not print. If the list overflows, lower `refs-lines` in the deck's
front matter.
