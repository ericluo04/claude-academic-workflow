# SKILL_INDEX

A one-page lookup for the 34 skills in this repo, indexed four different ways: by task, by trigger phrase, by category, and by composition. For full per-skill descriptions, see [skills/README.md](skills/README.md).

## Review-skill decision tree

Ten skills target reviewing. They are not redundant — they sit at different stages of the manuscript / project lifecycle.

**What are you reviewing?**

- **A manuscript (draft or near-final)**
  - 1-minute sanity check → [`/review-paper-light`](skills/review-paper-light/SKILL.md) (2 agents: contribution + identification)
  - Structured pre-submission referee report → [`/review-paper`](skills/review-paper/SKILL.md) (6 agents: spelling, internal consistency, unsupported claims, math, tables, contribution)
  - Deep adversarial read with quality thresholds → [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) (7 lenses: abstract, intro, methods, results, robustness, prose, citations; 80/90/95 score targets)
  - 5-critic adversarial cross-section, not manuscript-bound → [`/council`](skills/council/SKILL.md) (target-agnostic; also works on plans, R&R strategies, drafts, skill designs)

- **A single figure or table** → [`/blindspot`](skills/blindspot/SKILL.md) (Shklovsky 4-quadrant: unexplained / convenient-absence / unasked-question / unexploited-strength). Composes with `/seven-pass-review` (figure-level early, manuscript-level later).

- **Numeric claims in a manuscript (do the paper numbers match the code?)**
  - Single-language tolerance check → [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md)
  - Stricter cross-language audit (reimplement R↔Python, compare to 6 decimals) → [`/referee2`](skills/referee2/SKILL.md)

- **Research code itself (reproducible? matches paper?)** → [`/review-paper-code`](skills/review-paper-code/SKILL.md) (Discovery → Paper Analysis → Parallel Code Review → Synthesis → Report)

- **A pre-analysis plan / preregistration draft** → [`/review-pap`](skills/review-pap/SKILL.md) (6 agents: clarity/pre-spec, hypotheses/outcomes, identification, statistical plan, data/operational, adversarial referee)

- **A grant proposal** → [`/review-grant`](skills/review-grant/SKILL.md) (6-agent panel: clarity/compliance, internal consistency, significance/innovation, design/feasibility, budget/timeline/team, adversarial panel)

- **A skill design or workflow plan** → [`/council --chef-skill`](skills/council/SKILL.md) (skill-design critic roster; complements `/skill-creator`)

**Typical R&R sequencing:** [`/blindspot`](skills/blindspot/SKILL.md) (per disputed figure) → [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) (changed numbers) → [`/review-paper-light`](skills/review-paper-light/SKILL.md) (quick re-read) → [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) (deep pass) → [`/referee2`](skills/referee2/SKILL.md) (cross-language re-audit) → [`/replication-package`](skills/replication-package/SKILL.md) (assembly).

**Rule of thumb:** pre-draft / ideation → `/council`; draft-stage quick scan → `/review-paper-light`; draft-stage structured → `/review-paper`; pre-submission deepest pass → `/seven-pass-review`.

## By task

