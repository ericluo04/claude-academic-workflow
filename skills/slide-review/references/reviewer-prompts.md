# Reviewer prompts

The four lens prompts stage 6 sends, the paragraph on settled decisions that precedes them, and the
contract every reviewer returns. The density calibration and the settled decisions these prompts
encode are `style/house.md`; the paragraph below is the version reviewers receive.

## Settled decisions, said in every prompt

Some of the design is settled, and a reviewer proposing a change to any of it has produced a false
finding. Say so in the prompt. Assertion titles are mandated on content slides: the author's Beamer
deck lacked them only because Beamer made them awkward, and the current direction is the one they
want. The numbered section discs and the segmented bottom progress bar are the design as intended.
The appendix and the references sit outside the bar with the fill full through both, on purpose.
Theorem environments and speaker notes are wanted and the author plans to use more of them, so no
reviewer asks whether a `.proposition` block or a `::: {.notes}` block belongs in the deck; a finding
about one is a finding about its content or its legibility.

## Layout


All PNGs, plus `fit.json` from stage 3 and `probe.json` from stage 4. This is the lens that was fiction
before.

> You are auditing a reveal.js deck for whether a seated audience can actually see it. Read every PNG
> listed. The logical canvas is 1050x700 deck px; the screenshots are 2334x1556, so screenshot px / 2
> = deck px. Judge from pixels, never from the source.
>
> The two JSON files below already measured what is measurable. The first carries a status token per
> slide (`ok`, `OVERFLOW +Npx`, `TOO WIDE +Npx`, `N MISSING IMG`, `N CRUSHED FIG`, `FIG SHRUNK TO Npx`,
> `N UNRENDERED MATH`, `NEARLY EMPTY`), and a slide can carry several; reproduce each token and its
> number exactly. The second has font sizes, contrast ratios, and the deck's ground colour. Confirm or
> contradict every entry against what you see in the image, then add what no
> measurement catches: crowding, elements that fail to align on a common left edge, a figure whose axis
> labels or legend are too small to read at this size, a plot whose lines are indistinguishable, two
> adjacent items with no separation, a table whose columns collide, a heading colliding with the first
> line of body text.
>
> This deck's ground is {deck.ground}. {On a dark deck, add:} The dark ground is the theme, so do not
> report it. Report what fails against it: a figure sitting on a white panel, a code block on a light
> card, a colour that has gone nearly invisible, and running text at pure white, which blooms on a
> projector where `#e8e6e3` does not. Headings at pure white are intended.
>
> How much text a slide carries is the argument and pedagogy reviewers' call under the density rules
> in `style/house.md`, so leave that judgment to them. Crowding is yours where it is geometric: items with no
> separation between them, a block running into the slide margin.
>
> Every geometric claim carries its arithmetic, with the measurement and the threshold both stated.
> "The table's right edge is at 1358 deck px against a 1050 px canvas, so 308 px, roughly 29% of the
> width, is off screen." "The caption measures 11 deck px, 1.6% of the 700 px canvas height, under the
> 1.7% floor." A finding that says only that something looks too wide or too small gets dropped in
> synthesis.

## Argument


All PNGs plus the ordered title list from the probe.

> Read every PNG. First, extract the titles in order and write the deck's storyline from titles alone.
> Classify each: an assertion makes a claim the audience can disagree with ("Adoption raised prices
> 4.2%"), a label only names a topic ("Results", "Methodology"). A label title on a slide carrying a
> substantive point is MAJOR, because the audience loses the thread the moment they look away. Exempt
> section dividers (`.section-break`), the title slide, `.appendix` slides, and genuine agenda or
> roadmap slides.
>
> Then: does each slide make one point, or several stapled together. Does the sequence build an
> argument, or is it a list of things that are true. Where does a claim arrive with no support visible
> yet. Where does a slide answer a question the audience has not been given a reason to ask.
> {goal, if provided}
>
> Density runs one way on a talk deck. Report text the speaker could say instead, and never report a
> slide for being sparse: a heading plus one exhibit is finished work here, and the author's style is
> a narrated picture book. On a lecture deck, do not report a slide as too wordy for carrying more
> text than a conference slide would.
>
> The closing, by type. A talk's last main-body slide is the thank-you slide (an invitation to get in
> touch, the email, a QR code to the paper), so ask whether the content slide before it lands the
> payoff of the opening. A lecture has no thank-you slide, so its final content slide is the closing
> and that is the one to judge. Stage 3c has already checked which of the two is present, so do not
> re-report a missing or a stray thank-you slide.

## Pedagogy (lecture decks only)


All PNGs.

> Read every PNG. This is a teaching deck for students with business priors and limited statistics.
> Check: every symbol and every term is introduced before it is used, and flag the first slide where
> one is not. Formal content is motivated before it is stated. A worked example follows each definition
> within two slides. New concepts arrive one per slide, not four. Pacing: count consecutive dense
> slides with no example, figure, or breather, and flag runs longer than three. Cognitive load: a slide
> asking students to hold more than about four new things at once. Blocks on a content slide arrive one
> keypress at a time under `stage-slide.lua`, and a `.together` group is one beat, so count what is on
> screen at the same moment. Report each against a slide number.
>
> Students save this PDF and study from it, so the deck is also a document and carries more text than
> a conference slide would. Never report a slide as too wordy on that basis. Report text that is
> unclear or text that overwhelms, and say which of the two it is. A lecture ends without a thank-you
> slide, which stage 3c owns and you do not.

## Copy


All PNGs, plus the `.qmd` source so fixes can be exact.

> Read every PNG, then read the source at {path}. The images are the ground truth for what the audience
> sees; the source is where the fix goes. Report typos, doubled words, wrong or missing words,
> subject-verb disagreement, a symbol used for two different things or two symbols used for one thing,
> a term that changes mid-deck, numbers that disagree between a table and the sentence describing it,
> a citation rendered as a raw bibtex key or as `(smith2020?)`, and any math showing a backslash
> command on screen.
> Every item gets an exact `old_string` to `new_string` pair, unique in the source.
>
> Do not comment on the author's writing style, sentence length, tone, or word choice. Only errors and
> genuine ambiguity.

## The contract

All four return the same contract:

```
N. [CRITICAL|MAJOR|MINOR] slide 7 ("Main result") - one-line statement
   Evidence: what is visible in slide-07.png, with the arithmetic if it is a measurement.
   Fix: the specific change. For copy findings, exact old_string -> new_string.
```

No prose outside the numbered list. `NONE` if a reviewer finds nothing at its severity floor.
