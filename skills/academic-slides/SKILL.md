---
name: academic-slides
description: Create Beamer-inspired academic HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build slides for a conference talk, lecture, seminar, or thesis defense. Supports theorem environments, KaTeX equations, algorithm pseudocode, and citations. Helps academics discover their preferred visual theme through Beamer-style previews rather than abstract choices.
---

# Academic Slides Skill

> **Source.** This skill is a rethemed academic derivative of [`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides) by Zara Zhang. The Phase 0-5 architecture, "Show Don't Tell" preview UX, `STYLE_PRESETS.md` 12-preset convention, viewport-fit invariant, and `python-pptx`-based PPT ingest are all inherited. The academic fork swaps the 12 design themes for 12 Beamer-flavored themes (Madrid, Berlin, Copenhagen, Warsaw, Metropolis, etc.), adds Phase 0.5 (audience / takeaway / narrative arc), and layers in theorem / lemma / proof CSS classes, KaTeX math, and `data-pause` Beamer-style progressive disclosure.

Produces a single self-contained HTML file (inline CSS/JS, KaTeX via CDN — no npm, no build tools) with Beamer-style header/footer chrome, theorem/proof/algorithm boxes, KaTeX equations, `data-pause` progressive disclosure, keyboard + swipe navigation, and a 12-theme catalog (Madrid, Berlin, Copenhagen, Warsaw, Metropolis, Classic Serif, Cambridge, Lecture Notes, Technical Report, Thesis Defense, Seminar, Journal Article).

## Core Philosophy

1. **Zero Build Dependencies** — Single HTML file with inline CSS/JS. KaTeX via CDN.
2. **Show, Don't Tell** — Generate visual theme previews so the user can react to real designs rather than theme names.
3. **Academic Authenticity** — Beamer-inspired structure, Computer Modern / Source Serif typography, real theorem environments. Not PowerPoint-with-serif-fonts.
4. **Viewport Fitting (CRITICAL)** — Every frame MUST fit exactly within `100vh`. No scrolling within a frame, ever. This is non-negotiable.

---

## Reference Files

| Topic | Where to look |
|-------|---------------|
| Viewport fit invariant, density caps, theorem/proof/algorithm box CSS, `AcademicPresentation` JS controller, progressive disclosure (`data-pause`), KaTeX wiring, responsive `clamp()` typography, keyboard + swipe handlers | [`references/viewport-rules.md`](references/viewport-rules.md) |
| Full CSS / structural detail per theme, frame layouts, cross-theme conventions (title / section / content / theorem / results frames) | [`references/themes.md`](references/themes.md) |
| Phase 4 PPT-ingest via `python-pptx` (image extraction, equation flagging, speaker notes, asset path resolution) | [`references/ppt-ingest.md`](references/ppt-ingest.md) |
| Higher-level overview of the 12 presets (vibe, best-for, font, signature colors) | [`STYLE_PRESETS.md`](STYLE_PRESETS.md) |

For viewport rules, density caps, CSS box definitions, and progressive-disclosure mechanics, load `references/viewport-rules.md`. For full theme implementations including CSS, frame layouts, and theme-specific conventions, load `references/themes.md`. For PPT conversion (Mode B: ingest existing .pptx), see `references/ppt-ingest.md`. `STYLE_PRESETS.md` is the higher-level overview.

---

## When to Invoke

Trigger phrases include: "academic slides", "Beamer-inspired HTML slides", "conference talk slides", "thesis defense slides", "lecture slides", "seminar slides", "research presentation in HTML", "convert my PPTX to web slides", "make slides for my ICML paper", "slides with theorems and KaTeX". Use this skill when the user wants a single-file HTML deck with academic chrome rather than a `.pptx`, a Beamer `.tex`, or a Reveal.js / Slidev project.

For Beamer / LaTeX decks use `/create-lecture`. For PowerPoint (.pptx) decks use `/academic-pptx`. For full-deck review use `/slide-excellence`.

---

## Fast-Path Slash Form

```
/academic-slides <N>-slide <type> on <topic> [using <theme>]
```

Examples:
- `/academic-slides 10-slide lecture on dynamic programming using Metropolis`
- `/academic-slides conference talk on our ICML paper, Berlin theme`
- `Make 15 slides about transformer attention for my lab meeting`

When the user's message specifies enough format detail (topic, length, and/or theme name), you MAY skip the Phase 1 format questions (purpose, length, content types, field). However, you MUST still run Phase 0.5 (audience / takeaway / narrative arc). **No presentation should ever be generated without asking the Phase 0.5 questions.**

---

## Phase 0: Detect Mode

**Mode A — New Academic Presentation.** From scratch for a talk, lecture, or defense. → Phase 0.5 → Phase 1 → Phase 2 → Phase 3 → Phase 5.

**Mode B — PPT/PDF/Paper Conversion.** User has an existing `.pptx`, PDF, or paper URL. → Phase 4 (ingest) → Phase 0.5 → Phase 1P (paper focus) → Phase 2 → Phase 3 → Phase 5. See `references/ppt-ingest.md`.

**Mode C — Existing Presentation Enhancement.** User has an HTML deck and wants to improve it. Read the file, understand the structure, then enhance in place.

---

## Phase 0.5: Essential Content Questions (MANDATORY)

These questions MUST be asked before generating any presentation, regardless of mode or how much information the user provided. They cannot be inferred from topic or theme — they require the user's judgment. Ask all 3 in a single `AskUserQuestion` call.

**Why these matter.** A talk on "transformer attention" for NLP researchers looks completely different from one for undergraduate CS students. A talk whose takeaway is "our method is 3× faster" structures differently from one whose takeaway is "this framework unifies prior work." These questions determine content strategy, not format.

**Question 1 — Audience** (header `Audience`, "Who is your audience?")
- "Domain experts" — Skip basics; focus on contributions and technical depth.
- "Technical but not specialist" — Background present but not in your subfield.
- "Students / newcomers" — Need context, definitions, motivation before results.
- "Mixed / general academic" — Balance accessibility and depth.

**Question 2 — Key Takeaway** (header `Takeaway`, "If the audience remembers ONE thing, what should it be?")
- "A specific result" — A theorem, benchmark, or finding (follow up to ask for the one-sentence statement → store as `KEY_RESULT`, place on a dedicated frame, echo in conclusion).
- "A new method or technique" — How to do something they could not do before.
- "A conceptual framework" — A way of thinking about a problem.
- "A problem or open question" — Motivating future work.

**Question 3 — Narrative Arc** (header `Structure`, "How should the presentation flow?")
- "Problem → Solution → Results" — Classic research talk.
- "Background → Our Work → Impact" — Contextualizes the contribution.
- "Survey / Comparison" — Review multiple approaches.
- "Build-up / Tutorial" — Teach concepts progressively.

### How Answers Shape Content

**Audience → depth calibration:**
- Domain experts → skip intro definitions, assume standard notation, spend frames on technical detail, include prior-work comparison.
- Technical non-specialist → 1–2 background frames, define key terms on first use, intuition before formalism.
- Students / newcomers → motivation and examples first, define all notation, heavy progressive disclosure, recap frames.
- Mixed → start accessible, deepen progressively, mark deep-dives optional.

**Takeaway → emphasis strategy:**
- Specific result → build entire talk toward stating and supporting it; dedicated frame + echo in conclusion.
- New method → motivate, then most frames on method with worked examples; include a "key steps" summary frame.
- Conceptual framework → show fragmented prior view, then the unifying frame. Use comparison frames.
- Open question → build evidence the problem matters, show what's been tried, end with directions.

**Narrative arc → frame sequencing:**
- Problem → Solution → Results: Title, Motivation (1–2), Prior Work (1), Approach (2–3), Results (2–3), Conclusion.
- Background → Our Work → Impact: Title, Background (2–3), Contribution (3–4), Validation (1–2), Impact, Conclusion.
- Survey / Comparison: Title, Taxonomy, Approach A, B, C, Comparison Table, Takeaways, Open Problems.
- Build-up / Tutorial: Title, Prerequisites, Concept 1, 2, 3, Putting It Together, Examples, Summary.

---

## Phase 1: Content Discovery (Mode A, Full Interactive)

**Prerequisite:** Phase 0.5 has already been completed.

If the user is on the fast path (topic, length, theme all known), skip Phase 1 — Phase 0.5 has captured what matters. Proceed to Phase 2 or Phase 3.

Otherwise ask via `AskUserQuestion`:

1. **Purpose** (`Purpose`): Conference talk / Lecture-Course / Seminar-Workshop / Thesis Defense.
2. **Length** (`Length`): Short 5–10 / Medium 10–20 / Long 20+.
3. **Content Readiness** (`Content`): All content ready / Rough notes / Topic only.
4. **Content Types** (`Content Types`, multiSelect): Theorems/Proofs/Lemmas, Equations/Derivations, Algorithms/Pseudocode, Citations/References.
5. **Field** (`Field`): Math/Stats / CS-Engineering / Natural Sciences / Humanities-Social Sciences.

If the user has content, ask them to share it.

---

## Phase 1P: Paper Focus Discovery (Mode B Only)

**This phase runs AFTER Phase 4 (extraction) and AFTER Phase 0.5, BEFORE theme selection.** Specific to Mode B when the source is a research paper.

After summarizing the extracted paper, ask:

1. **Paper Focus** (`Focus`, multiSelect): Main results/theorems, Method/approach, Experiments/evaluation, Motivation/problem setup.
2. **Coverage** (`Coverage`): Deep dive on key results / Balanced overview / Highlight reel / Extended with discussion.
3. **What to Skip** (`Skip`, optional, only if paper is long): Related work, Proofs and derivations, Experimental details, Nothing.

### Content Directives for Paper Conversion

- "Main results" → 30–40% of frames on stating and supporting the theorem. Dedicated "Main Result" frame.
- "Method" → algorithm/pseudocode frames, step-by-step breakdowns, progressive disclosure for multi-step methods.
- "Experiments" → comparison tables, result-highlight frames, two-column method-vs-baseline.
- "Motivation" → 2–3 motivation frames before any results.
- "Deep dive" → most frames on the focus areas; other sections get at most 1 frame.
- "Highlight reel" → max 1 frame per section.
- "Related work" skipped → compress to one "Prior Work" frame with 3–4 key references.
- "Proofs" skipped → state theorems with `Proof: see paper`.

---

## Phase 2: Style Discovery ("Show, Don't Tell")

Most users can't articulate design preferences in words. Instead of asking "Madrid or Metropolis?", generate mini-previews and let them react.

### Two Selection Paths

**Option A — Guided Discovery (default).** User answers mood questions; skill generates 3 previews; user picks the favorite. Best when no specific style is in mind.

**Option B — Direct Selection.** If the user already knows the theme (`"Use Madrid"`, `"I want something like Metropolis"`), skip preview generation and go to Phase 3.

**Step 2.0 — Style Path Selection** (`Theme`, "How would you like to choose your theme?"):
- "Show me options" → continue to Step 2.1 (mood selection).
- "I know what I want" → ask `Theme` with all 12 options listed (Madrid, Berlin, Copenhagen, Warsaw, Metropolis, Classic Serif, Cambridge, Lecture Notes, Technical Report, Thesis Defense, Seminar, Journal Article), then skip to Phase 3.

**Step 2.1 — Mood Selection** (`Tone`, multiSelect ≤ 2):
- Authoritative/Rigorous → Madrid, Warsaw, Classic Serif, Thesis Defense.
- Clear/Pedagogical → Berlin, Copenhagen, Lecture Notes.
- Modern/Minimal → Metropolis, Technical Report, Seminar.
- Classic/Traditional → Cambridge, Classic Serif, Journal Article.

**Step 2.2 — Generate 3 Theme Previews.** Generate 3 distinct mini-HTML files (single title frame + one content frame with a theorem box). Each preview must feel academically authentic: Computer Modern or Source Serif primary, header/footer chrome, sample theorem box, sample KaTeX inline equation, muted/professional palette (no neon, no gradients-for-decoration). Each ~80–120 lines, fully self-contained.

Write previews to `.claude-design/frame-previews/style-a.html`, `style-b.html`, `style-c.html`.

**Step 2.3 — Present Previews.** Tell the user the file paths, give a one-line description of each theme, and ask:

```
Open each file:
  - .claude-design/frame-previews/style-a.html
  - .claude-design/frame-previews/style-b.html
  - .claude-design/frame-previews/style-c.html

Which resonates? What do you like? Anything to change?
```

Then `AskUserQuestion` (`Theme`): Theme A / Theme B / Theme C / "Mix elements" (if "Mix", ask what to combine).

For the per-theme CSS specifications and structural details to use when generating these previews, see `references/themes.md`. For the higher-level vibe / best-for / font reference, see `STYLE_PRESETS.md`.

---

## Phase 3: Generate Presentation

Inputs:
- Content directives from Phase 0.5 (audience, takeaway, narrative arc, `KEY_RESULT`).
- Content details from Phase 1 (or inferred from fast-path).
- Paper focus from Phase 1P (Mode B).
- Theme from Phase 2.

### Generation Rules

- Apply audience calibration throughout (no intro defs for experts; define all terms for students).
- Structure frames according to the chosen narrative arc (see sequencing in Phase 0.5).
- Place `KEY_RESULT` on a dedicated frame and echo in the conclusion.
- For paper conversions, allocate frames per the coverage choice; skip what the user marked skippable.

### File Structure

Default for new decks (Mode A) — single self-contained HTML, no side files:
```
presentation.html
```

For Mode B PPT conversion, an `assets/` folder is produced as a side effect of image extraction (see `references/ppt-ingest.md`). This is the only case where the deck is not strictly single-file:
```
presentation.html
assets/                # images extracted from the source .pptx
```

For projects with multiple decks:
```
[presentation-name].html
[presentation-name]-assets/
```

### HTML Architecture

The generated HTML follows this structure:

1. `<head>` — meta, academic font CDN (Computer Modern via jsDelivr, plus Google Fonts fallback per theme), KaTeX CSS + `katex.min.js` + `auto-render.min.js` with the standard `$…$` / `$$…$$` delimiter config.
2. Inline `<style>` block — base reset, CSS custom properties (theme tokens), viewport-fit base, frame containers, header/footer chrome, title/section/content frame styles, theorem/definition/proof/algorithm boxes, equation block, citation block, columns grid, item-list/enum-list, responsive breakpoints (700/600/500 px height; 600 px width), reveal + `data-pause` animations, reduced-motion fallback.
3. `<body>` — fixed `.frame-header`, fixed `.frame-footer`, one `<section class="frame">` per slide.
4. `<script>` — `AcademicPresentation` controller class: keyboard / wheel / swipe navigation, intersection observer for `.visible` fade-in, progressive disclosure (`data-pause` consumes one `next()` before advancing the frame), frame counter.

For the full base CSS, the controller class, density limits, and box definitions, see `references/viewport-rules.md`. For per-theme color tokens, chrome heights, sidebar widths, and font stacks, see `references/themes.md`.

### Required JS Features (every deck)

- `AcademicPresentation` class — keyboard (arrows, space, Page Up/Down, Home/End), touch/swipe, mouse wheel, frame counter (`X / Y`).
- IntersectionObserver — adds `.visible` class for CSS fade-in.
- Progressive disclosure — `data-pause="N"` consumed one step at a time before advancing frame (Beamer `\pause` equivalent).

### Code Quality

- Section headers as block comments explaining what / why / how to modify.
- Semantic HTML (`<section>`, `<header>`, `<footer>`, `<nav>`).
- Reduced-motion support.
- Viewport-fit invariant on every `.frame` (see `references/viewport-rules.md`).

---

## Phase 4: PPT Conversion (Mode B)

When the source is a `.pptx`:

1. Extract content via `python-pptx` (text, images → `assets/`, equation objects flagged, speaker notes).
2. Confirm extracted structure with the user, flag detected equation objects for manual KaTeX re-entry.
3. Run Phase 0.5 (essential content questions).
4. Run Phase 1P (paper focus / coverage / skip).
5. Run Phase 2 (theme selection).
6. Generate the HTML (Phase 3) with extracted text, image references, KaTeX-converted equations, speaker notes as HTML comments, and preserved slide order.

For the full `python-pptx` extraction script, the equation-object detection heuristic, the user-confirmation template, and asset-path resolution rules, see `references/ppt-ingest.md`.

---

## Phase 5: Delivery

1. Clean up `.claude-design/frame-previews/`.
2. Open the file in the browser (`open [filename].html` on macOS, `start` on Windows).
3. Print a summary:

```
Your presentation is ready.

File: [filename].html
Theme: [Theme Name]
Frames: [count]
Equations: KaTeX rendering enabled

Navigation:
- Arrow keys or Space to advance (including data-pause steps)
- Page Up / Page Down for frame-level navigation
- Home / End jumps to first / last
- Scroll and swipe also work; frame counter in footer

To customize:
- Colors and fonts: edit :root CSS variables at the top
- Theorem styles: .theorem-box / .definition-box / .proof-box variables
- Chrome: --header-bg, --header-fg, --footer-bg, --footer-fg
- Equations: $...$ inline, $$...$$ display (KaTeX)

Want adjustments?
```

---

## Examples

### Example 1 — Fast-Path New Deck

User: `/academic-slides 10-slide lecture on dynamic programming using Lecture Notes`

1. Detect fast path: length=10, purpose=lecture, theme=Lecture Notes, topic=dynamic programming.
2. **Phase 0.5 (still mandatory):** ask audience / takeaway / arc → student/newcomers, new method, build-up/tutorial.
3. Skip Phase 1 (format known).
4. Skip Phase 2 (theme known).
5. Phase 3: generate 10-frame Lecture Notes deck structured as a progressive tutorial — definitions and examples before formalism, recap frame at the end.
6. Phase 5: open the file, summary printed.

### Example 2 — PPT Conversion

User: "Convert my research paper PPT to web slides."

1. Mode B → Phase 4: `python-pptx` extracts text, saves images to `assets/`, flags equation objects.
2. Confirm extraction summary with user.
3. **Phase 0.5:** audience / takeaway / arc.
4. **Phase 1P:** paper focus / coverage / skip.
5. **Phase 2:** theme selection (preview or direct).
6. Phase 3: generate HTML with extracted text + asset references + KaTeX-converted equations + speaker notes as HTML comments, in chosen theme.
7. Phase 5: open and summarize.