| I want to... | Use |
|---|---|
| Draft a paper section (intro / methods / limitations) in my voice | [`/draft`](skills/draft/SKILL.md) |
| Scrub AI-writing tells out of text and rewrite it into my voice | [`/deslop`](skills/deslop/SKILL.md) |
| Find papers on a topic across arXiv / Semantic Scholar / OpenAlex | [`/litreview`](skills/litreview/SKILL.md) |
| Add a single paper to my `.bib` from a DOI / arXiv / title | [`/cite`](skills/cite/SKILL.md) |
| Audit my `.bib` for fabricated / wrong citations before submission | [`/bibcheck`](skills/bibcheck/SKILL.md) |
| Get a 1-minute adversarial gut check on a paper | [`/review-paper-light`](skills/review-paper-light/SKILL.md) |
| Get a structured pre-submission referee report | [`/review-paper`](skills/review-paper/SKILL.md) |
| Get a deep 7-pass adversarial manuscript review | [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) |
| Review research code for reproducibility | [`/review-paper-code`](skills/review-paper-code/SKILL.md) |
| Review a pre-analysis plan | [`/review-pap`](skills/review-pap/SKILL.md) |
| Review a grant proposal | [`/review-grant`](skills/review-grant/SKILL.md) |
| Run a cross-language replication audit (R ↔ Python) | [`/referee2`](skills/referee2/SKILL.md) |
| Verify every numeric claim in the manuscript matches the code | [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) |
| Spot what a hostile referee would catch in a single figure or table | [`/blindspot`](skills/blindspot/SKILL.md) |
| Get a 5-critic panel review on a plan / R&R / grant / skill | [`/council`](skills/council/SKILL.md) |
| Draft an R&R response letter in my voice | [`/referee-response`](skills/referee-response/SKILL.md) |
| Score a research idea against the marketing-journal bar | [`/evaluate-idea-marketing`](skills/evaluate-idea-marketing/SKILL.md) |
| Score a research idea against the broad-science bar | [`/evaluate-idea-science`](skills/evaluate-idea-science/SKILL.md) |
| Draft a preregistration (AsPredicted / OSF / AEA RCT) | [`/preregister`](skills/preregister/SKILL.md) |
| Bundle a journal-ready replication package | [`/replication-package`](skills/replication-package/SKILL.md) |
| Iterate a TikZ diagram until it visually checks out | [`/tikz-iterate`](skills/tikz-iterate/SKILL.md) |
| Compile a `.tex` and get a ranked error report (+ auto-iterate figures) | [`/compile-latex`](skills/compile-latex/SKILL.md) |
| Build a Beamer-style HTML deck | [`/academic-slides`](skills/academic-slides/SKILL.md) |
| Build a PowerPoint deck for an academic audience | [`/academic-pptx`](skills/academic-pptx/SKILL.md) |
| Scaffold a Beamer LaTeX talk or lecture from sources | [`/create-lecture`](skills/create-lecture/SKILL.md) |
| Multi-agent review of a Beamer deck | [`/slide-excellence`](skills/slide-excellence/SKILL.md) |
| Build a conference poster | [`/posterskill`](skills/posterskill/SKILL.md) |
| Build my morning task list | [`/daily-brief`](skills/daily-brief/SKILL.md) |
| Process Telegram replies into Notion task updates | [`/capture`](skills/capture/SKILL.md) |
| File one todo into Notion from chat | [`/log-todo`](skills/log-todo/SKILL.md) |
| Log a session diary entry to a Notion project page | [`/notion-log`](skills/notion-log/SKILL.md) |
| Extract action items from a Notion meeting-notes page | [`/notion-meeting-notes`](skills/notion-meeting-notes/SKILL.md) |
| Query the Notion Tasks DB ad-hoc (read-only) | [`/task-pulse`](skills/task-pulse/SKILL.md) |
| Create, edit, eval, or benchmark a skill | [`/skill-creator`](skills/skill-creator/SKILL.md) |

## By trigger phrase

