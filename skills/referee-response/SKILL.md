---
name: referee-response
description: Drafts an R&R response letter in the user's R2R style — sectioned by role (Senior Editor / Associate Editor / Reviewer 1 / Reviewer 2), reviewer quotes in `\textit{...}`, location-pinned changes ("see Section 3", "Footnote 7", "Table 4"), "Done." for trivial fixes, polite pushback with cited authority, abandoned drafts kept in `\begin{comment}` blocks. Reads existing `R2R_*.tex` files in the project for tone match and grounds every location pin against the actual `main*.tex`. Use whenever the user asks to "respond to referees", "draft an R&R response", "write the R2R", "address reviewer comments", "respond to the AE", or pastes reviewer comments from an Outlook export / decision letter. Also triggers on "continue the R2R" (extend a partial draft). Output goes to `<project>/R2R_R<n>.tex`.
argument-hint: "[continue] [from-email] [@path/to/decision-letter.pdf] [--five-q]"
---

# /referee-response — R&R response letter in the user's voice

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.user.voice_style_ref` — file containing the user's R2R voice fingerprint (per-role sections, italics for quotes, "Done." conventions, hedged pushback templates).
- `personal_config.paths.overleaf_root` — root containing project subdirs.
- `personal_config.projects[]` — per-project entries with `name`, `overleaf_subdir`, `main_tex`, and optional `r2r_glob` (defaults to `R2R_*.tex`).

## Purpose

The R&R is a journal submission, so the cost of fabrication is high: a hallucinated "we added X on page 27" gets caught by the editor and erodes trust. This skill uses a multi-pass review pattern — classify every comment, verify every location pin against the actual manuscript, surface gaps explicitly — and renders the *output* in the user's R2R style: per-role sections, italics for quotes, location pins, "Done." for trivials.

## When to invoke

The user invokes `/referee-response` when they have reviewer comments to respond to. Inputs come in several shapes:

- `/referee-response` with comments pasted in the message body.
- `/referee-response @path/to/decision-letter.pdf` (or `.txt`, `.docx`).
- `/referee-response from-email` — Outlook export pasted.
- `/referee-response continue` — extend a partial `R2R_R<n>.tex` already in the project.

## Required reading before drafting

Re-read on every invocation — don't summarize from session memory.

1. **`personal_config.user.voice_style_ref`** — full file, especially the R&R style section. This is canonical.
2. **The latest existing `R2R_R*.tex` in the project** — Glob the project's `R2R_*.tex` and read the highest-numbered one. This is the tone match for the new round.
3. **The current `main*.tex`** — to ground location pins. Read at least the table of contents (section/subsection labels), the footnote count, and any explicitly-labeled tables/figures.
4. A bibliography reference — only if a reviewer cites a paper that needs adding; route through `/cite` rather than fabricating citations.

If a referee report is a scanned/image PDF with no OCR text, stop and ask for a text version. Do not invent comments from the title page.

## Style rules — non-negotiable, from `voice_style_ref`

- **Opening of the file**: a one-paragraph global thanks ("We would like to thank the review team for your constructive, detailed, and insightful comments...") followed by a numbered `\begin{enumerate}` list summarizing the main changes at a high level. Then per-role sections.
- **Per-role sectioning**, in this order:
  - `\section*{Senior Editor}`
  - `\section*{Associate Editor}`
  - `\section*{Reviewer 1}`
  - `\section*{Reviewer 2}`
  - (continue if more reviewers; preserve numbering received)
  Each section opens with a one-paragraph thanks unique to that role.
- **Each comment**: verbatim quote in `\textit{...}`, then `\newline`, then response in plain text below.
- **"Done."** — exactly that, one word, period — for trivial fixes with an explicit SE/AE instruction. Always followed by a one-sentence location pin: "Done. See Footnote 7." Never use "Done." for substantive comments.
- **Location pins** — every substantive change is anchored: "see Section 3.2", "see Web Appendix A.4", "Footnote 7", "Table 4". Never say "we changed it" without a location. Never invent a location not verified against `main*.tex`.
- **Quoting new paper text into the R2R** — wrap with LaTeX double quotes `` `` ... '' `` and bold the load-bearing phrases with `\textbf{}`.
- **Polite pushback** when respectfully disagreeing — open with "To the best of our understanding..." or "We believe that our specification is aligned with...", then cite the relevant authority (e.g., `\citep{atheyImbens2017}`) and quote them inline. End by inviting the editor's discretion.
- **Abandoned drafts** — keep prior or abandoned response drafts inside `\begin{comment}...\end{comment}` blocks rather than deleting; preserves revision history.
- **Citations** — `\citep{}` / `\citealt{}` / `\citet{}` per the paper-voice rules. Never `\cite{}`.

## Workflow

### Step 1 — Parse the referee report

Extract structured comments. If the input is a PDF, use `pdftotext` (Windows: PowerShell `pdftotext.exe` if available; otherwise fall back to a quick Bash conversion). Convert to:

```
[
  { role: "Senior Editor",      comments: [ "<verbatim>", "<verbatim>", ... ] },
  { role: "Associate Editor",   comments: [ ... ] },
  { role: "Reviewer 1",         comments: [ ... ] },
  { role: "Reviewer 2",         comments: [ ... ] },
]
```

If the source isn't pre-labeled by role, ask once to confirm role assignments. If comments aren't numbered, preserve the source's structure (paragraphs, bullets) — don't impose numbering the user didn't receive.

### Step 2 — Multi-pass classification

For each comment, pick a response strategy. Doing this as a separate pass before drafting catches misclassifications early.

| Strategy | When to use | Response template |
|---|---|---|
| **Done.** | SE/AE gave an explicit instruction with a single-action fix (typo, format, missing citation, swap a word) | `Done. <location pin>.` |
| **Substantive change** | Reviewer requested an analysis, a robustness check, additional discussion, or a model revision — and the change is genuinely incorporated | Multi-sentence: acknowledge → state what we changed → location pin → quote new text inline with key phrase `\textbf{}` |
| **Partial / scoped change** | Reviewer asked for X, we did a scoped version of X | Multi-sentence: acknowledge → describe scope of what we did → location pin → explain (briefly) why we scoped rather than full |
| **Polite disagreement** | Reviewer's premise is mistaken or contradicts a more-authoritative source | Open with "To the best of our understanding..." → state reasoning → cite authority with brief inline quote → end inviting editor's discretion |
| **Deferred** | Out of scope, separate paper, would require new data collection beyond R&R window | Acknowledge → state why deferred → point to where (if anywhere) we flag this in the paper |
| **Needs user input** | Cannot classify without substantive judgment | Leave `% TODO: user — clarify what you want to do with R<n>.<m>` and a one-sentence question |

### Step 3 — Multi-pass verification (claim-discipline pass)

Before writing the final response paragraphs, for every "Substantive change" or "Partial change" classification:

1. Open `main*.tex` at the location you plan to pin.
2. Confirm the change is actually there. Match the quoted text in the response against the text in the manuscript (or its `\input{}` files).
3. If the change is **not** present, downgrade the classification:
   - "Substantive change" with no evidence in manuscript → `Partial change` with TODO, OR `% TODO: user — please confirm change made and update location`.
   - Never assert "we added X to Section Y" without having read X in Section Y.

The cost of getting this wrong is a credibility hit with the SE.

### Step 4 — Draft the response file

Output path: `<project>/R2R_R<n>.tex` where `<n>` is the round number specified, or one more than the highest existing `R2R_R*.tex`.

File header:

```latex
% Draft generated by /referee-response on <YYYY-MM-DD>
% Round: R<n>
% Project: <project name>
% Source style ref: <personal_config.user.voice_style_ref>
% Status: DRAFT — user to revise in Overleaf
% Verification: each "Substantive change" was checked against <main file>
% Inline TODOs flagged with % TODO
```

File body:

```latex
We would like to thank the review team for your constructive, detailed, and
insightful comments. We have substantially revised the manuscript in response.
The main changes are as follows:
\begin{enumerate}
  \item <one-sentence summary of major change 1, with location>
  \item <... change 2>
  \item <... change 3>
