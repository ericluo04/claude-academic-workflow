---
name: course-site
description: Build and maintain the semester course website that a set of Quarto lecture decks hangs off: the landing page students bookmark, the week table, the dark Yale site theme, the navbar and school mark, the instructor line, the handout post-render hook, and publishing to GitHub Pages. TRIGGER on "course website", "course site", "syllabus page", "course landing page", "week table", "add week 4 to the site", "link the new deck on the site", "publish the course site", "GitHub Pages for my course", "the site navbar", "logo on my course page", "put my syllabus online", "the site looks wrong on a phone". Use teaching-lecture to write or repair a deck; this skill owns everything around the decks.
---

# Course website

One Quarto website project per course, per semester. It holds the page students
bookmark, a row for every week, the theme that makes the site and the decks read
as one system, and the publish path to GitHub Pages.

The boundary with `teaching-lecture` is hard. That skill owns a deck: slide
staging, the teaching blocks, figures, pacing, the fit gate. This skill owns the
site: `_quarto.yml`, `index.qmd`, the site theme, the navbar, handout wiring, and
publishing. `teaching-lecture` carries a short course-website section for the case
where someone arrives from the deck side; this file is the authority, and where the
two disagree this one is newer.

The working example is `~/teaching/sample-ai-course`, which is where every measured
number below comes from.

## Layout

```
~/teaching/<course>/
  _quarto.yml                  # project, website, navbar, format, post-render
  index.qmd                    # title, subtitle, instructor line, week table
  assets/
    yale-site.scss             # the dark site theme (Bootstrap variables)
    yale-lecture.scss          # the dark reveal theme, used by every deck
    logo-white.svg             # the reversed school mark for the navbar
  lectures/
    _metadata.yml              # the whole revealjs format, once
    w01-prediction.qmd         # content only, no format block
    w03-evaluation.qmd
    images/                    # figures with a fixed pixel size
  R/
    make-figures.R             # pre-rendered exhibits, run from the project root
  scripts/
    build-handouts.sh          # post-render hook, builds a PDF per deck
  docs/                        # render output, committed, served by Pages
    .nojekyll
```

Two directories carry the whole design. `assets/` holds both themes plus the logo,
and `lectures/_metadata.yml` holds the deck format so a lecture file is content
from its first line. Keep the project out of Dropbox: rendered decks run several MB
each and the sync churns on every render.

## `_quarto.yml`

```yaml
project:
  type: website
  output-dir: docs
  render:
    - index.qmd
    - lectures/*.qmd
  post-render:
    - scripts/build-handouts.sh

website:
  title: "AI and Managerial Decisions"
  navbar:
    title: false
    logo: assets/logo-white.svg
    logo-alt: "Your School"
    left:
      - href: index.qmd
        text: Lectures

format:
  html:
    theme: [cosmo, assets/yale-site.scss]
    toc: false
```

`render:` is a glob, so a new lecture needs no config change. `output-dir: docs` is
what lets GitHub Pages serve from a branch subdirectory with no Actions workflow.

`title: false` on the navbar is required once a logo is set. With no navbar title
Quarto falls back to `website: title`, which prints the course name beside the mark
and repeats the page title 40px below it. Setting `false` is the only way to get a
brand that is the mark alone.

`toc: false` because the landing page is one screen. Turn it on for a long
syllabus page and the theme already styles the contents rail.

No `title-block-banner`. On this theme it paints a second coloured band directly
under the navbar, so the top of the page becomes two adjacent fields of the same
blue.

## `lectures/_metadata.yml`

Everything about the deck format lives here, so no `.qmd` repeats it:

```yaml
format:
  revealjs:
    theme: [default, ../assets/yale-lecture.scss]
    embed-resources: true
    html-math-method: mathjax
    slide-number: c/t
    incremental: true
    highlight-style: a11y-dark
    progress: true
    auto-animate-duration: 0.4
# stage-slide.lua runs citeproc itself, which is the only way a Lua filter can
# see the rendered entries and cut them across slides. Leaving this out gives a
# second, unpaginated bibliography on the last slide of any deck that cites,
# and `deck-check.mjs fit` fails the deck for it.
citeproc: false
# which entries-per-slide budget the reference list is packed to; the theme
# cannot be read from a filter, so it is named here, next to the theme (the
# starter extension shipped in this repo already carries `refs-fit: starter`)
refs-fit: lecture
engine: knitr
execute:
  echo: false
  warning: false
  message: false
filters:
  - ~/.claude/assets/quarto-yale/stage-slide.lua
```

