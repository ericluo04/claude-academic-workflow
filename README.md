# claude-academic-workflow

A complete academic-research workflow for Claude Code — 31 skills, 4 sub-agents, 3 hooks, 8 MCPs, Notion + Telegram task orchestration, cross-platform (Windows + macOS).

## What this is

This repo packages a working Claude Code configuration for academic researchers — particularly those in quantitative marketing, economics, or other quantitative social-science fields. The skills cover the full research lifecycle: drafting and reviewing manuscripts, lit-review across arXiv / Semantic Scholar / OpenAlex, citation auditing, slide-making (Beamer + PowerPoint), TikZ figure iteration, replication-package assembly, cross-language code audits, and day-to-day task orchestration through Notion + Telegram.

The setup is battle-tested in daily PhD-research use. It is not a demo. That said, it is opinionated: it assumes you write papers in LaTeX, draft slides in Beamer, keep a `.bib` per project, and track tasks in Notion. The skills ship clean of personal data — every project name, page ID, and home path resolves through `~/.claude/state/personal_config.json` at runtime — so a friend can fork the repo, drop their own IDs into the config file, and pick up the workflow without inheriting the original author's projects.

## Quick start

Five commands to a working setup. Side-by-side per OS.

**Windows (PowerShell):**

```powershell
git clone https://github.com/ericluo04/claude-academic-workflow.git
cd claude-academic-workflow
.\scripts\install.ps1
notepad $env:USERPROFILE\.claude\state\personal_config.json
# In a separate step, set TELEGRAM_BOT_TOKEN in your shell or GitHub Actions secrets
```

**macOS (bash/zsh):**

```bash
git clone https://github.com/ericluo04/claude-academic-workflow.git
cd claude-academic-workflow
./scripts/install.sh
$EDITOR ~/.claude/state/personal_config.json
# In a separate step, set TELEGRAM_BOT_TOKEN in your shell or GitHub Actions secrets
```

Then in Claude Code: `/daily-brief --hours 4` to verify the loop end-to-end. Full walk-through in [SETUP.md](SETUP.md).

## What's inside

**Drafting and writing** ([skills/](skills/))

- [`/draft`](skills/draft/SKILL.md) — section drafting in your configured voice (intro, methods, limitations, etc.)
- [`/cite`](skills/cite/SKILL.md) — resolve a DOI / arXiv / title to a `.bib` entry via Zotero
- [`/litreview`](skills/litreview/SKILL.md) — multi-source lit search (arXiv + Semantic Scholar + OpenAlex), deduped and ranked
- [`/preregister`](skills/preregister/SKILL.md) — draft an AsPredicted / OSF / AEA preregistration

**Reviewing and auditing** ([skills/](skills/))

- [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) — 7 parallel reviewers (abstract / intro / methods / results / robustness / prose / citations)
- [`/review-paper`](skills/review-paper/SKILL.md), [`/review-paper-light`](skills/review-paper-light/SKILL.md), [`/review-paper-code`](skills/review-paper-code/SKILL.md), [`/review-grant`](skills/review-grant/SKILL.md), [`/review-pap`](skills/review-pap/SKILL.md) — targeted pre-submission reviews
- [`/blindspot`](skills/blindspot/SKILL.md) — Shklovsky 4-quadrant figure / table audit
- [`/bibcheck`](skills/bibcheck/SKILL.md) — per-entry `.bib` verification against ground truth
- [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) — cross-check numeric claims against code output
- [`/referee2`](skills/referee2/SKILL.md) — adversarial cross-language replication (R ↔ Python)
- [`/council`](skills/council/SKILL.md) — N parallel critics + synthesizer on any target
- [`/referee-response`](skills/referee-response/SKILL.md) — draft an R&R response letter in your voice
- [`/evaluate-idea-marketing`](skills/evaluate-idea-marketing/SKILL.md), [`/evaluate-idea-science`](skills/evaluate-idea-science/SKILL.md) — pre-execution idea scoring

