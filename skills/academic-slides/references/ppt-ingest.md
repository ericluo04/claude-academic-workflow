# Phase 4: PPT Ingest (Mode B)

This reference covers the full PowerPoint conversion pipeline: `python-pptx` extraction, image extraction to `assets/`, equation-object detection and user flagging, speaker-notes extraction, slide-order preservation, and the reconciliation between "single self-contained HTML" (the new-deck default) and the `assets/` folder that PPT ingest necessarily produces.

For viewport / density / box CSS and the JS controller, see `viewport-rules.md`. For per-theme CSS, see `themes.md`.

---

## When This Phase Runs

Mode B: the user has an existing `.pptx`, PDF, or paper URL. Phase 4 runs **first** (before Phase 0.5), so the user's answers to "audience / takeaway / arc" and "paper focus / coverage / skip" are informed by the actual content already on the table.

Pipeline order for Mode B:

1. **Phase 4** — extract content, images, equation objects, speaker notes.
2. Confirm structure with user.
3. **Phase 0.5** — essential content questions.
4. **Phase 1P** — paper focus / coverage / skip.
5. **Phase 2** — theme selection.
6. **Phase 3** — generate HTML.
7. **Phase 5** — deliver.

---

## Single-File Output Reconciliation

The new-deck default (Mode A) is a single self-contained HTML file with inline CSS/JS and KaTeX via CDN — no side files.

PPT ingest cannot honor that strictly: the embedded images from the source `.pptx` must live somewhere on disk for the `<img>` tags to reference. The output is therefore:

```
presentation.html       # All CSS / JS / KaTeX inline; references ./assets/*
assets/
    frame1_img1.png
    frame1_img2.jpg
    ...
```

This is the **only** case where the deck is not strictly single-file. The HTML itself remains zero-dependency-zero-build; the `assets/` folder is purely a media side-channel. If the user wants strict single-file output for a Mode B conversion, suggest base64-inlining each image — but warn that decks with more than a handful of images become unwieldy.

For projects with multiple decks:

```
[name].html
[name]-assets/
```

---

## Step 4.1: Extract Content

Install: `pip install python-pptx`.

```python
from pptx import Presentation
from pptx.util import Inches, Pt
import json
import os
import base64


def extract_pptx(file_path, output_dir):
    """
    Extract all content from a PowerPoint file.
    Returns a JSON structure with slides, text, images, equation objects,
    and speaker notes. Images are written to <output_dir>/assets/.
    """
    prs = Presentation(file_path)
    frames_data = []

    # Create assets directory.
    assets_dir = os.path.join(output_dir, 'assets')
    os.makedirs(assets_dir, exist_ok=True)

    for frame_num, slide in enumerate(prs.slides):
        frame_data = {
            'number': frame_num + 1,
            'title': '',
            'content': [],
            'images': [],
            'equations': [],
            'notes': '',
        }

        for shape in slide.shapes:
            # 1. Extract title and other text frames.
            if shape.has_text_frame:
                if shape == slide.shapes.title:
                    frame_data['title'] = shape.text
                else:
                    frame_data['content'].append({
                        'type': 'text',
                        'content': shape.text,
                    })

            # 2. Extract images (shape_type 13 = Picture).
            if shape.shape_type == 13:
                image = shape.image
                image_bytes = image.blob
                image_ext = image.ext
                image_name = (
                    f"frame{frame_num + 1}_img"
                    f"{len(frame_data['images']) + 1}.{image_ext}"
                )
                image_path = os.path.join(assets_dir, image_name)

                with open(image_path, 'wb') as f:
                    f.write(image_bytes)

                frame_data['images'].append({
                    'path': f"assets/{image_name}",
                    'width': shape.width,
                    'height': shape.height,
                })

            # 3. Detect equation objects (OLE / EMF). Flag for KaTeX re-entry.
            if hasattr(shape, 'ole_format') or (
                hasattr(shape, 'image')
                and shape.image
                and shape.image.ext == 'emf'
            ):
                frame_data['equations'].append({
                    'type': 'equation_object',
                    'note': 'Detected equation object. Convert to KaTeX manually.',
                })

        # 4. Extract speaker notes.
        if slide.has_notes_slide:
            notes_frame = slide.notes_slide.notes_text_frame
            frame_data['notes'] = notes_frame.text

        frames_data.append(frame_data)

    return frames_data
```

### Extraction Notes

- **Slide order is preserved.** `prs.slides` iterates in source order; the `number` field carries the 1-indexed position.
- **Title detection.** `shape == slide.shapes.title` is the canonical check; falls through to `content` for non-title text frames.
- **Image filenames.** Deterministic `frameN_imgM.<ext>`. Use the `.ext` reported by `python-pptx` (commonly `png`, `jpg`, `gif`, `emf`).
- **Equation detection is heuristic.** PowerPoint equation editor objects are typically OLE-embedded with EMF rendering. `hasattr(shape, 'ole_format')` catches most; the EMF check catches rendered-image equations. False positives possible — surface to user, don't silently convert.
- **Encoding.** All text is Unicode; `python-pptx` returns strings directly. Pass through to the HTML generator unchanged.

