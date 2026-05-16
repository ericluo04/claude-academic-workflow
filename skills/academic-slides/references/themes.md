# Theme Implementations

Full CSS / structural detail for each of the 12 themes — deeper than `STYLE_PRESETS.md` (which is the higher-level vibe / best-for / font overview). This file is the implementation reference: per-theme CSS custom-property tokens, theme-specific frame layouts (e.g., Berlin sidebar, Warsaw gradient header), font wiring (CMU Serif via jsDelivr for Classic Serif, Fira Sans for Metropolis, Google Fonts for the rest), and cross-theme conventions for title / section / content / theorem / results frames.

For viewport-fit invariants, density caps, theorem-box CSS, KaTeX wiring, and the `AcademicPresentation` JS controller — all of which are theme-agnostic — see `viewport-rules.md`.

---

## Generic Theme Token Defaults

Every theme overrides these `:root` custom properties. Anything not overridden inherits sensible defaults defined in the base CSS (see `viewport-rules.md`).

```css
:root {
    /* Typography (override per theme) */
    --font-heading: 'CMU Serif', 'Source Serif 4', Georgia, serif;
    --font-body:    'CMU Serif', 'Source Serif 4', Georgia, serif;
    --font-mono:    'CMU Typewriter Text', 'Source Code Pro', 'Courier New', monospace;

    /* Frame chrome */
    --header-bg: #2c3e50;
    --header-fg: #ffffff;
    --footer-bg: #2c3e50;
    --footer-fg: #ffffff;

    /* Environment colors */
    --theorem-bg:     #e8f4f8;
    --theorem-border: #2980b9;
    --definition-bg:     #fdf2e9;
    --definition-border: #e67e22;
    --proof-bg:     #f9f9f9;
    --proof-border: #95a5a6;
    --example-bg:     #eafaf1;
    --example-border: #27ae60;
    --alert-bg:     #fdedec;
    --alert-border: #e74c3c;

    /* Chrome heights (override per theme) */
    --chrome-height-top:    clamp(2.5rem, 5vh, 3.5rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);
}
```

---

## Cross-Theme Frame Conventions

These frame types appear across all 12 themes; only the chrome and color tokens change.

### Title Frame

```html
<section class="frame title-frame">
    <div class="frame-content">
        <h1 class="reveal">Presentation Title</h1>
        <p class="reveal subtitle">Subtitle or Conference Name</p>
        <div class="author-block reveal">
            <p class="author">Author Name</p>
            <p class="institute">University / Institution</p>
            <p class="date">Conference, Date</p>
        </div>
    </div>
</section>
```

### Section Divider Frame

```html
<section class="frame section-frame">
    <div class="frame-content">
        <span class="section-number">1</span>
        <h2>Section Title</h2>
    </div>
</section>
```

### Content Frame (heading + bullets, max 4–5 bullets)

```html
<section class="frame">
    <div class="frame-content">
        <h2 class="reveal">Frame Title</h2>
        <ul class="item-list">
            <li class="reveal">First point.</li>
            <li class="reveal">Second point.</li>
            <li class="reveal">Third point.</li>
        </ul>
    </div>
</section>
```

### Theorem + Proof Frame (with `data-pause`)

```html
<section class="frame">
    <div class="frame-content">
        <h2 class="reveal">Main Result</h2>
        <div class="theorem-box reveal" data-pause="1">
            <span class="env-title">Theorem 1</span>
            <p>For $f \in C^1[a,b]$:</p>
            <p>$$\int_a^b f'(x)\,dx = f(b) - f(a)$$</p>
        </div>
        <div class="proof-box reveal" data-pause="2">
            <span class="env-title">Proof.</span>
            <p>By the fundamental theorem of calculus...</p>
        </div>
    </div>
</section>
```

### Results / Comparison Frame (two-column)

