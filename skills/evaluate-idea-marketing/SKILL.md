---
name: evaluate-idea-marketing
description: Run an 8-step iterative pre-execution evaluation of a quantitative marketing research idea targeting the Marketing Science / JMR / JCR / Management Science (Marketing) quality bar. Use whenever the user wants to "evaluate a research idea", "score this idea", "is this idea publishable in MKSCI/JMR/JCR/MS", "pivot my idea", "stress-test my project", "find threats to my idea", or pastes a research-question/hypothesis and asks whether it is worth pursuing. Covers idea evaluation, fairness review, pivoting, lit-review threat search with citation verification, and a final verdict — looping on the pivot until the idea scores at least 7/10 against the top marketing-journal bar.
---

# evaluate-idea-marketing

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.user.name` — used to fill the **Author** line in the generated report.
- `personal_config.user.affiliation` — optional, also used in the report metadata.
- `personal_config.user.voice_style_ref` — optional; if present, the report adopts that voice. Otherwise it uses a hedged academic register.

## Purpose

Run an iterative pre-execution review of a research idea against the publishable bar of the top quantitative-marketing journals: **Marketing Science (MKSCI), Journal of Marketing Research (JMR), Journal of Consumer Research (JCR), and the Marketing department of Management Science (MS)**. Be exacting, hedged, and constructive — never hostile. The whole point of this skill is to catch problems and hallucinated rationale *before* months of data work are committed.

The output is a single structured Markdown report saved to disk.

## Phase 0: Parse the input

Inspect the user's request for an idea description. Three modes:

1. **Template mode** — if the user asks for the template, says "give me the template", or has not provided any idea content, write the template at the path below and stop.
2. **File mode** — if the user supplied a path (`.txt`, `.md`, or `.pdf`), read that file and treat its content as the idea.
3. **Inline mode** — if the user pasted the idea content into the chat (research question, hypothesis, identification, data, three closest papers), treat that as the idea.

The required template content for **Template mode** is:

```
RESEARCH IDEA — QUANTITATIVE MARKETING SUBMISSION
=================================================

IDEA TITLE:
[One-line title]

PAPER TYPE: [Empirical (reduced-form) / Structural / Experimental (lab/field/online) / Theoretical / Methodological]

RESEARCH QUESTION:
[1-2 sentences. What specific question does this paper answer?]

HYPOTHESIS / MECHANISM:
[2-3 sentences. What is the proposed mechanism? Predicted sign or direction.
What would alternative explanations predict?]

MANAGERIAL / SUBSTANTIVE RELEVANCE:
[1-2 sentences. What marketing decision does this inform — pricing, advertising,
recommendation, assortment, branding, consumer welfare? Why does a manager,
platform, or policymaker care?]

---------- FOR EMPIRICAL/STRUCTURAL PAPERS ----------

IDENTIFICATION STRATEGY:
[2-3 sentences. DAG-level reasoning. Source of exogenous variation: shock, IV,
RDD, DiD, RCT, conjoint, or structural assumption. If you do not have one yet,
say so — the pipeline will surface this.]

DATA SOURCES:
[Name every dataset. Be specific.]

PROPOSED MODEL/REGRESSION:
[Equation or specification. For structural papers: utility specification,
moments. For experimental papers: design, manipulation, DV, planned analysis.]

---------- FOR THEORY/METHODOLOGY PAPERS ----------

MODEL SETUP / PROBLEM:
[See marketing-theory or method conventions.]

KEY PREDICTIONS / DEMONSTRATION:
[Testable predictions or simulation/empirical demonstration.]

---------- ALL PAPERS ----------

CLOSEST PAPER 1:
- Citation: [Authors, Year, Journal, Title]
- URL: [Google Scholar / SSRN / journal link]
- How it relates: [1-2 sentences. Be specific about the gap a referee would push on.]

CLOSEST PAPER 2:
- Citation, URL, How it relates

CLOSEST PAPER 3:
- Citation, URL, How it relates