**Slides and figures** ([skills/](skills/))

- [`/academic-pptx`](skills/academic-pptx/SKILL.md) — academic PowerPoint structure
- [`/academic-slides`](skills/academic-slides/SKILL.md) — Beamer-style HTML slides
- [`/create-lecture`](skills/create-lecture/SKILL.md) — scaffold a Beamer lecture or research-talk `.tex`
- [`/slide-excellence`](skills/slide-excellence/SKILL.md) — multi-agent slide review (visual + pedagogy + proofreading + TikZ)
- [`/tikz-iterate`](skills/tikz-iterate/SKILL.md) — compile → render → review → refine TikZ until it visually checks out
- [`/posterskill`](skills/posterskill/SKILL.md) — generate a conference poster from a paper

**Task orchestration** ([skills/](skills/))

- [`/daily-brief`](skills/daily-brief/SKILL.md) — score and rank open tasks, push top N to Telegram
- [`/capture`](skills/capture/SKILL.md) — process inbound Telegram replies into Notion task updates
- [`/log-todo`](skills/log-todo/SKILL.md) — mid-session capture into the Notion Tasks DB
- [`/notion-log`](skills/notion-log/SKILL.md) — append a dated entry to a Notion project page
- [`/notion-meeting-notes`](skills/notion-meeting-notes/SKILL.md) — extract action items from a Notion meeting page into the Tasks DB
- [`/task-pulse`](skills/task-pulse/SKILL.md) — read-only ad-hoc questions against the Tasks DB

**Replication and pipeline hygiene** ([skills/](skills/))

- [`/replication-package`](skills/replication-package/SKILL.md) — bundle a journal-ready replication archive

**Meta** ([skills/](skills/))

- [`/skill-creator`](skills/skill-creator/SKILL.md) — create / edit / eval / benchmark skills
- [`/init`](skills/init/SKILL.md), [`/review`](skills/review/SKILL.md), [`/security-review`](skills/security-review/SKILL.md), [`/simplify`](skills/simplify/SKILL.md), [`/update-config`](skills/update-config/SKILL.md), [`/keybindings-help`](skills/keybindings-help/SKILL.md), [`/fewer-permission-prompts`](skills/fewer-permission-prompts/SKILL.md), [`/loop`](skills/loop/SKILL.md), [`/schedule`](skills/schedule/SKILL.md), [`/claude-api`](skills/claude-api/SKILL.md)

One-page 4-way lookup table (by task, by trigger phrase, by category, by composition): [SKILL_INDEX.md](SKILL_INDEX.md). Full per-skill index with one-line descriptions: [skills/README.md](skills/README.md).

## Requirements

- Claude Code (latest)
- git, GitHub CLI (`gh`)
- Python >= 3.12 (+ `uv` for the stdio MCPs)
- Node.js >= 20 (for the OpenAlex / Playwright / GitHub MCPs)
- LaTeX: MiKTeX on Windows, MacTeX (or BasicTeX) on macOS

Per-OS install commands and recommended optional tooling: [docs/clis.md](docs/clis.md).

## MCPs used

Eight MCP servers wire Claude Code into external systems. Install details and OAuth flows in [docs/mcps.md](docs/mcps.md).

- **arxiv** — paper search / download / citation graph (stdio, no secrets)
- **semantic-scholar** — paper search, used by `/bibcheck` and `/litreview` (stdio, no secrets)
- **openalex** — academic search + trend analysis (stdio, free API key)
- **zotero** — read-only library lookup for `/cite` (stdio, API key)
- **playwright** — browser automation for OAuth flows and verification (stdio, no secrets)
- **github** — PR / issue / repo ops (local binary, GitHub PAT)
- **notion** — workspace I/O; backbone of `/log-todo`, `/notion-log`, `/capture`, `/task-pulse` (HTTP gateway, OAuth)
- **google-drive** — Drive file search (claude.ai web-portal connector, OAuth)