| If you say... | It routes to |
|---|---|
| "draft an intro", "rewrite in my voice", "write the limitations" | [`/draft`](skills/draft/SKILL.md) |
| "deslop this", "make this sound less like AI", "remove the AI tells", "humanize this" | [`/deslop`](skills/deslop/SKILL.md) |
| "respond to referees", "address reviewer comments", "draft the R&R" | [`/referee-response`](skills/referee-response/SKILL.md) |
| "cite this paper", "add to my bib" (with DOI / arXiv / title) | [`/cite`](skills/cite/SKILL.md) |
| "audit my bib", "any fake citations", "verify references" | [`/bibcheck`](skills/bibcheck/SKILL.md) |
| "find papers on X", "what's the literature on Y", "any recent work on Z" | [`/litreview`](skills/litreview/SKILL.md) |
| "review this paper", "pre-submission referee report" | [`/review-paper`](skills/review-paper/SKILL.md) |
| "quick check on this draft", "fast gut review" | [`/review-paper-light`](skills/review-paper-light/SKILL.md) |
| "review my code", "check reproducibility of this pipeline" | [`/review-paper-code`](skills/review-paper-code/SKILL.md) |
| "review my PAP", "pre-analysis-plan check" | [`/review-pap`](skills/review-pap/SKILL.md) |
| "review my grant", "NSF / NIH / ERC panel review" | [`/review-grant`](skills/review-grant/SKILL.md) |
| "seven pass review", "deep review my paper", "full adversarial review" | [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) |
| "cross-language audit", "reimplement in Python and compare" | [`/referee2`](skills/referee2/SKILL.md) |
| "audit reproducibility", "do the paper numbers match the code" | [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) |
| "blindspot check on Figure 3", "what's a hostile referee going to ask" | [`/blindspot`](skills/blindspot/SKILL.md) |
| "council review", "spawn critics on", "stress-test this plan" | [`/council`](skills/council/SKILL.md) |
| "evaluate this idea for MKSCI / JMR / JCR / MS" | [`/evaluate-idea-marketing`](skills/evaluate-idea-marketing/SKILL.md) |
| "evaluate this idea for PNAS / Nature / Science / NHB" | [`/evaluate-idea-science`](skills/evaluate-idea-science/SKILL.md) |
| "draft a preregistration", "AsPredicted form", "OSF prereg" | [`/preregister`](skills/preregister/SKILL.md) |
| "build a replication package", "pre-submission archive" | [`/replication-package`](skills/replication-package/SKILL.md) |
| "polish this tikz", "iterate this diagram until it looks right" | [`/tikz-iterate`](skills/tikz-iterate/SKILL.md) |
| "compile this", "build my paper/deck", "why won't this compile", "what are the latex errors" | [`/compile-latex`](skills/compile-latex/SKILL.md) |
| "build HTML slides", "Beamer-style deck in the browser" | [`/academic-slides`](skills/academic-slides/SKILL.md) |
| "make a pptx for my talk", "academic PowerPoint" | [`/academic-pptx`](skills/academic-pptx/SKILL.md) |
| "create a lecture on X", "scaffold a Beamer deck", "MBA lecture on Y" | [`/create-lecture`](skills/create-lecture/SKILL.md) |
| "full slide review", "pre-seminar review", "slide excellence" | [`/slide-excellence`](skills/slide-excellence/SKILL.md) |
| "build me a poster", "conference poster from this paper" | [`/posterskill`](skills/posterskill/SKILL.md) |
| "morning brief", "what should I work on", "rebuild today's list" | [`/daily-brief`](skills/daily-brief/SKILL.md) |
| "process my replies", "check Telegram", "pull new tasks from telegram" | [`/capture`](skills/capture/SKILL.md) |
| "TODO: ...", "remind me to ...", "log this: ...", "follow-up: ..." | [`/log-todo`](skills/log-todo/SKILL.md) |
| "log to notion: ...", "session log: ...", "diary entry for project X" | [`/notion-log`](skills/notion-log/SKILL.md) |
| "process meeting notes: <url>", "extract action items from <url>" | [`/notion-meeting-notes`](skills/notion-meeting-notes/SKILL.md) |
| "what's open for X", "anything stale", "what did I finish this week" | [`/task-pulse`](skills/task-pulse/SKILL.md) |
| "create a skill", "edit this skill", "eval / benchmark a skill" | [`/skill-creator`](skills/skill-creator/SKILL.md) |

## By category

**Drafting and writing**
- [`/draft`](skills/draft/SKILL.md) — paper-section drafts in user voice
- [`/referee-response`](skills/referee-response/SKILL.md) — R&R response letters with location-pinned changes
- [`/deslop`](skills/deslop/SKILL.md) — scrub AI-writing tells + rewrite into user voice (mechanical + semantic two-pass)

**Lit review and citations**
- [`/litreview`](skills/litreview/SKILL.md) — multi-source ranked paper search
- [`/cite`](skills/cite/SKILL.md) — resolve a paper to a Zotero + `.bib` entry
- [`/bibcheck`](skills/bibcheck/SKILL.md) — per-entry `.bib` verification against ground truth

**Reviewing and critique**
- [`/review-paper`](skills/review-paper/SKILL.md) — 6-agent pre-submission referee report
- [`/review-paper-light`](skills/review-paper-light/SKILL.md) — 2-agent 1-minute gut check
- [`/review-paper-code`](skills/review-paper-code/SKILL.md) — reproducibility + code-quality audit
- [`/review-pap`](skills/review-pap/SKILL.md) — 6-agent pre-analysis-plan review
- [`/review-grant`](skills/review-grant/SKILL.md) — 6-agent grant-proposal panel review
- [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) — 7 parallel lens reviews + synthesis
- [`/council`](skills/council/SKILL.md) — N parallel critics + synthesizer on any target
- [`/blindspot`](skills/blindspot/SKILL.md) — Shklovsky 4-quadrant audit of a single figure

**Empirical discipline**
- [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) — verify numeric claims match code output
- [`/referee2`](skills/referee2/SKILL.md) — cross-language R ↔ Python replication audit
- [`/preregister`](skills/preregister/SKILL.md) — draft AsPredicted / OSF / AEA preregistration
- [`/replication-package`](skills/replication-package/SKILL.md) — bundle journal-ready replication archive

**Idea evaluation**
- [`/evaluate-idea-marketing`](skills/evaluate-idea-marketing/SKILL.md) — score idea against MKSCI / JMR / JCR / MS bar
- [`/evaluate-idea-science`](skills/evaluate-idea-science/SKILL.md) — score idea against PNAS / NHB / Nature / Science bar

