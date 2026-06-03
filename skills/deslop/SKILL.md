---
name: deslop
description: Scrubs AI-writing tells (em-dash overuse, the "delve list", not-only-but-also, "it's important to note", vague attributions, rule-of-three, title-case headings, oaicite artifacts) from public-facing text — manuscripts, grant prose, emails, cover letters — and rewrites AI cadence into the user's own voice, matching the right register for the text type (correspondence voice for emails/messages/cover letters; manuscript voice for papers/sections/abstracts/grants). Two-pass: mechanical regex scrub + semantic rewrite. Auto-applies (edits files in place; returns cleaned text for pasted input); domain-whitelists econometrics terms (robust SEs, leverage points, significance) so they're not nuked. Trigger phrases: "/deslop", "deslop this", "scrub the AI", "make this sound less like AI", "remove the AI tells", "humanize this", "does this read like AI", "de-slop my email/intro/cover letter". Composes with /draft (which writes in-voice) — /deslop cleans existing text.
argument-hint: "[path-to-file OR pasted text] [--voice=correspondence|manuscript] [--mechanical-only] [--report] [--domain=marketing|econ|generic]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash"]
effort: medium
---

# /deslop — AI-writing-tell scrubber

`/deslop` takes any public-facing text — a manuscript paragraph, grant prose, an
email, a cover letter — and removes the fingerprints of AI writing so it reads
like the user's own voice rather than model default. It runs two passes: a
deterministic mechanical scrub, then a semantic rewrite into the user's cadence.

The detection taxonomy lives in `references/ai-tells.md` (tunable, versionable —
the delve-list shifts as models change). The econometrics whitelist lives in
`references/domain-whitelist.md`. The voice target lives in
`references/voice-samples.md`, which holds **two registers** — Correspondence and
Manuscript/grant — each falling back to the configured voice reference
(`personal_config.user.voice_style_ref`) until populated. Read all three on every
invocation — do not summarize from memory. The pass-2 rewrite uses ONE register,
selected per the "Voice register" section below.

## When to invoke

- "deslop this", "scrub the AI out of this", "make this sound less like AI"
- "does this read like AI?", "humanize this", "remove the AI tells"
- "de-slop my intro / email / cover letter / grant paragraph"
- Any time the user pastes text or names a file and wants the AI cadence gone.

Not for: verifying citations (→ `/bibcheck`), drafting new prose (→ `/draft`).

## Inputs

The argument is either a **file path** or **pasted text**.

- **File path** (e.g. a `.tex`, `.md`, `.txt`): edit in place. Recoverable via
  git / file history, so no review diff is needed (see Output behavior).
- **Pasted text**: return the cleaned text in chat. Do not write a file.

Flags:

- `--voice=correspondence|manuscript` — force the pass-2 voice register, skipping
  auto-detection. Aliases: `--voice=email` → correspondence; `--voice=paper` and
  `--voice=grant` → manuscript. See "Voice register" below.
- `--report` — print the tell-scorecard only; do NOT apply any change. Use when
  the user wants a preview.
- `--mechanical-only` — run pass 1 (deterministic scrub) and skip the LLM
  rewrite. Faster, fully predictable, no voice judgment.
- `--domain=marketing|econ|generic` — selects the whitelist strictness
  (`references/domain-whitelist.md`). Default: the user's field. `generic`
  relaxes the econometrics whitelist for non-technical prose (emails, letters).

## Voice register — select before the pass-2 rewrite

The pass-2 rewrite targets ONE of two registers from `references/voice-samples.md`.
The mechanical pass-1 scrub is **register-independent** (em-dash thinning,
delve-list, artifact stripping, sentence-case headings, etc. apply to all text) —
register selection affects only pass 2, plus the one punctuation rule noted below.

Select the register in this order:

1. **`--voice=` flag wins.** `correspondence` / `email` → Correspondence;
   `manuscript` / `paper` / `grant` → Manuscript.
2. **Auto-detect from the input:**
   - A `.tex` file, OR content containing `\citep`, `\section`,
     `\begin{abstract}`, or `\Cref`, OR the user says
     "paper / manuscript / section / abstract / grant / proposal / R&R"
     → **Manuscript register**.
   - An email, short message, cover letter, OR the user says
     "email / message / note / reply / cover letter", OR short informal text with
     a greeting and/or sign-off → **Correspondence register**.
