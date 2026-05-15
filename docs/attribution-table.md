# Attribution

This workflow is assembled from many sources. The table below lists the original repos, authors, and what was borrowed for each skill, sub-agent, or hook. Every item is used under the terms of its upstream license (mostly MIT). If you ship a fork, please preserve this table and add your own rows for anything you contribute.

## Master attribution table

| Component | Source repo | Author | What was borrowed |
|---|---|---|---|
| `/skill-creator` (entire skill) | [`anthropics/skills:skills/skill-creator`](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) | Anthropic | The whole skill — SKILL.md, the analyzer / comparator / grader sub-agents, the eval viewer, and the benchmark scripts. Forms the foundation for every other skill in this repo. Only modification: a catalog-conflict gate layered on top (anti-bloat check before writing a new SKILL.md) |
| `/draft` voice-shaping pattern | [obra/dotfiles](https://github.com/obra/dotfiles) | Jesse Vincent (obra) | Skill-as-style-mirror pattern; reading bundled exemplars to learn tone |
| `/referee-response` structure | [obra/dotfiles](https://github.com/obra/dotfiles) | Jesse Vincent (obra) | Sectioned response-letter scaffold; quoted-reviewer + location-pin format |
| `/cite` orchestration | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) | Scott Cunningham | Identifier-resolution flow (DOI → Zotero → bib append) |
| `/litreview` multi-source dedupe | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) | Scott Cunningham | Cross-source dedupe by DOI / arXiv-ID / fuzzy title |
| `/bibcheck` per-entry subagent fanout | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) | Scott Cunningham | One-subagent-per-entry pattern to avoid gradient decay |
| `/compile-latex` (planned) | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) | Scott Cunningham | `compiledeck` log-parsing approach (not yet ported) |
| `/audit-reproducibility` | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) + [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Scott Cunningham + Pedro H.C. Sant'Anna | Claim-extraction → tolerance-comparison flow (Scott) + 5-phase R / Python / Stata multi-language audit topology (Pedro) |
| `/referee2` cross-language replication | [scunning1975/mixtape-tools](https://github.com/scunning1975/mixtape-tools) | Scott Cunningham | Reimplement-in-second-language audit pattern |
| `/review-paper` 6-agent fanout | [claesbackman/AI-research-feedback](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | Base 6-agent design and agent role names (Spelling/Style, Internal Consistency, Unsupported Claims, Math/Notation, Tables/Figures, Adversarial Top-Journal) |
| `/review-paper-light` 2-agent split | [claesbackman/AI-research-feedback](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | Base 2-agent design (contribution / identification + causal overclaiming) and Phase 1 / 2 / 3 sequence |
| `/review-paper-code` 5-phase design | [claesbackman/AI-research-feedback](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | 5-phase Discovery → Paper Analysis → Parallel Code Review → Synthesis → Report design |
| `/review-pap` 6-agent fanout | [claesbackman/AI-research-feedback](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | Base 6-agent design (Clarity/Pre-spec, Hypotheses/Outcomes, Identification/Causal, Statistical Analysis Plan, Data/Operational, Adversarial Referee) |
| `/review-grant` 6-agent panel | [claesbackman/AI-research-feedback](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | Base 6-agent panel design (Clarity/Compliance, Internal Consistency, Significance/Innovation, Research Design/Feasibility, Budget/Timeline/Team, Adversarial Panel) |
| `/seven-pass-review` parallel fanout | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Seven-lens parallel review-subagent topology (Abstract / Intro / Methods / Results / Robustness / Prose / Citations) + 80 / 90 / 95 threshold scoring |
| `/council` skill | [cblatts/claudeblattman](https://github.com/cblatts/claudeblattman) | Chris Blattman | Parallel-critics-then-synthesis pattern |
| `/evaluate-idea-marketing` rubric loop | [cblatts/claudeblattman](https://github.com/cblatts/claudeblattman) | Chris Blattman | 8-step pre-execution scoring + pivot loop |
| `/evaluate-idea-science` rubric loop | [cblatts/claudeblattman](https://github.com/cblatts/claudeblattman) | Chris Blattman | Same 8-step rubric, tuned for broad-science venues |
| `/email-triage` (planned) | [cblatts/claudeblattman](https://github.com/cblatts/claudeblattman) | Chris Blattman | `triage-inbox` classification flow (not yet ported) |
| `/blindspot` Shklovsky frame | original | this repo | Four-quadrant peripheral-vision grid for single figures |
| `/preregister` 3-registry structure + clarity flags | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | OSF / AsPredicted / AEA RCT three-registry structure, MUST / SHOULD / MAY clarity-flag taxonomy, and retrospective-preregistration refusal gate. Underlying registry field structures remain those of AsPredicted / OSF / AEA RCT Registry. |
| `/replication-package` MKSCI layout | derived from Marketing Science replication policy | INFORMS | Folder convention (`code/`, `data/`, `output/`, `README.md`, `MANIFEST`) |
| `/posterskill` HTML poster scaffold | [ethanweber/posterskill](https://github.com/ethanweber/posterskill) | Ethan Weber | Skill name, paper-+-project-website ingestion, and single-file interactive React-HTML poster architecture (no build step) |
| `/academic-pptx` content scaffold | [Gabberflast/academic-pptx-skill](https://github.com/Gabberflast/academic-pptx-skill) | Gabberflast | Entire skill (SKILL.md, content_guidelines.md, slide_patterns.md). Frontmatter description verbatim; "Structured Argument" mode, ghost-deck test, action titles, communication-first design |
| `/academic-slides` HTML deck builder | [`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides) | Zara Zhang | Entire Phase 0-5 scaffolding (Show Don't Tell preview UX, STYLE_PRESETS 12-preset convention, viewport-fit invariant, python-pptx PPT ingest). Academic fork swaps themes (Beamer-flavored) and adds theorem/lemma/proof boxes, KaTeX, and `data-pause`. |
| `pre-compact.py` hook | original | this repo | Pre-compact summarization hook |
| `slide-auditor` sub-agent | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Visual layout auditor for Beamer slides, including the OVERFLOW / FONT CONSISTENCY / BOX FATIGUE / SPACING audit taxonomy. Generalized for marketing-domain conventions in this fork. |
| `pedagogy-reviewer` sub-agent | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Holistic pedagogical review including the 13-pattern checklist (Motivation Before Formalism, Incremental Notation, Worked Example After Every Definition, etc.). Generalized for MKSCI / JMR / JCR / MS seminars and MBA teaching decks in this fork. |
| `proofreader` sub-agent | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Strict prose proofreading lens covering Grammar / Typos / Overflow / Consistency / Academic Quality, with `quality_reports/` output convention. Generalized for marketing-domain conventions in this fork. |
| `tikz-reviewer` sub-agent | [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | "Merciless visual critic" TikZ review across Label Positioning, Geometric Accuracy, Visual Semantics, Spacing/Proportion, Aesthetic Polish, with CRITICAL / MAJOR / MINOR severity classification. Generalized for marketing-domain conventions in this fork. |

## License notes

All upstream repos cited above are MIT-licensed at the time of this writing. Where a skill is a direct port, the original copyright is preserved in the skill's `SKILL.md` header. Where a skill takes only a pattern (a structural idea, a fanout topology) and reimplements from scratch, the row above describes the borrowing and that's the extent of the attribution obligation.

## How to contribute

If you fork this repo and add a skill, add a row to this table with:

- Component name
- Source repo (if any) with link
- Author (yourself, or upstream)
- One-line description of what was borrowed (or "original" if from scratch)

Open the PR against `docs/attribution-table.md` alongside the skill PR so the two land together.

## Why the table is this detailed

A common failure mode in skill-sharing communities is silent absorption — patterns travel from repo to repo with no audit trail, and a year later nobody remembers who first solved the parallel-fanout-then-synthesize problem or who originated the per-entry subagent-per-citation idea. The table above tries to push against that by being explicit about provenance even when the borrowing is a pattern rather than code.

Two finer-grained notes on the kind of borrowing involved:

- **Pattern-level borrowing**: where the table says "fanout topology" or "rubric loop", the upstream gave the shape of the solution. The actual prompts, agent definitions, and tool wiring in this repo were rewritten from scratch — sometimes because the upstream was for a different domain (Blattman's seven-pass for economics manuscripts vs. this repo's marketing journals), sometimes because the upstream's prompts were closely entangled with its author's voice.
- **Verbatim borrowing**: in a few places the prompts themselves come close to the upstream. Where that happened the skill's `SKILL.md` includes a header line crediting the source and the upstream license.

If you spot anything that looks like missing attribution — a pattern that traces to a public source not in this table — please open an issue or PR. The default is to credit liberally.

## Acknowledgements

Beyond the direct attributions above, this workflow has benefited from:

- Anthropic's official [`anthropics/skills`](https://github.com/anthropics/skills) repo — `/skill-creator` is from there directly, and the broader skill / agent / hook abstractions (frontmatter conventions, the eval rubric, the way sub-agents compose) come from Anthropic's published guidance.
- The Beamer presentation tradition (Til Tantau et al.), which informs `/academic-slides` and `/slide-excellence`.
- The replication-package conventions that Marketing Science, JMR, JCR, and Management Science have converged on over the past decade, which underpin `/replication-package`.
- The AsPredicted, OSF, and AEA RCT Registry templates, which underpin `/preregister`.
- Conversations with co-authors and advisors that surfaced many of the rough edges these skills smooth over.