**Slides and figures**
- [`/academic-slides`](skills/academic-slides/SKILL.md) — Beamer-style HTML decks with KaTeX
- [`/academic-pptx`](skills/academic-pptx/SKILL.md) — academic PowerPoint structure
- [`/create-lecture`](skills/create-lecture/SKILL.md) — scaffold Beamer lecture or talk `.tex`
- [`/slide-excellence`](skills/slide-excellence/SKILL.md) — multi-agent Beamer deck review
- [`/posterskill`](skills/posterskill/SKILL.md) — generate HTML conference poster
- [`/tikz-iterate`](skills/tikz-iterate/SKILL.md) — compile-render-judge-refine TikZ loop
- [`/compile-latex`](skills/compile-latex/SKILL.md) — compile `.tex`, ranked error report, diff-vs-last-compile, auto figure-iterate

**Task workflow**
- [`/daily-brief`](skills/daily-brief/SKILL.md) — score open tasks, push top N to Telegram
- [`/capture`](skills/capture/SKILL.md) — translate Telegram replies into Notion writes
- [`/log-todo`](skills/log-todo/SKILL.md) — mid-session capture into Notion Tasks DB
- [`/notion-log`](skills/notion-log/SKILL.md) — append diary entry to a Notion project page
- [`/notion-meeting-notes`](skills/notion-meeting-notes/SKILL.md) — extract meeting action items into tasks
- [`/task-pulse`](skills/task-pulse/SKILL.md) — read-only ad-hoc Tasks DB queries

**Meta / skill craft**
- [`/skill-creator`](skills/skill-creator/SKILL.md) — create / edit / eval / benchmark skills

## Composition map

Typical multi-skill chains. Each `→` is a hand-off; figure-level skills loop within the chain.

- **Drafting a new paper**: [`/litreview`](skills/litreview/SKILL.md) → [`/cite`](skills/cite/SKILL.md) (top hits) → [`/draft`](skills/draft/SKILL.md) → [`/deslop`](skills/deslop/SKILL.md) (scrub any AI cadence) → [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) → [`/referee2`](skills/referee2/SKILL.md) → [`/bibcheck`](skills/bibcheck/SKILL.md) → [`/replication-package`](skills/replication-package/SKILL.md)
- **Pre-execution check on a new idea**: [`/evaluate-idea-marketing`](skills/evaluate-idea-marketing/SKILL.md) or [`/evaluate-idea-science`](skills/evaluate-idea-science/SKILL.md) → [`/preregister`](skills/preregister/SKILL.md) → [`/review-pap`](skills/review-pap/SKILL.md)
- **Pre-talk prep**: [`/create-lecture`](skills/create-lecture/SKILL.md) → [`/compile-latex`](skills/compile-latex/SKILL.md) (build + auto-iterate every figure) → [`/slide-excellence`](skills/slide-excellence/SKILL.md). For a single figure outside a full build, [`/tikz-iterate`](skills/tikz-iterate/SKILL.md) directly.
- **R&R cycle**: [`/referee-response`](skills/referee-response/SKILL.md) → [`/blindspot`](skills/blindspot/SKILL.md) (per disputed figure) → [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md) (changed numbers) → [`/referee2`](skills/referee2/SKILL.md) (full code re-audit)
- **Pre-submission gauntlet**: [`/review-paper-light`](skills/review-paper-light/SKILL.md) → [`/review-paper`](skills/review-paper/SKILL.md) → [`/seven-pass-review`](skills/seven-pass-review/SKILL.md) → [`/bibcheck`](skills/bibcheck/SKILL.md) → [`/audit-reproducibility`](skills/audit-reproducibility/SKILL.md)
- **Grant submission**: [`/council`](skills/council/SKILL.md) (early plan) → [`/review-grant`](skills/review-grant/SKILL.md) (full draft)
- **Daily workflow**: [`/daily-brief`](skills/daily-brief/SKILL.md) (morning) → [`/capture`](skills/capture/SKILL.md) (Telegram poll) → [`/log-todo`](skills/log-todo/SKILL.md) (ad-hoc) → [`/notion-log`](skills/notion-log/SKILL.md) (end of session) → [`/task-pulse`](skills/task-pulse/SKILL.md) (ad-hoc queries)
- **Building a new skill**: [`/skill-creator`](skills/skill-creator/SKILL.md) → [`/council --chef-skill`](skills/council/SKILL.md) (red-team)

---

For the full per-skill catalog with one-line descriptions, see [skills/README.md](skills/README.md). For source-credit on each skill, see [ATTRIBUTION.md](ATTRIBUTION.md). For installation, see [README.md](README.md) and [SETUP.md](SETUP.md).