The relative theme path resolves inside a website project. The working copy, with
the full comments, is `~/teaching/sample-ai-course/lectures/_metadata.yml`. What
each key does, and why `stage-slide.lua` is not optional, is in `teaching-lecture`.

## The site theme

`assets/yale-site.scss` layers on `cosmo` and turns it dark. Bootstrap and bslib
variables here, so nothing in this file transfers to a deck. The palette matches
`yale-lecture.scss` exactly, and the two files each carry their own copy of it:
Quarto compiles theme SCSS from a temp directory, so a relative `@import` cannot
resolve. Edit one, edit the other.

| Role | Hex | On the #1a1c1e ground |
|---|---|---|
| Ground | `#1a1c1e` | the whole page below the navbar |
| Raised surface | `#24272a` | table body, code blocks, cards |
| Table header | `#2b2f33` | one step up from raised |
| Hairline | `#33373b` | borders |
| Body text | `#e8e6e3` | 13.7:1 |
| Headings | `#ffffff` | 17.1:1 |
| Pale accent | `#a8ceff` | 10.5:1, the subtitle and h4 |
| Links | `#63aaff` | 7.1:1, and every accent rule |
| Muted | `#9aa0a6` | 6.5:1, the instructor line, captions, footer |
| Inline code | `#ffa07a` | 8.6:1 |

Yale blue `#00356b` measures 1.4:1 against the ground, which is invisible. It
appears in one place, the navbar, where white type on it measures 12.2:1.
Everything below the navbar sits on the ground, including the page title. The 2px
`#63aaff` rule on the navbar's lower edge is what marks where the chrome stops and
the page begins, and it is the reason the masthead needs no border of its own.

Variables the theme exposes, at the top of the file. Turn these instead of writing
new margins anywhere else:

| Variable | Default | What it moves |
|---|---|---|
| `$heading-space-above` | `4rem` | space before an h2, the main rhythm control |
| `$heading-space-below` | `0.85rem` | space after an h2, above its accent bar |
| `$block-space-below` | `1.75rem` | after a table or a list |
| `$title-space-above` | `2.25rem` | navbar rule to the h1 |
| `$title-space-below` | `2rem` | masthead to the first body block |
| `$masthead-rule` | `2px` | the accent rule under the navbar |
| `$navbar-logo-height` | `38px` | ceiling on the school mark |

Headings are asymmetric on purpose, large above and small below, so an h2 binds to
the section it opens. The selectors carry a `.content` or `.quarto-container`
prefix because Quarto's own stylesheet sets heading and table margins and loads
after the theme.

## The masthead

Three tiers, each smaller and quieter than the one above:

```markdown
---
title: "AI and Managerial Decisions"
subtitle: "Your School, Fall 2026"
---

::: {.instructor}
Taught by [Your Name](https://your-site.example),
Assistant Professor
:::
```

Title in white at 2.05x base, subtitle in pale blue at 1.1rem, instructor in muted
grey at 0.95rem with the link in pale blue. The ranking is legible before any of it
is read.

The instructor line is body markup. Quarto's `author` field renders inside the
`quarto-title-meta` grid under a small column label, and that grid is the thing the
theme suppresses (see the traps), so a fenced div is what gives the third line with
no label and no grid row.

Spacing uses the two masthead variables and adds nothing new. The trick is that the
masthead's lower gap transfers onto the instructor line when one is present:

```scss
#title-block-header.quarto-title-block:has(+ .instructor) {
  margin-block-end: 0;
}

main.content > .instructor {
  margin-top: 0.5rem;
  margin-bottom: $title-space-below;
}
```

So the three lines stay one block, `$title-space-below` still measures masthead to
body, and a page with no instructor line keeps its gap on the title block. `:has()`
is already a dependency of this theme, which uses it to drop the empty metadata
grid.

## The navbar and the school mark

The brand is your school's mark alone, on the blue bar.

Getting the file. Many universities publish no open logo download, so the vector
paths can come
from the inline SVG the school's own site serves in its page header. Download
it and commit it. Never hotlink a mark from a university server, which makes the
page depend on their CDN and breaks the offline case.

The committed asset, `assets/logo-white.svg`, should be the mark cropped out
of the full lockup: delete the wordmark group, tighten the viewBox to the
mark's measured bounding box, and reset the `width` and `height`
attributes to match. One recolour reproduces the reversed variant a school's
own dark header typically renders through CSS custom properties: the mark's
outline goes from `currentColor` to a pale tint. A dark-on-transparent mark dropped
straight onto `#00356b` is invisible; if only a dark variant can be found and
recolouring is not wanted, say so and set a small white wordmark in
CSS instead of shipping an illegible image.

