---
name: evaluate-idea-science
description: Run an 8-step iterative pre-execution evaluation of a research idea targeting the broad general-science quality bar — PNAS, Nature Human Behaviour, Nature, Science. Use whenever the user wants to evaluate an idea for "a general-science venue", "PNAS", "Nature Human Behaviour", "Science", "Nature", or asks "is this big enough for a broad audience", "does this have general-interest impact", "could this go to Nature?" Also use when the user has a marketing/economics/CS idea and wonders whether to reframe it for a generalist editor. Covers phenomenon novelty, mechanism strength, generalizability, society-level implications, narrative tightness for a non-specialist editor, lit-review threat search, and a final verdict — looping on the pivot until the idea scores at least 7/10 against the broad-science bar.
---

# evaluate-idea-science

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.user.name` — used to fill the **Author** line in the generated report.
- `personal_config.user.affiliation` — optional, also used in report metadata.

## Purpose

Run an iterative pre-execution review of a research idea against the publishable bar of broad general-science journals: **PNAS, Nature Human Behaviour, Nature, Science**. This bar differs sharply from any field-journal bar — generalist editors and a non-specialist audience care about big-picture phenomena, broad generalizability, society-level stakes, and a clean narrative a smart non-expert can follow in two paragraphs.

Be exacting, hedged, and constructive — never hostile. The point is to catch problems and hallucinated rationale *before* months of data work are committed to a target that may not actually want the paper.

The output is a single structured Markdown report saved to disk.

## Phase 0: Parse the input

Inspect the user's request for an idea description. Three modes:

1. **Template mode** — if the user asks for the template, says "give me the template", or has not provided any idea content, write the template at the path below and stop.
2. **File mode** — if the user supplied a path (`.txt`, `.md`, or `.pdf`), read that file and treat its content as the idea.
3. **Inline mode** — if the user pasted the idea content into the chat, treat that as the idea.

The required template content for **Template mode** is:

```
RESEARCH IDEA — GENERAL-SCIENCE SUBMISSION
==========================================

IDEA TITLE:
[One-line title]

ONE-PARAGRAPH NEWSPAPER LEDE:
[3-4 sentences. Imagine a science reporter writing the first paragraph of a
news article about this finding. What is the phenomenon, why does it matter
for ordinary people, and what is surprising about your answer?]

THE PHENOMENON:
[1-2 sentences. What general-interest phenomenon is this paper about? Frame
it broadly.]

CORE QUESTION:
[1-2 sentences. What specific question does this paper answer? It should be
phrasable in plain English without jargon.]

HYPOTHESIS / MECHANISM:
[2-3 sentences. Proposed mechanism. Predicted direction. What alternative
hypothesis would a generalist editor wonder about?]

SOCIETY-LEVEL IMPLICATIONS:
[2-3 sentences. If this finding holds, what changes for policy, technology
design, public understanding, or human welfare? Be concrete; be honest.]

EVIDENCE STRATEGY:
[2-3 sentences. Empirical or experimental design. For PNAS/NHB-style work,
strong designs include large field experiments, registered analyses,
multi-country replications, large-scale observational data with credible
identification, or pre-registered behavioral experiments. Be specific.]

GENERALIZABILITY:
[2-3 sentences. Across what populations, settings, time periods, or platforms
do you expect the finding to hold? Across which would you NOT expect it?]

DATA SOURCES:
[Name every dataset. Be specific about country, time period, sample size,
and how it will be obtained.]

---------- ALL PAPERS ----------

CLOSEST PAPER 1:
- Citation: [Authors, Year, Journal, Title]
- URL: [Google Scholar / Nature / Science / OSF link]
- How it relates: [1-2 sentences.]

CLOSEST PAPER 2:
- Citation, URL, How it relates

CLOSEST PAPER 3:
- Citation, URL, How it relates

REPLICATION POTENTIAL:
[1-2 sentences. Is the finding pre-registrable? Will the data and code be
shareable? Can another team replicate within a year?]

