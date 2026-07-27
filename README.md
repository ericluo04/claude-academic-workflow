# claude-academic-workflow

An academic-research workflow for Claude Code: skills for reading papers, running literature reviews, auditing bibliographies, drafting preregistrations, writing referee reports and R&R responses, assembling replication packages, compiling LaTeX, iterating TikZ figures, and a Quarto reveal.js slide system with render-time quality gates. It was built for quantitative marketing and economics; most of it transfers to any empirical field.

Everything in this repository, including both example decks and their figures, is AI-generated with Claude Code, as a proof of concept for what an agent-built research workflow looks like. Generated content is the responsibility of whoever uses it: verify citations, numbers, and claims before relying on them, the same way you would verify a research assistant's first draft.

Two live example decks, rendered by these skills and published on GitHub Pages:

- [Research talk](https://ericluo04.github.io/claude-academic-workflow/talk/talk.html): a seminar deck, with staged reveals, jump buttons into the appendix, and a paginated reference list.
- [Teaching lecture](https://ericluo04.github.io/claude-academic-workflow/lectures/w03-evaluation.html): a classroom deck, with teaching blocks, a worked example, discussion prompts, and agenda tracking.

Both are static pages that make zero network requests at display time; the [index](https://ericluo04.github.io/claude-academic-workflow/) links them with keyboard shortcuts. Their sources are in `examples/`, and the live copies are those sources rendered against the starter theme in `slide-tooling/`, exactly as they render out of the box. The starter theme carries the machinery inside one worked look (paper ground, serif display headings, a plum accent), and the theme file marks every spot where your own taste replaces it.

## Quickstart

```bash
git clone https://github.com/ericluo04/claude-academic-workflow
cd claude-academic-workflow
cp -R skills/* ~/.claude/skills/
cp agents/tikz-reviewer.md ~/.claude/agents/
mkdir -p ~/.claude/assets && cp -R slide-tooling ~/.claude/assets/quarto-yale
```

Then read [SETUP.md](SETUP.md): it names every path and helper the skills assume (the Crossref contact address, the PDF helper, the Overleaf glob) and how to adjust each one. `CLAUDE.md` is the author's working global configuration, shared as an example. The three `style/house.md` files in the slide skills are stubs for your own taste: author line, closing-slide wording, palette rationale, density calibration.

## Skills

| Skill | What it does |
|---|---|
| `reading-papers` | Looks up and reads a specific paper from a link, DOI, title, or vague description, across marketing, economics, psychology, and CS venues. |
| `litreview` | Finds, ranks, and synthesizes the literature on a topic across Semantic Scholar, OpenAlex, and arXiv, then reads the top hits with parallel subagents. |
| `bibcheck` | Audits a `.bib` file entry by entry against canonical metadata and writes a corrected copy; catches wrong years, mis-cited authors, and hallucinated entries. |
| `preregister` | Drafts a registry-ready preregistration (AsPredicted, OSF, AEA RCT) with clarity flags and placeholders instead of invented content. |
| `council` | Spawns five independent critic subagents in parallel on any target, then a synthesis pass that ranks findings by how load-bearing they are. |
| `review-paper` | Runs a full referee review with six agents in parallel, triaged CRITICAL/MAJOR/MINOR against a named target journal. |
| `referee-response` | Drafts an R&R response letter where every claimed change is located and read in the manuscript before a location pin is written. |
| `replication-package` | Assembles a journal-ready replication archive and scans it for secrets, PII, and absolute local paths first. |
| `compile-latex` | Compiles with latexmk, auto-detects the engine and bib backend, and emits a ranked error report with file:line attribution. |
| `tikz-iterate` | Compiles a TikZ figure, rasterizes it, has the `tikz-reviewer` agent actually look at the image, and iterates until approved. |
| `research-talk` | Authors a Quarto reveal.js deck for a seminar, conference talk, or job talk: assertion titles, staged reveals, a deep appendix for questions. |
| `teaching-lecture` | Authors classroom lecture decks built for engagement: worked examples, discussion prompts, checks for understanding, projector-sized figures. |
| `slide-review` | Renders a deck, screenshots every slide in a real browser, and reviews the pictures for overflow, contrast, broken figures, and a weak argument. |
| `course-site` | Builds the semester course website the lecture decks hang off, and publishes it to GitHub Pages. |

`agents/tikz-reviewer.md` is the adversarial visual critic `tikz-iterate` loops on. `slide-tooling/` holds the machinery the slide skills share: the staging filter, the fit and staging gates, the offline checker, a starter theme, and vendored MathJax and Inter; its README documents all of it.

## Things you may not know

A few of the higher-leverage discoveries from building this, none of them obvious from the docs.

- Claude Code's agent view runs many named sessions side by side, each with its own context, which is how the parallel-subagent habit in `CLAUDE.md` scales past one project: one session drives the paper revision while another rebuilds a lecture deck in a second repository, and you move between them the way you move between browser tabs. Starting another line of work is nearly free. Press the left arrow on an empty prompt (or run `claude agents`) and the current session backgrounds itself into the view; speak or type a task into the dispatch input at the bottom and a fresh session spins up on it, so with voice input on (next bullet), a new query costs a keypress and a spoken sentence.

  The view also does the supervising. Sessions are grouped by state (needs input, working, ready for review, completed), so a glance separates the agents that are blocked on you from the ones still going; selecting a row re-activates that session with its context intact, so you can hand a running agent more work instead of starting over. You end up steering a fleet instead of babysitting one chat. The [agent view docs](https://code.claude.com/docs/en/agent-view) cover the dispatch shortcuts and session states.

  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-dark.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=a5bed7434bae368faea3a8f023b52aa2">
    <img alt="Agent view in a terminal: sessions grouped under needs input, working, and completed, with a dispatch input at the bottom" src="https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-light.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=7a186c96ed47d6700d084d77e786be65">
  </picture>

  image: [Anthropic docs](https://code.claude.com/docs/en/agent-view)

- Voice input in hold mode (the `voice` block in the settings below) makes long, messy instructions cheap to give: hold the key and think out loud, corrections and all. It pairs well with remote control from a phone, where typing is the slow part. Rough transcription is fine; the agent resolves "that figure with the wrong axis label" from context.

- Settings worth turning on in `~/.claude/settings.json`, all defaults the author runs with:

  ```json
  {
    "cleanupPeriodDays": 365,
    "remoteControlAtStartup": true,
    "agentPushNotifEnabled": true,
    "preferredNotifChannel": "terminal_bell",
    "fileCheckpointingEnabled": true,
    "voice": { "enabled": true, "mode": "hold" }
  }
  ```

  - `cleanupPeriodDays` is the reproducibility setting: Claude Code deletes chat transcripts after 30 days by default, and a year of retention means the session that produced an analysis, a figure, or a referee response can still be reopened and audited when a coauthor or reviewer asks how it was made.
  - `remoteControlAtStartup` lets you drive sessions from your phone through the Claude app. The computer has to be on with Claude Code running, but that is exactly the common case: out to lunch, or the laptop charging at home on a weekend. Sessions started on the computer automatically appear in the app on your phone, so when something comes to mind while you are away you can steer a running session or start work from wherever you are. When you get back, the desktop sessions reflect everything done from the phone, conversations included. Time away stops being dead time: work can run and be steered while you are out and be ready when you return.
  - `agentPushNotifEnabled` sends a push when a background agent finishes, so a long run does not need watching.
  - `preferredNotifChannel` set to `terminal_bell` rings the terminal bell whenever a task finishes or needs your input; the next bullet has the macOS setup.
  - `fileCheckpointingEnabled` checkpoints file edits so a bad change can be rolled back.
  - `voice` turns on hold-to-talk dictation, covered two bullets up.

- macOS Terminal can call you back when a long run finishes. The exact path, verified on Terminal 2.15: Terminal > Settings > Profiles > select your profile > Advanced tab, then under Bell check "Audible bell". In the same group, "Badge app and window Dock icons" and "Bounce app icon when in background" cover bells that ring while Terminal is in the background. For a spoken alert on top of the sound, the checkbox lives outside Terminal: System Settings > Accessibility > Spoken Content > "Speak announcements" has the Mac announce by voice when an app wants attention. `"preferredNotifChannel": "terminal_bell"` above is what makes Claude Code ring the bell in the first place, whenever a task finishes or needs your input.

- MCP integrations worth setting up:
  - Zotero: the deep one. The agent searches the library by keyword or semantically across full texts, runs retraction checks through scite before a paper gets cited, reads the attached PDFs and your annotations, and adds new entries by DOI. Pair it with Better BibTeX: stable citation keys mean the references the agent writes today still compile next month.
  - Playwright: a real browser the agent drives, for scraping and form-filling, and for looking at rendered pages and slide decks instead of trusting the markup; `slide-review` screenshots every slide through it.
  - Gmail, Google Calendar, Google Drive: Gmail covers the drafting trick at the end of this section. Calendar and Drive answer scheduling questions and read shared documents without a download step.
  - Notion: reading and writing pages and databases, for when a lab or a course already lives there.
  - Hugging Face: model and dataset search plus repo files, for the ML side of a research pipeline.
  - A scholarly-search connector: semantic search over the academic literature as a tool call; the reading and lit-review skills use it as one rung of their source ladder.

  Consumer connectors (travel, tickets, restaurants) exist too, and occasionally earn their keep.

### API keys

Keys live in one env file outside the repo (`~/.claude/secrets/scholar.env` here, chmod 600); the skills reference it by path, so nothing sensitive sits in a skill file or a repository. All of them are optional and free; the tools fall back to the public pools without them. The ones worth having:

- OpenAlex offers a free key that raises the daily request budget substantially.
- Semantic Scholar issues keys on request.
- Crossref uses no keys; it wants a `mailto=` contact in each request, which routes you to its polite pool with better service. The `bibcheck` skill already sends one; set your own address there.

Two details of the supporting tooling: `paper.py` disk-caches every response for 30 days and rate-limits itself politely, so re-running a search does not re-spend the request budget, and the PDF helper runs on uv straight from its shebang, with no environment to build first.

### The Gmail drafting trick

When a university mail account cannot integrate with anything, draft in a personal Gmail via the Gmail MCP and copy the draft out of Gmail's web editor into the university client. Terminal copy-paste can sometimes mangle spacing and line breaks, so drafting in Gmail and copying from its editor is the cleaner route. The agent writes and revises the draft; you paste and send.

## License and credit

MIT, see [LICENSE](LICENSE). The skills adapt ideas from several public workflows (Pedro Sant'Anna, Scott Cunningham, Chris Blattman, Claes Bäckman, and others); [ATTRIBUTION.md](ATTRIBUTION.md) traces each one and covers the vendored Inter (OFL) and MathJax (Apache 2.0) copies.
