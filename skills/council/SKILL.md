---
name: council
description: Spawn up to 5 independent critic subagents in PARALLEL on a target — a research idea, draft, R&R strategy, grant proposal, experimental design, pre-analysis plan, talk plan, IRB protocol, or skill design — collect their raw outputs, then run a SEPARATE synthesis pass that produces a single prioritized action list without majority-voting. Default critic roster is tuned for quantitative-marketing research (skeptic, pre-mortem, methodologist, academic-editor, harsh-referee); `--chef-skill` swaps in a skill-design roster (works with `/skill-creator`). Use whenever the user says "/council", "council review", "get a council on", "spawn critics on", "parallel critique", "kitchen cabinet review", "panel review", "stress-test this idea / plan / skill", or "what would 5 experts say". Target-agnostic and configurable, distinct from `/seven-pass-review` (which is manuscript-bound and runs 7 fixed lens passes on abstract / intro / methods / results / robustness / prose / citations) and from `/evaluate-idea-marketing` and `/evaluate-idea-science` (which run an 8-step linear pre-execution scoring rubric and loop until score >= 7). `/council` is one-shot, parallel, target-agnostic; use it when the target is heterogeneous (e.g., a plan, a skill, an R&R reply) or when the user wants a fast adversarial cross-section rather than a structured scorecard.
argument-hint: "[target — file path, draft text, or topic description] [--chef-skill] [--critics=skeptic,premortem,methodologist,editor,referee] [--n=5]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Task", "Monitor"]
effort: medium
---

# Council — Parallel Critics + Separate Synthesis

Five independent critics, one synthesizer, no majority voting. Single round.

## When to use

- The user is stuck between two framings of a paper, R&R, or grant — and wants adversarial pressure.
- A plan, design, or skill draft is "almost right" and needs failure-mode pressure before it ships.
- The target is heterogeneous (idea + design + venue choice mixed together) so `/seven-pass-review` and `/evaluate-idea-*` don't fit cleanly.
- Pre-submission gut-check that's lighter than `/seven-pass-review` but broader than `/review-paper-light`.

Not for: numeric audits (use `/audit-reproducibility`), manuscript line-edits (use `/seven-pass-review` or `/review-paper`), or staged idea scoring loops (use `/evaluate-idea-marketing` or `/evaluate-idea-science`).

## Inputs

- `$0` — the target. One of:
  - **File path** (`.tex`, `.md`, `.qmd`, `.txt`, `.pdf`, `.R`, `.py`, or a `SKILL.md` for `--chef-skill` mode). Read it once in the main agent before dispatching critics.
  - **Inline topic description** — a paragraph stating the decision, plan, or idea. No file read needed.
- `--chef-skill` — swap the default roster for the skill-design roster. Use with `/skill-creator` drafts.
- `--critics=a,b,c` — explicit roster override (names without `-agent` suffix). If a name isn't in the default roster, treat it as a free-form role-string prompt.
- `--n=K` — number of critics (default 5, hard cap 5). If user asks for more, refuse with "Hard cap is 5. Pick a tighter panel."

## Critic roster (default, quantitative-marketing tuned)

Spawned as `general-purpose` subagents with inline role-string prefixes. No persona files required.

1. **Skeptic** — *"Challenge the core claim or hypothesis. What would have to be true for this to be wrong? Where is the load-bearing assumption that the author has not stress-tested? Be specific to the target — name the assumption, not the genre."*
2. **Pre-mortem** — *"Imagine it is 12 months from now and this paper / plan / grant has failed. What is the most likely failure mode? Walk back from the failure to the present and name the decision point at which it could have been avoided."*
3. **Methodologist** — *"Challenge identification, measurement, and design. Tuned for quant-marketing: DiD, IV, RD, RCT, conjoint, eye-tracking, vignette, field experiment, scraped-panel obs, GAN / SAE / embedding methods. Are exclusion restrictions defensible? Is the unit of analysis vs. unit of treatment consistent? For ML / GenAI components — train / test / holdout discipline? External validity?"*
4. **Academic editor** — *"Venue fit, narrative tightness, contribution framing. Default targets: Marketing Science / JMR / JCR / Management Science. If the user signals general-science (PNAS / Nature Human Behaviour / Nature / Science), recalibrate. Does the contribution fit the audience? Is the framing tight enough for a non-specialist editor? What would you tell the user to cut or expand?"*
5. **Harsh referee** — *"You are the most likely Reviewer 2. Produce the rejection arguments a sharp referee at the target venue would write. Do not be balanced. Name the specific objection (overclaiming, identification, sample, mechanism, novelty, scope) and give the sentence you would write in the report."*

