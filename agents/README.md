# Sub-agents

Specialist Claude Code sub-agents used by the slide/deck-quality skills in this repo. Drop these `.md` files into `~/.claude/agents/` (or a project-level `.claude/agents/`) and Claude Code will auto-discover them.

Each agent runs in its own context, with restricted tool access (`Read`, `Grep`, `Glob` only — they audit, they don't edit). All are configured `model: inherit` so they pick up whichever model the caller is using.

## Index

| Agent | Model | Purpose | Invoked by |
|---|---|---|---|
| `tikz-reviewer` | inherit | Devil's-advocate TikZ diagram reviewer; checks label overlap, geometry, color semantics, and aesthetic polish with concrete measurements. Iterate until APPROVED. | `/slide-excellence`, `/tikz-iterate` |
| `proofreader` | inherit | Beamer-deck proofreading: grammar, typos, overflow, citation-key resolution, natbib-apa consistency, notation. | `/slide-excellence` |
| `slide-auditor` | inherit | Visual layout auditor for Beamer slides: overflow, font consistency, box fatigue, spacing, semantic colors. | `/slide-excellence` |
| `pedagogy-reviewer` | inherit | Holistic pedagogical review against 13 patterns (motivation-before-formalism, incremental notation, worked examples, narrative arc, pacing). Distinguishes research-seminar mode from MBA-teaching mode. | `/slide-excellence` |

## How they fit together

`/slide-excellence` is a fanout wrapper that spawns the proofreader, slide-auditor, and pedagogy-reviewer in parallel against the same `.tex` deck, and (conditionally on TikZ being present) the tikz-reviewer as well. Each agent writes its own report under `quality_reports/`, and the calling skill synthesizes them into a single prioritized revision checklist.

`tikz-reviewer` is designed to be called iteratively — the calling agent fixes flagged issues, re-invokes the reviewer, and loops until the reviewer's verdict line is `APPROVED`.

## Attribution

Authored by Lan Luo (https://github.com/ericluo04). Lightly generalized from the originals (replaced "Lan" / "Lan's" with "the user" where the prompt made ownership assumptions); domain examples (MKSCI / JMR / JCR / MS, MBA teaching contexts) are kept intact so the prompts remain concrete and useful.