Several of the above (notably Google Drive, plus Gmail, Hugging Face, Scholar Gateway, and the lifestyle/travel set) are installed through the claude.ai connector catalog in the browser rather than via `claude mcp add`. See [docs/mcps.md](docs/mcps.md) for the OAuth flow and full per-connector breakdown.

## Workflow architecture

```
+-------------------------+        +-----------------------------+
|  Claude Code (skills)   | <----> |  Personal config (gitignored)|
|  ~/.claude/skills/      |        |  ~/.claude/state/            |
|  ~/.claude/agents/      |        |    personal_config.json     |
|  ~/.claude/hooks/       |        +-----------------------------+
+-------------------------+
            |
            | reads / writes
            v
+-------------------------+
|  MCPs                   |     Notion, Zotero, arXiv, Semantic
|  (8 servers)            | --> Scholar, OpenAlex, Playwright,
+-------------------------+     GitHub, Google Drive
            |
            | task data + diary entries
            v
+-------------------------+        +-----------------------------+
|  Notion workspace       | <----> |  lan-daily-brief (separate  |
|  (Tasks DB, project     |        |  repo) — Telegram bot +     |
|  pages, weekly agenda)  |        |  GitHub Actions cron        |
+-------------------------+        +-----------------------------+
                                              |
                                              v
                                       Telegram bot
                                       (morning brief,
                                       capture replies)
```

Skills live under `~/.claude/` and read all personal data from `~/.claude/state/personal_config.json`. The orchestration repo runs scheduled GitHub Actions that call the same Notion API and push to a Telegram bot — see [orchestration/README.md](orchestration/README.md).

## Setup

Full step-by-step in [SETUP.md](SETUP.md). The installer scripts (`scripts/install.ps1` / `scripts/install.sh`) handle the file copies; the rest is configuring Notion, Telegram, and MCPs in order.

## Personalization

Every skill resolves personal data at runtime from `~/.claude/state/personal_config.json` — Notion page / database IDs, Telegram chat ID, Overleaf root path, project list, voice-reference `.tex` file. To adapt this workflow to your own projects: [docs/adapting.md](docs/adapting.md).

## Attribution

This repo stands on the shoulders of other Claude Code workflow authors who shared their setups publicly:

- **Scott Cunningham** ([`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools)) — `/referee2`, `/blindspot`, `/bibcheck`, `/tikz-iterate` (concept), `/slide-excellence` patches, `/create-lecture --triage`
- **Chris Blattman** ([`chrisblattman/claudeblattman`](https://github.com/chrisblattman/claudeblattman)) — `/council`, daily-brief scoring patches, atomic-write discipline, `/notion-meeting-notes` thin-content gate, `/litreview --four-axis`, `/skill-creator` catalog-conflict gate
- **aspi6246** ([`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation)) — `/referee-response --five-q`, `/review-paper` buried-contribution check
- **Andrej Karpathy** ([`karpathy/autoresearch`](https://github.com/karpathy/autoresearch)) — reviewed; inspiration cited
- **Hugo Sant'Anna** ([`hugosantanna/clo-author`](https://github.com/hugosantanna/clo-author)) — reviewed; surfaced ideas in `docs/future-work.md`
- **Pedro H.C. Sant'Anna** ([`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow)) — earlier reference for the workflow-as-config-repo pattern

Full per-item attribution with the lines that were borrowed: [ATTRIBUTION.md](ATTRIBUTION.md).

## License

MIT — see [LICENSE](LICENSE). All source repos credited above ship under permissive licenses compatible with MIT redistribution; see [ATTRIBUTION.md](ATTRIBUTION.md) for per-source license notes.

## Status and disclaimer

This is tuned for one researcher's specific PhD workflow (quantitative marketing, Beamer + LaTeX, Notion + Telegram, Overleaf-on-Dropbox). It is a friendly fork-and-adapt: every personalized field reads from `~/.claude/state/personal_config.json`, so you can rewire to your own projects without touching skill prose. Bug reports and PRs welcome; large structural reworks are easier as forks.
