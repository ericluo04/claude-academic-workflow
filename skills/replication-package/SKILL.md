---
name: replication-package
description: Bundle a journal-ready replication package (code + data + output + environment + manifest) for a quantitative-marketing paper, zipped to the layout that Marketing Science, JMR, JCR, and Management Science expect at acceptance or revision. Use this skill WHENEVER the user says "/replication-package", "build a replication package", "prepare submission package", "MKSCI replication", "JMR replication", "JCR replication", "Management Science replication", "pre-submission package", "package for replication", "bundle the replication files", "zip up the code and data for submission", "ship the replication archive", or otherwise asks to gather code, data, tables, figures, and environment info into a single submission-ready archive. Also trigger when they say things like "the editor wants the replication files", "ProjectX is going up for replication review", or paste an MKSCI/JMR data-availability email and ask what to send. This skill is the right move even when they do not explicitly say the word "skill" or "package" — if the task is "gather everything a replicator would need into a zip", that is this skill. Do not confuse with /audit-reproducibility (which CHECKS numbers against code) — this skill ASSEMBLES the archive after the numbers already match.
---

# Replication Package

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.paths.overleaf_root` — root containing project subdirs.
- `personal_config.paths.home_paths_to_redact` — list of absolute-path prefixes to strip during sanitization (e.g. the user's `C:\Users\<you>\`, `/Users/<you>/`, Dropbox sync roots).
- `personal_config.user.name`, `personal_config.user.personal_email`, `personal_config.user.university_email`, `personal_config.user.affiliation` — used to render the README author/contact block.
- `personal_config.projects[]` — each entry with `name`, `overleaf_subdir`, `main_tex`, and optional `paper_slug` (a lowercase-hyphenated short name).

## Purpose

Bundle a complete, sanitized, submission-ready replication archive for a paper, matching the policies of Marketing Science, JMR, JCR, and Management Science (Marketing). The goal is a zip the user can hand to a journal editor or replication committee without follow-up.

## When to invoke

Trigger on any of these (do not wait for an exact phrasing):

- `/replication-package <project>` — slash-style invocation
- "build a replication package for <project name>"
- "prepare submission package" / "pre-submission package" / "ship the replication archive"
- "MKSCI replication", "JMR replication", "JCR replication", "Management Science replication"
- "package for replication" / "bundle the replication files" / "zip up the code and data"
- An MKSCI/JMR data-editor email pasted in chat with a request to assemble the deliverable

The right output is a single `.zip` in the project root plus a short report flagging anything that needs the user's eyes before they ship it.

If the user is asking whether the **numbers in the paper match the code**, that is `/audit-reproducibility`, not this skill — defer.

## Output layout

The archive looks like this. Create it under a top-level directory named `<paper-slug>_replication_<YYYYMMDD>/` and then zip that directory:

```
<paper-slug>_replication_<YYYYMMDD>/
├── README.md                # paper citation, software, runtime, files map, contact
├── code/                    # 00_setup.R, 01_clean.R, 02_analysis.R, ...
├── data/
│   ├── raw/                 # raw data or pointers to public sources
│   ├── processed/           # intermediate
│   └── README.md            # data dictionary
├── output/
│   ├── tables/              # auto-generated .tex tables matching paper
│   └── figures/             # auto-generated .pdf/.png matching paper
├── env/
│   ├── sessionInfo.txt      # R session info
│   ├── requirements.txt     # Python pinned versions
│   └── renv.lock            # R lockfile if the project uses renv
└── meta/
    ├── git_hash.txt         # commit hash at submission
    ├── manifest.json        # every file + size + sha256
    └── checklist.md         # MKSCI/JMR replication checklist filled in
