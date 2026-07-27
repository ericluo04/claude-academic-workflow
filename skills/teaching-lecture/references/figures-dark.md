# Figures matched to the deck ground

R is the default. `engine: knitr`, ggplot for static exhibits, `ggplotly` only
when hovering or zooming genuinely helps the teaching.

## Geometry

The canvas is 1050x700 and its content box is 945 px wide. knitr renders at
192 dpi. `auto-stretch` is on by default, so a lone figure gets `.r-stretch` and
is scaled to the height left under the heading, which makes `fig-height` mostly
an aspect-ratio control. The rendered sizes below were measured on a
lecture theme at a 34px root; the mechanics are the same on any theme, so
re-measure if yours runs a different root.

| Chunk options | Rendered on slide | Use for |
|---|---|---|
| `fig-width: 8`, `fig-height: 4.2`, `base_size = 18` | 945 x 496 | full-width exhibit, heading only |
| `fig-width: 8`, `fig-height: 4.0`, `base_size = 18` | 913 x 456 | full width plus one caption line |
| `fig-width: 9`, `fig-height: 5`, `base_size = 20` | 920 x 511 | full width, fills the slide |
| `fig-width: 5.4`, `fig-height: 4.0`, `base_size = 20` in a 58% column | 466 x 346 | figure beside interpretation |

`base_size` runs higher than in a research deck because a lecture theme runs a
larger body type, and a figure whose axis labels are half the size of the prose
reads as an afterthought. On-screen text is roughly `base_size × 1.4` for a
full-width figure.

## Captioned figures

Captioning a cell figure takes `label:` as well as `fig-cap:`, and the label
has to carry the `fig-` prefix:

```r
#| label: fig-board
#| fig-cap: "Colour marks every system whose interval overlaps the leader's."
#| fig-width: 8
#| fig-height: 4.0
```

With both, Quarto builds the figure as a crossref target, `auto-stretch` hoists
the image out to be a direct child of the section and drops the caption beside
it as a `<p class="caption">`, and the theme rides that caption on the image's
own fragment state, so it arrives with the figure and costs no extra keypress.
The caption prints as `Figure 1: …` in the muted ink at 0.6em and carries into
the handout. With `fig-cap:` and no `label:`, the caption still renders but the
figure stays wrapped, `auto-stretch` refuses to touch it, and the image comes
out at its authored width instead of filling the height under the heading. That
is the `fig-cap` mistake to know about, and the fit gate does not catch it
because the smaller figure still fits. The AST mechanics behind this are in the
README under "Figures and tables".

## Figures take the deck ground

A default ggplot lands a pure-white panel that ignores whatever ground the deck
has. On the starter theme's warm paper it reads as a mismatched card; on a dark
theme it is a lightbox on the wall, the single most visible way a lecture deck
looks unfinished. Define a theme once in the setup chunk, keyed to the deck
theme's documented palette table, and reuse it:

```r
# Values from your deck theme's palette table; these are the starter theme's.
# A dark theme swaps in its own ground and inks, and the method is identical.
deck_ground <- "#faf7f2"   # the slide ground, exactly
deck_grid   <- "#ddd6c9"   # the theme's hairline
deck_text   <- "#33302b"   # body ink
deck_axis   <- "#6b6157"   # muted ink

deck_theme <- function(base_size = 18) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background   = element_rect(fill = deck_ground, colour = NA),
      panel.background  = element_rect(fill = deck_ground, colour = NA),
      legend.background = element_rect(fill = deck_ground, colour = NA),
      panel.grid.major  = element_line(colour = deck_grid),
      panel.grid.minor  = element_blank(),
      text              = element_text(colour = deck_text),
      axis.text         = element_text(colour = deck_axis),
      legend.position   = "top"
    )
}

scale_colour_manual(values = c(treated = "#7d3a5e", control = "#6b6157"))
```

Series colours come from the same table (here the starter accent against its
muted ink), so a contrast the deck names in a colour span looks identical
inside the figure.

Fill with the exact ground hex instead of asking for a transparent PNG. A
transparent background antialiases the text against nothing and the labels come
out fringed.

A figure lifted from the paper arrives with a white panel and the paper's own
colours, neither keyed to the deck. Regenerate it with `deck_theme()` when it
is a figure students have to read, and keep any that stay white to the
`.full-bleed` slides where the image is the whole slide, so the deck does not
alternate.

## The silent-shrink trap

`auto-stretch` converts overflow into shrinkage. Six bullets plus an 8 x 4.2
figure renders the figure at 370 x 194 px with unreadable axis labels, and the
fit gate reports that slide as ok, because nothing overflowed. Crushed to zero
height it does get flagged, but merely shrunk to illegibility it does not.

