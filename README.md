# claude-academic-workflow

An academic-research workflow for Claude Code: skills for reading papers, running literature reviews, auditing bibliographies, designing and analyzing causal-inference studies (difference-in-differences, regression discontinuity, instrumental variables, synthetic control, randomized experiments), drafting preregistrations, checking drafts before submission, writing R&R responses, assembling replication packages, compiling LaTeX, iterating TikZ figures, and a Quarto reveal.js slide system with render-time quality gates. It was built for quantitative marketing and economics; most of it transfers to any empirical field.

Everything in this repository, including the two example decks and their figures, is AI-generated with Claude Code, as a proof of concept for what an agent-built research workflow looks like. Generated content is the responsibility of whoever uses it: verify citations, numbers, and claims before relying on them, the same way you would verify a research assistant's first draft.

## Quickstart

```bash
git clone https://github.com/ericluo04/claude-academic-workflow
cd claude-academic-workflow
cp -R skills/* ~/.claude/skills/
cp agents/tikz-reviewer.md ~/.claude/agents/
mkdir -p ~/.claude/assets && cp -R slide-tooling ~/.claude/assets/quarto-yale
```

Then read [SETUP.md](SETUP.md): it names every path and helper the skills assume (the Crossref contact address, the PDF helper, the Overleaf glob) and how to adjust each one. `CLAUDE.md` is the author's working global configuration, shared as an example. The three `style/house.md` files in the slide skills are stubs for your own taste: author line, closing-slide wording, palette rationale, density calibration.

## The global CLAUDE.md

`CLAUDE.md` is what Claude Code loads into every session as standing instructions; this one carries the author's voice rules (how prose should read) and working style (parallel subagents by default, decisions through the option picker, judgment calls raised before acting), which shape every skill's output without being repeated in any of them. If you adapt this repo, add your own standing context here: quants will want a computing-grid section (cluster login, Slurm citizenship rules, where storage lives), plus anything else Claude should know in every session, like data locations or preferred stacks.

## Skills

