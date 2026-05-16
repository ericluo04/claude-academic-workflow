# Viewport Rules, Density Caps, and Controller Mechanics

This reference defines the viewport-fit invariant, content density caps, all academic content-box CSS (`.theorem-box`, `.definition-box`, `.lemma-box`, `.corollary-box`, `.proof-box`, `.algorithm-box`, `.example-box`), KaTeX wiring, `clamp()` responsive typography, progressive disclosure (`data-pause`), and the `AcademicPresentation` JS controller (keyboard + swipe + wheel handlers, frame counter, IntersectionObserver). Everything in this file is mandatory for every generated deck.

---

## The Viewport-Fit Invariant (Non-Negotiable)

Every frame fits exactly within one viewport height:

```text
Each frame = exactly one viewport height (100vh / 100dvh)
Content overflows? -> Split into multiple frames or reduce content.
Never scroll within a frame.
```

### Content Density Caps Per Frame

| Frame Type | Maximum Content |
|------------|-----------------|
| Title Frame | 1 title + 1 subtitle + author/institute/date block |
| Content Frame | 1 heading + 4–5 bullet points OR 1 heading + 2 short paragraphs |
| Theorem/Proof Frame | 1 theorem box (max 4 lines) + 1 proof sketch (max 5 lines) |
| Equation Frame | 1 heading + 1–3 display equations with optional annotation |
| Algorithm Frame | 1 heading + max 12 lines of pseudocode |
| Definition Frame | 1 heading + 1–2 definition boxes (max 3 lines each) |
| Citation/References Frame | 1 heading + max 8 reference entries |
| Section Divider Frame | 1 section number + 1 section title + optional outline |

**Content exceeds limits? Split into multiple frames.** Never reduce font size below readability, never strip padding, never allow scrolling within a frame.

### Overflow Prevention Checklist

Before finalizing any deck, verify:

1. Every `.frame` has `height: 100vh; height: 100dvh; overflow: hidden;`.
2. All font sizes use `clamp(min, preferred, max)`.
3. All spacing uses `clamp()` or viewport units.
4. Content containers have `max-height` constraints.
5. Images have `max-height: min(50vh, 400px)` or similar.
6. Columns use `auto-fit` with `minmax()`.
7. Height breakpoints exist at 700px, 600px, 500px.
8. No fixed pixel heights on content elements.
9. Theorem/proof boxes have `max-height` constraints.
10. Per-frame density respects the caps in the table above.

### Testing Sizes

Recommend the user test at:
- Desktop: 1920×1080, 1440×900, 1280×720
- Tablet: 1024×768, 768×1024 (portrait)
- Mobile: 375×667, 414×896
- Landscape phone: 667×375, 896×414

### When Content Doesn't Fit

**DO:** split into multiple frames, reduce bullets (max 4–5), shorten text (1–2 lines per bullet), break long proofs across "Proof (cont.)" frames.

**DO NOT:** shrink fonts below readable, remove padding, allow scrolling, cram content.

---

## Required Base CSS

Every generated deck MUST include the following base CSS (theme-specific tokens override `--header-bg`, `--theorem-border`, etc. — see `themes.md`).