3. **On ambiguity:** infer the most likely register from content, APPLY it, and do
   not stop to ask. STATE the choice in the scorecard (one line, e.g.
   `Register: manuscript`) so the user can re-run with `--voice=` if it was wrong.

**Register-conditional punctuation rule (the one pass-1 exception):**

- **Correspondence:** convert AI em-dashes "—" to a spaced hyphen " - " if that is
  the user's correspondence convention (see `references/voice-samples.md`); never
  introduce an em-dash.
- **Manuscript:** em-dashes / en-dashes follow standard academic LaTeX usage. Do
  NOT force the spaced hyphen. Still thin em-dash *overuse* by frequency, but a
  correctly-used em-dash in formal prose is fine.

## Pass 1 — Mechanical scrub (deterministic)

Apply the regex + word-list detectors in `references/ai-tells.md`, in this order.
Each detector is keyed on **frequency, not presence** — see the thresholds in the
reference file. Run every delve-list candidate through `domain-whitelist.md`
*before* flagging it.

Detector families (full patterns + thresholds in `references/ai-tells.md`):

1. **Delve-list vocabulary** — flag by density; suppress on a domain anchor.
2. **Stock phrases** — "it's important to note that", "stands as a testament",
   "in the heart of", "rich tapestry of", etc.
3. **Negative parallelism** — `not only … but`, `it's not …, it's …`.
4. **Vague attributions** — "studies show", "experts argue" → named source or cut.
5. **Connective-opener overuse** — sentence-initial Additionally/Moreover/…
6. **Trailing "-ing" significance clauses** — "…, further enhancing its …".
7. **AI-tool artifacts (HARD FAIL)** — `oaicite`, `contentReference`,
   `turn0search`, `grok_card`, stray `utm_source=`. Always strip on any match.
8. **Punctuation / formatting** — em-dash density, curly→straight quotes,
   `**Bold:** description` lists, Title Case headings → sentence case, emoji in
   headings, `---` before a heading. (Em-dash handling is register-conditional —
   see "Voice register": user's correspondence convention vs. standard academic
   usage in Manuscript.)
9. **Rule of three** — flag triplet density; prune the filler third in pass 2.

Pass 1 fixes are mechanical and safe (artifact removal, formatting, em-dash
thinning, sentence-case headings). Anything requiring judgment about meaning is
deferred to pass 2.

## Pass 2 — Semantic rewrite to voice

Skip this pass under `--mechanical-only` or `--report`. Otherwise, first select
the voice register (see "Voice register" above), then rewrite the
flagged-but-not-mechanically-fixable prose into the user's voice **for that
register** — the correspondence voice for emails/messages/cover letters, or the
manuscript voice for papers/sections/abstracts/grants:

- **Promotional / significance puffery → plain fact.** "stands as a vibrant hub"
  → "is a town".
- **Hedging filler → direct claim or deletion.** Strip empty throat-clearing
  ("it's important to note that"); KEEP the author's genuine substantive hedges.
- **Vague attribution → named source or cut.** Never invent a citation.
- **AI cadence → user's cadence.** Kill elegant variation (forced synonym swaps),
  kill the "Challenges and Future Prospects" conclusion frame.
- **"is"-avoidance verb inflation → plain copula.** "serves as / boasts /
  represents" where it just means "is" → "is".

Ground the voice in the SELECTED register of `references/voice-samples.md` (each
register falls back to the configured voice reference when its samples are empty;
for manuscript input that reference is the same one `/draft` uses). Preserve every
substantive claim, number, quotation, and title exactly — adjust phrasing and
cadence only. For `.tex`, respect LaTeX: keep `\emph` over `\textit`, `\Cref`,
natbib citations; do not mangle math or macros.

## Domain whitelist

See `references/domain-whitelist.md`. The short version: a delve-list word is
suppressed (not flagged) when it sits within a few tokens of a stats anchor
(`standard errors`, `regression`, `specification`, `identification`, `controls`,
`p-value`, …). "robust standard errors", "leverage points", "significant at the
5% level", "comprehensive controls" are technical vocabulary, not slop. The verb
"leverage a dataset" IS a tell; the noun "leverage points" is not.

## Output behavior — auto-apply (no review diff)

