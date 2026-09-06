# Failure taxonomy, the full table

Every symptom this skill has met and the response to each. SKILL.md points here instead of carrying
a short form of the table.

| Symptom | Response |
|---|---|
| `quarto render` non-zero | `RENDER_FAILED:<msg>` from the log, stop. Do not review the previous HTML. |
| `check-offline.py` exit 1 on an opt-in deck | CRITICAL finding, keep going. Identify which cause (math config or Google-Fonts theme) and report the specific fix; do not try to patch the HTML. |
| An external `cdn.jsdelivr` MathJax reference | Expected on every default deck. Not a finding, and not a reason to run the offline check. |
| Probe reports `ground: "rgb(255, 255, 255)"` on a lecture deck | The dark theme did not load. CRITICAL, and stop the dark checks, since every one of them would measure against the wrong ground. |
| Probe reports `engine: "none"` | The math engine never ran, or the deck has no math. Cross-check `UNRENDERED MATH` from stage 3 before calling it either way. |
| `figures[].note` says `unmeasurable` | The canvas read was refused. Report those figures as sent for human review and name the slides. Do not write a luminance you did not measure. |
| `deck-check.mjs fit` exit 1 | Working as intended. Every slide it names is a finding; carry its numbers through unaltered. |
| `UNPAGINATED BIBLIOGRAPHY: div#refs holds N entries` | The deck set a `bibliography:` and left out `citeproc: false`, so pandoc rendered a second copy of the whole reference list onto one slide on top of the paginated one. CRITICAL; the fix is the one front-matter line. |
| A reference list that overflows its slide | The `refs-fit` preset is missing or wrong for the theme (`starter` for this repo's starter extension, `talk` for a 30px root, `lecture` for 34px). MAJOR. `STAGE_REFS_DEBUG=1 quarto render deck.qmd` prints what the packer decided, and `refs-lines` overrides it. Do not recommend `.scrollable`: it hides the overflow from the gate, breaks `auto-stretch`, and does not print. |
| A citation on the wall as a literal `@key` | `citeproc: false` is set and `stage-slide.lua` is not in `filters:`, so nobody ran citeproc. CRITICAL. |
| `stage-check.mjs` exit 1 with `LEAKS AT STEP 0` | Content is visible before the first keypress. CRITICAL. Name every slide it lists; the usual causes are a figure cell, an `.r-stack` base layer, or a top-level `.nonincremental` list. |
| `stage-check.mjs` exit 1 with `DEAD STEP` or `DEAD STEPS` | A press advances the deck and changes nothing on the wall. CRITICAL. Quote the slide and the press numbers it names. The usual cause is a container div wrapped around content that already stages itself, so the fix is to drop the wrapper or mark it `.together` if the beat was meant. |
| A `MathJax.Hub.Config` exception in the console | Expected on every deck with `embed-resources: true` and MathJax: pandoc loads mathjax@4 (the bare-string `html-math-method: mathjax`) and reveal's bundled plugin still runs its MathJax-2 path. Reproduced on a two-slide deck with no theme and no filter. Not a finding. The math still typesets; cross-check `UNRENDERED MATH` if in doubt. |
| A jump button's `data-jump` target does not resolve | CRITICAL. Reveal fails an unresolved hash silently and lands on the title slide, so this only ever shows up mid-question. Report the label and the id. |
| Progress bar reaches only two thirds on the closing slide | Nothing marks where the main deck ends: no `.appendix-break` or `.references-break` divider, and no `.appendix` or `.references` slides. MAJOR; the fix is the divider. |
| A talk deck with no thank-you slide | MAJOR, from stage 3c. The last main-body slide carries the invitation to get in touch, the contact block from `style/house.md`, and a QR code to the paper, ahead of the appendix divider and with the references last. |
| A thank-you slide on a lecture deck | MINOR, from stage 3c. It belongs on a talk. A lecture's last slide is the one idea students leave with. |
| A reviewer proposes dropping the numbered section discs, unsegmenting the progress bar, or putting the appendix or the references back into it | Not a finding. Those are settled and the author likes them. Drop the item in synthesis and keep it out of the report. |
| A reviewer reports a sparse talk slide as underdeveloped, or a lecture slide as too wordy on the amount of text alone | Not a finding on either type, per the density rules in stage 6. Drop it in synthesis. A talk slide is flagged for text the speaker could say instead; a lecture slide is flagged for text that is unclear or that overwhelms. |
| Slide numbers all one colour in the handout PDF and a different colour on screen | A theme rule shaped `:has(section.present…)`, which matches every page in print because reveal marks every section `.present` there. Both current themes guard these with `html:not(.print-pdf)`; a third-party theme may not. |
| `deck-check.mjs` or `capture.mjs` cannot find Chrome | Set `CHROME_BIN` to the binary in `/Applications`. Do not substitute a hand-written overflow probe. |
| `capture.mjs` prints `WARNING: scale is ...` | The deck overrides `width`, `height`, or `margin`. Carry the printed scale into the reviewer prompts in place of 2.0. |
| `capture.mjs` reports every figure `unmeasurable` | Chrome ran without `--allow-file-access-from-files`, so the canvas was tainted under `file://`. The script passes the flag; a wrapper that relaunches Chrome must too. |
| `Reveal is not defined` | Page not finished loading, or an HTML that is not a reveal deck. Re-evaluate once, then stop. |
| Page changes under you mid-capture | Another agent grabbed the browser. Abandon the capture and switch to the decktape path; do not retry browser work in parallel. |
| Rasterizer reports an unrecoverable error | Usually not a PDF at all. Confirm the first five bytes are a PDF magic number. |
| `Read` fails on a `.pdf` | Expected, there is no poppler. Convert with `pdfread.py png` and read the PNG. |
| `decktape` gives a blank or single-page PDF | Wrong exporter. It must be `decktape reveal`, with the deck's own `file://` path. |
| Reviewer returns prose, not the numbered contract | Re-prompt once with "Please respond in the required format." On a second drift, surface the raw reply. |
