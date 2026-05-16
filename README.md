# claude-academic-workflow

A complete academic-research workflow for Claude Code — 32 skills, 4 sub-agents, 3 hooks, 6 stdio MCPs plus the claude.ai connector catalog, Notion + Telegram task orchestration, cross-platform (Windows + macOS).

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

At a glance:

| Component | Count | Location | Index |
|---|---|---|---|
| Skills | 32 | [`skills/`](skills/) | [SKILL_INDEX.md](SKILL_INDEX.md) (4-way lookup), [skills/README.md](skills/README.md) (one-liners) |
| Sub-agents | 4 | [`agents/`](agents/) | [agents/README.md](agents/README.md) |
| Hooks | 3 | [`hooks/`](hooks/) | [hooks/README.md](hooks/README.md) |
| Personal config (template) | 1 | [`skills/_config/`](skills/_config/) | [skills/_config/README.md](skills/_config/README.md) |
| Settings templates | 2 | [`config/`](config/) | [config/README.md](config/README.md) |
| Docs | 11 | [`docs/`](docs/) | see [Documentation](#documentation) below |
| Helper scripts | 6 | [`scripts/`](scripts/) | see [Scripts](#scripts) below |

The skill listing below is grouped by task. The full alphabetical index with trigger phrases and composition pointers is in [SKILL_INDEX.md](SKILL_INDEX.md).

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
- [`/academic-slides`](skills/academic-slides/SKILL.md) — Beamer-style HTML slides (with [`STYLE_PRESETS.md`](skills/academic-slides/STYLE_PRESETS.md) and [`references/`](skills/academic-slides/references/) for theme / viewport / PPT-ingest rules)
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

**Sub-agents** ([agents/](agents/)) — specialist reviewers spawned by the slide-quality skills, restricted to read-only tools.

- [`tikz-reviewer`](agents/tikz-reviewer.md) — devil's-advocate TikZ diagram review (used by `/slide-excellence`, `/tikz-iterate`)
- [`proofreader`](agents/proofreader.md), [`slide-auditor`](agents/slide-auditor.md), [`pedagogy-reviewer`](agents/pedagogy-reviewer.md) — Beamer deck review (used by `/slide-excellence`)

**Hooks** ([hooks/](hooks/)) — harness-lifecycle scripts, all fail-open so a bug never blocks Claude Code.

- [`pre-compact.py`](hooks/pre-compact.py) — snapshot active plan + first unchecked task before compaction
- [`post-compact-restore.py`](hooks/post-compact-restore.py) — replay the snapshot on `SessionStart`
- [`format-on-edit.py`](hooks/format-on-edit.py) — auto-run `ruff format` / `styler::style_file()` after every Edit/Write

**Personalization** — every skill resolves personal data at runtime from `~/.claude/state/personal_config.json` (Notion IDs, Telegram chat ID, Overleaf root, project list, voice-reference `.tex`). Template + field-by-field documentation in [`skills/_config/`](skills/_config/README.md). To adapt the workflow to your own projects: [docs/adapting.md](docs/adapting.md).

## Requirements

- Claude Code (latest)
- git, GitHub CLI (`gh`)
- Python >= 3.12 (+ `uv` for the stdio MCPs)
- Node.js >= 20 (for the OpenAlex / Playwright / GitHub MCPs)
- LaTeX: MiKTeX on Windows, MacTeX (or BasicTeX) on macOS

Per-OS install commands and recommended optional tooling: [docs/clis.md](docs/clis.md).

## MCPs

Three integration shapes — install commands, OAuth flows, and per-skill consumption table in [docs/mcps.md](docs/mcps.md).

**1. Stdio MCPs (6, open-source, run locally via `claude mcp add`)**

- **arxiv** — paper search / download / citation graph (no secrets)
- **semantic-scholar** — paper / author / citation-graph queries (free API; optional key for higher quota)
- **openalex** — bibliographic graph, author disambiguation (free "polite pool" email)
- **zotero** — read-only library lookup for `/cite` (API key)
- **playwright** — browser automation for OAuth flows and verification (no secrets)
- **github** — PR / issue / repo ops (local binary, GitHub PAT)

**2. HTTP / OAuth gateway MCPs (1, CLI-added)**

- **notion** — workspace I/O; backbone of `/log-todo`, `/notion-log`, `/capture`, `/task-pulse`, `/notion-meeting-notes`, `/daily-brief`

**3. claude.ai web-portal connectors (OAuth, browser-based — no `claude mcp add` needed)**

Installed by clicking "Connect" in the claude.ai Settings → Connectors catalog. Tools then appear inside Claude Code with the `mcp__claude_ai_<Provider>__<action>` prefix. The catalog evolves — verify the live set on the connector page.

- **Google Drive** — Drive file search; used ad hoc by `/cite` and reference lookups
- **Gmail** — email read/triage and draft creation; planned `/email-triage` skill
- **Hugging Face** — search models / datasets / papers / spaces; used by `/litreview` on ML topics
- **Scholar Gateway** — institutional-access bridge for paywalled content; best-effort assist to `/cite`, `/bibcheck`, `/litreview`
- **Microsoft 365** — Outlook / Calendar / Teams / OneDrive; **commonly blocked by university tenants** — substitute via Gmail forwarding + iCal, see [docs/outlook-gmail.md](docs/outlook-gmail.md)
- **Lifestyle / travel** — Resy, StubHub, Booking.com, Expedia, Tripadvisor, Trivago. Optional; useful for conference-trip logistics from `/log-todo`-style asks.

Full per-connector breakdown (scopes, why-useful, status): [docs/mcps.md](docs/mcps.md#claudeai-web-portal-connectors-oauth-browser-based-setup).

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
|  MCPs                   |     6 stdio: arxiv, semantic-scholar,
|  6 stdio + 1 HTTP       | --> openalex, zotero, playwright, github
|  + claude.ai connectors |     1 HTTP gateway: notion
+-------------------------+     claude.ai catalog: Google Drive, Gmail,
                                Hugging Face, Scholar Gateway, M365,
                                Resy/StubHub/Booking/Expedia/Tripadvisor/
                                Trivago
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

Skills live under `~/.claude/` and read all personal data from `~/.claude/state/personal_config.json`. The orchestration repo runs scheduled GitHub Actions that call the same Notion API and push to a Telegram bot — see [orchestration/README.md](orchestration/README.md) for the high-level shape and the link to the companion repo [`ericluo04/lan-daily-brief`](https://github.com/ericluo04/lan-daily-brief).

## Documentation

Eleven docs under [`docs/`](docs/), one per concern. Start with `platforms.md` if you are setting up a fresh machine.

| Doc | Covers |
|---|---|
| [platforms.md](docs/platforms.md) | Side-by-side Windows / macOS / Linux paths, package managers, and toolchain matrix |
| [clis.md](docs/clis.md) | Recommended CLIs with install commands and version checks |
| [mcps.md](docs/mcps.md) | Full MCP catalog: stdio installs, HTTP gateway, claude.ai connectors, token refresh |
| [tex-setup.md](docs/tex-setup.md) | MiKTeX / MacTeX / TeX Live for slide and replication skills |
| [notion-setup.md](docs/notion-setup.md) | Notion Tasks DB + Weekly Agenda + project pages layout and integration |
| [telegram-setup.md](docs/telegram-setup.md) | Bot creation, token handling, chat-ID retrieval |
| [overleaf-dropbox.md](docs/overleaf-dropbox.md) | Overleaf ↔ Dropbox sync for the project tree the skills read from |
| [outlook-gmail.md](docs/outlook-gmail.md) | Substitute path when Microsoft 365 OAuth is blocked at your university |
| [adapting.md](docs/adapting.md) | How a friend forks the repo and rewires it to their own projects |
| [future-work.md](docs/future-work.md) | Roadmap of unshipped skills and patches |
| [attribution-table.md](docs/attribution-table.md) | Master attribution table (per-skill, per-source, per-license) |

## Scripts

Helper scripts in [`scripts/`](scripts/):

- [`install.ps1`](scripts/install.ps1) / [`install.sh`](scripts/install.sh) — copy skills / agents / hooks into `~/.claude/`, render `settings.json` from the template, scaffold `state/`.
- [`verify.ps1`](scripts/verify.ps1) / [`verify.sh`](scripts/verify.sh) — post-install sanity check (MCPs reachable, personal_config fields filled, hook scripts executable).
- [`redact-check.py`](scripts/redact-check.py) — local pre-commit gate that scans for secrets and personal IDs against `scripts/.blocklist.json`. CI runs gitleaks over the same surface — see [Security](#security).
- [`_render_settings.py`](scripts/_render_settings.py) — template substitution helper used by the installers.

## Configuration

Two settings templates in [`config/`](config/), both rendered by the installer into `~/.claude/`:

- [`settings.example.json`](config/settings.example.json) → `~/.claude/settings.json` (global config; registers the three hooks)
- [`settings.local.example.json`](config/settings.local.example.json) → `~/.claude/settings.local.json` (per-user permission allowlist; merged over the base)

Both target files are user-local and gitignored once installed. Details and the `${HOME}` substitution rule: [config/README.md](config/README.md).

## Security

Three layers, all on by default:

1. **`personal_config.json` is gitignored** and lives only under `~/.claude/state/`. Skills surface a "config missing" error and refuse to proceed rather than guess if a field is unset — guessing produces silently wrong Notion writes. Bot tokens and API keys never go in this file; they live in `~/.claude/state/telegram.json` (gitignored) or GitHub Actions Secrets. See [skills/_config/README.md](skills/_config/README.md#safe-to-share-vs-never-share) for the safe-to-share table.
2. **`scripts/redact-check.py`** runs locally before every commit, scanning files against an exact-string blocklist (`scripts/.blocklist.json`, gitignored; example at `.blocklist.example.json`) and a pattern set.
3. **CI secret scan** — [`.github/workflows/secret-scan.yml`](.github/workflows/secret-scan.yml) runs gitleaks against [`.gitleaks.toml`](.gitleaks.toml) on every PR to catch anything the local check missed.

## Setup

Full step-by-step in [SETUP.md](SETUP.md). The installer scripts (`scripts/install.ps1` / `scripts/install.sh`) handle the file copies; the rest is configuring Notion, Telegram, and MCPs in order. To adapt to your own projects: [docs/adapting.md](docs/adapting.md).

## Attribution

This repo stands on the shoulders of other Claude Code workflow authors who shared their setups publicly. High-level credits below; full per-item attribution with the lines that were borrowed is in [ATTRIBUTION.md](ATTRIBUTION.md).

- **Anthropic** ([`anthropics/skills`](https://github.com/anthropics/skills)) — `/skill-creator` (entire skill, including analyzer / comparator / grader sub-agents, eval viewer, and benchmark scripts); the foundation every other skill in this repo was built on
- **Scott Cunningham** ([`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools)) — `/referee2`, `/blindspot`, `/bibcheck`, `/tikz-iterate` (concept), `/slide-excellence` pedagogy lenses, `/create-lecture --triage`
- **Pedro H.C. Sant'Anna** ([`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow)) — all four sub-agents (`slide-auditor`, `pedagogy-reviewer`, `proofreader`, `tikz-reviewer`), `/seven-pass-review`, `/preregister`, `/slide-excellence` base orchestrator, `/create-lecture` base workflow, `/audit-reproducibility` 5-phase audit, both compaction hooks (`pre-compact.py`, `post-compact-restore.py`), and the workflow-as-config-repo pattern itself
- **Chris Blattman** ([`chrisblattman/claudeblattman`](https://github.com/chrisblattman/claudeblattman)) — `/council`, `/daily-brief` wait-factor + type-balance scoring, atomic-write discipline, `/notion-meeting-notes` thin-content gate, `/litreview --four-axis`, `/skill-creator` catalog-conflict gate
- **Claes Bäckman** ([`claesbackman/AI-research-feedback`](https://github.com/claesbackman/AI-research-feedback)) — base designs for all five review skills (`/review-paper`, `/review-paper-light`, `/review-paper-code`, `/review-pap`, `/review-grant`), including agent counts and role names
- **Zara Zhang** ([`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides)) — `/academic-slides` scaffolding (Phase 0-5 architecture, "Show Don't Tell" preview UX, STYLE_PRESETS convention, viewport-fit invariant, python-pptx ingest)
- **Gabberflast** ([`Gabberflast/academic-pptx-skill`](https://github.com/Gabberflast/academic-pptx-skill)) — `/academic-pptx` (entire skill — SKILL.md, content_guidelines.md, slide_patterns.md, "Structured Argument" mode, ghost-deck test, action titles)
- **Ethan Weber** ([`ethanweber/posterskill`](https://github.com/ethanweber/posterskill)) — `/posterskill` (entire skill — paper + project-website ingestion, single-file React-via-CDN interactive HTML poster architecture)
- **aspi6246** ([`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation)) — `/referee-response --five-q`, `/review-paper` and `/review-paper-light` buried-contribution check
- **Andrej Karpathy** ([`karpathy/autoresearch`](https://github.com/karpathy/autoresearch)) — reviewed; broader "Claude Code as iterative research collaborator" framing cited
- **Hugo Sant'Anna** ([`hugosantanna/clo-author`](https://github.com/hugosantanna/clo-author)) — reviewed; non-overlapping ideas surfaced in [docs/future-work.md](docs/future-work.md)

## License

MIT — see [LICENSE](LICENSE). All source repos credited above ship under permissive licenses compatible with MIT redistribution; see [ATTRIBUTION.md](ATTRIBUTION.md) for per-source license notes.

## Status and disclaimer

This is tuned for one researcher's specific PhD workflow (quantitative marketing, Beamer + LaTeX, Notion + Telegram, Overleaf-on-Dropbox). It is a friendly fork-and-adapt: every personalized field reads from `~/.claude/state/personal_config.json`, so you can rewire to your own projects without touching skill prose. Bug reports and PRs welcome; large structural reworks are easier as forks.