Each critic ends with: `VERDICT: APPROVE | REVISE | REJECT` and a one-line rationale.

## `--chef-skill` alternate roster

Swap roster for skill / tool design review. Use with `/skill-creator` drafts or any `SKILL.md` the user wants stress-tested before installing.

1. **Skill engineer** — *"Will this skill work, will it last, does the abstraction earn its keep? Focus on: invocation discoverability (do the trigger phrases match real user language?), prompt-budget discipline, failure recovery, whether it duplicates existing skill coverage (Glob `~/.claude/skills/*/SKILL.md` to check)."*
2. **Trigger-overlap critic** — *"Read the description's trigger phrases and compare to neighboring skills (`/draft`, `/cite`, `/litreview`, `/log-todo`, `/notion-log`, `/review-*`, etc.). Where would a user say one phrase and trigger the wrong skill? Name the collision and the disambiguating phrase that would fix it."*
3. **Edge-case critic** — *"What breaks this skill? Empty input, file-not-found, MCP not authenticated, ambiguous target, PDF that won't extract, Windows path with spaces, project the skill wasn't tuned for. List the top 5 edge cases and what the skill should do in each."*
4. **MCP / tooling fit** — *"Does this skill match the user's MCP setup (Zotero, Notion, GitHub-Copilot-only, semantic-scholar, arxiv, openalex, gmail, gdrive, playwright)? Are the right tool names used? Does it handle the GitHub MCP being Copilot-only (no full GitHub auth)? Does it respect Windows path conventions?"*
5. **Cold-start tester** — *"Pretend you are the user three weeks from now, having forgotten this skill exists. Read the description. Will you know when to invoke it? Will the argument-hint tell you what to type? Will the failure modes be intelligible? If not, name the exact phrase that's missing."*

Each ends with: `VERDICT: SHIP | REVISE | REJECT` and a one-line rationale.

## Workflow

### Phase 0 — Input prep

1. Parse `$0` and flags. If `--chef-skill`, lock to the skill-design roster; skip target-type inference.
2. If `$0` is a file path: Read it once in the main agent. For `.pdf`, fall back to `pdftotext -layout` or to the `.tex` source. For `SKILL.md`, also `Glob` neighboring `~/.claude/skills/*/SKILL.md` so the trigger-overlap critic has the catalog to compare against.
3. If `$0` is inline text: use as-is.
4. Resolve roster: default 5 for the main flow; default 5 for `--chef-skill`. `--critics=...` overrides; `--n=K` truncates to K (cap 5). Validate roster names; unknown names become free-form role-string critics.
5. Create scratch dir `~/.claude/cache/council_<YYYYMMDD>_<run_id>/` for raw critic outputs.

### Phase 1 — Parallel critic dispatch (SINGLE message, N Task calls)

This is the load-bearing step. Send ONE message with N `Task` tool calls — one per critic. They must run in parallel; do NOT serialize. Each call:

- `subagent_type`: `general-purpose`
- `description`: 3–5 word summary (e.g., "Skeptic critique of draft")
- `prompt`: the critic's role-string prefix + the target content (file contents or inline topic) + the instruction *"Produce raw critique in this role's voice. Be specific to the target, not the genre. End with VERDICT: <APPROVE|REVISE|REJECT> + one-line rationale. Write your output to `~/.claude/cache/council_<run_id>/critic_<role>.md` and also return it as your final message."*

Do not inline-synthesize. Do not summarize across critics in the main agent. Just collect.

### Phase 2 — Synthesizer (SEPARATE Task call, AFTER all critics return)

Wait for all N critics. Then spawn one MORE `Task` call:

- `subagent_type`: `general-purpose`
- `description`: "Synthesize council critiques"
- `prompt`: the raw critic outputs + the original target + the synthesis template (below).