A school site's own markup often carries two things that have to be inlined
away for the
file to stand alone inside an `<img>`: the mark is a `<symbol>` reached by
`<use>`, and it points at a `clip-path` that does not exist on the page. Inline
both. Record the provenance in a comment
at the top of the SVG; read that comment before editing the file, and see the
traps below before writing an XML comment of your own.

A school mark is normally a registered trademark. Use is governed by university
trademark policy;
there is no open licence. A course page run by that school's own faculty is
ordinary use.

Sizing. Quarto's own rule is `height: 30px; max-height: 30px`, a fixed height.
The theme replaces it with a ceiling, `$navbar-logo-height` (default 38px), and
lets the width give:

```scss
.navbar .navbar-brand img.navbar-logo,
.navbar .navbar-brand-container img.navbar-logo {
  height: auto;
  width: auto;
  max-height: $navbar-logo-height;
  max-width: 100%;
  padding-right: 0;
}

.navbar .navbar-brand {
  min-width: 0;   // let the anchor shrink so max-width has something to hit
}
```

That needs `width` and `height` attributes on the SVG itself. An SVG with only a
viewBox has no intrinsic size, so `height: auto` resolves against the 300x150
default object size and the result stops tracking the real aspect. With intrinsic
dimensions a near-square mark renders at the default ceiling with a matching
narrow width, far too narrow to hit the `.navbar-brand-container` max-width
clamp, so it holds that size at every viewport width. The ceiling stays because
it is the correct rule for any wider mark that might replace a cropped one.

Quarto emits two `<img class="navbar-logo">` from a single `logo:`, one
`light-content` and one `dark-content`, both with the same `src`. Only one is
visible and the other takes no space, so a single reversed file is the whole job on
a single-theme site.

Above 992px the navbar is held to the same column as the body:

```scss
@media (min-width: 992px) {
  .navbar > .navbar-container {
    max-width: calc(850px - 3em);
    margin-inline: auto;
    padding-inline: 0;
  }
}
```

Quarto's article grid centres a body column of `calc(850px - 3em)`, so without this
the mark sits over the page gutter and the search icon sits over the middle of the
week table. Below 992px the bar keeps Bootstrap's full-width padding, which is
where the collapsed toggler needs it.

## The week table

The main object on the landing page, and the thing students actually use:

```markdown
| Week | Lecture | Slides | Handout |
|---|---|---|---|
| 1 | What a model can and cannot give you | | |
| 3 | Why benchmark scores mislead | [slides](lectures/w03-evaluation.html) | [pdf](lectures/w03-evaluation.pdf) |
```

Rows for weeks not yet written, with empty link cells, are worth keeping: the shape
of the semester is information. The theme styles the table as a raised panel with a
hairline frame, an accent rule under the header row, quiet stripes, and a narrow
tabular first column, so no classes are needed on it.

The `pdf` cell only resolves because the post-render hook builds that file. A row
linking a PDF that nothing builds is a 404 no gate catches.

Under the table, a short section explaining the deck vocabulary earns its space,
because the five coloured blocks are a semester-long convention and students need
the key once. Give it the full `$heading-space-above`.

## Adding lecture N+1

Three steps, no config change:

1. `lectures/wNN-slug.qmd`, content only, since `_metadata.yml` carries the format.
2. A row in the `index.qmd` table with both links.
3. In the new deck's agenda, set last week's item to `.done`.

While drafting, render the one deck: `quarto render lectures/wNN-slug.qmd`. That
triggers the post-render hook for that file alone, so the handout follows.

## Handouts

The week table links a PDF next to every deck, so the handout has to be a render
product. A full `quarto render` prunes everything in `docs/` that it did not
produce, which deletes a PDF placed there by hand, and a handout built once goes
stale the next time the deck changes. `post-render` runs after the prune, so a file
written there survives.

`scripts/build-handouts.sh` in the sample course is the working copy. It reads
`QUARTO_PROJECT_OUTPUT_FILES`, so rendering one lecture rebuilds one handout, falls
back to every deck in `docs/lectures/` when run by hand with no arguments, skips
with a warning when node or the exporter is missing so the site still renders on a
bare machine, and exits nonzero when an export actually fails. Adding a lecture
needs no change to it.

The exporter itself, and why the student handout comes out one page per slide
instead of one page per build step, is in `teaching-lecture`.

## Build and verify