---

## Step 4.2: Confirm Content Structure

After extraction, present a summary to the user:

```
I have extracted the following from your PowerPoint:

**Frame 1: [Title]**
- [Content summary, first ~80 chars]
- Images: [count]
- Equations detected: [count, if any]

**Frame 2: [Title]**
- [Content summary]
- Images: [count]

...

All images have been saved to ./assets/.
Note: [N] equation objects were detected. These will need manual conversion
to KaTeX `$...$` (inline) or `$$...$$` (display) syntax. I will ask you
to re-enter each equation in LaTeX so it renders correctly in the HTML.

Does this look correct? Should I proceed to the content questions?
```

If the user confirms, proceed to Phase 0.5. If the user wants to drop / merge / reorder slides, take the edits before Phase 0.5.

---

## Step 4.3: Equation Re-Entry

For each frame with `equations` entries, ask the user to type the LaTeX source so it can be inlined as `$…$` or `$$…$$`. Keep a running map `frame_number -> [equation_latex_strings]` and pass it to the HTML generator in Phase 3.

If the user declines (e.g., "skip equations, I'll add them later"), drop a visible placeholder in the generated frame:

```html
<p class="reveal"><em>[Equation: to be re-entered as LaTeX]</em></p>
```

---

## Step 4.4: Generate HTML

In Phase 3, the HTML generator consumes the `frames_data` list and produces one `<section class="frame">` per entry, preserving:

- All text content (`title` → `<h2>`, `content` → `<ul class="item-list">` or `<p>` per frame-type density caps).
- All images (referenced as `./assets/...` from the inline HTML).
- Frame order (1-indexed).
- Speaker notes as HTML comments at the bottom of each frame: `<!-- NOTES: ... -->`.
- KaTeX-converted equations from Step 4.3 inline at the correct frame position.

For each generated frame, apply the density caps from `viewport-rules.md`. If a single source slide overflows (too many bullets, too much text), split it across multiple HTML frames named `Frame X (cont.)`.

---

## Step 4.5: Speaker Notes Strategy

Two options:

1. **Inline HTML comments (default).** `<!-- NOTES: ... -->` immediately before the closing `</section>` of each frame. Invisible in the rendered deck; visible in DevTools or `view-source:`. Zero extra files.
2. **Separate notes file.** Generate `presentation-notes.html` with all notes visible, indexed by frame number. Useful for presenters who want to see notes during the talk on a second screen.

Default to (1). Offer (2) when the user mentions presenter view, dual monitors, or "I need to see my notes while presenting."

---

## Asset Path Resolution

- Generated `<img>` tags use relative path `./assets/...`.
- If the user opens `presentation.html` via `file://`, browsers resolve assets relative to the HTML.
- If the user serves over HTTP (`python -m http.server`), same resolution.
- If the user moves `presentation.html` to a different folder without `assets/`, images break — call this out in the Phase 5 summary.

---

## Step 4.6: Content Quality Pass

After extraction confirmation, proceed to:

1. **Phase 0.5** — audience / takeaway / arc.
2. **Phase 1P** — paper focus / coverage / skip.
3. **Phase 2** — theme selection (preview or direct).

Then Phase 3 generates with all directives applied — the extracted PPT content provides the raw material, while Phase 0.5 / 1P / 2 directives shape *how* it gets sequenced, calibrated, and styled.

---

## Troubleshooting

**`python-pptx` import error.** `pip install python-pptx`. Some environments need `pip install --upgrade pip` first.

**No title detected for some slides.** Slides without an explicit title placeholder return `shape == slide.shapes.title` as `None`. Fall back to the first text-frame as title.

**Images write but the deck shows broken links.** Confirm the generated HTML uses `./assets/` (with the `./`) not `/assets/` (root-relative). Confirm the file was written to the same folder that contains `assets/`.

**Equations rendered as EMF stay as raster images.** Expected — PowerPoint equation objects do not export to MathML cleanly. The user must re-enter as LaTeX (Step 4.3) or accept the raster image (in which case it gets stored as a regular `assets/...` image instead).

**Notes contain Unicode that breaks the HTML.** Escape `<`, `>`, `&` if writing notes inline. HTML comments do not interpret HTML entities, but `--` inside a comment will break it; replace `--` with `—` (em-dash) or `- -`.

**Large images blow up the deck visually.** All images have `max-width: 100%; max-height: min(50vh, 400px);` from the base CSS — they'll fit. If the original is enormous, consider downsampling with Pillow before writing to `assets/`.