```html
<section class="frame">
    <div class="frame-content">
        <h2>Comparison</h2>
        <div class="columns two-col">
            <div><h3>Ours</h3>...</div>
            <div><h3>Baseline</h3>...</div>
        </div>
    </div>
</section>
```

### Frame Chrome (global header + footer)

```html
<header class="frame-header">
    <span class="short-title">Paper Title</span>
    <span class="section-title">Current Section</span>
</header>

<footer class="frame-footer">
    <span class="author-short">A. Name</span>
    <span class="title-short">Short Title</span>
    <span class="frame-number"></span>   <!-- populated by AcademicPresentation -->
</footer>
```

---

## 1. Madrid

Classic Beamer Madrid: blue header/footer bars, navy + white.

```css
:root {
    --font-heading: 'STIX Two Text', Georgia, serif;
    --font-body:    'STIX Two Text', Georgia, serif;
    --font-mono:    'Source Code Pro', 'Courier New', monospace;

    --bg-primary: #ffffff;
    --header-bg: #2c3e7b;
    --footer-bg: #2c3e7b;
    --header-fg: #ffffff;
    --footer-fg: #ffffff;

    --text-primary:   #1a1a2e;
    --text-secondary: #4a5568;

    --theorem-bg:     #e8eef8;
    --theorem-border: #2c3e7b;
    --definition-bg:     #fdf2e9;
    --definition-border: #d4740e;
    --proof-bg:     #f8f8f8;
    --proof-border: #95a5a6;
    --example-bg:     #eafaf1;
    --example-border: #27ae60;

    --chrome-height-top:    clamp(2.5rem, 5vh, 3.5rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);
}
```

**Layout signature:** Blue header bar (section title left, frame number right), matching blue footer (author short + short title + frame number). Content area centered.

**Fonts.** Google Fonts: `STIX+Two+Text:wght@400;700` and `Source+Code+Pro:wght@400`.

---

## 2. Berlin

Structured, sidebar-navigation theme — distinguishes itself by replacing the top chrome with a left sidebar.

```css
:root {
    --font-heading: 'Source Serif 4', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', 'Courier New', monospace;

    --bg-primary: #ffffff;
    --header-bg: #1a365d;
    --header-fg: #ffffff;
    --footer-bg: transparent;
    --footer-fg: #718096;

    --text-primary:   #1a202c;
    --text-secondary: #4a5568;

    --theorem-bg:     #ebf8ff;
    --theorem-border: #2b6cb0;
    --definition-bg:     #fefce8;
    --definition-border: #a16207;
    --proof-bg:     #f8f8f8;
    --proof-border: #94a3b8;
    --example-bg:     #f0fdf4;
    --example-border: #15803d;

    --chrome-width-sidebar: clamp(10rem, 18vw, 14rem);
    --chrome-height-top:    clamp(2rem, 4vh, 3rem);
    --chrome-height-bottom: 0;
}

/* Sidebar layout */
.frame--sidebar { flex-direction: row; }
.frame--sidebar .sidebar {
    width: var(--chrome-width-sidebar, 0);
    flex-shrink: 0;
    overflow: hidden;
    background: var(--header-bg);
    color: var(--header-fg);
}
.frame--sidebar .frame-content {
    flex: 1;
    width: calc(100% - var(--chrome-width-sidebar, 0));
}
```

**Layout signature:** Left sidebar with section list (active section highlighted), compact top header with frame title only, no footer bar. Section numbers in sidebar.

**Frame structure adjustment:** Use `<section class="frame frame--sidebar">` with a `<div class="sidebar">` child containing the section navigation list, alongside `<div class="frame-content">`.

---

## 3. Copenhagen

Clean, minimal, serif-driven — small rounded header block, generous whitespace.