```css
/* ===========================================
   VIEWPORT FITTING: MANDATORY BASE STYLES
   These styles MUST be included in every presentation.
   They ensure frames fit exactly in the viewport.
   =========================================== */

/* 1. Lock html/body to viewport */
html, body {
    height: 100%;
    overflow-x: hidden;
}

html {
    scroll-snap-type: y mandatory;
    scroll-behavior: smooth;
}

/* 2. Each frame = exact viewport height */
.frame {
    width: 100vw;
    height: 100vh;
    height: 100dvh; /* Dynamic viewport height for mobile browsers */
    overflow: hidden; /* CRITICAL: Prevent ANY overflow */
    scroll-snap-align: start;
    display: flex;
    flex-direction: column;
    position: relative;
}

/* 3. Content container with flex for centering */
.frame-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    max-height: 100%;
    overflow: hidden; /* Double protection */
    padding: var(--frame-padding);
    padding-top: calc(var(--chrome-height-top) + var(--frame-padding));
    padding-bottom: calc(var(--chrome-height-bottom) + var(--frame-padding));
}

/* 4. ALL typography uses clamp() for responsive scaling */
:root {
    --title-size: clamp(1.5rem, 5vw, 3.5rem);
    --h2-size: clamp(1.25rem, 3.5vw, 2.25rem);
    --h3-size: clamp(1rem, 2.5vw, 1.75rem);
    --body-size: clamp(0.75rem, 1.5vw, 1.125rem);
    --small-size: clamp(0.65rem, 1vw, 0.875rem);

    --frame-padding: clamp(1rem, 4vw, 4rem);
    --content-gap: clamp(0.5rem, 2vw, 2rem);
    --element-gap: clamp(0.25rem, 1vw, 1rem);

    --chrome-height-top: clamp(2.5rem, 5vh, 3.5rem);
    --chrome-height-bottom: clamp(1.5rem, 3vh, 2.5rem);

    --ease-subtle: ease-in-out;
    --duration-normal: 0.3s;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: var(--font-body);
    background: #ffffff;
    color: #2c3e50;
    overflow-x: hidden;
    height: 100%;
}

/* 5. Frame header / footer (Beamer-style chrome) */
.frame-header, .frame-footer {
    position: fixed;
    left: 0;
    right: 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 var(--frame-padding);
    font-size: var(--small-size);
    z-index: 100;
}
.frame-header {
    top: 0;
    height: var(--chrome-height-top);
    background: var(--header-bg);
    color: var(--header-fg);
}
.frame-footer {
    bottom: 0;
    height: var(--chrome-height-bottom);
    background: var(--footer-bg);
    color: var(--footer-fg);
}

/* 6. Title and section divider frames */
.title-frame .frame-content,
.section-frame .frame-content {
    text-align: center;
    align-items: center;
}
.title-frame h1 {
    font-family: var(--font-heading);
    font-size: var(--title-size);
    font-weight: 700;
    line-height: 1.2;
    margin-bottom: var(--content-gap);
}
.title-frame .subtitle {
    font-size: var(--h2-size);
    color: var(--theorem-border);
    margin-bottom: var(--content-gap);
}
.author-block { font-size: var(--body-size); line-height: 1.6; }
.author-block .author { font-weight: 600; }
.author-block .institute { font-style: italic; }
.section-frame .section-number {
    font-size: var(--title-size);
    font-weight: 700;
    color: var(--theorem-border);
    opacity: 0.3;
}
```

---

## Theorem / Definition / Lemma / Corollary / Proof / Algorithm / Example Boxes

```css
/* ===========================================
   THEOREM ENVIRONMENTS (Beamer-style)
   =========================================== */
.theorem-box, .definition-box, .example-box, .lemma-box, .corollary-box {
    border-left: 4px solid var(--theorem-border);
    background: var(--theorem-bg);
    padding: clamp(0.5rem, 1.5vw, 1rem) clamp(0.75rem, 2vw, 1.5rem);
    margin: clamp(0.25rem, 0.5vw, 0.5rem) 0;
    max-height: min(40vh, 350px);
    overflow: hidden;
}

.definition-box {
    border-left-color: var(--definition-border);
    background: var(--definition-bg);
}

.example-box {
    border-left-color: var(--example-border);
    background: var(--example-bg);
}

.theorem-box .env-title,
.definition-box .env-title,
.example-box .env-title,
.lemma-box .env-title,
.corollary-box .env-title {
    font-weight: 700;
    font-size: var(--body-size);
    color: var(--theorem-border);
    margin-bottom: clamp(0.2rem, 0.5vw, 0.5rem);
}

.definition-box .env-title { color: var(--definition-border); }
.example-box .env-title    { color: var(--example-border); }

/* Proof environment with automatic QED square */
.proof-box {
    border-left: 2px solid var(--proof-border);
    background: var(--proof-bg);
    padding: clamp(0.4rem, 1vw, 0.75rem) clamp(0.75rem, 2vw, 1.5rem);
    font-style: italic;
    margin: clamp(0.25rem, 0.5vw, 0.5rem) 0;
}
.proof-box::after {
    content: '\25A1';  /* QED square */
    float: right;
    font-style: normal;
}

/* Algorithm / pseudocode block */
.algorithm-box {
    border: 1px solid var(--theorem-border);
    background: var(--proof-bg);
    padding: clamp(0.5rem, 1.5vw, 1rem);
    font-family: var(--font-mono);
    font-size: var(--small-size);
    line-height: 1.6;
    margin: clamp(0.25rem, 0.5vw, 0.5rem) 0;
}

/* Centered display equation block (with optional annotation) */
.equation-block {
    text-align: center;
    margin: var(--content-gap) 0;
    font-size: clamp(1rem, 2vw, 1.5rem);
}

/* Reference / citation list */
.citation-block {
    font-size: var(--small-size);
    line-height: 1.5;
    padding-left: 2em;
    text-indent: -2em;
}
.citation-block p { margin-bottom: clamp(0.15rem, 0.3vw, 0.3rem); }
```