WHY THIS MATTERS:
[1-2 sentences. Substantive marketing implication; broader social-science
implication if applicable.]
```

Save this template to `./idea_template_marketing.txt` only in Template mode, then stop.

For File mode and Inline mode, before running anything verify that the idea contains: (a) research question, (b) hypothesis with predicted sign, (c) at least a sketch of identification or experimental design, (d) data source(s), and (e) three named closest papers. If any of these are missing, ask for them and stop — do not fabricate them.

Choose a working directory: if a file path was supplied, use that file's parent directory; otherwise use the current working directory. Build an `<idea_slug>` from the title (lowercase, dashes, no punctuation), and let `<DATE>` be today's date in `YYYY-MM-DD` format. The final report path is:

```
<workdir>/idea_eval_<idea_slug>_<DATE>.md
```

## Phase 1: The 8-step pipeline

Run the steps below sequentially. The loop continues until the idea (or its latest pivot) scores **>= 7/10** at Step 4 *and* the Step 8 reviewer agrees the score is justified. Hard cap: **3 pivots**. After the third pivot fails, write the report with the current best version and recommend `drop` or `radical-rethink`.

For each step, **do the reasoning in your head and write only the final block into the report**. We do not need a verbose trace. Keep each step under ~300 words unless a list is genuinely required.

### Step 1: Evaluate idea

Score the idea 1–10 against six criteria, applying the **MKSCI/JMR/JCR/MS bar**. The bar means: (i) a sharp managerial or substantive marketing question that a serious editor would care about, (ii) identification or experimental design that survives a skeptical structural/causal/behavioral reviewer, (iii) novelty over a tight cluster of closest marketing papers — not just over loosely related work, (iv) data feasibility consistent with what marketing PhDs realistically obtain (proprietary panels, scraped data, lab/online experiments, platform partnerships), (v) substantive contribution beyond the next-best paper.

Criteria:
1. **Novelty within marketing literature.** Not "first to study X anywhere" but "first to credibly answer this specific question in marketing." Compare to the three closest papers.
2. **Identification / design rigor.** For empirical papers, name the threat (selection, reverse causality, OVB, attrition) and assess whether the design beats it. For experimental papers, evaluate construct validity, demand effects, sample, and generalizability. Reduced-form papers: is the IV/RDD/DiD assumption defensible? Structural papers: are identifying restrictions credible?
3. **Theoretical or empirical advancement for marketing.** Does it move a marketing literature stream forward — pricing, advertising, search, recommendation, branding, social influence, sustainability, fairness, generative AI?
4. **Managerial relevance.** Is there a non-trivial decision a manager, platform, or regulator could make differently because of this? "Interesting to academics only" is a flag.
5. **Data feasibility.** Are panel data, online-experiment recruitment, scraping pipeline, partnership, or simulation realistic given typical PhD/junior-faculty resources?
6. **Relevance and timing.** Is this a question marketing cares about now (vs. a 2010 question), or a timeless question with a fresh angle?

Output: numeric score on each criterion + overall (1–10), and a hedged 200-word critique. Be specific. Adopt the user's voice (if a voice-style ref is configured): "we believe", "to the best of our understanding", "to note", numbered enumerate when listing weaknesses.

### Step 2: Review the evaluation

Adopt the persona of a senior marketing professor reading the Step-1 critique. Ask: is the critique fair, accurate, well-reasoned? Did Step 1 over- or under-weight any criterion? Did it dismiss a defense the idea actually has? State agree / partially agree / disagree in 150 words. If Step 2 finds Step 1 unfair, re-run Step 1 with corrections before continuing.

### Step 3: Pivot (only if Step 1/Step 2 score < 7)

Propose a pivot that keeps the core marketing topic but fixes the lowest-scoring criterion. Concretely:
1. Keep the substantive area.
2. Add a credible identification or design improvement (a specific shock, IV, RDD, DiD setting, or experimental manipulation — name it).
3. Sharpen the predicted sign and the mechanism.
4. Name the data move (different panel, different platform scrape, partner with a firm, run a conjoint, add a field experiment).
5. Articulate the "new thing we learn" in one sentence.

Max 400 words. Hedged, enumerated.

### Step 4: Evaluate pivot

Re-run Step 1 on the pivot using the same six criteria. If the pivot score is <= Step-1 score, loop back to Step 3 with the failure reason recorded. If the pivot scores >= 7, continue to Step 5.

### Step 5: Lit-review threat search

Use available search tools to find papers **the idea did not cite that could scoop or scoop-by-proximity it**. The goal is to surface threats, not to write a literature review. Search across:

- **Semantic Scholar** (`mcp__semantic-scholar__search_papers`, `get_related_papers`, `get_paper_references` if MCP available)
- **OpenAlex** (`mcp__openalex__openalex_search_entities`) for broader marketing/economics/CS overlap
- **arXiv** (`mcp__arxiv__search_papers`) for CS/ML papers, especially if the idea touches generative AI, recommendation, or NLP
- **WebSearch** for SSRN working papers, NBER, recent MKSCI/JMR/JCR/MS issues, and Marketing-Letters/Quantitative-Marketing-and-Economics overlap
- **Google Scholar** (via WebSearch / WebFetch) for citation counts and very recent preprints

For each threat paper, record: full citation, verifiable URL (Semantic Scholar / SSRN / journal landing page), 2-sentence summary, and `threat_level: HIGH | MEDIUM | LOW`. HIGH = same mechanism + similar data + recent; MEDIUM = adjacent mechanism or different setting; LOW = related but distinct contribution.

Then write a one-paragraph **gap analysis**: given the verified threats, is there still a clear marginal contribution? End with **defensive recommendations** (2-4 specific moves the user can make against the highest threats).

### Step 6: Verify the lit review

For every paper cited in Step 5 — and every paper the user named as a closest paper — verify it actually exists. The whole point is to catch hallucinated citations. Use Semantic Scholar `get_paper_details` or WebSearch on `"<title>" <first author>` and confirm a real landing page. If a paper cannot be verified, **remove it from the threat list** or mark it `[UNVERIFIED]` in the report. Do not invent URLs.

Also do a quick missing-category check: are there obvious classes of papers a marketing reviewer would expect (e.g., a recent JMR special issue on the topic, a Marketing Science Best Paper finalist, a foundational behavioral paper) that Step 5 missed? Add any verified additions.

### Step 7: Final verdict

Synthesize everything into a one-page verdict containing:
1. **Final score** (1–10) for the current best version of the idea, with one-paragraph justification.
2. **Top 3 remaining threats** and concrete moves to address each.
3. **Suggested working title** and a one-paragraph abstract that positions the paper for the target journal.
4. **Recommended target journal** among MKSCI / JMR / JCR / MS — with one sentence on fit and one sentence on the best realistic fallback (e.g., QME, JIM, Marketing Letters).
5. **Key risk: what could kill this paper?** One paragraph.
6. **Recommendation**: `proceed` (score >= 7 with at most cosmetic concerns), `pivot` (score 5–6.5, name the next pivot), or `drop` (score < 5 after pivots, or a HIGH threat that is genuinely fatal).

### Step 8: Review the final verdict

Adopt the senior-marketing-professor persona again. Read the full report and ask: is the final score consistent with the evidence? Is any threat over- or under-weighted? Is the suggested journal realistic? Are the next steps actionable? State agree / partially agree / disagree in 200 words. If you disagree and the score should be < 7, loop back to Step 3 (subject to the 3-pivot cap).

## Phase 2: Write the report

Save the consolidated report to `<workdir>/idea_eval_<idea_slug>_<DATE>.md`. If the file exists, append `-v2`, `-v3`, etc. Use the exact structure below. Write in a hedged, modest register; use numbered `enumerate`-style lists when listing changes or threats.

```markdown
# Pre-Execution Idea Evaluation — <Idea Title>