**The synthesizer must NOT majority-vote.** Spell this out in the prompt: *"You are not summarizing votes. A single critic raising a load-bearing concern outweighs 4 critics who didn't notice it. Your job is to reason about which concerns are load-bearing — i.e., which would, if true, kill the paper / plan / skill — and surface those first. If a minority concern is load-bearing, it dominates. If the majority concern is cosmetic, it goes to the bottom."*

### Phase 3 — Emit report

Print the synthesis to the main conversation. Include the raw critic outputs in a `<details>` block at the bottom for verification.

## Synthesis non-majority-voting principle

Multi-critic systems drift toward majority voting because it's the easy aggregation. That defeats the point. The council exists to surface minority concerns from specialized lenses. Bake this into the synthesizer prompt explicitly:

- A concern raised by 1 critic that would kill the project is more important than a concern raised by 4 critics that is cosmetic.
- If the methodologist names an identification problem and no one else mentions it, that goes at the top — not at the bottom because "only one critic flagged it."
- The synthesizer reasons about load-bearingness, not frequency.

## Output report shape

```markdown
# Council Review: <target>

**Date:** YYYY-MM-DD
**Mode:** <default | --chef-skill>
**Critics:** <N> (<roster>)
**Synthesizer verdict:** <SHIP | REVISE-MINOR | REVISE-MAJOR | REJECT-AND-REFRAME>

## Load-bearing concerns (action required)
1. **[lens]** <concern> — *why this is load-bearing in one sentence* — recommended fix
2. ...

## Second-tier concerns
- **[lens]** <concern> — recommended fix

## Polish (optional)
- ...

## Per-critic verdicts
| Critic | Verdict | One-line rationale |
|---|---|---|
| Skeptic | | |
| Pre-mortem | | |
| Methodologist | | |
| Academic editor | | |
| Harsh referee | | |

## Contradictions between critics
[If two critics disagree (e.g., editor says "expand contribution framing" but referee says "trim — overclaiming"), surface here and recommend a reconciliation. Do not silently average.]

<details>
<summary>Raw critic outputs</summary>

[Inline each critic's raw output, headed by their lens.]

</details>
```

## Relation to other skills

- **`/seven-pass-review`** — manuscript-bound, 7 fixed lenses (abstract / intro / methods / results / robustness / prose / citations). Use when the target IS a complete paper and you want exhaustive lens-by-lens coverage. `/council` is target-agnostic and cheaper (5 vs 7 critics, no fixed lenses).
- **`/evaluate-idea-marketing`** and **`/evaluate-idea-science`** — 8-step linear pre-execution scoring rubric with a loop until score >= 7. Use for go / no-go on a research idea before any work is done. `/council` is one-shot, parallel, and works for ideas, plans, drafts, skills, or any heterogeneous target — no scoring loop.
- **`/review-paper`** — 6-agent journal-targeted referee report. Closer in spirit to `/council` but locked to paper review. Use `/council` when the target is not a paper.
- **`/review-paper-light`** — 2-agent fast contribution / identification check. Cheaper than `/council`; use when you only need a gut check, not a full panel.
- **`/skill-creator`** — pairs with `/council --chef-skill` for adversarial review of skill drafts before installation.
- **`/blindspot`** — adjacent but different: `/blindspot` finds what you haven't considered; `/council` pressure-tests what you HAVE considered.

## Failure modes

- **File unreadable.** `.pdf` extraction failed, `.tex` has unresolved `\input{}`s, or path doesn't exist. Surface the error and ask for a clean version; do not proceed with empty content.
- **A critic returns empty or off-topic.** Mark that critic as DEGRADED in the synthesis and continue. Do not block the report on one critic. Optionally re-spawn that critic once.
- **All critics agree the target is fine.** Possible. Report it honestly with `SHIP` verdict; do not manufacture concerns. The council can sign off.
- **Synthesizer drifts into majority voting.** Re-read the synthesizer output before emitting. If it ranks by frequency rather than load-bearingness, re-spawn the synthesizer with a sharper non-majority-vote instruction.
- **`--chef-skill` invoked on a non-skill target.** Surface the mismatch and ask whether to switch to the default roster.

## Out of scope

- Iterative debate / round-2 critic calls. Single round only — multi-round drifts toward conformity.
- Auto-applying fixes. This skill produces a checklist; it does not edit the target.
- Numeric audits (`/audit-reproducibility`).
- LLM-proposed dynamic persona generation. Roster is either default, `--chef-skill`, or explicit `--critics=...`.