### Sample Usage

```html
<section class="frame">
    <div class="frame-content">
        <h2 class="reveal">Frame Title</h2>
        <div class="theorem-box reveal" data-pause="1">
            <span class="env-title">Theorem 1 (Main Result)</span>
            <p>Inline math $f(x) = ax^2$ and display:</p>
            <p>$$\int_a^b f(x)\,dx = F(b) - F(a)$$</p>
        </div>
        <div class="proof-box reveal" data-pause="2">
            <span class="env-title">Proof.</span>
            <p>By the fundamental theorem of calculus...</p>
        </div>
    </div>
</section>
```

---

## Columns and Lists

```css
.columns {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));
    gap: clamp(0.5rem, 1.5vw, 1rem);
}
.columns.two-col   { grid-template-columns: 1fr 1fr; }
.columns.three-col { grid-template-columns: 1fr 1fr 1fr; }

/* Beamer-style item list with triangle bullet */
.item-list { list-style: none; padding: 0; }
.item-list li {
    font-size: var(--body-size);
    line-height: 1.4;
    padding-left: 1.5em;
    position: relative;
    margin-bottom: clamp(0.2rem, 0.5vw, 0.5rem);
}
.item-list li::before {
    content: '\25B8';  /* Small right triangle */
    position: absolute;
    left: 0;
    color: var(--theorem-border);
    font-weight: bold;
}

.enum-list { padding-left: 1.5em; }
.enum-list li {
    font-size: var(--body-size);
    line-height: 1.4;
    margin-bottom: clamp(0.2rem, 0.5vw, 0.5rem);
}

/* Lists scale with viewport */
.item-list, .enum-list { gap: clamp(0.4rem, 1vh, 1rem); }

/* Images constrained to viewport */
img, .image-container {
    max-width: 100%;
    max-height: min(50vh, 400px);
    object-fit: contain;
}
```

---

## Responsive Breakpoints

```css
/* Short viewports (< 700px height) */
@media (max-height: 700px) {
    :root {
        --frame-padding: clamp(0.75rem, 3vw, 2rem);
        --content-gap: clamp(0.4rem, 1.5vw, 1rem);
        --title-size: clamp(1.25rem, 4.5vw, 2.5rem);
        --h2-size: clamp(1rem, 3vw, 1.75rem);
    }
}

/* Very short (< 600px height) */
@media (max-height: 600px) {
    :root {
        --frame-padding: clamp(0.5rem, 2.5vw, 1.5rem);
        --content-gap: clamp(0.3rem, 1vw, 0.75rem);
        --title-size: clamp(1.1rem, 4vw, 2rem);
        --body-size: clamp(0.7rem, 1.2vw, 0.95rem);
    }
    .frame-nav, .keyboard-hint, .decorative { display: none; }
}

/* Landscape phones (< 500px height) */
@media (max-height: 500px) {
    :root {
        --frame-padding: clamp(0.4rem, 2vw, 1rem);
        --title-size: clamp(1rem, 3.5vw, 1.5rem);
        --h2-size: clamp(0.9rem, 2.5vw, 1.25rem);
        --body-size: clamp(0.65rem, 1vw, 0.85rem);
    }
}

/* Narrow viewports (< 600px width) */
@media (max-width: 600px) {
    :root { --title-size: clamp(1.25rem, 7vw, 2.5rem); }
    .columns { grid-template-columns: 1fr; }
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.2s !important;
    }
    html { scroll-behavior: auto; }
}
```

