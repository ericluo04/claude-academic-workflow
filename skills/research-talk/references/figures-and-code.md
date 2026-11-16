# Figures, code, tables, and layout

Everything here is measured on the Editorial format's 1280x720 canvas. The
content box is 1136 px wide (72 px side padding) and runs from y=190, under the
title rule, to y=656. knitr renders at 192 dpi, so `fig-width: 8` produces a
1536 px image.

## Figures that fit

A lone figure on a slide gets `.r-stretch` from Quarto's `auto-stretch` (on by
default) and is scaled to the height left under the heading, so `fig-height`
sets the aspect ratio more than the final size. Verified renders:

| Chunk options | Rendered on slide |
|---|---|
| `fig-width: 8`, `fig-height: 4.2` | 810 x 425, with room for an `.aside-note` under it (`#adoption`) |
| `fig-width: 5.4`, `fig-height: 4.0` in a 58% column, inside a fragment | 518 x 384 (`#event-study`) |

Start at `fig-width: 8`, `fig-height: 4.2` for a full-width exhibit and
`fig-width: 5.4`, `fig-height: 4.0` for a two-column one. Set `base_size` in
the ggplot theme to 15 for full width and 13 in a column; a figure carrying
print-sized axis labels is unreadable from the back of the room.

Auto-stretch fails loudly in one case worth knowing: when a slide holds a
figure plus enough other content to overflow, the stretch computes to zero and
the figure renders at full width and 0 px high. It looks like a missing image.
The fit gate reports it as `CRUSHED FIG`.

Auto-stretch stops applying the moment the image is nested in a fragment, a
column, or a layout panel, and `.r-stretch` by hand does not bring it back: it
only clears the size caps, so a large image comes out at natural size and runs
off the bottom (the README, "Figures and tables", has the mechanism and the
measured 424px overflow). Size a nested figure with `fig-width` and
`fig-height`, and let the fit gate confirm it.

A figure that arrives on a click sits inside a fragment div, so it loses
auto-stretch. Size it with `fig-width` and `fig-height`, as `#event-study`
does. On a `{.stage}` slide the filter puts the fragment on the image itself,
the one form auto-stretch survives.

Give a talk figure a plain chunk label. A label that starts with `fig-` makes
Quarto add a "Figure 1" caption under it.

## The figure palette

Figures match the slide: the vermilion accent (`#D4371C`) for the series the
slide is about, a mid gray (`#8c8c8c`) for the comparison, gray axis text
(`#5c5c5c`), horizontal grid lines only (`#e6e6e6`), and a white ground. The
setup chunk of the example talk defines `col_main`, `col_soft`, `col_text`,
`col_bg`, and a `talk_theme()` for ggplot2. A figure made in Python uses the
same five values. One accent per figure: a second highlighted series goes in
gray or in the dark ink, never in a second bright colour.

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

against the 1136px content width, or 1280px if the row goes full bleed. Solve
for h, take the lesser of that and the vertical room under the heading, and
back off about 20px.

With portrait images the width term binds well before height does, which is
counterintuitive on a slide showing a wide empty band under the row: four
portrait images averaging 0.67 aspect need 2.68 times their height in width, so
480px tall would need 1286px across on a 1280px slide however much vertical
room is free. When a request for a much larger figure is geometrically
impossible, the recoverable slack is in the gaps and the separator column, and
it is worth saying what the real ceiling is rather than silently landing under
it.

Read the actual numbers instead of eyeballing a screenshot. Open the deck in a
browser (`file://` is fine), navigate to the slide, and divide
every `getBoundingClientRect()` by `Reveal.getScale()` to get canvas pixels;
elements on non-current slides measure zero, so jump with `Reveal.slide(i, 0)`
first.

## Code and output on the same slide

Set `echo: true` on the chunk (the format defaults `echo: false`).
`output-location` takes five values and they are not equivalent on a 1280x720
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

Tables span the content column and carry rules only, no fills: a rule under
the header and one under the last row. Wrap a regression table in
`::: {.regtable}` and every second body row (the standard errors under their
estimates) turns gray, with a hairline above the last two rows (`#table`).
Put `.spec` on a wide specification table, as a div around it or as a class on
a raw `<table>`, so it sets at 20px (`#robustness`, `#ap-window`), and `.num`
on a column to right-align numerals. Mark the focal estimate with `.em`.

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

Four colons open the wrapper and three open each column. The columns are
top-aligned, so the interpretation lines up with the top of the exhibit. 58/42 leaves the text column wide enough to avoid two-word lines.
