# Citations and the reference list

A seminar deck cites constantly, so the citation has to be visible and has to
stay under the claim. Cite on the slide where the borrowed thing appears; the
full list goes at the very end, after the appendix, and paginates itself.

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

The theme gives `span.citation` two properties and nothing else: 0.88em
(26.4px against the 30px root, 8.9:1 in the appendix gray on white) and no
compounding inside an `.aside-note` or a figcaption, which are already the
quiet register. Hovering lights the whole citation, author, year, and
parentheses together, in the mid blue at 5.2:1 on white, and the tooltip that
pops the reference entry answers the whole citation too, on one line or two
when it wraps; in a multi-cite each citation previews its own entry. That
retargeting is the filter's, runs on every deck, and needs nothing in the
front matter; the mechanics are in the README under "Citations and the
reference list".

## The reference list at the very end

```markdown
## Appendix {.appendix-break background-color="var(--appendix-ground)"}

... appendix slides ...

## References {.references-break background-color="var(--references-ground)"}

## References {.references}

::: {#refs}
:::
```

`bibliography: talk-refs.bib` is the only front-matter line the deck adds; the
format already carries `citeproc: false` and a `refs-fit` preset (this repo's
starter extension sets `refs-fit: starter`).

`citeproc: false` is not cosmetic. Quarto runs pandoc's citeproc after its
whole filter chain, so the only way a filter can see rendered entries and cut
them into slides is to run citeproc itself, which `stage-slide.lua` does. A
deck that loses the line (a plain `revealjs` format, say) renders a second,
unpaginated bibliography; `deck-check.mjs fit` fails the deck and names the
fix.

The preset picks the measured line budget for its theme: `refs-fit: starter`
budgets 25.9 rendered lines at 134 characters per line, with the hanging
indent taking 0.026 of a line off every wrapped line (a `talk` preset for a
30px root, 25.7 lines at 125, is also kept). The packer is greedy: it fills
each slide to the budget and the last slide carries the remainder however
short, so the sample talk packs 10 entries and then 3. How many entries fit
depends on
how long they run; `STAGE_REFS_DEBUG=1 quarto render talk.qmd` prints what the
packer decided, so read that instead of expecting a fixed count. The filter
cannot read the theme, because Quarto compiles the SCSS to a hashed bundle
before any filter runs, which is why the format names the preset next to the
theme. Forgetting the line costs an under-filled slide, never an overflow.
`refs-lines` and `refs-chars-per-line` override the preset outright; the
packing model and its derivation are in the README under "How many entries
fit".

The divider is the appendix divider again, same ring and same gray. The
references slides carry no pill: the standing label belongs to
`section.appendix h2::before` alone, because the heading is already the word
References and a label above it would repeat the heading. Nothing on them is
staged: a reference list is not an argument being built, and `stage-check.mjs`
reports them as `reference list` and skips them. A `.jump-back` written after
the trailing `.aside-note` lands on the last page, if you want one.

Do not put `.scrollable` on a references slide. It hides overflow from the
gate, breaks `auto-stretch`, and does not print. If the list still overflows,
the budget is wrong: read the `STAGE_REFS_DEBUG=1` render and override with
`refs-lines`.