| Skill | What it does |
|---|---|
| `reading-papers` | Looks up and reads a specific paper from a link, DOI, title, or vague description, across marketing, economics, psychology, and CS venues. |
| `litreview` | Finds, ranks, and synthesizes the literature on a topic across Semantic Scholar, OpenAlex, and arXiv, then reads the top hits with parallel subagents. |
| `bibcheck` | Audits a `.bib` file entry by entry against canonical metadata and writes a corrected copy; catches wrong years, mis-cited authors, and hallucinated entries. |
| `causal-design` | Triages a causal question to the identification strategy the data can actually support, then hands off to the skill that owns it. Carries the selection-on-observables branch itself: overlap, doubly robust estimation, double machine learning, causal forests, sensitivity analysis. |
| `did` | Runs a difference-in-differences analysis with the heterogeneity-robust estimators, event-study diagnostics, and honest bounds on pre-trend violations. |
| `synthetic-control` | Builds and validates synthetic control comparisons, including synthetic difference-in-differences, the augmented and penalized variants, and factor-model alternatives. |
| `rdd` | Runs a regression discontinuity in both the continuity and local-randomization frameworks, with the design gate and the full falsification battery. |
| `iv` | Estimates instrumental-variables designs with weak-instrument-robust inference, shift-share and formula instruments, and an explicit exclusion-restriction argument. |
| `field-experiment` | Designs and analyzes randomized experiments: stratified and clustered assignment, randomization inference, power, attrition bounds, and pre-specified heterogeneity. |
| `preregister` | Drafts a registry-ready preregistration (AsPredicted, OSF, AEA RCT) with clarity flags and placeholders instead of invented content. |
| `council` | Spawns five independent critic subagents in parallel on any target, then a synthesis pass that ranks findings by how load-bearing they are. |
| `review-paper` | Runs a simulated referee review of your own draft with six agents in parallel, triaged CRITICAL/MAJOR/MINOR against a named target journal. See the [note of caution](#a-note-of-caution-on-reviewing) below. |
| `referee-response` | Drafts an R&R response letter where every claimed change is located and read in the manuscript before a location pin is written. |
| `replication-package` | Assembles a journal-ready replication archive and scans it for secrets, PII, and absolute local paths first. |
| `compile-latex` | Compiles with latexmk, auto-detects the engine and bib backend, and emits a ranked error report with file:line attribution. |
| `tikz-iterate` | Compiles a TikZ figure, rasterizes it, has the `tikz-reviewer` agent actually look at the image, and iterates until approved. |
| `research-talk` | Authors a Quarto reveal.js deck for a seminar, conference talk, or job talk: assertion titles, staged reveals, a deep appendix for questions. See the [example decks](#quarto-for-slides) below. |
| `teaching-lecture` | Authors classroom lecture decks built for engagement: worked examples, discussion prompts, checks for understanding, projector-sized figures. |
| `slide-review` | Renders a deck, screenshots every slide in a real browser, and reviews the pictures for overflow, contrast, broken figures, and a weak argument. |
| `course-site` | Builds the semester course website the lecture decks hang off, and publishes it to GitHub Pages. |

`agents/tikz-reviewer.md` is the adversarial visual critic `tikz-iterate` loops on. `slide-tooling/` holds the machinery the slide skills share: the staging filter, the fit and staging gates, the offline checker, a starter theme, and vendored MathJax and two webfont families; its README documents all of it.

### A note of caution on reviewing

`review-paper` is built for your own manuscripts: a pre-submission check on a draft before you send it out, to be run only on work you wrote. Do not use it, or any generative AI tool, to review other people's submissions. Journals are explicit about this: [Management Science's submission guidelines](https://pubsonline.informs.org/page/mnsc/submission-guidelines) tell the review team directly that they "should not upload any part of a manuscript submitted to *Management Science* into a generative AI tool such that it might compromise confidentiality and/or copyright", and JMR's [submission guidelines](https://journals.sagepub.com/author-instructions/mrj) defer to Sage's [ChatGPT and generative AI policy](https://www.sagepub.com/en-us/nam/chatgpt-and-generative-ai), which reserves the right to take action when a reviewer breaches peer-review confidentiality with GenAI tools. If you referee, check the journal's AI policy before involving any tool at all.

## Quarto for slides

Two live example decks, rendered by these skills and published on GitHub Pages:

- [Research talk](https://ericluo04.github.io/claude-academic-workflow/talk/talk.html): a seminar deck, with staged reveals, a framing withdrawn in place, a headline estimate that takes the accent on cue, jump buttons into the appendix, and a paginated reference list.
- [Teaching lecture](https://ericluo04.github.io/claude-academic-workflow/lectures/w03-evaluation.html): a classroom deck, with teaching blocks, a comparison that arrives from both sides, a leaderboard that gains its error bars in place, a worked example, discussion prompts, and agenda tracking.

Both are static pages that make zero network requests at display time; the [index](https://ericluo04.github.io/claude-academic-workflow/) links them with keyboard shortcuts. Their sources are in `examples/`, and the live copies are those sources rendered against the starter theme in `slide-tooling/`, exactly as they render out of the box.

The decks demonstrate what the pipeline can do; how your slides should look stays your call. The starter theme carries the machinery inside one worked look (paper ground, Literata display headings over IBM Plex Sans text, a plum accent), and the theme file marks every spot where your own taste replaces it. How wordy each slide is, the palette, the typography, and the staging rhythm are all preferences written down in plain text, in the doctrine and pacing sections of the `research-talk` and `teaching-lecture` skill files and in the SCSS variables at the top of the starter theme, so changing any of them is editing a paragraph or a variable. If the examples strike you as ugly, that is the expected case: rewrite the preferences until the output matches your own taste.

What Quarto reveal.js gives you:

- Modern web layout, with flexible animation: reveal's fragment variants, `.r-stack` for layering one exhibit over another in place, explicit fragment indices for regrouping a build across columns, and a transition set per slide. `auto-animate` carries an element across a slide boundary too; `slide-tooling/README.md` says what it can and cannot reach once the staging filter is in the chain.
- LaTeX equations, typeset from macros you define in the front matter.
- R and Python chunks that execute at render.
- Citations straight from a `.bib` file, rendered with a hover preview of the full reference and collected into a paginated list at the end.
- Video embedded with one HTML tag.

Beamer does the second of those and not the other three; its animation exists but is far less flexible. PowerPoint does none of them well: transitions and animations are not scriptable, and nothing in the AI-authoring chain writes its equation format, so an agent-written deck comes out static with its math as text or images. Either is a reasonable choice when a venue or your coauthors require it, when the talk already lives there, or when you simply prefer it and it fits your workflow better.

An important note: rendering needs a network. Quarto fetches its reveal.js dependencies the first time, and code chunks install what they import. Presenting does not, because `slide-tooling/` vendors MathJax and both typefaces, so a finished deck opens from a local file with the wifi off. That last part is this repo's doing rather than Quarto's default, which loads MathJax from a CDN and leaves the equations blank on a podium laptop with no connection.

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

- Overleaf's Dropbox integration makes every Overleaf project a plain folder on your computer. It takes a paid Overleaf plan and one link: in Overleaf, Account Settings > Dropbox > Link, authorize on the Dropbox side, and with the Dropbox desktop app installed each project appears at `Dropbox/Apps/Overleaf/<project name>`. You and your coding agent then edit the manuscript with any editor, and the edits reach Overleaf and your coauthors within seconds, in both directions. This is the setup that lets the LaTeX skills here (`compile-latex`, `bibcheck`, `referee-response`) work on Overleaf manuscripts as ordinary local files; the manuscript glob in SETUP.md already points at this folder. Two caveats from the [Overleaf docs](https://docs.overleaf.com/integrations-and-add-ons/dropbox): sync covers every active project you can edit, owned or shared, with no per-project selection, and linking your own account gives coauthors nothing on their machines (a collaborator who wants the same local folder needs their own paid plan).

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
  - Playwright: a real browser the agent drives. Concrete uses: booking flights and comparing options across sites, filling out forms (registrations, IRB portals, survey platforms), reading pages that sit behind a login or only render with JavaScript, scraping structured data, and looking at rendered pages and slide decks instead of trusting the markup; `slide-review` screenshots every slide through it. One caveat: the server's default persistent profile admits one browser instance at a time, so a single server drives one shared browser session and browser work serializes; the [Playwright MCP docs](https://github.com/microsoft/playwright-mcp) tell parallel clients to start separate server instances with `--isolated` or a distinct `--user-data-dir`. With one server, give it one task at a time, and when agents run in parallel, route the browser through one of them while the others take the non-browser work.
  - Gmail, Google Calendar, Google Drive: Gmail covers the drafting trick at the end of this section. Calendar and Drive answer scheduling questions and read shared documents without a download step.
  - Notion: reading and writing pages and databases, for when a lab or a course already lives there.
  - Hugging Face: model and dataset search plus repo files, for the ML side of a research pipeline.
  - A scholarly-search connector: semantic search over the academic literature as a tool call; the reading and lit-review skills use it as one rung of their source ladder.

  Consumer connectors (travel, tickets, restaurants) exist too, and occasionally earn their keep.

- An AI assistant sitting in your Zoom calls is worth having, and which one matters less than having one: Notion AI's meeting notes, Zoom's own AI Companion, and Otter all do the job. The value shows up weeks later, when you come back to a project after time away and the meeting summaries and extracted to-dos are how you remind yourself what is going on and reorganize. They also make the discussion searchable, so "what did we decide about X" has an answer without re-watching anything.

### API keys

Keys live in one env file outside the repo (`~/.claude/secrets/scholar.env` here, chmod 600); the skills reference it by path, so nothing sensitive sits in a skill file or a repository. All of them are optional and free; the tools fall back to the public pools without them. The ones worth having:

- OpenAlex offers a free key that raises the daily request budget substantially.
- Semantic Scholar issues keys on request.
- Crossref uses no keys; it wants a `mailto=` contact in each request, which routes you to its polite pool with better service. The `bibcheck` skill already sends one; set your own address there.

Two details of the supporting tooling: `paper.py` disk-caches every response for 30 days and rate-limits itself politely, so re-running a search does not re-spend the request budget, and the PDF helper runs on uv straight from its shebang, with no environment to build first.

### Name your sessions

Rename a session to what it is actually about (`/rename`), and `/resume` will show you a list you can read months later instead of a wall of timestamps and first lines. It costs a few seconds and it is what makes closing the terminal safe. Picking a project back up becomes choosing it from a list rather than reconstructing where you were.

### The Gmail drafting trick

When a university mail account cannot integrate with anything, draft in a personal Gmail via the Gmail MCP and copy the draft out of Gmail's web editor into the university client. Terminal copy-paste can sometimes mangle spacing and line breaks, so drafting in Gmail and copying from its editor is the cleaner route. The agent writes and revises the draft; you paste and send.

### Keyboard shortcuts

The prompt takes two families of keys: the readline editing bindings a shell already gives you, and Claude Code's own controls.

| Key | What it does |
|---|---|
| `Ctrl+A` / `Ctrl+E` | Move to the start or end of the line |
| `Ctrl+U` / `Ctrl+K` | Delete backward to the start of the line, or forward to the end |
| `Ctrl+W` or `Option+Delete` | Delete the previous word |
| `Option+B` / `Option+F` | Move back or forward one word |
| `Shift+Tab` | Cycle permission modes, including plan mode |
| `Esc` | Interrupt Claude mid-turn, or close an open dialog |
| `Esc` `Esc` | Open the rewind menu on an empty prompt; clear the draft when the input has text |
| `Ctrl+O` | Toggle the transcript viewer, which shows the full tool output |
| `Up` | Step back through prompt history, once the cursor reaches the top row |
| `/` | Run a command or a skill |
| `@` | Reference a file by path, with autocomplete |
| `#` | Save what you type as a memory for later sessions |
| `!` | Run a shell command and drop its output into the session |

Option+B and Option+F need the Option key sending Meta, which macOS Terminal does not do by default: Terminal > Settings > Profiles > select your profile > Keyboard tab, then check "Use Option as Meta key".

### Read your own usage with /insights

`/insights` reads your session history and writes an HTML report: what you actually work on, which tools you lean on, where sessions went wrong, and concrete suggestions with the evidence behind each one. The useful part is the friction analysis, since it names patterns you cannot see from inside a single session (the questions that turned into twenty diagnostic commands, the sessions that ended mid-build, the standing conventions that got skipped). The report ends with copy-paste suggestions, and the good way to use them is to hand the whole thing back to Claude Code: point it at the HTML file and ask it to read the suggestions critically, say which are genuinely worth it, and fold those into the skills and `CLAUDE.md` you already have instead of adding new files. A capable model reading its own usage report will tell you that half the proposals duplicate something you built months ago.

### Side questions with /btw

While Claude is working on something long, `/btw` asks a quick question without interrupting it. The side question runs alongside the main task instead of derailing it, so you can check what a flag does or think out loud while a build or a research pass keeps going, and the main work resumes where it was. It keeps its own history, separate from the thread you interrupted.

### Running a model on your own machine (Ollama)

Not many people know this one. If you need to work with material that is confidential, unpublished, or covered by an agreement about where data may go, or you need to work with no network at all on a flight or a bus ride, you can run a language model on your own computer. [Ollama](https://ollama.com) is the easiest way in: a free, open-source tool that downloads and runs open-weight models locally, so prompts and documents are processed on your machine and never transmitted to any cloud service or company. It is a separate tool from Claude Code, and the models it serves are open-weight ones from other labs; many of them are now performant enough for real work, though the larger ones want capable hardware. Setup is on the [download page](https://ollama.com/download), and the [project repository](https://github.com/ollama/ollama) has the rest.

On a 48 GB Apple Silicon machine the set I keep installed is `qwen3.6:35b` for reasoning and coding, `gemma4:12b` when I want a fast answer, and `glm-ocr` for pulling tables and equations out of scanned PDFs, with audio handled separately by `mlx-whisper` since Ollama accepts text and images but not sound; pull the plain tags rather than the `-mlx` ones, which are faster but silently ignore images.

## License and credit

MIT, see [LICENSE](LICENSE). The skills adapt ideas from several public workflows (Pedro Sant'Anna, Scott Cunningham, Chris Blattman, Claes Bäckman, and others); [ATTRIBUTION.md](ATTRIBUTION.md) traces each one and covers the vendored Literata and IBM Plex Sans (both OFL) and MathJax (Apache 2.0) copies.