```bash
cd ~/teaching/<course>
quarto render                 # whole site into docs/, handouts included
touch docs/.nojekyll          # a full render deletes it every time
```

Then look at the page. The site has no equivalent of the deck fit gate, so a
screenshot is the check:

```bash
cd docs && (python3 -m http.server 8847 >/dev/null 2>&1 &) ; sleep 2
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --disable-gpu --hide-scrollbars --virtual-time-budget=4000 \
  --window-size=1440,1200 --screenshot=/tmp/site.png \
  "http://127.0.0.1:8847/index.html"
pkill -f "http.server 8847"
```

Serve over HTTP; do not open `file://`. The search index and the site libraries are
fetched relative to the document and behave differently on a file URL. Add
`--force-device-scale-factor=2` when checking whether the mark is crisp.

Check 500px as well as a desktop width. A logo plus a long title is where a navbar
breaks, and 500px is where Bootstrap has collapsed the nav but the brand, the
toggler and the search icon are all still in the bar.

Headless Chrome clamps its viewport to a 500px minimum, so `--window-size=320,700`
lays the page out at 500px and screenshots a 320px crop of it, which reads as a
horizontal overflow bug that is not there. To test narrower, put the page in a
sized iframe and shoot that, since media queries inside an iframe answer to the
iframe's width:

```html
<figure><figcaption>360px</figcaption>
<iframe src="index.html" width="360" height="120"></iframe></figure>
```

## Publishing to GitHub Pages

```bash
cd ~/teaching/<course>
quarto render
touch docs/.nojekyll
git add docs && git commit -m "Week 3" && git push
```

Set Pages to serve from `main` and `/docs` once, in the repository settings.
`quarto publish gh-pages` also works for a website project, but it maintains a
second `gh-pages` branch and needs push credentials at publish time; the `docs/`
route keeps the rendered site on `main`, so a plain `git push` is the whole
publish step. `quarto publish` also writes `.nojekyll` for you, and the `docs/`
route does not, so that `touch` is a permanent part of the recipe. Without the
file Jekyll drops every `_files` directory and all asset paths break.

The repository has to be public, or on a plan that includes Pages for private
repositories. A free private repository can hold the project and will not serve it.

`docs/site_libs/` picks up its own copy of reveal.js even when the decks embed
theirs, and `docs/search.json` appears whether or not search is wanted. Both are
harmless; commit them.

## Traps

| Symptom | Cause | Fix |
|---|---|---|
| A second coloured band under the navbar | `title-block-banner: true` | remove it; the title sits on the ground here |
| An empty band between the subtitle and the body | Quarto emits `quarto-title-meta` even with no author or date, and the empty div still takes a grid row | `.quarto-title-meta:not(:has(*)) { display: none }` plus the `:empty` case |
| The course name printed beside the logo | navbar with a logo and no title falls back to `website: title` | `title: false` in the navbar block |
| Navbar shows alt text instead of the mark | the SVG will not parse | XML comments cannot contain two hyphens in a row, so a CSS custom property written with its leading dashes makes the file unparseable; validate with `python3 -c "import xml.etree.ElementTree as ET; ET.parse('x.svg')"` |
| The mark is invisible on the blue bar | a dark-on-transparent logo | the reversed variant with the pale outline |
| Some text or a rule vanishes on the ground | `#00356b` used as ink, 1.4:1 | `#63aaff`, or `#a8ceff` for a pale accent |
| A `pdf` link on the site 404s after a render | the render pruned a hand-placed file | build it in the `post-render` hook |
| Every asset 404s on GitHub Pages | a full render deleted `docs/.nojekyll` and Jekyll dropped the `_files` directories | `touch docs/.nojekyll` after every full render, and commit it |
| Only one lecture is ever online | `quarto publish` was pointed at a single `.qmd`, and a standalone-document publish replaces the whole site | render the website project and push `docs/`, served from `main` and `/docs` |
| The pushed site never appears | Pages on a private repository needs a paid plan | make the repository public |
| The instructor line appears under an "Author" label | Quarto's `author` field renders in the metadata grid | a `::: {.instructor}` div in the body |
| Headings crowd the block above them | Quarto's own stylesheet loads after the theme and sets heading margins | the `.content` and `.quarto-container` prefixed selectors already in the theme |
| A phone screenshot looks like the page overflows sideways | headless Chrome clamps the viewport to 500px | shoot the page inside a sized iframe |
| A theme edit does nothing | an `@import` of the other SCSS file, which cannot resolve from Quarto's temp compile directory | duplicate the palette values and keep the two files in sync by hand |
