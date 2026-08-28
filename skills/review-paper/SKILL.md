---
name: review-paper
description: Referee a full manuscript against a named target journal: parallel agents on style, consistency, unsupported claims, math, exhibits, and contribution, triaged CRITICAL/MAJOR/MINOR. TRIGGER on "review my paper", "referee my draft", "is this ready to submit", "what would a referee say", "desk reject risk", "read this like Reviewer 2", "referee this for [journal]", "write my referee report". Critiquing an idea or plan is council; answering referees is referee-response.
---

# review-paper

Six agents read the manuscript in parallel and return severity-tagged findings with quoted
evidence; the main thread consolidates them into one dated report ranked by what would sink the
paper. Nothing in the manuscript is edited. Topology and agent roles adapted from
[`claesbackman/AI-research-feedback`](https://github.com/claesbackman/AI-research-feedback), the
buried-contribution gate from
[`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation).

## Options

| Argument | Default | Meaning |
|---|---|---|
| a journal name (first token) | `top-field` | journal persona and bar for agent 6 |
| a file path | auto-detect | main `.tex`, or a `.pdf` of the compiled draft |
| `--quick` | off | run only agents 6 and 3, skip the rest |
| `--referee` | off | journal referee mode: a submittable report, see below |

Recognized journals, case-insensitive. Marketing: `MKSCI`, `JMR`, `JCR`, `MS`. Economics:
`AER`, `QJE`, `JPE`, `Econometrica`, `REStud`, `AEJMacro`, `JME`, `RED`. Finance: `JF`, `JFE`,
`RFS`, `JFQA`. Anything unrecognized is treated as a file path, and an absent journal means
`top-field`: high general standards for a leading field journal, no specific persona. Add
journals by editing this list. Store the result as `TARGET_JOURNAL`.

## Referee mode

`--referee` switches the skill from a pre-submission check on the user's own draft to a
submittable report on a paper the user is refereeing for a journal. Enter this mode when the flag
is passed, when the user says they are refereeing, or when the paper is clearly not theirs. When
it is ambiguous whose paper it is, ask which hat the user is wearing before doing anything else.

What changes:

- The manuscript must be supplied as a path or a PDF. Phase 1 uses step 1 only; never glob the
  working directory or the Overleaf projects. If no path was given, ask for one.
- Agent 6 keeps its full brief, including the buried-contribution gate, but critiques the paper
  for the editor and drops every piece of advice addressed to the author: no fallback outlets in
  part 5, no coaching on what would reach the target's bar. Its recommendation becomes one of the
  journal's conventional decisions: accept, minor revision, major revision, or reject.
- All six agents still run (two with `--quick`), and the CRITICAL/MAJOR/MINOR triage still
  happens, as internal analysis. The final report is written from that analysis and never shows
  the tags.

The output replaces the phase 3 structure. Write `REFEREE_REPORT_<YYYY-MM-DD>.md` to the current
working directory, or wherever the user says; never into an Overleaf project. Address it to the
editor and the authors in the conventional register:

1. A summary paragraph restating the paper in the referee's own words: the research question, the
   design, the data, and the main findings. Specific enough to show the paper was read.
2. Major comments, numbered. Built from the CRITICAL and MAJOR findings: identification threats,
   missing analyses, overclaiming, internal contradictions. Each states the issue, points at the
   exact location, and where possible says what would resolve it.
3. Minor comments, numbered. Notation, exposition, table and figure documentation, typos worth
   the authors' time. Compress agent 1's copy edits into a few representative items; a referee
   report is not a proofreading pass.
4. Recommendation, with a short justification tied to the major comments.

Report back in chat: the report path, the recommendation, and the counts of major and minor
comments.

## Phase 1: find the manuscript

1. An explicit path argument wins. The Read tool cannot open a `.pdf` on this machine (it needs
   `pdftoppm`; this setup assumes no Homebrew and no poppler, so adjust to yours), so route every PDF through the helper:
   `~/.claude/assets/bin/pdfread.py text paper.pdf` for the text, or
   `~/.claude/assets/bin/pdfread.py png paper.pdf --pages N --dpi 150 --out /tmp/p` and then Read
   the PNG when the layout or a figure matters. Never call `pdftotext` or `pdftoppm`.
2. No path: Glob `**/*.tex` in the working directory.
3. Still nothing: Glob `~/Library/CloudStorage/Dropbox*/Apps/Overleaf/*/*.tex` (this setup
   assumes Overleaf projects sync there via Dropbox), show the matching project
   directories, and ask which one. Do not guess between projects.

In referee mode, step 1 is the only step: skip steps 2 and 3 and ask for the path if none was
given.

Then build the file set. The main document is the `.tex` containing `\documentclass` or
`\begin{document}`; follow every `\input`, `\include`, and `\subfile` to get the rest, and read
all of them. Figures are `**/[Ff]igure*/**/*.pdf` and the same for `png`, `jpg`, `jpeg`, `eps`,
`svg`, plus root-level images. Tables are `**/[Tt]able*/**/*.tex` plus root-level
`*[Tt]able*.tex`. Exclude `**/_minted-*/**`, `**/build/**`, `**/output/**`, `**/.git/**`, and
Dropbox conflicted copies (`*conflicted copy*`), which are stale and produce phantom findings.

Record every file path and its role, the figure and table lists, and the title, authors, and
abstract. If no figures turn up, tell the user they may live in a non-standard directory and to
re-run with an explicit path. Same for tables, adding that agent 5 will then be limited to
captions and cross-references.

## Phase 2: launch the agents

One message, all agents at once, `subagent_type: general-purpose`. Each agent prompt is the
shared brief below, then that agent's checklist, then its output sections. Subagents inherit
nothing, so write the shared brief into every prompt in full. Agent 6 additionally gets the line
"The target journal is `<TARGET_JOURNAL>`" and keeps the conditional logic in its brief intact.

### Shared brief (paste into every agent prompt)

> You are reviewing an academic empirical manuscript. Read every file listed at
> the end of this prompt, completely, before writing anything. Files are LaTeX source unless
> noted. The Read tool cannot open a `.pdf` here, so get PDF text with
> `~/.claude/assets/bin/pdfread.py text <file.pdf>` (add `--pages 1-20` to work through a long
> document in chunks). `pdftotext` and `pdftoppm` are not installed in this setup; do not call them.
>
> Ignore LaTeX markup unless the markup is itself the problem. For every finding, quote the exact
> text and give a location precise enough to find it without searching: file and section for
> LaTeX, page and paragraph for a PDF.
>
> Tag every individual finding with a severity at the start of its line, one tag per item, never
> per section:
> `[CRITICAL]` would trigger a desk rejection or invalidates a claim, and must be fixed before
> submission. `[MAJOR]` a referee will raise it and it costs a revision round. `[MINOR]` polish.
>
> Report only what the files support. If a check is impossible from the sources you were given,
> say so explicitly instead of skipping it silently, and do not speculate about content you
> could not read. An empty category is a real finding: write "None found" instead of padding.
>
> Files to review: [tex paths] Figures: [figure paths] Tables: [table paths]

### Agent 1, spelling, grammar, and academic style

Copy editor at a top empirical journal. Check misspellings, with attention to proper nouns,
technical terms, and confusable pairs (affect/effect, principal/principle); grammar, including
subject-verb agreement, tense discipline (present for findings, past for what was done),
articles, dangling modifiers, comma splices, fragments; sentences that need re-reading, supplying
a clearer alternative; typographic consistency (hyphenation such as "long-run" versus "long run",
attributive versus predicative "high-income", em versus en dash); number formatting (under ten
spelled out in prose, "15%" versus "15 percent" used consistently).

Flag every instance of: "interestingly", "importantly", "notably", "it is worth noting",
"obviously", "clearly" (delete, let the finding speak); tautologies ("very unique", "absolutely
essential"); "significant" used for size or importance when it should mean statistical significance;
"This paper contributes to the literature by" (show it); passive voice where active is natural;
inconsistent person ("we find" alongside "the paper argues").

Output sections: Critical, Major, and Minor issues, each a numbered list of
`[TAG] location | "problem text" -> "correction" | reason`; then Recurring style patterns, one
example per pattern with a global fix instruction.

### Agent 2, internal consistency and cross-references

Technical reviewer checking whether the paper contradicts itself.

1. Numerical consistency. Every number in the text (coefficients, percentages, sample sizes,
   years) must match the referenced table, read from the table source directly. Numbers that
   exist only inside a figure image cannot be verified from source; skip those instead of flagging
   them.
2. Abstract against body, and introduction previews ("we find X") against what the results
   section actually delivers.
3. Terminology. List the key terms and flag any that shift meaning across sections, including
   variable names that change and technical terms used interchangeably with loose synonyms.
4. Sample description: years, observation counts, and filters consistent across abstract, data
   section, and table notes.
5. Fixed effects and controls: what each specification claims versus what its table shows.
6. Magnitude and direction of the same finding wherever it is restated.
7. Citations. Every author-year cited in text must have a bibliography entry. Flag missing ones.
   For citations that carry the paper's positioning (closest prior work, "X shows Y" claims that
   the argument leans on), verify with
   `~/.claude/skills/reading-papers/scripts/paper.py resolve "<author year title>" --json` and
   flag any characterization that does not match the cited work. Do not audit the whole
   bibliography entry by entry; that is the `bibcheck` skill's job. Check the citations the
   argument leans on.

Output sections: Critical inconsistencies (`[TAG] location A <-> location B | what conflicts`);
Terminology drift (term, how it varies, recommended standard); Minor inconsistencies.

### Agent 3, unsupported claims and identification integrity

Skeptical econometrician enforcing claim discipline: a claim must never exceed what the
identification allows. This agent works at the sentence level; the overall research design is
agent 6's job.

1. Causal language ("causes", "leads to", "drives", "determines", "due to", "results in") applied
   to findings that are only correlational. Quote the sentence, say why it exceeds the design,
   and separate two cases: causal words over a correlation, and a mechanism described as an
   established fact when it is a hypothesis.
2. Generalization past the sample: managerial or policy implications drawn from one platform,
   market, or period without an argument for why they travel.
3. Mechanism claims asserted instead of argued.
4. Missing caveats. Walk the obvious threats for this design (selection into the sample, reverse
   causality, measurement error, omitted variables) and flag each one the paper never addresses.
5. Priority claims ("we are the first to show", "no prior study has examined"). Check with
   `~/.claude/skills/reading-papers/scripts/paper.py resolve` or `cites`; if a counterexample
   turns up, that is `[CRITICAL]`. If the search is inconclusive, flag it as an unverified
   priority assertion the authors must confirm, and do not rule on it yourself.
6. Statistical versus economic or managerial significance: significance reported with no
   discussion of magnitude, or "significant" standing in for "important".
7. Hedging in both directions: claims stated too strongly, and strong results buried under
   excessive hedging.

Output sections: Causal overclaiming (`[TAG] location | "quote" | why it overclaims | fix: weaken
the language or add the evidence`); Generalization issues; Missing caveats (topic, where it
belongs, suggested text); Minor language issues.

### Agent 4, mathematics, equations, and notation

1. Correctness: derivations follow from stated assumptions, no algebraic or arithmetic errors,
   subscripts and terms in written regressions match the verbal description.
2. Notation consistency: one symbol per quantity (list every symbol defined and flag reuse),
   stable subscript conventions ($i$ individual, $t$ time, $g$ group), vectors and matrices
   distinguishable from scalars.
3. Undefined notation: every symbol defined at or before first use.
4. Equation numbering: referenced equations are numbered, numbered equations are referenced, and
   each in-text reference points at the right equation.
5. Specification consistency: the written equation against the verbal description, the table
   column headers, and the stated controls and fixed effects. Variables in the text but not the
   equation, and vice versa.
6. Rate definitions: annualization formulas, percent versus percentage point, log approximations
   flagged where used.
7. Inference notation: standard error, t-statistic, and confidence interval formulas, and
   clustering notation consistent with how the paper says inference is done.
8. LaTeX math problems that change meaning or readability: missing `\left`/`\right` on tall
   delimiters, `*` for multiplication, unwrapped text in math mode, broken alignment in multi-line
   equations.

Output sections: Mathematical errors (location, error, correction); Notation inconsistencies
(symbol, the two conflicting uses, resolution); Undefined notation; Specification issues; LaTeX
math formatting.

### Agent 5, tables, figures, and their documentation

Journal production editor. The Read tool displays `.png`, `.jpg`, and `.jpeg` figures visually.
For a figure saved as `.pdf`, rasterize it first with
`~/.claude/assets/bin/pdfread.py png fig.pdf --dpi 200 --out /tmp/fig` and Read the PNG. Look at
every figure you can render and judge what is actually plotted. For a `.eps` figure, ghostscript
(if installed) can rasterize it when needed:
`gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r200 -o /tmp/fig.png fig.eps`, then Read the PNG.
`.svg` cannot be viewed; assess it from caption, notes, and label text only, and say that is
what you did.

For every table: a caption that stands alone; column headers naming the dependent variable and
the specification difference; notes covering sample definition, dependent variable and units,
controls, fixed effects, how standard errors are computed and at what clustering level, the
meaning of the stars, and whether the parenthetical is a standard error or a t-statistic;
standard errors and N in every column, with differing samples across columns made explicit; every
table cited in text and every in-text reference pointing at a table that exists and shows what is
claimed; consistent decimals, stars, and fixed-effect indicators.

For every figure: a self-contained caption; both axes labeled with units; a legend for multiple
series; confidence intervals on binscatters, coefficient plots, and event studies; notes covering
the sample, what is plotted (raw data or residuals after controls), bin counts and absorbed
controls for binscatters, what the intervals represent, and the data source; every figure cited
in text, with the description matching what the image shows. Where you viewed the image, also
flag unreadable fonts, overlapping labels, truncated axes, and colors that die in greyscale.

Output sections: Tables with missing or incomplete notes (by table number); Figures with missing
or incomplete notes (by figure number); Cross-reference issues; Formatting inconsistencies.

### Agent 6, contribution evaluation (adversarial top-journal referee)

Demanding associate editor deciding whether the paper goes to referees or gets desk rejected.
Exacting and specific, not hostile. Adopt the norms of `TARGET_JOURNAL`: for a named marketing
journal, its scope, methodological bar, framing expectations around substantive marketing
relevance and managerial implications, and its audience; for a named economics or finance
journal, the same; for `top-field`, high general standards with no journal persona.

Part 1, the central contribution. State in one sentence what the paper claims to contribute. Is
it new or a replication in a new setting? What is the closest prior paper and what does this add
beyond it? Does it settle something researchers disagree about? Does it change how people think
about the topic? Rate it Transformative, Significant, Incremental, or Insufficient for the target
journal, and justify in two or three sentences.

Part 1b, buried-contribution gate. From `\begin{document}`, counting prose only (skip LaTeX
commands, comments, and the abstract), count words until the first sentence containing "we find",
"we show", "we document", "our main result", "the headline", "we report", "in this paper, we",
"the contribution", or "we contribute". Report the count and the phrase that matched, or "no
trigger found in body". Over 2500 words: `[MAJOR]`, headline finding buried deep, strong
desk-reject risk at MKSCI, JMR, JCR, and MS. Between 1500 and 2500: `[WARN]`, buried roughly
three double-spaced pages in, a common desk-reject signal. At or under 1500: `[OK]`. If the
abstract already delivers the headline unambiguously, downgrade `[WARN]` to `[INFO]` and note
why. Never downgrade `[MAJOR]`: a 2500-word runway buries the finding whatever the abstract says.

Part 2, identification and credibility, judged at the design level (sentence-level claims are
agent 3's job).
What variation identifies the main result, is it plausibly exogenous, and what are the threats?
Does the paper confront them or paper over them? Is the finding causal, correlational, or
descriptive, and does the paper claim the right one? What would a skeptical econometrician say in
a seminar, and what would it take to convince a top-journal audience?

Part 3, analyses. Required (up to 5, absence is a blocker): robustness checks not performed,
including any the paper claims but does not show; alternative explanations left standing; missing
placebo or falsification tests. For each, state the analysis, why its absence undermines
credibility, and what a positive result would do to your view. Write "None" if the paper covers
its identification concerns. Suggested (up to 5, not blockers): mechanism tests, subgroup
analyses, extensions, each described precisely with why it matters and whether it is feasible
given the data the paper describes.

Part 4, literature positioning. Are the right papers cited, and what is obviously missing? Does
the paper distinguish itself from the closest work? Is it over-citing minor papers and
under-citing major ones? Is the introduction's framing the most compelling one available?

Part 5, journal fit and recommendation. For a named journal, is this a strong fit on scope,
methods, and contribution level, and what are the fit risks? For `top-field`, name the best
realistic targets. Recommend Send to referees, Revise before sending to referees, or Desk reject,
say concretely what would reach the target's bar, and name the best fallback outlet.

Part 6, four to seven pointed questions aimed at the weakest points, worded as they would appear
in a referee report.

Tag every Required analysis `[CRITICAL]` and every Suggested analysis `[MAJOR]`. Output sections
follow parts 1 through 6 in order, with part 1b inside part 1.

## Quick mode

With `--quick`, run agents 6 and 3 only, in parallel, and skip phase 1's figure and table globs.
This is the cheap gut check: does the paper have a contribution, is it buried, and does the prose
claim more than the design supports. Emit the report with only those two sections plus the
priority list, mark the header `Scope: quick (contribution and identification only)`, and tell
the user that consistency, math, tables and figures, and copy editing were not run.

## Phase 3: consolidate and save

If an agent returns nothing or malformed output, insert a placeholder section ("Agent did not
return output") and say so in the summary. Do not silently drop it and do not re-run the whole
fanout for one failure.

In referee mode, consolidate the same way but write the report described in the referee mode
section instead of the structure below.

Save to `PRE_SUBMISSION_REVIEW_<YYYY-MM-DD>.md` in the main `.tex` file's directory, suffixing
`-v2`, `-v3` if that name is taken. Structure:

```markdown
# Pre-submission referee report

Paper: <title> | Authors: <authors> | Date: <YYYY-MM-DD>
Review standard: <journal name, or "leading field journal" for top-field>

## Overall assessment
<Three or four sentences: what the paper does, from agent 6 part 1; its principal strength, from
the contribution rating; the single most critical issue, from the top of the priority list. Do
not introduce judgments the agents did not make.>

Preliminary recommendation: <copied verbatim from agent 6 part 5, not paraphrased>

## 1. Contribution and referee assessment   <- agent 6
## 2. Unsupported claims and identification  <- agent 3
## 3. Internal consistency                   <- agent 2
## 4. Mathematics and notation               <- agent 4
## 5. Tables, figures, and documentation     <- agent 5
## 6. Spelling, grammar, and style           <- agent 1

## Priority action items
```

Build the priority list by collecting every tagged item across agents and ranking:
`[CRITICAL]` from agent 3 and agent 6 part 2 first, then `[CRITICAL]` from agent 6 part 3, then
remaining `[CRITICAL]` in agent order, then all `[MAJOR]`, then `[MINOR]`. Keep each item's
source agent and location so the author can jump to it. A `[WARN]` from agent 6's part 1b enters
the list as `[MINOR]` unless the reviewer upgrades it; `[OK]` and `[INFO]` stay in the report
body and never enter the priority list.

Then report back in chat: the report path, agent 6's recommendation, the top five action items,
and the count of findings in each severity.
