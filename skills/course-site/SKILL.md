---
name: course-site
description: Build and maintain the Quarto course website the lecture decks hang off: landing page, week table, site theme, navbar, handout hook, publishing to GitHub Pages. TRIGGER on "course website", "syllabus page", "week table", "add week 4 to the site", "link the new deck on the site", "publish the course site", "GitHub Pages for my course". Writing or repairing a deck is teaching-lecture.
---

# Course website

One Quarto website project per course, per semester. It holds the page students
bookmark, a row for every week, the theme that makes the site and the decks read
as one system, and the publish path to GitHub Pages.

The boundary with `teaching-lecture` is hard. That skill owns a deck: slide
staging, the teaching blocks, figures, pacing, the fit gate. This skill owns the
site: `_quarto.yml`, `index.qmd`, the site theme, the navbar, handout wiring, and
publishing. `teaching-lecture` carries a short course-website section for the case
where someone arrives from the deck side. `teaching-lecture/SKILL.md` owns the
deck-level YAML and this skill owns only the site-level files.

The measured numbers below come from the example course this repo's `examples/`
lecture was extracted from; the mechanisms are what transfer to yours.

## Layout

```
~/teaching/<course>/
  _quarto.yml                  # project, website, navbar, format, post-render
  index.qmd                    # title, subtitle, instructor line, week table
  _extensions/starter/         # the deck format, installed once by `quarto add`
  assets/
    site.scss                  # your site theme (Bootstrap variables on a bootswatch base)
    logo.svg                   # the school or course mark for the navbar
    mathjax/                   # the slide tooling's MathJax copy, so deck math self-hosts
  lectures/
    _metadata.yml              # the per-course deck config, once
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

The decks run on the `starter-revealjs` extension format from the shared slide
tooling. Adopt it once at the project root, and give the site a MathJax copy:

```bash
cd ~/teaching/<course>
quarto add ~/.claude/assets/quarto-yale --no-prompt      # installs _extensions/starter/
cp -R ~/.claude/assets/quarto-yale/{mathjax,fonts} assets/
```

`assets/` holds the site theme plus the mark, and `lectures/_metadata.yml` holds
the deck config so a lecture file is content from its first line. Keep the
project out of Dropbox: rendered decks run several MB each and the sync churns
on every render.

## `_quarto.yml`

```yaml
project:
  type: website
  output-dir: docs
  render:
    - index.qmd
    - lectures/*.qmd
  resources:
    - assets/mathjax
  post-render:
    - scripts/build-handouts.sh

website:
  title: "AI and Managerial Decisions"
  navbar:
    title: false
    logo: assets/logo.svg
    logo-alt: "Your School"
    left:
      - href: index.qmd
        text: Lectures

format:
  html:
    theme: [cosmo, assets/site.scss]
    toc: false
```

`render:` is a glob, so a new lecture needs no config change. `output-dir: docs` is
what lets GitHub Pages serve from a branch subdirectory with no Actions workflow.
The `resources` entry keeps `docs/assets/mathjax/` in place across renders, which
is where the deck config below points the math.

`title: false` on the navbar is required once a logo is set. With no navbar title
Quarto falls back to `website: title`, which prints the course name beside the mark
and repeats the page title 40px below it. Setting `false` is the only way to get a
brand that is the mark alone.

`toc: false` because the landing page is one screen. Turn it on for a long
syllabus page and style the contents rail in the site theme.

Leave `title-block-banner` off. It paints a coloured band directly under the
navbar, and with a navbar that already carries the brand the top of the page
becomes two stacked mastheads.

## `lectures/_metadata.yml`

The extension format carries the deck machinery (theme, staging filter,
`citeproc: false`, the refs preset, the verified reveal defaults), so this file
holds only what is per-course:

```yaml
format:
  starter-revealjs:
    # These lectures render to docs/lectures/<name>.html and the site's MathJax
    # copy is at docs/assets/mathjax/ (the `resources` entry in _quarto.yml
    # keeps it there across renders), so the url is the path from the rendered
    # page to that copy.
    html-math-method:
      method: mathjax
      url: ../assets/mathjax/MathJax.js
engine: knitr
```

`bibliography:` stays out of it, in the one lecture that cites. What each key
does, and why the staging filter is not optional, is in `teaching-lecture`.

## The site theme

Theme choice is yours. Quarto's built-in [bootswatch themes](https://quarto.org/docs/websites/website-tools.html)
(cosmo, flatly, litera, darkly, and the rest) are the fast route: name one under
`theme:` and the site is presentable with zero SCSS. The durable pattern is a
bootswatch base plus one custom file layered on it, `theme: [cosmo,
assets/site.scss]`, where your palette, spacing, and navbar rules live. Whatever
the look, four disciplines carry over from the deck side:

- Write a measured contrast table into the head of `site.scss`, the way the deck
  theme does: each ink with its WCAG ratio against the page ground, measured with
  a checker. Anything used for text holds 4.5:1 or better. When some text or a
  rule later vanishes on the page, the table is where the answer is.
- Make the site and the decks read as one system: shared palette family, shared
  accent. The deck theme compiles inside the extension and the site theme in
  `assets/`, and the two files cannot share values through an `@import`, because
  Quarto compiles theme SCSS from a temp directory where a relative import does
  not resolve. Duplicate the shared values and keep the copies in sync by hand.
- Expose spacing as SCSS variables at the top of the file (space above and below
  headings, after a table or list, around the masthead, the navbar logo ceiling)
  and turn those instead of writing new margins per selector. Heading space
  works best asymmetric, large above and small below, so a heading binds to the
  section it opens.
- Prefix selectors with `.content` or `.quarto-container`. Quarto's own
  stylesheet sets heading and table margins and loads after the theme, so an
  unprefixed rule loses the tie.

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

Size and colour the tiers so the ranking is legible before any of it is read:
title largest in the heading ink, subtitle next in an accent, instructor line
smallest in the muted ink.

The instructor line is body markup. Quarto's `author` field renders inside the
`quarto-title-meta` grid under a small column label, and that grid is the thing the
theme suppresses (see the traps), so a fenced div is what gives the third line with
no label and no grid row.

The masthead's lower gap should transfer onto the instructor line when one is
present, so the three lines stay one block:

```scss
#title-block-header.quarto-title-block:has(+ .instructor) {
  margin-block-end: 0;
}

main.content > .instructor {
  margin-top: 0.5rem;
  margin-bottom: 2rem;   // whatever your masthead-to-body spacing variable holds
}
```

A page with no instructor line keeps its gap on the title block. `:has()` is
also what drops the empty metadata grid (the traps again), so it is already a
dependency.

## The navbar and the school mark

The brand is your school's or course's mark alone, on the bar.

Getting the file. Many universities publish no open logo download, so the vector
paths can come
from the inline SVG the school's own site serves in its page header. Download
it and commit it. Never hotlink a mark from a university server, which makes the
page depend on their CDN and breaks the offline case.

The committed asset, `assets/logo.svg`, should be the mark cropped out
of the full lockup: delete the wordmark group, tighten the viewBox to the
mark's measured bounding box, and reset the `width` and `height`
attributes to match. Match the mark's colouring to your navbar ground: a school's
own site often renders the reversed (light-on-dark) variant through CSS custom
properties, and one recolour of the outline reproduces it. A dark-on-transparent
mark dropped straight onto a dark navbar is invisible; if only a dark variant
can be found and recolouring is not wanted, say so and set a small wordmark in
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
Replace it in the site theme with a ceiling and let the width give:

```scss
.navbar .navbar-brand img.navbar-logo,
.navbar .navbar-brand-container img.navbar-logo {
  height: auto;
  width: auto;
  max-height: 38px;   // your logo-height variable
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
dimensions a near-square mark renders at the ceiling with a matching
narrow width, far too narrow to hit the `.navbar-brand-container` max-width
clamp, so it holds that size at every viewport width. The ceiling stays because
it is the correct rule for any wider mark that might replace a cropped one.

Quarto emits two `<img class="navbar-logo">` from a single `logo:`, one
`light-content` and one `dark-content`, both with the same `src`. Only one is
visible and the other takes no space, so a single file is the whole job on
a single-theme site.

Above 992px, hold the navbar to the same column as the body:

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
of the semester is information. Style the table in the site theme so no classes
are needed on it; a rule under the header row and a narrow tabular first column
go a long way.

The `pdf` cell only resolves because the post-render hook builds that file. A row
linking a PDF that nothing builds is a 404 no gate catches.

Under the table, a short section explaining the deck vocabulary earns its space,
because the coloured teaching blocks are a semester-long convention and students
need the key once.

## Adding lecture N+1

Three steps, no config change:

1. `lectures/wNN-slug.qmd`, content only, since `_metadata.yml` carries the config.
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

Write `scripts/build-handouts.sh` so that it reads
`QUARTO_PROJECT_OUTPUT_FILES` (so rendering one lecture rebuilds one handout),
falls
back to every deck in `docs/lectures/` when run by hand with no arguments, skips
with a warning when node or the exporter is missing so the site still renders on a
bare machine, and exits nonzero when an export actually fails. Adding a lecture
then needs no change to it. The per-deck export is one call:

```bash
node ~/.claude/assets/quarto-yale/deck-check.mjs handout \
  docs/lectures/w03-slug.html docs/lectures/w03-slug.pdf
```

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
| A second coloured band under the navbar | `title-block-banner: true` | remove it; the title sits on the page ground |
| An empty band between the subtitle and the body | Quarto emits `quarto-title-meta` even with no author or date, and the empty div still takes a grid row | `.quarto-title-meta:not(:has(*)) { display: none }` plus the `:empty` case |
| The course name printed beside the logo | navbar with a logo and no title falls back to `website: title` | `title: false` in the navbar block |
| Navbar shows alt text instead of the mark | the SVG will not parse | XML comments cannot contain two hyphens in a row, so a CSS custom property written with its leading dashes makes the file unparseable; validate with `python3 -c "import xml.etree.ElementTree as ET; ET.parse('x.svg')"` |
| The mark is invisible on the navbar | the logo's ink matches the bar's ground (a dark mark on a dark bar) | recolour the mark for your ground |
| Some text or a rule vanishes on the page | an ink whose measured ratio against the ground is near 1:1 (a brand colour on a dark ground, a pale gray on white) | check the hex against the site theme's contrast table and swap in one that holds 4.5:1 |
| A `pdf` link on the site 404s after a render | the render pruned a hand-placed file | build it in the `post-render` hook |
| Every asset 404s on GitHub Pages | a full render deleted `docs/.nojekyll` and Jekyll dropped the `_files` directories | `touch docs/.nojekyll` after every full render, and commit it |
| Only one lecture is ever online | `quarto publish` was pointed at a single `.qmd`, and a standalone-document publish replaces the whole site | render the website project and push `docs/`, served from `main` and `/docs` |
| The pushed site never appears | Pages on a private repository needs a paid plan | make the repository public |
| The instructor line appears under an "Author" label | Quarto's `author` field renders in the metadata grid | a `::: {.instructor}` div in the body |
| Headings crowd the block above them | Quarto's own stylesheet loads after the theme and sets heading margins | prefix the theme's selectors with `.content` or `.quarto-container` |
| A phone screenshot looks like the page overflows sideways | headless Chrome clamps the viewport to 500px | shoot the page inside a sized iframe |
| A theme edit does nothing | an `@import` of the other SCSS file, which cannot resolve from Quarto's temp compile directory | duplicate the shared values and keep the two files in sync by hand |
