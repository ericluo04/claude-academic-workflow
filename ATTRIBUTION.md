# Attribution

## Why this matters

This workflow stands on the shoulders of other Claude Code workflow authors who shared their setups publicly. Every adopted skill, patch, or pattern is traced to its source below. If you build on this repo, please preserve attributions — that is how this ecosystem stays generous.

The skills and patches that came from other repos were adapted, not copied verbatim — but the ideas are theirs and the GitHub links below let you read the originals. If you are an author listed here and want a credit removed, added, or reworded, please open an issue.

---

## Master attribution table

| Item | Source repo | Author | What was borrowed |
|---|---|---|---|
| `/skill-creator` (the whole skill, incl. analyzer/comparator/grader sub-agents, eval viewer, benchmark scripts) | [`anthropics/skills:skills/skill-creator`](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) | Anthropic | The entire skill. This repo's only addition is the catalog-conflict gate (anti-bloat check) layered on top |
| `/referee2` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Cross-language replication audit; adapted from R<->Stata to R<->Python |
| `/blindspot` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Shklovsky 4-quadrant figure / table audit |
| `/bibcheck` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Per-entry `.bib` verification with one subagent per entry |
| `/tikz-iterate` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) (`/tikz` 3-pass collision audit) + this repo | Scott Cunningham + this repo | Concept of iterative TikZ refinement; this repo extends to a full compile / render / review / fix loop using `pdftoppm` and a vision-judging subagent |
| `/council` | [`chrisblattman/claudeblattman`](https://github.com/chrisblattman/claudeblattman) | Chris Blattman | N parallel critic subagents + separate synthesizer pass; default critic roster tuned for quant marketing |
| `/daily-brief` wait-factor + type-balance scoring | [`chrisblattman/claudeblattman:morning-brief`](https://github.com/chrisblattman/claudeblattman) | Chris Blattman | Scoring patches: tasks that have waited longer score higher, type rotation prevents same-category streaks |
| Atomic-write discipline in `/daily-brief` and `/capture` | [`chrisblattman/claudeblattman:done`](https://github.com/chrisblattman/claudeblattman) v1.11 | Chris Blattman | Write-to-tmp-then-rename pattern for `today_brief.json` etc to avoid partial-write corruption |
| `/notion-meeting-notes` hollow-transcript gate | [`chrisblattman/claudeblattman:post-meeting`](https://github.com/chrisblattman/claudeblattman) | Chris Blattman | Thin-content gate: refuse to file action items if the meeting page has no `### Action Items` block or fewer than N words |
| `/slide-excellence` titles-as-assertions + density audit | [`scunning1975/MixtapeTools:beautiful_deck`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Two pedagogy/visual lenses that became two of the review agents |
| `/referee-response --five-q` | [`aspi6246/Claude-Code-Presentation:the_editor_persona`](https://github.com/aspi6246/Claude-Code-Presentation) | aspi6246 | "So-what" 5-question stress test applied to reviewer responses |
| `/review-paper` and `/review-paper-light` buried-contribution check | [`aspi6246/Claude-Code-Presentation:the_editor_persona`](https://github.com/aspi6246/Claude-Code-Presentation) | aspi6246 | Mechanical word-count gate: if the contribution sentence appears after word N in the abstract, flag it |
| `/litreview --four-axis` | [`chrisblattman/claudeblattman:tips-curate`](https://github.com/chrisblattman/claudeblattman) | Chris Blattman | 4-axis relevance scoring (replaces a single 1-5 score) |
| `/skill-creator` catalog-conflict gate | [`chrisblattman/claudeblattman:tips-integrate`](https://github.com/chrisblattman/claudeblattman) v2.1 | Chris Blattman | Anti-bloat catalog check: before creating a new skill, search the catalog for overlapping triggers |
| `/create-lecture --triage` | [`scunning1975/MixtapeTools:beautiful_deck`](https://github.com/scunning1975/MixtapeTools) Step 0 | Scott Cunningham | Audience + closing-claim triage at the start of slide creation |
| `/academic-pptx` (entire skill) | [`Gabberflast/academic-pptx-skill`](https://github.com/Gabberflast/academic-pptx-skill) | Gabberflast | Entire skill (SKILL.md, content_guidelines.md, slide_patterns.md). Frontmatter description verbatim; "Structured Argument" mode, ghost-deck test, action titles, communication-first design |
| `/posterskill` (entire skill) | [`ethanweber/posterskill`](https://github.com/ethanweber/posterskill) | Ethan Weber | Skill name, paper-+-project-website → single-file output design, React-via-CDN interactive HTML poster architecture |
| `/academic-slides` (entire skill) | [`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides) | Zara Zhang | Entire skill scaffolding — Phase 0-5 architecture, "Show Don't Tell" preview UX, STYLE_PRESETS 12-preset convention, viewport-fit invariant, python-pptx PPT ingest. The academic fork swaps themes (Beamer-flavored), adds Phase 0.5 audience/takeaway/arc, and layers in theorem/lemma/proof CSS + KaTeX + `data-pause`. |
| `/review-paper`, `/review-paper-light`, `/review-paper-code`, `/review-pap`, `/review-grant` (base designs) | [`claesbackman/AI-research-feedback`](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | Base skill names, agent-count topology (6 / 2 / 5-phase / 6 / 6), and agent role names for all five review skills. The aspi6246 buried-contribution gate is layered on top of `/review-paper` and `/review-paper-light` only. |
| `/preregister` | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | OSF / AsPredicted / AEA RCT three-registry structure, MUST / SHOULD / MAY clarity-flag taxonomy, retrospective-preregistration refusal gate |
| `/seven-pass-review` | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Seven-lens parallel review (Abstract / Intro / Methods / Results / Robustness / Prose / Citations), parallel-subagent-then-synthesizer topology, 80 / 90 / 95 threshold scoring |
| `/slide-excellence` base orchestration | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Conditional-spawn orchestrator + base agent lineup (visual / pedagogy / proofread, plus TikZ when present). Scott's pedagogy lenses sit on top. |
| `/create-lecture` base | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Beamer lecture-scaffold workflow (intake → analysis → structure → draft → polish), notation-consistency check, dual research-talk / pedagogical-lecture mode split. Scott's `--triage` Step-0 gate sits on top. |
| `/audit-reproducibility` 5-phase audit | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | 5-phase tolerance-based reproducibility check (extract → match → compare → PASS/FAIL → summarize). Shares credit with Scott's claim-extraction-to-tolerance-comparison flow from MixtapeTools. |
| slide-auditor, pedagogy-reviewer, proofreader, tikz-reviewer sub-agents | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | All four sub-agent definitions adapted, including the 13-pattern pedagogy checklist and the OVERFLOW / FONT CONSISTENCY / BOX FATIGUE / SPACING audit taxonomy. Generalized for marketing-domain conventions. |
| Reviewed, not adopted into a skill | [`hugosantanna/clo-author`](https://github.com/hugosantanna/clo-author) | Hugo Sant'Anna | Econ-paper scaffold; surfaced ideas in `docs/future-work.md` |
| Reviewed, not adopted into a skill | [`karpathy/autoresearch`](https://github.com/karpathy/autoresearch) | Andrej Karpathy | ML training-loop pattern; inspiration noted, not incorporated as a skill |
| Reviewed previously | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | Earlier reference for the workflow-as-config-repo pattern that this repo extends |

A per-skill version-pinned table (with the source commit hash that each adoption is based on) is maintained at [docs/attribution-table.md](docs/attribution-table.md).

---

## Author thank-yous

### Anthropic — [`anthropics/skills`](https://github.com/anthropics/skills)

The `/skill-creator` skill in this repo is from Anthropic's official skills repo. It is the foundation on which every other skill in this repo was built and refined — analyzer / comparator / grader sub-agents, the eval viewer, the variance-analysis benchmark scripts, even the structural conventions for SKILL.md frontmatter. The only modification here is a catalog-conflict gate (a pre-write check that warns when a proposed new skill would near-duplicate an existing one), layered on top so the workflow stays anti-bloat as it grows. Thank you for shipping this in the open.

### Scott Cunningham — [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools)

Scott's `MixtapeTools` repo is the single largest source of ideas in this workflow. Four full skills (`/referee2`, `/blindspot`, `/bibcheck`, `/tikz-iterate`) are direct descendants of his commands, and two more (`/slide-excellence`, `/create-lecture`) borrow specific lenses from his `beautiful_deck` and `tikz` work. His `/referee2` design — reimplementing an analysis in a second language and using bug orthogonality to surface errors — is the strongest single pattern in this repo. His `/blindspot` is the rare review skill that catches what the author has stopped seeing, rather than restating what is already on the page. Thank you, Scott, for shipping these in the open.

### Chris Blattman — [`chrisblattman/claudeblattman`](https://github.com/chrisblattman/claudeblattman)

Chris's `claudeblattman` repo contributed the orchestration-side patches that turned a daily-brief skill from "okay" to "actually usable" — wait-factor scoring, type-balance rotation, atomic writes. His `/council` design (N parallel critics + a separate synthesizer that does not majority-vote) is the cleanest implementation of adversarial review I have seen and became the spine of `/council` here. The `notion-meeting-notes` thin-content gate and the `skill-creator` catalog-conflict gate are also lifted from his repo and prevent two distinct categories of silent failure (action items filed from empty meetings; skill bloat from near-duplicate skills). Thank you, Chris.

### aspi6246 — [`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation)

aspi6246's `the_editor_persona` skill contributed two specific lenses that show up in this repo: the "5 questions a hostile editor will ask" stress test that became `/referee-response --five-q`, and the mechanical "did you bury the contribution past word N of the abstract" gate that became part of `/review-paper` and `/review-paper-light`. Both are short, sharp, and reusable across submission targets. Thank you.

### Andrej Karpathy — [`karpathy/autoresearch`](https://github.com/karpathy/autoresearch)

Andrej's `autoresearch` repo was reviewed during the design phase. The ML training-loop pattern it formalizes does not map directly into the quant-marketing / econ workflow that this repo targets (different feedback loops, different evaluation criteria), so no skill in this repo derives from it. Mentioning the inspiration anyway because the broader idea of "Claude Code as an iterative research collaborator, not a single-shot generator" is foundational and Andrej articulated it clearly.

### Hugo Sant'Anna — [`hugosantanna/clo-author`](https://github.com/hugosantanna/clo-author)

Hugo's `clo-author` repo was reviewed during the design phase. Several of his econ-paper-drafting ideas are adjacent to what `/draft` and `/replication-package` already do, and the overlap was large enough that adopting them would have created near-duplicate skills (`skill-creator`'s catalog-conflict gate would have flagged them). The ideas that did not overlap — e.g., his explicit treatment of identification-strategy framing in the intro — are noted in `docs/future-work.md` for a future iteration.

### Pedro H.C. Sant'Anna — [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow)

Pedro's `claude-code-my-workflow` is the second-largest source of structural patterns in this workflow after Scott Cunningham's `MixtapeTools`. All four sub-agents in this repo (`slide-auditor`, `pedagogy-reviewer`, `proofreader`, `tikz-reviewer`) are adapted from Pedro's agent definitions, including the 13-pattern pedagogy checklist and the OVERFLOW / FONT CONSISTENCY / BOX FATIGUE / SPACING audit taxonomy. On the skill side, `/seven-pass-review` (seven-lens parallel review with 80 / 90 / 95 thresholds), `/preregister` (OSF / AsPredicted / AEA RCT three-registry structure plus MUST / SHOULD / MAY clarity flags), the `/slide-excellence` base orchestrator, and the `/create-lecture` base workflow are all adapted from his repo; `/audit-reproducibility` shares credit with Scott's MixtapeTools. Beyond the individual skills, Pedro's repo was also the earlier reference for the workflow-as-config-repo pattern itself — bundle your skills, hooks, MCPs, and setup docs into one public repo and let collaborators fork it; this repo extends that pattern with the runtime-config-lookup approach (`personal_config.json`) so skill prose stays clean of personal data. Thank you, Pedro — this workflow would be a much thinner repo without your work.

### Claes Bäckman — [`claesbackman/AI-research-feedback`](https://github.com/claesbackman/AI-research-feedback)

Claes's `AI-research-feedback` repo is the source of the five review skills in this repo: `/review-paper` (6-agent fanout), `/review-paper-light` (2-agent split), `/review-paper-code` (5-phase reproducibility audit), `/review-pap` (6-agent PAP review), and `/review-grant` (6-agent grant panel). The agent counts and the agent role names match his originals; this fork tunes the journal-target and registration-target lists for quantitative marketing (MKSCI / JMR / JCR / MS) alongside the econ / finance and registry targets Claes already covered. The aspi6246 buried-contribution gate is layered on top of `/review-paper` and `/review-paper-light` only and is not from Claes's repo. Thank you, Claes, for shipping a clean, reusable review-skill set.

### Gabberflast — [`Gabberflast/academic-pptx-skill`](https://github.com/Gabberflast/academic-pptx-skill)

Gabberflast's `academic-pptx-skill` is the source of `/academic-pptx` in its entirety — SKILL.md, content_guidelines.md, slide_patterns.md, the "Structured Argument" mode, the ghost-deck test, action titles, and the communication-first design philosophy. The frontmatter description in this fork is verbatim from the original. The only adaptation here is trigger-surface tuning for quantitative-marketing audiences (faculty seminars, MBA teaching, grant briefings). Thank you, Gabberflast.

### Ethan Weber — [`ethanweber/posterskill`](https://github.com/ethanweber/posterskill)

Ethan's `posterskill` is the source of `/posterskill` — the same skill name, the same paper-plus-project-website ingestion design, the same single-file interactive React-HTML poster architecture (React/Babel via CDN, no build step, drag-to-resize layout). This fork adapts the prompt surface for quantitative-marketing conference posters and adds project-folder conventions consistent with the rest of this workflow. Thank you, Ethan.

### Zara Zhang — [`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides)

Zara's `frontend-slides` repo is the structural parent of this repo's `/academic-slides`. The Phase 0-5 architecture, the "Show Don't Tell" preview UX (Phase 2 generates 3 mini-HTML style previews instead of asking abstract questions), and the `STYLE_PRESETS.md` 12-preset convention all come from her work. The academic fork retains the scaffolding and swaps in Beamer-flavored themes plus academic-deck primitives (theorem/lemma/proof boxes, KaTeX, `\pause` analogue). Thank you, Zara.

---

## License compatibility notes

This repo ships under the MIT License (see [LICENSE](LICENSE)). Each source repo cited above also ships under an MIT or similarly permissive license, so redistribution under MIT is straightforward. Per-repo license check:

- `anthropics/skills` — MIT. Compatible.
- `scunning1975/MixtapeTools` — MIT. Compatible.
- `chrisblattman/claudeblattman` — MIT. Compatible.
- `aspi6246/Claude-Code-Presentation` — MIT. Compatible.
- `karpathy/autoresearch` — MIT. Compatible (no code adopted regardless).
- `hugosantanna/clo-author` — MIT. Compatible (no code adopted regardless).
- `pedrohcgs/claude-code-my-workflow` — MIT. Compatible.
- `claesbackman/AI-research-feedback` — MIT. Compatible.
- `Gabberflast/academic-pptx-skill` — MIT. Compatible.
- `ethanweber/posterskill` — MIT (verified). Compatible.
- `zarazhangrui/frontend-slides` — MIT. Compatible.

If you spot an incompatibility (a source repo has changed license, or an adoption falls outside MIT permissions), please open an issue and we will fix the credit, remove the adoption, or seek explicit permission.

---

## How to contribute back

If you fork this repo and build something useful:

- **Improvements to existing skills** — open a PR against this repo. We are happy to merge cleanups, bug fixes, and additional sources.
- **New skills inspired by this workflow** — please add a credit line in your skill's `SKILL.md` pointing back to whichever source actually inspired it (this repo, Scott's, Chris's, etc). That is the only "license" obligation that matters in practice.
- **Bug reports or attribution corrections** — open an issue. If a credit here is wrong, missing, or worded badly, please tell us so we can fix it.

The goal is a generous, transparent ecosystem where ideas flow between researchers' workflows without getting lost. Preserving attribution is how that stays sustainable.