\end{enumerate}

\section*{Senior Editor}
We thank the Senior Editor for <one-sentence specific thanks, not generic>.

\textit{<verbatim quote of SE comment 1>}
\newline
<response paragraph, location-pinned>

\textit{<verbatim quote of SE comment 2>}
\newline
Done. See Footnote 12.

\section*{Associate Editor}
We thank the Associate Editor for <specific thanks>.

\textit{<quote>}
\newline
<response>

\section*{Reviewer 1}
We thank Reviewer 1 for <specific thanks>.

\textit{<quote>}
\newline
<response>

\section*{Reviewer 2}
We thank Reviewer 2 for <specific thanks>.

\textit{<quote>}
\newline
<response>
```

### Step 5 — Chat report

Print to chat (not into the file):

1. Path to the new `R2R_R<n>.tex`.
2. Count of comments parsed per role.
3. **Count of `% TODO:` items** needing user attention, with the comment IDs (e.g., R1.3, R2.7).
4. **Substantive positions taken** that the user should sanity-check — list each one with its location pin and the position taken. Surfaces anything where a judgment was made that the user might want to override.
5. Any reviewer comments that **cite a paper not yet engaged with** in the manuscript — suggest routing those papers through `/cite` before submitting.

## Modes

### Default (no flags)

Behavior is exactly as described in the Workflow section above: per-role sectioning, `\textit{...}` quotes, location pins verified against `main*.tex`, "Done." for trivial fixes, hedged pushback with cited authority, abandoned drafts preserved in `\begin{comment}...\end{comment}` blocks. No additional gating.

### `--five-q` — so-what gatekeeping on pushback (OPT-IN)

Activates a hostile-editor stress test on every paragraph classified as **Polite disagreement** in Step 2. Before drafting the pushback prose, answer the following five questions about the disputed claim, in a brief scratch block (not in the output file):

1. What is the question?
2. Why should anyone care?
3. What is the finding?
4. How do we know?
5. What does it mean for the field?

If any answer is unclear, hand-wavy, or thinner than the reviewer's objection, **switch strategy** from "defend and push back" to "concede partially + strengthen with new evidence" (i.e., reclassify the comment from `Polite disagreement` to `Partial / scoped change` per the Step 2 table). Draft the new concede-and-strengthen paragraph as the active response, and preserve the original rejected pushback draft inside `\begin{comment}...\end{comment}` per the abandoned-draft convention.

In the Step 5 chat report, add a line per comment that was downgraded: "R<n>.<m>: pushback downgraded under --five-q; weak answer to Q<k>".

This flag is OPT-IN ONLY — invoked as `/referee-response --five-q` (combinable with `continue`, `from-email`, or a `@path` input). Without the flag, default behavior is unchanged. Never auto-trigger.

## Failure modes

- **Comments not labeled by role**: ask once for labeling, then proceed.
- **Comment too vague to classify** ("the paper needs more context"): mark `% TODO: user — needs your read; possibly substantive`, not a guess.
- **Reviewer cites a specific paper not in the bib**: flag, suggest `/cite`. Do not draft a response that pretends the paper is already cited.
- **PDF input is image-only / scanned with no OCR**: stop; ask for a text version. Don't invent comments.
- **Multiple reviewers raise the same point**: respond to each separately within their own section — do not merge. Cross-reference with "(see also our response to Reviewer 1, Comment 3)" if helpful.
- **Reviewer asks for something already pushed back on in a prior round**: read the prior `R2R_R<n-1>.tex` for the existing language; reuse / refine rather than restart the argument. Don't contradict the prior position without flagging it as a `% TODO: user — prior round said X; do we still hold that line?`.
- **AE gives directly conflicting instructions to a reviewer** ("AE says X; R2 says not-X"): write the response following the AE's instruction (the AE is decisive) and surface the conflict explicitly in the chat report.
- **`main*.tex` has been edited since the prior R2R was filed and you can't tell what's new**: don't assume edits exist — verify against current `main*.tex`. If a location-pin can't be verified, downgrade per Step 3.

## Anti-patterns — never do these

- Don't restructure the per-role `\section*{...}` convention.
- Don't summarize multiple comments into one combined response.
- Don't drop a comment because it seems redundant — every comment gets an explicit reply.
- Don't write in first person singular — always "we".
- Don't use `\cite{}`; use `\citep{}` / `\citealt{}` / `\citet{}`.
- Don't claim a change was made without verifying against `main*.tex`. Use `% TODO` instead.
- Don't delete the abandoned-draft `\begin{comment}` blocks from prior rounds — preserve them.
- Don't push to Overleaf or commit — Dropbox handles sync.

## Out of scope

- Modifying `main*.tex` — the user does substantive paper edits themselves; this skill only drafts the response letter.
- Generating new analyses to address a reviewer concern — that's a separate workflow (run R/Python, regenerate tables, then come back to this skill).
- Adding citations to the `.bib` — route through `/cite`.
- Critiquing the reviewer's arguments substantively — surface positions, don't invent counter-arguments the user hasn't sanctioned.
- Writing the SE/AE thanks paragraph in generic boilerplate — make it specific to what the SE/AE actually said.