---

## Entrance Animation and Progressive Disclosure (`data-pause`)

Academic decks use one entrance effect only: a subtle fade. Never use scale / slide / blur / particle / parallax / 3D / cursor-trail / counter animations.

```css
/* Subtle fade */
.reveal {
    opacity: 0;
    transition: opacity var(--duration-normal) var(--ease-subtle);
}
.frame.visible .reveal { opacity: 1; }

/* Stagger children subtly */
.reveal:nth-child(1) { transition-delay: 0.05s; }
.reveal:nth-child(2) { transition-delay: 0.10s; }
.reveal:nth-child(3) { transition-delay: 0.15s; }
.reveal:nth-child(4) { transition-delay: 0.20s; }

/* Progressive disclosure (Beamer \pause equivalent) */
[data-pause] {
    opacity: 0;
    transition: opacity var(--duration-normal) var(--ease-subtle);
}
[data-pause].paused-visible { opacity: 1; }
```

`data-pause="N"` on a child element hides it until the user advances the Nth pause step on the current frame. The `AcademicPresentation` controller consumes one `next()` press per pause step before moving to the next frame, exactly like Beamer's `\pause`.

---

## KaTeX Wiring

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16/dist/contrib/auto-render.min.js"
    onload="renderMathInElement(document.body, {delimiters: [
        {left: '$$', right: '$$', display: true},
        {left: '$',  right: '$',  display: false}
    ]});"></script>
```

Use `$…$` for inline math and `$$…$$` for display math. Escape `&` as `&amp;` inside equations if needed.

---

## `AcademicPresentation` JS Controller

```html
<script>
/* ===========================================
   ACADEMIC PRESENTATION CONTROLLER
   Frame navigation, progressive disclosure (\pause),
   animations, keyboard/touch/wheel input.
   =========================================== */
class AcademicPresentation {
    constructor() {
        this.frames = document.querySelectorAll('.frame');
        this.currentFrame = 0;
        this.currentPause = 0;
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupIntersectionObserver();
        this.setupProgressiveDisclosure();
        this.updateFrameCounter();
        this.showFrame(0);
    }

    /* ----- Navigation ----- */
    setupNavigation() {
        document.addEventListener('keydown', (e) => {
            switch (e.key) {
                case 'ArrowRight':
                case 'ArrowDown':
                case ' ':
                case 'PageDown':
                    e.preventDefault(); this.next(); break;
                case 'ArrowLeft':
                case 'ArrowUp':
                case 'PageUp':
                    e.preventDefault(); this.prev(); break;
                case 'Home':
                    e.preventDefault(); this.goToFrame(0); break;
                case 'End':
                    e.preventDefault(); this.goToFrame(this.frames.length - 1); break;
            }
        });

        /* Touch / swipe */
        let touchStartY = 0;
        document.addEventListener('touchstart', (e) => {
            touchStartY = e.touches[0].clientY;
        });
        document.addEventListener('touchend', (e) => {
            const deltaY = touchStartY - e.changedTouches[0].clientY;
            if (Math.abs(deltaY) > 50) {
                deltaY > 0 ? this.next() : this.prev();
            }
        });

        /* Mouse wheel */
        let wheelTimeout;
        document.addEventListener('wheel', (e) => {
            e.preventDefault();
            clearTimeout(wheelTimeout);
            const delta = e.deltaY;
            wheelTimeout = setTimeout(() => {
                delta > 0 ? this.next() : this.prev();
            }, 50);
        }, { passive: false });
    }