WHY A GENERAL-SCIENCE AUDIENCE SHOULD CARE:
[1-2 sentences. Why is this not just a field-specific paper?]
```

Save this template to `./idea_template_science.txt` only in Template mode, then stop.

For File mode and Inline mode, verify the idea has: (a) a plain-English phenomenon framing, (b) hypothesis with predicted direction, (c) evidence strategy, (d) at least one named dataset or experimental design, (e) three named closest papers, and (f) at least an attempt at society-level implications. If any are missing, ask and stop — do not fabricate.

Choose a working directory: if a file path was supplied, use that file's parent; otherwise the current working directory. Build an `<idea_slug>` from the title (lowercase, dashes, no punctuation), and let `<DATE>` be today's date in `YYYY-MM-DD` format. The final report path is:

```
<workdir>/idea_eval_<idea_slug>_<DATE>.md
```

## Phase 1: The 8-step pipeline

Run the steps sequentially. The loop continues until the idea (or its latest pivot) scores **>= 7/10** at Step 4 *and* the Step 8 reviewer agrees. Hard cap: **3 pivots**. After the third failed pivot, write the report with the current best version and recommend `drop`, `reframe-for-specialist-journal`, or `radical-rethink`.

Do the reasoning in your head and write only the final block of each step into the report. Keep each step under ~300 words.

### Step 1: Evaluate idea

Score the idea 1–10 on six general-science-bar criteria. The bar means: (i) the phenomenon must be legible to a smart non-specialist editor in two paragraphs, (ii) the finding should change something a broad audience cares about, (iii) generalizability across populations/settings/contexts is a *core* virtue, not an afterthought, (iv) the design must be unusually clean or unusually large, (v) replication and pre-registration are valued, (vi) novelty is judged against the *whole science literature*, not one field.

Criteria:
1. **Phenomenon novelty for a broad audience.** Is the phenomenon itself surprising or important to someone who is not a specialist in the home field? A finding novel within marketing but a 30-year-old finding in psychology, behavioral economics, sociology, or human-computer interaction will be desk-rejected. Compare to closest work across all fields.
2. **Mechanism strength.** Is the proposed mechanism mechanistically clean — does it actually explain the phenomenon, not just predict it? Generalist editors reward "we understand *why*" over "we measure how much."
3. **Generalizability.** Across populations (US vs. multi-country), platforms (one site vs. multi-site), time (one year vs. multi-year), and contexts (one product vs. many). Single-platform single-country single-year work struggles at this bar unless the design is unusually credible.
4. **Society-level implications.** Does this matter for policy, technology design, public health, education, climate, equity, AI, democracy? "Important to one industry" is necessary but not sufficient.
5. **Narrative tightness for a generalist editor.** Can the paper's contribution be stated cleanly in one sentence and the finding in one bar chart? Editors triage on this within five minutes.
6. **Replication potential and methodological transparency.** Pre-registration, open data, open code, multi-team replicability. Increasingly load-bearing at NHB and PNAS.

Output: numeric score on each + overall + a hedged 200-word critique. Specific. Hedged voice: "we believe", "to note", numbered enumerate.

### Step 2: Review the evaluation

Adopt the persona of a senior interdisciplinary social-scientist (think: a PNAS associate editor with appointments in psychology and economics). Ask: is Step 1's critique fair? Did it under-weight an interdisciplinary contribution that *would* land at NHB? Did it over-rate something field-specific scholars love but generalist editors would yawn at? State agree / partially agree / disagree in 150 words. If unfair, re-run Step 1.

### Step 3: Pivot (only if score < 7)

Propose a pivot that keeps the phenomenon but raises the general-science bar. Concretely:
1. Keep the core phenomenon.
2. Broaden generalizability (multi-country, multi-platform, multi-context, multi-year).
3. Sharpen the mechanism — propose a follow-up study or moderator that pins down *why*.
4. Tighten the narrative — restate the contribution in one sentence for a non-specialist.
5. Strengthen the design (pre-registration, large field experiment, scale up the sample, add a replication arm).
6. Lift the society-level stake — be specific about which policy or design decision changes.

Max 400 words, hedged, enumerated.

### Step 4: Evaluate pivot

Re-run Step 1 on the pivot. If score did not rise above the prior score, loop back to Step 3 with the failure reason recorded. If >= 7, continue to Step 5.

### Step 5: Lit-review threat search

For the general-science bar, the threat surface is **wider than for a field journal**. Search across:

- **Semantic Scholar** (`mcp__semantic-scholar__search_papers`, `get_related_papers`, `search_authors`) for broad cross-field coverage
- **OpenAlex** (`mcp__openalex__openalex_search_entities`) for interdisciplinary breadth (psychology, sociology, public health, HCI, computational social science)
- **arXiv** (`mcp__arxiv__search_papers`) especially CS/ML/stat for adjacent computational work
- **WebSearch** for Nature / Science / PNAS / NHB recent issues, OSF pre-registrations, large-replication consortia (ManyLabs, Psychological Science Accelerator, COVIDiSTRESS)
- **Google Scholar** via WebSearch / WebFetch for citation counts and very recent preprints

A general-science threat is broader than a field threat: a 2019 *Psychological Science* paper showing the same mechanism in a different domain is a HIGH threat for a Nature submission even if no field-specific paper has shown it. Score every threat:
- `HIGH`: same phenomenon + similar evidence type + reaches similar conclusion, in ANY field
- `MEDIUM`: adjacent phenomenon or different field but generalist editors would cite
- `LOW`: related but clearly distinct contribution

Record: full citation, verifiable URL, 2-sentence summary, threat level, **and which field**. End with a one-paragraph **gap analysis** and 2-4 **defensive recommendations**.

### Step 6: Verify the lit review

For every paper cited in Step 5 and every paper the user named as a closest paper, verify it exists. Use Semantic Scholar `get_paper_details` or WebSearch on `"<title>" <first author>`. If a paper cannot be verified, **remove or mark `[UNVERIFIED]`**. Do not invent DOIs or URLs.

Missing-category check: for general-science, common categories that field-trained authors forget are: (i) cross-cultural / WEIRD-vs-non-WEIRD replications, (ii) large field-experiment papers (e.g., GiveDirectly, Behavioural Insights Team work), (iii) computational social science (e.g., Salganik / Centola), (iv) public health / health-comms parallels, (v) recent OSF pre-registrations on the exact topic. Add any verified additions.

### Step 7: Final verdict

Synthesize into a one-page verdict:
1. **Final score** (1–10) with justification.
2. **Top 3 remaining threats** and concrete moves.
3. **Suggested working title** (catchy, short, plain-English) and a one-paragraph 150-word abstract written for a generalist editor (no jargon).
4. **Recommended target**: PNAS / Nature Human Behaviour / Science / Nature, with one-sentence fit reasoning and one-sentence fallback (e.g., Psych Science, Nature Communications, Science Advances, PNAS Nexus).
5. **Key risk**: what could kill this paper at the generalist bar? One paragraph.
6. **Recommendation**: `proceed` (score >= 7), `pivot` (5-6.5), `reframe-for-specialist-journal` (the phenomenon and design are strong but the general-interest framing does not hold — better to submit to a field journal), or `drop`.

### Step 8: Review the final verdict

Adopt the generalist-editor persona again. Read the full report. Is the score consistent with the evidence? Is the recommended target realistic? Are the threats correctly weighted across fields? State agree / partially agree / disagree in 200 words. If you disagree and score < 7, loop back to Step 3 (subject to the 3-pivot cap).

## Phase 2: Write the report

Save to `<workdir>/idea_eval_<idea_slug>_<DATE>.md`. If the file exists, append `-v2`, `-v3`, etc. Use the structure below in a hedged, modest, enumerated voice.

```markdown
# Pre-Execution Idea Evaluation — <Idea Title>