**Author**: <personal_config.user.name>
**Date**: <DATE>
**Target standard**: Marketing Science / JMR / JCR / Management Science (Marketing)
**Final score**: <X>/10
**Recommendation**: <proceed | pivot | drop>

---

## Executive summary

[3-4 hedged sentences: what the idea is, what the principal strength is, what the single most critical concern is, and the recommendation.]

---

## 1. Idea (as submitted)

[Restate the research question, hypothesis, identification, data, and three closest papers — verbatim or near-verbatim from the user's input.]

---

## 2. Step 1 — Initial evaluation

[Six-criterion scores + overall + 200-word hedged critique.]

## 3. Step 2 — Review of the evaluation

[Agree / partially agree / disagree + 150-word reasoning.]

## 4. Step 3-4 — Pivot history

[For each pivot attempted: what the pivot was, the new score, why it succeeded or failed. If no pivot was needed, write "No pivot required — initial idea scored >= 7."]

## 5. Step 5 — Threat search

**Threats found** (verified in Step 6):
1. [Citation] — URL — threat level — 2-sentence summary
2. ...

**Gap analysis**: [One paragraph.]

**Defensive recommendations**:
1. ...
2. ...

## 6. Step 6 — Verification notes

[List any papers that were proposed but could not be verified, and any obvious categories the search missed and were added.]

## 7. Step 7 — Final verdict

**Final score**: <X>/10
**Top remaining threats**:
1. ...
2. ...
3. ...

**Suggested working title**: <title>
**One-paragraph abstract**:
[Hedged, 150 words.]

**Recommended target**: <journal> (fallback: <journal>).
**Key risk**: [One paragraph.]

## 8. Step 8 — Review of the verdict

[Agree / partially agree / disagree + 200-word reasoning.]

---

## Appendix: Scoring rubric

| Criterion | Score (1-10) |
|---|---|
| Novelty within marketing lit | |
| Identification / design rigor | |
| Theoretical/empirical advancement | |
| Managerial relevance | |
| Data feasibility | |
| Relevance and timing | |
| **Overall** | |
```

After saving, report:
1. The path to the saved report.
2. The final score and recommendation.
3. The top three threats by name.
4. Any unverified citations that the user should double-check by hand.

## Failure modes

- **No concrete idea provided.** If the user asks to evaluate "my project" without a research question, hypothesis, identification, data, and three closest papers, ask for the missing pieces and stop. Do not fabricate them.
- **Web search / MCP unavailable.** If Semantic Scholar / OpenAlex / arXiv / WebSearch are all unavailable, Step 5/6 cannot run reliably. Run Steps 1-4 and 7-8, mark Step 5/6 as **`[NOT RUN — verification tools unavailable]`**, and tell the user the threat search must be done by hand before trusting the verdict.
- **Ambiguous scoring.** If the six criteria pull in opposite directions and the overall score is hard to set, do not split the difference invisibly. State the tension explicitly ("we believe novelty is high but data feasibility is weak; we land at 6.5 because feasibility tends to dominate in MKSCI/JMR refereeing") and surface the reasoning.
- **Step 5 finds a HIGH threat with very recent publication.** Do not silently drop the project. Surface the threat, propose at least one concrete pivot that survives it, and let the Step 7 recommendation be `pivot` or `drop` based on whether the pivot is credible.
- **3-pivot cap reached.** Write the report with the current best version. Recommend `drop` or `radical-rethink`; do not loop indefinitely.
- **Citation cannot be verified.** Mark `[UNVERIFIED]` rather than removing silently or asserting it exists. Better a flagged uncertainty than a fabricated rationale.

## Out of scope

- **Implementation suggestions.** This skill does not write code, design the survey, set up the scraper, or pick the structural-model functional form. It evaluates whether to do the project, not how.
- **Funding-fit analysis.** Not the place to evaluate NSF/Marketing-Science-Institute fit. Use `/review-grant` for that.
- **IRB / ethics advice.** If the idea involves human subjects, the user must handle IRB through their own institution. Flag it as a feasibility note but do not advise on protocol.
- **Hiring or co-author advice.** Out of scope.
- **Replacement for an actual referee report.** This is pre-execution evaluation. After the paper is drafted, use `/review-paper` against MKSCI/JMR/JCR/MS for the referee simulation.
