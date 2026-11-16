# Narrative: the arc, selection, wording, and the three input cases

This file says what goes in the talk and in what order. `staging.md` says how
each slide builds. `../style/house.md` holds the author's own calibration.

## The slide is a prompt for the voice-over

Each slide carries three things at most:

1. the exhibit (a figure, a table, an equation, a diagram);
2. the line that names it;
3. the focal number, if the slide has one.

The speaker says everything else: the setup, the intuition, the caveats, and
the bridge to the next slide. When a line exists only so the room can follow
along later, cut it. When a question on the slide is one the speaker will ask
aloud, cut it too.

Speaker notes are optional. If the author wants help with the script, write a
separate cue sheet outside the deck, one line per click, keyed to the slide
`#id` and the click number.

## The arc

The Editorial flow is the frame for every arc: title, content slides grouped
under accent section slides, Takeaways, Backup, references. Section slides
carry one word or a short phrase ("Setting", "Identification", "Estimates"),
never a number, and they replace an outline slide.

An empirical paper with one identification strategy:

1. Title.
2. The fact or puzzle, in one to three slides.
3. The claim and the headline estimate, by the third slide.
4. Setting: the data and the source of variation.
5. Identification: the equation, built term by term, and the assumption.
6. Estimates: the main table or figure, one finding per slide.
7. Mechanism or heterogeneity.
8. The main threat and what answers it.
9. Takeaways.
10. Backup, then references.

A method or framework paper replaces 5 to 8 with one section per stage of the
method, each ending on its own deliverable (a table, a figure, a generated
example), and then the validation study. A multi-study paper gets one section
per study, each running design, data, specification, result.

Budget about one content slide per minute of speaking. A one-hour seminar runs
about 35 to 45 main slides. Build the backup slides past the budget on purpose:
every cut for time and every anticipated question is a backup slide.

## One running example

One example threads the whole talk. Choose it with the author: bring two or
three candidates as pictures or numbers, not as a list of ids. A good candidate
exists at every stage of the argument, shows one clear change, and was
confirmed by the evidence. When a later slide uses the example, reuse the same
files, and record their paths in the slide comment.

## Selecting and cutting

Default every paper paragraph to "said aloud". Then decide, paragraph by
paragraph:

1. On the slide, as an exhibit, a label, or a number.
2. Said aloud by the speaker.
3. In the backup slides, behind a button.
4. Cut.

The backup slides take estimation details, full tables, robustness, design
details, and anything a questioner might ask for. Cut technical detail that
does not change the story, a slide that breaks the flow, paper-only caveats,
and a supporting graph whose point the speaker can say.

A cut slide stays in the source inside a dated comment block (`staging.md`,
"Retired slides").

## Wording for the room

Paper jargon becomes the plain domain word, and the same word is used on every
slide. Ask the author for the room's word when a paper term is technical.

Titles are in sentence case. Title a problem neutrally. There is no label above
a slide title: no kicker, no eyebrow, no small colored word over the heading.

Cut filler words from bullets. Put `.em` on the one phrase the room should keep.

## Case A: the input is a full paper

1. Ask the four questions in SKILL.md, "Before drafting anything".
2. Read the paper for the problem, the source of variation or the stages of the
   method, the deliverable of each, and the evidence.
3. Pick the running example with the author.
4. Draft the arc as a title list with the section words. Read it back before
   writing any slide body.
5. Sort each paper paragraph into slide, aloud, backup, or cut. Write the sort
   down as a table the author can scan.
6. Rename paper jargon for the room. Bring the renames as a list of pairs.
7. Build the bodies: the exhibit, the label, the focal number.
8. Plan the clicks for each slide in speaking order (`staging.md`).
9. Build the backup slides in main-talk order, each with a button and a Back.
10. Walk the deck with the author one slide at a time, and apply their changes
    exactly.

## Case B: the input is analyses plus an outline

1. Treat the outline as the arc. Do not restructure it without asking.
2. Map each outline item to an analysis output (a figure, a table, an
   estimate). List the items with no output and ask about each.
3. Ask for the running example and for the exact names of the variables as the
   author wants them on slides.
4. For each analysis, prefer a figure with the inference on it (a bracket with
   the coefficient, an annotated effect) to a table. The full table goes to a
   backup slide behind a one- or two-word button.
5. Where the outline assumes background the room lacks, propose prerequisite
   slides.
6. Steps 7 to 10 of Case A apply unchanged.

## Case C: the input is someone else's paper

The speaker presents a paper they did not write, for example to a reading
group that will discuss it. The arc of Case A does not fit: there are no
contributions of the speaker's own to claim.

The arc:

1. Title, naming the paper and its authors.
2. Intro: one slide per core idea of the paper, explained intuitively, each
   with one visual.
3. Why it matters: one slide, a few bullets in words.
4. The question, in the speaker's words, on its own slide.
5. The premise: the paper's one idea in a picture. The design goes here too,
   stated once, one slide per lever or condition, so later evidence slides only
   point back to it.
6. The model, step by step, with each evidence figure right after the
   prediction it tests. The derivation follows the derivation chain in
   `staging.md`.
7. A methods aside, if the room needs one, last.
8. Takeaways: what the paper shows, in claims the room can dispute.

Rules for Case C:

1. Paper first. Present what the paper does. Its caveats, its side cases, and
   the speaker's critique go to backup slides behind buttons.
2. Use one running example from the paper for every step. On the setup slide,
   name the concept, show the example stimuli or data, and state the measured
   outcome in one line.
3. Fill in every step the paper skips, so no line of the derivation is a leap.
   Keep the full derivation and its check in a note beside the deck, and name
   that note in the slide comment.
4. Use the paper's symbols. Where one symbol has two meanings in the paper,
   pick one meaning and rename the other on every slide and figure.
5. A fitted parameter, a robustness check, or a larger replication goes in one
   `.aside-note` line or a backup slide, never on its own main slide.
6. Cite every borrowed figure and claim on its slide, from a verified `.bib`.
7. Before the walk with the author, run one critic pass, by a reviewer that did
   not build the deck, on two questions. Fact: does each slide say what the
   paper says? Attribution: is each idea and figure credited to the paper that
   made it? Apply the fixes and list what changed.

The procedure is Case A's with two changes. Step 2 reads the paper for its
premise, its model, each prediction, and the figure that tests each prediction.
Step 5 sends the speaker's own critique to the backup slides by default.

## Notation and first drafts

These hold in every case.

1. One symbol per quantity across the text and the figures of the deck. Before
   any figure is drawn, write the symbol list in a comment at the top of the
   deck. The example talk's list names $p_{jmt}$, $A_{jt}$,
   $\mathrm{RivalShare}_{mt}$, $\beta_1$, $\beta_2$, $\gamma_j$, and
   $\delta_{mt}$, and no slide reuses one of them for anything else.
2. First drafts are lean. No step tags (assumption, identity, approximation)
   and no caveat lines in the main talk. Put the detail the speaker needs into
   the slide comment or a backup slide.
3. Lean is about tags and caveats, never about the substance the room needs to
   follow. Each setup slide says what the units are, what the variation is, and
   how many observations there are.

## Before the talk

1. Read only the titles in order. With the voice-over, they tell the story.
2. Check that nothing moves between consecutive slides that share content.
3. Check that every button has a Back that returns to its click.
4. Check that the backup slides follow the order of the main talk.