**Author**: <personal_config.user.name>
**Date**: <DATE>
**Target standard**: General-science (PNAS / Nature Human Behaviour / Nature / Science)
**Final score**: <X>/10
**Recommendation**: <proceed | pivot | reframe-for-specialist-journal | drop>

---

## Executive summary

[3-4 hedged sentences for a generalist reader: phenomenon, principal strength, single most critical concern, recommendation.]

---

## 1. Idea (as submitted)

[Restate the phenomenon, question, hypothesis, evidence strategy, generalizability claim, data, society-level implications, and three closest papers.]

## 2. Step 1 — Initial evaluation

[Six-criterion scores + overall + 200-word hedged critique.]

## 3. Step 2 — Review of the evaluation

[Agree / partially agree / disagree + 150-word reasoning.]

## 4. Step 3-4 — Pivot history

[For each pivot: what changed, new score, why it succeeded or failed. If none was needed, write "No pivot required — initial idea scored >= 7."]

## 5. Step 5 — Cross-field threat search

**Threats found** (verified in Step 6):
1. [Citation] — URL — field — threat level — 2-sentence summary
2. ...

**Gap analysis**: [One paragraph.]

**Defensive recommendations**:
1. ...
2. ...

## 6. Step 6 — Verification notes

[Unverified papers; categories that were missing and added.]