Per the user's explicit preference, **do not** run an interactive accept/reject
loop per edit.

- **File argument**: edit the file in place with the `Edit` tool. The user
  recovers prior versions via git / file history if needed.
- **Pasted text**: return the cleaned text directly in chat.
- **`--report`**: apply nothing; print only the scorecard.

After applying (or in `--report` mode), print a short **scorecard** — what
changed, by category, with counts. Not a per-edit diff; a summary:

```
deslop scorecard — <file or "pasted text">  [domain=econ]
  Register: manuscript  (auto-detected; override with --voice=correspondence)
  HARD FAIL artifacts stripped ........ 2  (oaicite, contentReference)
  Delve-list words removed/replaced ... 5  (delve→examine, tapestry→set, …)  [3 suppressed by whitelist]
  Stock phrases rewritten ............. 3
  Em-dashes thinned ................... 4 → 1
  Negative parallelism rewritten ...... 1
  Vague attributions flagged .......... 2  (need a citation — see below)
  Title-case headings → sentence ...... 2
  Rule-of-three triplets pruned ....... 1
  Semantic rewrites (pass 2) .......... 6 sentences
Whitelist suppressions: "robust standard errors", "leverage points", "comprehensive controls"
Unresolved: 2 vague attributions need a real source — route to /cite or cut.
```

## Anti-over-scrub guardrails

- **Frequency is the signal, not presence.** One em-dash, one triplet, one
  "additionally" is fine. Tune thresholds; never zero out a construction.
- **Preserve direct quotations and titles verbatim.** Never scrub inside a quote.
- **Preserve domain technical terms** (the whitelist).
- **Never invent facts** to "improve" a sentence. If removing puffery leaves an
  unknown fact, flag it — do not fabricate.
- **Keep the author's real voice.** Remove the machine's fingerprints, not the
  writer's own style. The user's genuine hedges and rhythm stay.

## Relation to /draft and /referee-response

- `/draft` *writes* new prose in the user's voice. `/deslop` *cleans* existing
  text — they compose: draft → deslop, or deslop text written elsewhere.
- `/referee-response` writes R&R letters in-voice; run `/deslop` on a pasted
  paragraph if it came from another tool and needs the AI cadence removed.
- `/deslop` never adds citations or verifies them — that is `/bibcheck` (audit)
  and `/cite` (add).

## Examples

**Email (pasted, `--domain=generic`).** Input: *"I wanted to reach out to delve
into a potential collaboration. Your groundbreaking work stands as a testament to
your commitment to excellence — not only is it rigorous, but it also showcases a
nuanced understanding of the field."* → Output: *"I'm writing about a possible
collaboration. Your work is rigorous and shows a careful understanding of the
field, which is why I'd like to talk."* Scorecard: 1 stock phrase, 1 delve word,
1 negative-parallelism, 1 em-dash, "groundbreaking" puffery — all cleaned.

**Manuscript paragraph (file, `--domain=econ`).** Input contains *"We leverage a
rich tapestry of data. Our robust standard errors underscore the pivotal role of
the treatment, highlighting its enduring significance."* → The whitelist
**suppresses** "robust" (anchored to "standard errors"). "leverage" (verb),
"rich tapestry", "underscore", "pivotal role", and the trailing "-ing" clause are
fixed: *"We use a large panel. The treatment effect is precisely estimated
(robust standard errors)."* Scorecard notes the whitelist suppression so the user
sees the term was deliberately kept.

## Out of scope

- **Citation verification** — `/bibcheck` (audit existing `.bib`), `/cite` (add
  one entry). `/deslop` only flags vague attributions; it never invents or
  verifies a citation.
- Writing new sections from scratch — `/draft`.
- Translating to a non-author voice (e.g. "make this sound journalistic") —
  decline; `/deslop` targets the user's own voice only.

## Credit

The AI-tell detection taxonomy in `references/ai-tells.md` (delve-list,
stock-phrase set, negative-parallelism patterns, formatting tells, markup
artifacts, vague-attribution markers) is derived from the Wikipedia essay
**"Signs of AI writing"** —
<https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing> — used under
**CC BY-SA**. That derived taxonomy text carries the CC BY-SA attribution +
share-alike obligation; the skill *code / workflow* itself is MIT (see the
repo `LICENSE`). See `ATTRIBUTION.md` for the repo-level credit.
