# Mirror notes

This repository is a genericized subset of a working `~/.claude` tree. Each file here is derived
from a private original by a fixed set of rules, and a few things are deliberately different
rather than merely renamed. Both are written down so a later sync applies them instead of
re-deriving them, and so a reader can tell an adaptation from an oversight.

## Genericization rules

1. Absolute home paths become `~`. The one exception is a sample log or JSON payload where a
   literal path is the point, which uses `/Users/you/...`.
2. The author's name, email, and site become `Your Name`, `you@example.edu`, and
   `https://your-site.example`. A `mailto=` in an API call keeps the placeholder plus the line
   telling the reader to substitute a real address. An author name inside a `.bib` entry is a real
   citation and stays.
3. Institution names go neutral: an HPC cluster rather than a named grid, `/home/<user>/` rather
   than a netid, `Dropbox-YourUniversity` rather than a named account, a generic mark and site
   theme rather than a specific school's.
4. Flat assertions about the author's machine become guidance a reader can adapt, in the form
   "this setup assumes X; adjust to your machine".
5. Memory links in double brackets are removed. Where the sentence needed the fact the memory
   carried, the fact is stated inline.
6. Nothing points into the private configuration. A skill that referenced a rule living only in
   the private `CLAUDE.md` carries that rule inline instead.
7. Per-call subagent model routing is stripped, since the routing convention it belongs to is not
   published here.
8. Skills route only to skills this repository ships. A passage that handed work to a private
   skill is rewritten to say what to do instead of naming a skill the reader does not have.
9. No skill directory is added that is not already here. Files inside an existing skill may be
   added.

## Deliberate divergences

The `.vmid` class in `research-talk`. The private theme defines a class that centres a div's
content under a title pinned to the top, and the private skill documents it. The
`starter-theme.scss` shipped here has no such class, so the public skill covers vertical alignment
with reveal's own `{.center}` and never mentions `.vmid`. Keep it out until the shipped theme
gains an equivalent.

One reveal.js format instead of two. The private tooling ships a light talk format and a dark
lecture format; `slide-tooling/` ships a single `starter-revealjs`. Every place the private skills
contrast the two named themes is generalized here to "the shipped starter theme" and "a deck on a
designed dark theme". The directory name `~/.claude/assets/quarto-yale/` and the
`.highlight-yale` class survive as names only, because SETUP.md installs to that path.

Stub house styles. `research-talk/style/house.md`, `teaching-lecture/style/house.md`, and
`slide-review/style/house.md` are stubs for the reader's own author line, contact block, palette
rationale, and density calibration. The private originals hold the author's real values and are
not published. A sync never overwrites a stub.

A neutral course site. `course-site` uses `assets/site.scss` and `assets/logo.svg` where the
private skill names a specific school's site theme and shield.

The prose-tell list in `review-paper`. The private skill points at the Voice section of the
private `CLAUDE.md`; the public copy inlines the list of constructions to flag.

Skills not published. The private tree also holds skills for unstructured-data causal inference,
sparse autoencoders, activation steering, image-generator interpretability, and email drafting.
None of them are here, and the shared bibliography's section comments name topics rather than
those skills.

Sections of `CLAUDE.md` not published. The private file carries a section on mirroring the
configuration to its own repositories and a section on a specific computing grid. Neither belongs
in a file offered as an example, so neither is published.