## 7. Step 7 — Final verdict

**Final score**: <X>/10
**Top remaining threats**:
1. ...
2. ...
3. ...

**Suggested working title**: <plain-English title>
**One-paragraph abstract** (for a generalist editor, no jargon):
[150 words, hedged.]

**Recommended target**: <journal> (fallback: <journal>).
**Key risk**: [One paragraph.]

## 8. Step 8 — Review of the verdict

[Agree / partially agree / disagree + 200-word reasoning.]

---

## Appendix: Scoring rubric

| Criterion | Score (1-10) |
|---|---|
| Phenomenon novelty for a broad audience | |
| Mechanism strength | |
| Generalizability | |
| Society-level implications | |
| Narrative tightness for a generalist editor | |
| Replication potential and transparency | |
| **Overall** | |
```

After saving, report:
1. The path to the saved report.
2. The final score and recommendation.
3. The top three threats.
4. Any unverified citations to double-check by hand.

## Failure modes

- **No concrete idea provided.** Without phenomenon, hypothesis, evidence strategy, data, and three closest papers, ask for the missing pieces and stop. Do not fabricate.
- **Web search / MCP unavailable.** If Semantic Scholar / OpenAlex / arXiv / WebSearch all fail, Step 5/6 cannot run reliably. Run Steps 1-4 and 7-8, mark Step 5/6 as **`[NOT RUN — verification tools unavailable]`**, and tell the user the cross-field threat search must be done by hand before trusting the verdict. This skill's value depends heavily on the cross-field search because general-science threats come from outside the home field — be especially conservative about scoring without it.
- **Ambiguous scoring.** If the six criteria pull in opposite directions, do not split silently. State the tension ("we believe phenomenon novelty is high but generalizability is currently single-country, single-platform; we land at 6 because generalist editors penalize narrow settings heavily").
- **HIGH threat from an adjacent field.** A psychology/sociology paper from 10 years ago can kill a Nature submission. Do not silently drop it. Surface it, suggest a pivot, and let Step 7 recommend `reframe-for-specialist-journal` if the general-science framing genuinely no longer holds.
- **Field-jargon contamination.** Authors from any single field tend to leak jargon; the report and abstract must read as if written for a generalist audience. If the abstract still contains discipline-specific shorthand ("ad creative", "CTR", "SKU", "managerial implication", "treatment effect" without explanation), flag and rewrite.
- **3-pivot cap reached.** Write the report with the current best version. Recommend `drop`, `reframe-for-specialist-journal`, or `radical-rethink`. Do not loop indefinitely.
- **Citation cannot be verified.** Mark `[UNVERIFIED]` rather than asserting it exists or removing it silently.

## Out of scope

- **Implementation suggestions.** This skill does not design the field experiment, write the pre-registration, set up the multi-country sample, or implement the analysis pipeline. It evaluates whether the project clears the general-science bar, not how to execute it.
- **Funding-fit analysis.** Use `/review-grant` for NSF, NIH, foundation fit.
- **IRB / ethics advice.** Field experiments and multi-country work raise serious IRB issues; flag as a feasibility note but do not advise on protocol.
- **Registered-report / pre-registration drafting.** Use `/review-pap` for that workflow.
- **Replacement for an actual referee report.** After the paper is drafted, use `/review-paper` (with a general-science target) for the referee simulation. This skill is for pre-execution only.
- **Career strategy.** Whether a junior scholar *should* aim a paper at Nature versus banking field-journal publications for tenure is a strategy question, not an idea-quality question. The user decides.
