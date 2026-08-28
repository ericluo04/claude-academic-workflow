# Figures, code, tables, and layout

Everything here is measured on the 1050x700 canvas, whose content box is 945 px
wide. knitr renders at 192 dpi here, so `fig-width: 8` produces a 1536 px
image.

## Figures that fit

A lone figure on a slide gets `.r-stretch` from Quarto's `auto-stretch` (on by
default) and is scaled to the height left under the heading, so `fig-height`
sets the aspect ratio more than the final size. Verified renders:

| Chunk options | Rendered on slide |
|---|---|
| `fig-width: 8`, `fig-height: 4.2` | 945 x 496, comfortable under a two-line heading |
| `fig-width: 9.5`, `fig-height: 5.5` | 908 x 526, fills the slide, no room for a takeaway line |
| `fig-width: 5.4`, `fig-height: 4.0` in a 58% column | 466 x 346 |

Start at `fig-width: 8`, `fig-height: 4.2` for a full-width exhibit and
`fig-width: 5.4`, `fig-height: 4.0` for a two-column one. Set `base_size` in
the ggplot theme to 15 for full width and 13 in a column; a figure carrying
print-sized axis labels is unreadable from the back of the room.

Auto-stretch fails loudly in one case worth knowing: when a slide holds a
figure plus enough other content to overflow, the stretch computes to zero and
the figure renders 945 px wide by 0 px high. It looks like a missing image.
The fit gate reports it as `CRUSHED FIG`.

Auto-stretch stops applying the moment the image is nested in a fragment, a
column, or a layout panel, and `.r-stretch` by hand does not bring it back: it
only clears the size caps, so a large image comes out at natural size and runs
off the bottom (the README, "Figures and tables", has the mechanism and the
measured 424px overflow). Size a nested figure with `fig-width` and
`fig-height`, and let the fit gate confirm it.

A figure you write as a chunk needs none of this: the format's filter stages a
figure cell by putting the fragment on the image itself, the one form
auto-stretch survives, so the figure waits for its keypress and still fills
the slide (`staging.md` has the caption case).

Missing image files fail silently at exit 0. The fit gate catches them as
`MISSING IMG`.

Keep figures static. Each ggplot PNG adds roughly 100 KB. Plotly adds 3.8 MB
the first time it appears, and a seminar exhibit almost never gains from
hover; `teaching-lecture` covers the interactive case.

## Sizing a row of images by hand

A hand-laid row (a set of product photos, four stimulus conditions, a before
and after pair) gets none of Quarto's stretching, so its size is arithmetic.
For n images at a shared height h, the row occupies

    h * sum(w_i / h_i)  +  (n - 1) * gap  +  any separator column

against the 945px content width, or 1050px if the row goes full bleed. Solve
for h, take the lesser of that and the vertical room under the heading, and
back off about 20px.

With portrait images the width term binds well before height does, which is
counterintuitive on a slide showing a wide empty band under the row: four
portrait images averaging 0.67 aspect need 2.68 times their height in width, so
425px tall would need 1140px across on a 1050px slide however much vertical
room is free. When a request for a much larger figure is geometrically
impossible, the recoverable slack is in the gaps and the separator column, and
it is worth saying what the real ceiling is rather than silently landing under
it.

Read the actual numbers rather than eyeballing a screenshot. Serve the deck
(`python3 -m http.server`), drive it with Playwright to the slide, and divide
every `getBoundingClientRect()` by `Reveal.getScale()` to get canvas pixels;
elements on non-current slides measure zero, so jump with `Reveal.slide(i, 0)`
first.

## Code and output on the same slide

Set `echo: true` on the chunk (the format defaults `echo: false`).
`output-location` takes five values and they are not equivalent on a 1050x700
canvas:

- `column` is the right default when you are showing code. Code goes left,
  output right, and both stay readable. Verified with `lm` plus
  `knitr::kable`.
- `default` puts output directly under the code. Fine for three lines of code
  and a short printout; it is the fastest way to overflow a slide.
- `fragment` is `default` with the output appearing on a keypress. Use it when
  you want the audience to predict the answer.
- `slide` sends the output to a new slide that repeats the heading. Use it for
  a full regression table that cannot share space with its code.
- `column-fragment` combines the two. Rarely worth it in a research talk.

Set it document-wide under `execute:` if most chunks show code. In a research
talk most chunks should not: the audience wants the table, not the call that
produced it. Leave the format's `echo: false` in place and turn `echo: true`
on for the two or three slides where the code is the point.

## Engines and R setup

One execution engine per document. R plus Python goes through knitr with
reticulate, not by mixing engines. Under reticulate every top-level expression
renders, so a bare `fig.update_layout(...)` emits a duplicate figure; assign
it instead.

If anything calls `knitr::raw_block()` or `htmltools::HTML()`, export
`RSTUDIO_PANDOC=~/.local/quarto/bin/tools/aarch64` first. Without it
`rmarkdown::pandoc_version()` returns 0 and the raw HTML vanishes with no
error.

Installed and working: knitr, rmarkdown, ggplot2, dplyr, data.table,
reticulate, fixest, modelsummary, tinytable. To add more without sudo:

```bash
Rscript -e 'install.packages("sandwich", repos="https://cloud.r-project.org")'
# lands in ~/Library/R/arm64/4.6/library, the default R_LIBS_USER,
# so no env var is needed at render time
```

## Tables

Tables sit flush against the left text rail, so a narrow table lines up with
the heading above it. A table with four or more columns needs no class: both
themes stretch it to the full text column via `table:has(tr > :nth-child(4))`,
with padding scaled up, so its right edge lands where the aside note and the
takeaway rule end; 2-3 column tables keep natural width. Quarto's inline
`width:100%` (written when `tbl-colwidths` is set) agrees with the rule.

Put `.spec` on a wide specification table so it shrinks instead of clipping
(`: Caption text {.spec}` on the caption line), and `.num` on a column to
right-align numerals. A table is always one beat to the staging filter; its
cells are never staged.

`modelsummary(..., output = "markdown")` with column names `(1)` and `(2)`
gets mangled: pandoc reads the parenthesised numbers as ordered-list markers
and the header renders as `1.` and `2.`. Name the columns something else
("OLS", "+ controls") or emit HTML.

## Two columns

````markdown
:::: {.columns}
::: {.column width="58%"}
```{r}
#| fig-width: 5.4
#| fig-height: 4.0
# the exhibit
```
:::
::: {.column width="42%"}
The gap opens only after disclosure, and only where search costs are high.

::: {.result}
[Estimate]{.label}
0.29 log points (s.e. 0.04)
:::

::: {.aside-note}
Low-search-cost markets move by 0.06, not distinguishable from zero.
:::
:::
::::
````

Four colons open the wrapper and three open each column. The theme sets
`align-items: flex-start` so the interpretation lines up with the top of the
exhibit. 58/42 leaves the text column wide enough to avoid two-word lines.