```

The `<paper-slug>` is lowercase-hyphenated and comes from `personal_config.projects[].paper_slug` (else derived from the project directory name).

## Workflow

The reason for this order is: identify scope first, inventory before transforming, sanitize before zipping, and surface anything the user must review BEFORE the archive leaves their machine.

### 1. Identify the project root

- If the user passes an argument (`/replication-package <project>`), resolve it against `personal_config.projects[]` (matching against `name` and `aliases`) and join with `personal_config.paths.overleaf_root`.
- Otherwise use the current working directory.
- Confirm by Glob-ing for a `main*.tex` and at least one `.R` or `.py` file. If neither is present, ask the user where the project lives rather than guessing.

### 2. Detect language and decide what `env/` needs

Scan the project tree once:

- `.R` / `.Rmd` present → R package. Need `sessionInfo.txt`. If `renv.lock` exists in the project, copy it.
- `.py` / `.ipynb` present → Python package. Need `requirements.txt`.
- Both → mixed; produce both files.

This determines which env-capture commands run in step 5.

### 3. Inventory

Build the inventory before copying anything. Projects usually already have a sensible structure; respect it.

- **Code**: Glob all `.R`, `.Rmd`, `.py`, `.ipynb`. Sort by likely run order — filenames starting with digits (`00_setup.R`, `01_clean.R`, `02_analysis.R`) come first in numeric order, then the rest alphabetically. If nothing is numbered, infer order from `source()` / `import` dependencies and note your guess in the README so the user can correct it.
- **Tables and figures**: Glob `Table_*.tex`, `Figure_*.pdf`, `Figure_*.png` under `output/`, `tables/`, `figures/`, and the project root. Map each to where it appears in the paper by grep-ing the main `.tex` for the filename — this is what makes the README's "files mapping" section accurate instead of generic.
- **Bibliography**: Glob `*.bib`. Include in `meta/` for citation reproducibility but do not put it in `code/`.
- **Main paper `.tex`**: The file being submitted (`main.tex`, `mainR2.tex`, etc.). Used to extract the paper title, abstract, and the claim/table/figure list. Do NOT copy the `.tex` into the archive — replication packages are about code+data, not the manuscript.
- **Data**: Glob common data extensions (`.csv`, `.rds`, `.parquet`, `.dta`, `.feather`, `.npz`, `.h5`) under `data/`. Note total size; if any single file exceeds 100 MB, flag it (journals usually want external hosting for large data).

### 4. Sanitize

This is the step where the user most needs help — fast at writing code but slow at scrubbing personal paths and stray credentials. Do it carefully and surface everything you change.

**Absolute paths**: Replace any literal occurrence of paths listed in `personal_config.paths.home_paths_to_redact` with a portable placeholder. The substitutions:

- Any prefix in `personal_config.paths.home_paths_to_redact` (e.g. `C:\Users\<you>\`, `/Users/<you>/`) → `<DATA_DIR>/...` (when inside `data\` or `data/`) or relative path (when inside the project)
- Cloud-sync paths like `Dropbox\Apps\Overleaf\<project>\` → `./` relative to the package root
- The user's local username (from `personal_config.user.local_username` if set) anywhere → strip it

Do these as in-place edits on **copies** of the code in `code/`, never on the originals in the project tree.

**Secrets**: Grep every code file for the regex

```
(secret|api[_-]?key|token|password|bearer|aws_secret|openai|anthropic)\s*[=:]\s*['"][^'"]{8,}['"]
```

and additionally common variable names like `OPENAI_API_KEY`, `HF_TOKEN`, `WANDB_API_KEY`. Do NOT auto-strip — flag each hit in the final report with file + line number and let the user decide. The reason: false positives (e.g., `password = "<read from env>"`) are common, and silently rewriting code would erode trust in this skill.

**PII**: Grep for email addresses, US phone formats (`\d{3}-\d{3}-\d{4}`), and SSN-like patterns. Flag, do not strip. The user's own email (from `personal_config.user.personal_email` / `university_email`) in author/contact metadata is fine — only flag third-party PII in data files or comments.

**Notebooks**: For `.ipynb`, strip outputs (large cell outputs balloon the archive and often contain stale plots from earlier runs). If `jupyter` is available, run `jupyter nbconvert --clear-output --inplace <file>` on the copy. If not, parse the JSON and zero out the `outputs` and `execution_count` fields.

### 5. Generate the meta files

Run from the project root, capturing output to the appropriate file under `env/` or `meta/`:

- **`env/sessionInfo.txt`** — `Rscript -e "sessionInfo()"`. If `Rscript` is not on PATH, write a placeholder that says so and flag it in the report; the user can paste the output manually from RStudio.
- **`env/requirements.txt`** — if a virtualenv is active, `pip freeze`. Otherwise, parse `import` and `from X import` statements out of all `.py` and `.ipynb` files, deduplicate, and write the bare package names without versions, prefixed by a comment line `# Unpinned — generated by static import scan; pin before shipping`.
- **`env/renv.lock`** — copy from project root if present; otherwise omit (don't fabricate).
- **`meta/git_hash.txt`** — `git rev-parse HEAD` and `git status --short` (so a dirty working tree shows up). If the project is not a git repo, write `not a git repository at packaging time` and flag it — MKSCI prefers a hash but accepts the note.
- **`meta/manifest.json`** — walk the assembled package directory, record `path`, `size_bytes`, and `sha256` for every file. JSON, sorted by path. This is what the data editor checks the archive against.
- **`meta/checklist.md`** — see template below.
- **`README.md`** — see template below.
- **`data/README.md`** — minimal data dictionary stub: one row per data file with columns name, source, rows, columns, description. Fill in what you can detect (file size, first-row column names for CSVs); leave a `[FILL IN]` placeholder for description and source if you cannot infer them.

### 6. Zip

Produce `<paper-slug>_replication_<YYYYMMDD>.zip` in the project root (one level above the staging directory). Use PowerShell's `Compress-Archive` on Windows or `zip -r` via Bash if available. Do not zip the staging directory into itself — exclude the staging dir's parent from the archive root.

### 7. Report back

End with a concise report covering:

1. **Path to the zip** (absolute).
2. **Total files** and **total size** (MB).
3. **Sanitization flags** — every secret/PII hit, with file + line. This is the section the user must read before they ship.
4. **Path-rewrite summary** — count of substitutions per file (so the user can spot-check anything weird).
5. **Anything missing** — e.g., no `sessionInfo.txt` because Rscript wasn't found, no git hash because not a repo, large data files needing external hosting.
6. **Next steps** — e.g., "pin requirements.txt, paste sessionInfo from RStudio, upload `data/raw/full_dataset.parquet` (450 MB) to OSF and reference in README".

## Sanitization rules

The rules above as a quick reference:

| Class | Pattern | Action |
|---|---|---|
| User home path | any prefix in `personal_config.paths.home_paths_to_redact` | Auto-rewrite to `<DATA_DIR>/...` or relative |
| Local username | value of `personal_config.user.local_username` | Strip |
| Secrets | `(secret\|api[_-]?key\|token\|password\|bearer)\s*[=:]\s*['"][^'"]{8,}['"]` | Flag in report, do NOT strip |
| Env-var secret names | `OPENAI_API_KEY`, `HF_TOKEN`, `ANTHROPIC_API_KEY`, `WANDB_API_KEY`, `AWS_SECRET_ACCESS_KEY` | Flag if value is hardcoded; OK if read from `os.environ` / `Sys.getenv` |
| Email addresses | `[\w.+-]+@[\w-]+\.[\w.-]+` (excluding the user's own emails from config) | Flag |
| Phone | `\d{3}[-.\s]\d{3}[-.\s]\d{4}` | Flag |
| Notebook outputs | `.ipynb` cell outputs | Strip on the copy |

## README template

Use this structure in the generated `README.md` (filling in detected values; leave `[FILL IN]` for things you cannot infer):

```
# Replication Package: [Paper Title]

**Citation.** [Author(s)]. ([Year]). [Title]. *[Journal]*, [vol(issue)], [pages]. [DOI]

**Authors.** <personal_config.user.name> (<personal_config.user.affiliation>), [co-authors].
**Contact.** <personal_config.user.name>, <personal_config.user.university_email>

## Abstract
[Extracted from main .tex \abstract{...}]

## Software requirements
- R [version detected from sessionInfo, else FILL IN], packages: see env/sessionInfo.txt or env/renv.lock
- Python [version], packages: see env/requirements.txt
- Hardware: [FILL IN — e.g., "16 GB RAM sufficient" or "1x A100 GPU for model training"]
- Estimated runtime: [FILL IN]

## How to reproduce
1. Place raw data files in `data/raw/` (see data/README.md for sources)
2. From the package root, run scripts in order:
   - `Rscript code/00_setup.R`
   - `Rscript code/01_clean.R`
   - ... [list detected scripts in order]
3. Outputs land in `output/tables/` and `output/figures/`

## Files mapping
| Paper element | Produced by | Output file |
|---|---|---|
[One row per table/figure, populated from the grep of main .tex]

## Notes
- All paths are relative to the package root unless prefixed with `<DATA_DIR>`.
- Numerical results reproduce within tolerance 0.001 on the listed software versions.
- Git commit at packaging: see meta/git_hash.txt
```

## Checklist template (`meta/checklist.md`)

This is the MKSCI/JMR-style policy checklist the user signs when submitting. Fill in `[x]` / `[ ]` based on what you actually generated.

```
# Replication Package Checklist

Target journal: [MKSCI | JMR | JCR | MS]

## Code
- [ ] All code that produces tables and figures in the paper is included
- [ ] Code runs end-to-end from raw data to final outputs
- [ ] Scripts are numbered or otherwise sequenced
- [ ] No absolute paths; all paths relative to package root or `<DATA_DIR>`

## Data
- [ ] Raw data included, OR
- [ ] Data access path documented (proprietary/restricted sources)
- [ ] Data dictionary (data/README.md) describes every file
- [ ] No personally identifying information

## Environment
- [ ] R sessionInfo captured (env/sessionInfo.txt)
- [ ] Python requirements pinned (env/requirements.txt)
- [ ] renv.lock included (if R + renv used)
- [ ] Hardware requirements stated

## Reproducibility
- [ ] Numerical results reproduce within tolerance 0.001
- [ ] Tables in output/tables/ match paper
- [ ] Figures in output/figures/ match paper
- [ ] Random seeds set where applicable

## Metadata
- [ ] README.md complete (citation, software, runtime, contact)
- [ ] Git commit hash recorded (meta/git_hash.txt)
- [ ] File manifest with sha256 (meta/manifest.json)
- [ ] Contact email for replication questions: <user university email>
```

## Examples

### Example 1: an MKSCI R2 paper

User says: "build a replication package for ProjectA"

- Project root resolved via `personal_config.projects["ProjectA"]`.
- Main `.tex`: `mainR2.tex`
- Paper slug: `projecta`
- Output: `<project_root>/projecta_replication_20260511.zip`
- Reports back: 23 files, 47 MB, 0 secret hits, 14 absolute-path rewrites across 6 scripts, sessionInfo captured, git hash `a3f9...`, checklist marked for MKSCI.

### Example 2: a JMR-targeted submission

User says: "/replication-package projectb --target jmr"

- Same workflow, but checklist target line reads "JMR" and the README's Files Mapping section is populated against the project's `main.tex`.

## Failure modes

- **Project root ambiguous**: skill invoked from `~`. Ask once, then proceed with the user's answer. Do not start packaging from `~` "to see what happens."
- **Rscript not on PATH**: `sessionInfo.txt` becomes a placeholder. Flag in the report; do not block the rest of the workflow.
- **`pip freeze` returns global packages**: If no venv is active, the freeze is misleading. Prefer the static import scan and warn the user.
- **Hardcoded API key found**: Stop short of zipping. Show the user the exact file/line, ask whether to (a) replace with `os.environ['KEY']`, (b) leave it (they confirm it's a public test key), or (c) abort.
- **Data files exceed 100 MB or 2 GB total**: Build the archive without the large files, drop a `data/raw/README.md` pointing to OSF / Dataverse / institutional FTP, and flag it in the report. MKSCI prefers external hosting over giant zips.
- **Not a git repo**: `git_hash.txt` says so explicitly. The user can manually drop a hash in if they have one elsewhere.

## Out of scope

This skill does NOT:

- **Submit** the package anywhere — no upload to MKSCI ScholarOne, OSF, Dataverse, or the journal portal.
- **Push** anything to a GitHub repo. If the user wants the code mirrored on GitHub, that's a separate ask.
- **Modify the manuscript** (`main*.tex`, `.bib`). The replication archive is code+data+env+meta; the paper goes through the editorial system separately.
- **Run the code** to verify outputs reproduce. That is `/audit-reproducibility`. This skill assumes the user has already audited and just needs the archive assembled.
- **Generate new tables or figures**. It only packages what already exists in `output/`.
- **Edit the source code in place**. All sanitization is done on copies inside the staging directory; the project tree is read-only from this skill's perspective.