    /* ----- Frame display ----- */
    next() {
        /* Advance pause before frame */
        if (this.advancePause()) return;
        if (this.currentFrame < this.frames.length - 1) {
            this.showFrame(this.currentFrame + 1);
        }
    }

    prev() {
        if (this.currentFrame > 0) {
            this.showFrame(this.currentFrame - 1);
        }
    }

    goToFrame(index) { this.showFrame(index); }

    showFrame(index) {
        /* Backward nav resets pause to step 0 (Beamer default). */
        const leaving = this.frames[this.currentFrame];
        if (leaving) {
            leaving.querySelectorAll('[data-pause]').forEach(el =>
                el.classList.remove('paused-visible'));
        }
        this.currentFrame = index;
        this.currentPause = 0;
        this.frames[index].scrollIntoView({ behavior: 'smooth' });
        this.updateFrameCounter();
    }

    /* ----- Progressive disclosure (\pause) ----- */
    setupProgressiveDisclosure() {
        this.frames.forEach(frame => {
            frame.querySelectorAll('[data-pause]').forEach(el => {
                el.classList.remove('paused-visible');
            });
        });
    }

    advancePause() {
        const frame = this.frames[this.currentFrame];
        const pauseElements = frame.querySelectorAll('[data-pause]');
        const nextPause = this.currentPause + 1;
        let found = false;
        pauseElements.forEach(el => {
            if (parseInt(el.dataset.pause) === nextPause) {
                el.classList.add('paused-visible');
                found = true;
            }
        });
        if (found) { this.currentPause = nextPause; return true; }
        return false;
    }

    /* ----- IntersectionObserver (entrance fade) ----- */
    setupIntersectionObserver() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) entry.target.classList.add('visible');
            });
        }, { threshold: 0.5 });
        this.frames.forEach(frame => observer.observe(frame));
    }

    /* ----- Frame counter ----- */
    updateFrameCounter() {
        const counter = document.querySelector('.frame-number');
        if (counter) {
            counter.textContent = `${this.currentFrame + 1} / ${this.frames.length}`;
        }
    }
}
new AcademicPresentation();
</script>
```

---

## Troubleshooting

**KaTeX not rendering.** Confirm CDN scripts load. Confirm the `onload` calls `renderMathInElement`. Confirm delimiter config (`$…$` inline, `$$…$$` display). Escape `&` to `&amp;` inside math if needed.

**Computer Modern not loading.** Confirm the jsDelivr CDN link is present and accessible. Fallback chain should include Source Serif 4 and Georgia.

**Theorem box overflowing.** Verify `max-height: min(40vh, 350px)` on the box. Reduce statement length (≤ 4 lines). Split long proofs across "Proof (cont.)" frames.

**Frame numbering wrong.** Confirm `updateFrameCounter()` runs on every navigation. Verify `.frame-number` element exists in the footer. Confirm `this.frames` picks up all `.frame` elements.

**`data-pause` not working.** Verify `data-pause="N"` with `N = 1, 2, 3, …`. Confirm `advancePause()` runs before frame advance in `next()`. Confirm `.paused-visible` is added on reveal.

**Speaker notes.** Notes from PPT ingest are stored as HTML comments (`<!-- NOTES: ... -->`). Open DevTools to read, or generate a separate `-notes.html` if dedicated view needed.

**Header/footer covering content.** Header/footer are global `position: fixed` with `z-index: 100`. `.frame-content` accounts for them via `padding-top: calc(var(--chrome-height-top) + var(--frame-padding))`.

---

## Animation Patterns: Forbidden List

Do not use any of these in an academic deck:

- Scale, slide, or blur entrance animations
- Gradient mesh or noise texture backgrounds
- Grid-pattern overlays
- 3D tilt or parallax effects
- Custom cursor with trail
- Particle system backgrounds
- Magnetic / hover effects
- Counter animations

The only entrance effect is the opacity fade defined above.