```css
:root {
    --font-heading: 'EB Garamond', Georgia, serif;
    --font-body:    'EB Garamond', Georgia, serif;
    --font-mono:    'Source Code Pro', 'Courier New', monospace;

    --bg-primary: #ffffff;
    --header-bg: #2d4a7a;
    --header-fg: #ffffff;
    --footer-bg: transparent;
    --footer-fg: #718096;

    --text-primary:   #1a202c;
    --text-secondary: #4a5568;

    --theorem-bg:     #f0f5ff;
    --theorem-border: #2d4a7a;
    --definition-bg:     #fef3c7;
    --definition-border: #b45309;
    --proof-bg:     #fafafa;
    --proof-border: #9ca3af;
    --example-bg:     #ecfdf5;
    --example-border: #059669;

    --chrome-height-top:    clamp(2rem, 4vh, 3rem);
    --chrome-height-bottom: clamp(1.2rem, 2.5vh, 2rem);
}
```

**Layout signature:** Compact rounded header pill with section title, thin rule below, no decorative footer bg, frame number in bottom-right.

---

## 4. Warsaw

Bold, authoritative, high-impact — full-width gradient header bar.

```css
:root {
    --font-heading: 'STIX Two Text', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', 'Courier New', monospace;

    --bg-primary: #ffffff;
    --header-bg: linear-gradient(135deg, #1a365d 0%, #2c5282 100%);
    --footer-bg: #1a365d;
    --header-fg: #ffffff;
    --footer-fg: #ffffff;

    --text-primary:   #1a202c;
    --text-secondary: #4a5568;

    --theorem-bg:     #e8eef8;
    --theorem-border: #1a365d;
    --definition-bg:     #fef9c3;
    --definition-border: #a16207;
    --proof-bg:     #f8f8f8;
    --proof-border: #94a3b8;
    --example-bg:     #dcfce7;
    --example-border: #16a34a;
    --accent: #c53030;

    --chrome-height-top:    clamp(3rem, 6vh, 4.5rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);
}
```

**Layout signature:** Gradient header (navy → blue, 135°), prominent section title, bold separator under header, navigation dots in footer, red accent for alerts.

**Note.** Warsaw is the only theme using a CSS gradient for `--header-bg`. The gradient is purely structural chrome (not "decoration") and is permitted.

---

## 5. Metropolis

Modern sans-serif Beamer-mtheme look. Fira Sans throughout, dark teal chrome, orange accent.

```css
:root {
    --font-heading: 'Fira Sans', system-ui, sans-serif;
    --font-body:    'Fira Sans', system-ui, sans-serif;
    --font-mono:    'Fira Code', 'Source Code Pro', monospace;

    --bg-primary: #fafafa;
    --header-bg: #23373b;
    --footer-bg: #23373b;
    --header-fg: #fafafa;
    --footer-fg: #fafafa;

    --text-primary:   #23373b;
    --text-secondary: #5a6872;

    --accent: #eb811b;
    --theorem-bg:     #f5f0eb;
    --theorem-border: #eb811b;
    --definition-bg:     #ebf5f0;
    --definition-border: #23373b;
    --proof-bg:     #f5f5f5;
    --proof-border: #8a9ba5;
    --example-bg:     #fdf6ec;
    --example-border: #eb811b;

    --chrome-height-top:    clamp(2.5rem, 5vh, 3.5rem);
    --chrome-height-bottom: clamp(1.2rem, 2.5vh, 2rem);
}
```

**Layout signature:** Dark teal chrome, orange progress bar at top, orange `--accent` used for theorem borders. Fira Sans / Fira Code (matches the real Metropolis Beamer theme).

**Fonts.** Google Fonts: `Fira+Sans:wght@400;600` and `Fira+Code:wght@400`.

**Note.** This is the one theme where sans-serif body is correct. Do not substitute serif here.

---

## 6. Classic Serif

The most "LaTeX-like" theme — Computer Modern via jsDelivr, no chrome bars, paper-cream background.