The other half of the trap: `auto-stretch` stops applying the moment the image
is nested, and adding `.r-stretch` by hand inside a column, an `.r-stack`, or a
fragment is worse than doing nothing, because the class also clears the size
caps and the image overflows at natural size. The full mechanics, with the
measured 424px overflow, are in the README under "Figures and tables" and
"Things that will silently break the deck". Set `fig-width` and `fig-height`
instead, or an explicit `width=` on a file image, and let the fit gate confirm
it.

A figure written as a chunk needs none of this. `stage-slide.lua` stages a
figure cell by putting the fragment on the image itself, which is the one form
`auto-stretch` survives, so the figure waits for its keypress and still fills
the slide.

So when a slide has a figure and anything else on it, read the per-image
geometry: `deck-check.mjs fit deck.html --json` gives `w` and `h` for every
image. Treat a full-slide figure under about 600 px wide as a failure and fix it
by moving the text into a column, where the figure is not stretched at all:

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
::: {.keyidea}
[Key idea]{.label}
The slope is the same in both groups. Only the intercept moves.
:::
:::
::::
````

Four colons open the wrapper, three open each column.

## Interactive figures

Live plotly works here and the R path needs no workaround. Built as the offline
variant it is even a single file making zero network requests at display time,
verified by reading the browser network log: one request, for the file itself.

Style the widget to the deck ground as well, or it arrives as a white
rectangle:

```r
ggplotly(p) |>
  plotly::layout(
    paper_bgcolor = deck_ground, plot_bgcolor = deck_ground,
    font = list(color = deck_text)
  )
```

````markdown
```{r}
#| fig-width: 9
#| fig-height: 5
library(plotly)
ggplotly(p)
```
````

Cost, measured on the self-contained build against a 3.3 MB bare deck: a static
ggplot PNG adds 84 KB, a DT table 317 KB, plotly 3.78 MB the first time it
appears and nothing after, because the bundle dedupes. A lecture with any number
of R plotly figures lands near 7 MB, fine for GitHub Pages.

plotly animation with a play button and a frame slider is worth the payload for
anything that evolves over rounds or periods, and it needs no network once
loaded.

A choropleth fetches `cdn.plot.ly/world_110m.json` at display time, because
`topojsonURL` is compiled into plotly.js and no Quarto setting can embed it.
With wifi that is a non-issue; in a room without it the map comes up blank, so
use a static image of the map when the network is in doubt.

If a deck must use Python plotly, plotly.py 6.x emits a dead CDN module import
that 403s in class; the fix is `plotly-connected: false` in the front matter,
never a hand-written `pio` line, and `_freeze/` has to be cleared after changing
it. The full story is in the README under "Things that will silently break the
deck".

A Python plotly deck also carries its own MathJax 2, because plotly.py
hardcodes `include_mathjax="cdn"` per figure and `self-contained-math` does not
govern it. Under `embed-resources` that copy is inlined, which costs about
1.5 MB and explains a deck coming out larger than expected; under the default
recipe it means the page pulls MathJax twice.

Set `QUARTO_PYTHON` to an absolute venv interpreter path, since an unactivated
`.venv` is detected but not used and Quarto falls back to the stock 3.9.6. Do
not mix R plotly with Python plotly, which inlines plotly.js twice.

`modelsummary(output = "markdown")` with `(1)` / `(2)` column headers comes out
as `1.` and `2.`, because pandoc reads the parenthesized numbers as ordered-list
markers. Rename the columns.

## Video and images

Raw HTML is the form that works:

```html
<video src="clips/robot-hand.mp4" width="900" controls></video>
```

Under the default recipe that stays a relative path, so the clip has to ship
alongside the deck in the course site. Under `embed-resources` it is inlined at
about 1.32x, so a 14 KB clip adds 19 KB. The `{{< video >}}` shortcode is
broken under `embed-resources`: it writes a `<source>` with no `type`
attribute, so video.js refuses it and the slide shows a visible "No compatible
source was found for this media" modal. There is no ffmpeg on this machine; to
trim a clip, `uv run --with imageio-ffmpeg python -c "import imageio_ffmpeg as
f; print(f.get_ffmpeg_exe())"` gives a static binary.

`## Screenshot {.full-bleed}` with a bare `![](shot.png)` gives an edge-to-edge
image capped under the heading. `## Title {background-image="shot.png"
background-size="contain"}` puts the image behind the slide, which is the right
treatment for a visual you want to talk over; note that a screenshot with a
white UI reads as a bright panel against a tinted or dark ground, so crop
tight.
