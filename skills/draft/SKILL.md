---
name: draft
description: Drafts paper sections (Intro, Lit Review, Method, Empirical Setting, Empirics, Discussion, Limitations, or arbitrary paragraphs) in the user's voice — hedged, modest, natbib-apa citations, \Cref cross-references, \emph over \textit, figure/table notes minipages, three-stream lit-review structure. Use this skill whenever the user asks to "draft", "write", "rewrite in my voice", "give me a paragraph on", or "draft a section" for any of their papers. Also triggers on phrases like "write the limitations", "draft an intro for X", "write up the empirical setting", "rewrite this in my voice". Output always goes to a dated draft file under `<project>/drafts/` — never directly into the main `.tex`.
---

# /draft — Section drafting in the user's voice

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.user.voice_style_ref` — path to a `.tex` or `.md` file containing the user's voice fingerprint (preferred macros, hedging vocabulary, citation idioms). If unset, this skill cannot reliably match a personal voice and must ask whether to use a neutral academic register instead.
- `personal_config.paths.overleaf_root` — root directory containing all project subdirs.
- `personal_config.projects[]` — each entry declares `name`, `overleaf_subdir`, `main_tex`, optional `bib_file`, optional `nickname` and `aliases`, optional `stage` (e.g. "working paper", "R&R at MKSCI").

## Purpose

The user writes for quantitative-marketing journals (Marketing Science, JMR, JCR, Management Science) and similar venues. Their LaTeX is on Overleaf, synced through Dropbox. They write the final word themselves in Overleaf — this skill's job is to deliver a clean draft that already sounds like them, with the citations and macros they actually use, so the manual edit pass is small.

## Required reading before drafting a single sentence

Re-read these on every invocation. Personal voice is precise — summarizing from previous-turn memory is not acceptable.

1. **`personal_config.user.voice_style_ref`** — the canonical voice fingerprint (paper voice + R&R voice + macro inventory). Read fully.
2. **The active project's `preamble.tex`** — to know which bold-math macros and citation commands are available. Glob `preamble.tex` first; fall back to the first ~100 lines of the main `.tex` if no separate preamble exists.
3. **The active project's main `.tex` (and any sibling section files)** — at least enough to: (a) match notation already established for variables, (b) avoid re-introducing definitions, (c) avoid duplicating citations the user already used.
4. **The active project's `.bib`** — so `\citep{}` keys are real, not hallucinated. If the user names a paper that isn't in the .bib, surface that and route them to `/cite` rather than fabricating a key.

If any of (1)-(4) is missing, surface the gap and ask once before proceeding.

## Identifying the active project

The user's projects live under `personal_config.paths.overleaf_root`. Pick the project in this order:

1. The user's explicit mention of a project name or alias from `personal_config.projects[]`.
2. cwd if it's already inside one of those folders.
3. If still ambiguous, ask. Don't guess — the wrong preamble means the wrong macros.

Each project entry in `personal_config.projects[]` should expose enough to locate its main file and bib:

| Config field | Meaning |
|---|---|
| `name` | Canonical project name |
| `nickname` / `aliases` | User shorthand the skill can match against free-form mentions |
| `overleaf_subdir` | Subdirectory under `overleaf_root` |
| `main_tex` | Filename of the main `.tex` (e.g. `main.tex`, `mainR2.tex`) |
| `bib_file` | Filename of the `.bib` |
| `stage` | Optional — e.g. "JMP", "R&R at MKSCI (R2)", "working paper" |

## Style rules — strict, from `voice_style_ref`

These are the "non-negotiables" — they're what makes the draft sound personal and not like Claude default.

- **Citations**: `\citep{key}` is the default (parenthetical). `\citealt{key}` when already in a sentence and the author name with no parens is needed. `\citet{key}` only when the author is the grammatical subject. Never `\cite{}`. In appendices, the project may use `\citealtlatex` / `\citeplatex` — check preamble.
- **Cross-references**: `\Cref{fig:...}`, `\Cref{tab:...}`, `\Cref{sec:...}`. Never `Figure~\ref{...}` or `Section 3`.
- **Emphasis**: `\emph{...}` for technical/conceptual emphasis (the workhorse). `\textbf{}` reserved for genuinely critical claims — sparingly. Italics on first-use of a term being defined.
- **Hedged tone**: "to the best of our knowledge", "we believe", "to note", "more broadly", "in contrast", "altogether", "furthermore". Sprinkle, don't carpet. Never overclaim. Avoid "interestingly", "importantly", "obviously", "clearly", "needless to say" — those die on the first revision pass.
- **Voice**: first-person plural ("we"), short-to-medium sentences, one claim per paragraph, active voice unless passive is necessary for emphasis.
- **Figures and tables**: every `\begin{figure}` / `\begin{table}` block is followed by `\begin{minipage}{\textwidth}\footnotesize \emph{Notes:} <detailed notes>\end{minipage}`. If the notes are not known, write a placeholder and tag `% TODO`. Sample minipage:
  ```latex
  \begin{minipage}{\textwidth}
  \footnotesize \emph{Notes:} % TODO: describe sample, what is plotted, controls absorbed, CI level, data source.
  \end{minipage}
  ```
- **Footnotes**: for pre-registration deviations, methodological asides, citations to less-central work. Not for parenthetical asides — those go inline.
- **Bold-math macros**: prefer the project's existing bold-math macros (e.g. `\bphi`, `\bomega`, `\bz`, `\bw`, `\bs`, `\bm{\theta}`, `\bm{\psi}`, `\bm{\gamma}`, `\bm{\alpha}`, `\bm{\beta}`) over `\boldsymbol{...}`. Check preamble.
- **Numbers in prose**: spell out one through nine; numerals for 10+ and for any number with a unit. Percentages: `15\%` not "15 percent".

## Section-specific guidance

**Intro (5–7 paragraphs typical for MKSCI)** — Hook with a substantive phenomenon or puzzle (not a methodological one). Position relative to three short streams of prior work in 1–2 sentences each. State the gap. State the contribution as 3 bullets max. Preview findings concretely (one effect-size sentence per main finding). End with a roadmap paragraph.

**Lit Review** — Three streams, one paragraph each. Each opens with the stream's name and the core idea, surveys 4–8 key papers with `\citep{}` (sentence-by-sentence, not piled at the end), and ends with one sentence positioning the current paper relative to the stream. End the section with a 1-paragraph synthesis.

**Method** — Plain-English description first, formal model second. Define notation as you introduce it. State assumptions explicitly as `\textbf{Assumption 1.}` blocks when there are multiple. Use the project's existing bold-math macros from preamble.

**Empirical Setting / Data** — Describe the setting in narrative form (one paragraph), then bullet or table the data sources, sample windows, observation counts, and any pre-registration. Always include a sample-construction paragraph with explicit filters.

**Empirics** — Model-free first, model-based second. Each subsection leads with the question being answered. Each table/figure is anchored to a `\Cref{tab:...}` reference in the body text and accompanied by a notes minipage.

**Discussion** — What we found, what it means substantively (not statistically), implications for managers / researchers / policymakers, broader contributions. No new findings here.

**Limitations** — Explicit, enumerated. Don't bury. Each item: limitation + why it doesn't kill the paper + how future work could address. Three to five items typically.

**Rewrite-in-my-voice** — when the user pastes a paragraph, preserve all substantive claims exactly; adjust only phrasing, citation form, emphasis, and hedging to match style rules. If the change is substantial, show the old/new diff as `% OLD:` / `% NEW:` comment blocks inside the draft.

## Output

Write to: `<project>/drafts/<section>_<YYYYMMDD>_claude.tex` — create `drafts/` if it doesn't exist.

Header comment block on every draft file:
```latex
% Draft generated by /draft on <YYYY-MM-DD>
% Section: <e.g., Introduction, Limitations>
% Project: <project name>
% Source style ref: <personal_config.user.voice_style_ref>
% Status: DRAFT — user to revise in Overleaf
% Inline TODOs flagged with % TODO
```

Then the section content. Use `% TODO:` comments to flag:
- Citations needed (`% TODO: cite — paper on user-generated content`)
- Numbers to be filled (`% TODO: fill N=`)
- Empirical claims unverifiable from current context (`% TODO: confirm this matches Table 4`)
- Locations the user needs to disambiguate (`% TODO: user — should this go before or after the field-experiment paragraph?`)

**Never invent**: citation keys, numerical results, author names, paper titles, statistical claims not already in the data or results.

## After writing — chat report

1. Path to the new draft file.
2. Two-sentence summary of what was written.
3. List of every `% TODO:` item inline so the user knows what to fill.
4. List of `\citep{}` keys used that don't appear in the project `.bib` — flag for `/cite` next.

Do not modify the main `.tex`. Do not stage commits. Do not push to Overleaf. Dropbox sync handles propagation.

## Failure modes

- **Project ambiguous**: if the user didn't name a project and cwd isn't inside one, ask once. Don't default to whichever project is at the top of the config.
- **Preamble missing**: if no `preamble.tex` and the main `.tex` doesn't reveal macros, write the draft assuming `\boldsymbol{...}` and tag `% TODO: confirm bold-math macros against preamble`.
- **.bib file missing or empty**: write the draft with placeholder citations like `\citep{TODO_smith2023}` and tag the absence — don't fabricate keys that "look real".
- **Rewrite request contains numeric claims you can't verify**: preserve the numbers exactly as written; do not silently round or rephrase magnitudes.
- **Section that requires unwritten results** (e.g., Empirics with no Tables/ yet): draft the prose scaffolding with `\Cref{tab:TBD_main}` placeholders and tag each one `% TODO: produce table first`.
- **R&R-style rewrite where the source paragraph already follows the style**: say so explicitly rather than padding with cosmetic changes. The right answer is sometimes "this paragraph is already in your voice".

## Out of scope

- Modifying the main `.tex` directly — the user does precise edits in Overleaf.
- Generating BibTeX entries — that's `/cite`. Flag missing citations; don't fabricate them.
- Running the lit search to populate citations — that's `/litreview` upstream of this skill.
- Drafting referee responses — that's `/referee-response`.
- Writing in a non-personal voice (e.g., "draft this in journalistic style") — decline politely and ask whether they want the voice or the style adjusted.
- Producing figures, tables, regressions, or code — those come from the user's R/Python pipeline.
- Committing or pushing — Dropbox handles Overleaf sync.