```css
:root {
    --font-heading: 'CMU Serif', 'Latin Modern Roman', Georgia, serif;
    --font-body:    'CMU Serif', 'Latin Modern Roman', Georgia, serif;
    --font-mono:    'CMU Typewriter Text', 'Latin Modern Mono', 'Courier New', monospace;

    --bg-primary: #fffff8;
    --header-bg: transparent;
    --header-fg: #111111;
    --footer-bg: transparent;
    --footer-fg: #666666;

    --text-primary:   #111111;
    --text-secondary: #444444;

    --theorem-bg:     #f5f5f0;
    --theorem-border: #333333;
    --definition-bg:     #f0f5f0;
    --definition-border: #2e5c3f;
    --proof-bg:     transparent;
    --proof-border: #888888;
    --example-bg:     #f5f0f0;
    --example-border: #5c2e2e;

    --chrome-height-top:    0;
    --chrome-height-bottom: clamp(1rem, 2vh, 1.5rem);
}
```

**Layout signature:** Cream/off-white paper-like background, no header bar (frame title serves as header), thin horizontal rules as separators, minimal frame number in bottom-right.

**Fonts.** Requires jsDelivr CDN:
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/computer-modern@0.1.2/cmu-serif.css">
```

**If user picks Classic Serif:** confirm the CMU font CDN is included and add a Latin Modern fallback chain.

---

## 7. Cambridge

University formal — forest green + gold, ceremonial. Suitable for thesis defense or inaugural lecture.

```css
:root {
    --font-heading: 'EB Garamond', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #fffdf7;
    --header-bg: #1e3a2f;
    --footer-bg: #1e3a2f;
    --header-fg: #d4af37;
    --footer-fg: #d4af37;

    --text-primary:   #1a1a2e;
    --text-secondary: #4a5568;
    --accent: #d4af37;

    --theorem-bg:     #f0f5f2;
    --theorem-border: #1e3a2f;
    --definition-bg:     #fdf8e8;
    --definition-border: #8b6914;
    --proof-bg:     #f8f8f5;
    --proof-border: #7a8a7f;
    --example-bg:     #eef5f0;
    --example-border: #2d5a3f;

    --chrome-height-top:    clamp(2.5rem, 5vh, 4rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);
}
```

**Layout signature:** Forest-green header/footer bars with gold text and gold accent lines. Space for a university crest in the header (left of section title). Formal serif typography.

---

## 8. Lecture Notes

Warm, approachable, pedagogical — for teaching.

```css
:root {
    --font-heading: 'Source Serif 4', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #faf6f0;
    --header-bg: transparent;
    --header-fg: #2d2d2d;
    --footer-bg: transparent;
    --footer-fg: #6b5b4f;

    --text-primary:   #2d2d2d;
    --text-secondary: #6b5b4f;
    --accent: #c0392b;

    --theorem-bg:     #fff8e1;
    --theorem-border: #c0392b;
    --definition-bg:     #e8f5e9;
    --definition-border: #2e7d32;
    --proof-bg:     #faf6f0;
    --proof-border: #a0937e;
    --example-bg:     #e3f2fd;
    --example-border: #1565c0;

    --chrome-height-top:    0;
    --chrome-height-bottom: clamp(1rem, 2vh, 1.5rem);
}
```

**Layout signature:** Parchment-like cream background, no header bar (open spacious feel), red accent (professor's red pen), larger body font than other themes, warm-yellow theorem boxes. Friendly aesthetic.

**Typography tweak:** When this theme is selected, bump body size by ~10% (`--body-size: clamp(0.85rem, 1.7vw, 1.25rem);`) for student readability.

---

## 9. Technical Report

Dense, precise, engineering-focused — IEEE/ACM feel.

```css
:root {
    --font-heading: 'Source Serif 4', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #ffffff;
    --header-bg: #2d3748;
    --footer-bg: #2d3748;
    --header-fg: #e2e8f0;
    --footer-fg: #e2e8f0;

    --text-primary:   #1a202c;
    --text-secondary: #4a5568;
    --accent: #3182ce;

    --theorem-bg:     #ebf8ff;
    --theorem-border: #3182ce;
    --definition-bg:     #fefce8;
    --definition-border: #a16207;
    --proof-bg:     #f7fafc;
    --proof-border: #a0aec0;
    --example-bg:     #f0fff4;
    --example-border: #38a169;

    --chrome-height-top:    clamp(2rem, 4vh, 3rem);
    --chrome-height-bottom: clamp(1.2rem, 2.5vh, 2rem);
}
```

**Layout signature:** Compact slate-gray chrome, IEEE-style blue accent, two-column-friendly layouts via `.columns.two-col`, monospace-heavy emphasis for code/algorithm snippets.

---

## 10. Thesis Defense

Formal, authoritative, institution-ready — dark navy.

```css
:root {
    --font-heading: 'STIX Two Text', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #ffffff;
    --header-bg: #0d1b2a;
    --footer-bg: #0d1b2a;
    --header-fg: #e0e7ff;
    --footer-fg: #e0e7ff;

    --text-primary:   #0d1b2a;
    --text-secondary: #334155;
    --accent: #1d4ed8;

    --theorem-bg:     #eff6ff;
    --theorem-border: #1d4ed8;
    --definition-bg:     #fefce8;
    --definition-border: #a16207;
    --proof-bg:     #f8fafc;
    --proof-border: #94a3b8;
    --example-bg:     #f0fdf4;
    --example-border: #16a34a;

    --chrome-height-top:    clamp(3rem, 6vh, 4.5rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);
}
```

**Layout signature:** Dark navy chrome with space for an institution logo in the header (left of section title). Tall header bar (committee-friendly, formal). Prominent frame numbering. Blue accent.

---

## 11. Seminar

Informal, relaxed, discussion-oriented — for lab meetings, reading groups.

```css
:root {
    --font-heading: 'EB Garamond', Georgia, serif;       /* italic 500 */
    --font-body:    'EB Garamond', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #fafaf8;
    --header-bg: transparent;
    --header-fg: #2d3436;
    --footer-bg: transparent;
    --footer-fg: #636e72;

    --text-primary:   #2d3436;
    --text-secondary: #636e72;
    --accent: #6c5ce7;

    --theorem-bg:     #f3f0ff;
    --theorem-border: #6c5ce7;
    --definition-bg:     #fef3f2;
    --definition-border: #b91c1c;
    --proof-bg:     transparent;
    --proof-border: #a1a1aa;
    --example-bg:     #f0f9ff;
    --example-border: #0284c7;

    --chrome-height-top:    0;
    --chrome-height-bottom: clamp(0.8rem, 1.5vh, 1.2rem);
}

h1, h2, h3 { font-style: italic; font-weight: 500; }
```

**Layout signature:** No header bar (casual / open), italic display headings (conversational), purple accent (informal but academic), minimal footer with just frame number.

---

## 12. Journal Article

Paper-like, mathematical, publication-quality — AMS/Springer aesthetic.

```css
:root {
    --font-heading: 'STIX Two Text', Georgia, serif;
    --font-body:    'Source Serif 4', Georgia, serif;
    --font-mono:    'Source Code Pro', monospace;

    --bg-primary: #ffffff;
    --header-bg: transparent;
    --header-fg: #000000;
    --footer-bg: transparent;
    --footer-fg: #666666;

    --text-primary:   #000000;
    --text-secondary: #333333;

    --theorem-bg:     #f8f8f8;
    --theorem-border: #000000;
    --definition-bg:     #f0f0f0;
    --definition-border: #333333;
    --proof-bg:     transparent;
    --proof-border: #666666;
    --example-bg:     #f5f5f5;
    --example-border: #444444;

    --chrome-height-top:    0;
    --chrome-height-bottom: clamp(1rem, 2vh, 1.5rem);
}
```

**Layout signature:** Pure black & white, strong horizontal rules between sections, two-column layouts via `.columns.two-col`, centered numbered theorem environments, minimal — content is the design.

---

## Font Source Quick Reference

| Theme | Heading | Body | Mono | Source |
|-------|---------|------|------|--------|
| Madrid | STIX Two Text (700) | STIX Two Text (400) | Source Code Pro | Google Fonts |
| Berlin | Source Serif 4 (600) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Copenhagen | EB Garamond (600) | EB Garamond (400) | Source Code Pro | Google Fonts |
| Warsaw | STIX Two Text (700) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Metropolis | Fira Sans (600) | Fira Sans (400) | Fira Code | Google Fonts |
| Classic Serif | CMU Serif | CMU Serif | CMU Typewriter Text | jsDelivr CDN |
| Cambridge | EB Garamond (700) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Lecture Notes | Source Serif 4 (700) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Technical Report | Source Serif 4 (600) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Thesis Defense | STIX Two Text (700) | Source Serif 4 (400) | Source Code Pro | Google Fonts |
| Seminar | EB Garamond (500 italic) | EB Garamond (400) | Source Code Pro | Google Fonts |
| Journal Article | STIX Two Text (600) | Source Serif 4 (400) | Source Code Pro | Google Fonts |

---

## Theme-Specific "Load Also" Rules

- **Classic Serif** → also wire the jsDelivr CMU CSS link in `<head>`.
- **Metropolis** → also wire Fira Code (not just Fira Sans) so `.algorithm-box` looks correct.
- **Berlin** → also generate the `.frame--sidebar` markup variant for content frames; add a `<div class="sidebar">` populated with section nav.
- **Warsaw** → confirm the gradient in `--header-bg` is preserved through the chrome generator (do not flatten to a single color).
- **Cambridge / Thesis Defense** → reserve header chrome height for a university crest / institution logo on the left.

---

## Tone-to-Effect Mapping (Generation Hint)

When the user picks a mood (Phase 2.1) and Phase 2 generates 3 previews, use this mapping:

### Formal / Traditional
- Serif fonts (Computer Modern, STIX Two Text, Source Serif 4)
- Muted institutional colors (navy, burgundy, forest green)
- Structured header/footer chrome with bars
- Best themes: Madrid, Warsaw, Cambridge, Thesis Defense

### Modern / Clean
- Sans-serif fonts (Fira Sans, Source Sans 3)
- High contrast, minimal decoration
- Thin or absent chrome bars
- Best themes: Metropolis, Technical Report

### Warm / Pedagogical
- Serif or rounded fonts
- Warmer palette (cream backgrounds, warm grays, soft blues)
- Approachable, larger font sizes
- Visible structure aids (section numbers, outlines)
- Best themes: Lecture Notes, Seminar, Copenhagen

### Dense / Technical
- Compact spacing, smaller base font
- Monospace accents for code / algorithms
- Equation-heavy layouts, multi-column support
- Best themes: Berlin, Classic Serif, Journal Article

---

## Forbidden Aesthetics (Generic / Non-Academic)

**Fonts.** No Calibri, Arial, Comic Sans, or display/decorative fonts (Archivo Black, Syne, Clash Display). No sans-serif as the sole body font except in Metropolis.

**Colors.** No neon accents (#00ffcc, #d4ff00, #ff00aa). No pure saturated backgrounds. No electric blue (#0066ff). No gradient meshes. (Warsaw's structural header gradient is the only permitted gradient.)

**Layouts.** No centered-only with no frame structure. No floating abstract blobs. No "creative" asymmetric layouts. No dark backgrounds (except an optional Lecture Notes dark mode).

**Decorations.** No abstract gradient shapes, halftone textures, neon glow `box-shadow`, or noise textures. Academic decks use horizontal rules, theorem-box borders, and structural chrome only.
