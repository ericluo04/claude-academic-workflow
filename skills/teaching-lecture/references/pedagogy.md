# Pedagogy: density, prompts, checks, and the pattern audit

## How dense a teaching slide should be

A teaching deck is deliberately wordier than a talk deck. Students save the PDF
and read it a week later with nobody narrating it, so the deck is a study
document as well as a projection, and a line that only makes sense with your
voice over it is a line the student loses. That is a design goal here, and the
sparse-slide instinct gets diluted for it on purpose. The author's calibration
target and the strength of the dilution are in `style/house.md`.

The ceiling is unchanged. Text still has to be presented naturally and clearly,
and it must never bury the room in information while you are talking. Wordier
means complete sentences and definitions written out in full. It does not mean a
paragraph on the wall.

What earns space in the slide body is whatever a student cannot reconstruct from
the wall a week on: the statement of a definition or a result, the steps of a
derivation, the numbers in the example, the caveat that changes what the result
means, the name of the thing so they can look it up, the pointer to where this
goes next. What stays spoken is delivery: the show of hands, the aside about the
vendor who tried it, the reason you are pausing here, the second phrasing you
reach for when the first one lands badly. Those go in `::: {.notes}`.

None of this loosens the per-slide discipline. One idea per slide, and the
second idea is the next slide. The extra words buy fuller sentences about that
one idea, never a second idea wedged under the first. Two blocks per slide is
still the limit, and eight single-line bullets still fills the canvas at the
34px root.

The narrated picture book is still the overall philosophy: you talk, the slide
shows, and the picture comes before the notation. The study-document requirement
dilutes it and does not replace it.

## Show the thing before naming it

A two-to-five-word assertion carries a beat on its own, and `.r-fit-text`
scales the line to the slide width:

```markdown
## {.center}

::: {.r-fit-text}
Accuracy is not a decision
:::
```

## The teaching vocabulary is semantic

Keep the block-class mapping fixed for the whole semester. `.keyidea` is the one
thing to remember, `.definition` is new vocabulary, `.example` is the concrete
case, `.warning` is the common error, `.question` is something the student has
to do. Reusing `.warning` for a definition destroys the vocabulary you spent
weeks building.

## Speaker notes

Write speaker notes. They earn more here than anywhere else in this toolchain,
because a lecture is the deck you deliver live for 75 minutes and then teach
again next year to a different room. `::: {.notes}` puts your delivery into
reveal's speaker view (press `S`), where it is in front of you and off the wall.

```markdown
::: {.notes}
Ask for a show of hands first. Half the room says ship it; use that.
:::
```

Every content slide that has something to say about how to say it gets a note:
the question you open on, where the room usually goes wrong, how long to wait,
the callback to week 2. A `.question` or a `.prompt` slide always gets one,
since the whole slide is a thing you run and the running of it is written
nowhere else in the file.

Notes appear in neither PDF export, which is why the slide body carries what the
student rereads and the notes carry only what you do in the room.

## Discussion prompts and checks for understanding

Two kinds of interaction, not interchangeable. A `.prompt` slide is open-ended
and takes three to five minutes of talking. A `.question` block is a check for
understanding with a determinate answer, takes 30 seconds, and works best in the
peer-instruction pattern from physics teaching (Mazur): pose it, students commit
individually, they argue in pairs, then commit again. Every block gets at least
one check for understanding, and its answer goes on the next slide as a
`.fragment` so you cannot reveal it early by accident.

Put the first prompt around minute 25, before attention drops rather than after.
Put the second before the hardest material, so students have already said the
wrong thing out loud and want the answer.

## Pedagogical patterns

Adapted from the 13-pattern pedagogy review in the source repo, translated into
what this theme and reveal actually provide. Check a draft against these before
handing it over. The right column is what to look for when auditing.

| Pattern | Red flag |
|---|---|
| Motivation before formalism. Why, then what, then a case. | A definition slide with no slide before it that makes the student want the definition. |
| A worked example within two slides of every definition, in `ol.steps`. Hard requirement here, unlike a research talk where one empirical thread serves several definitions. | Two definition slides in a row. |
| Incremental notation. At most two new symbols a slide, each introduced in prose before it appears in display math. | A slide needing `s`, `a`, `L`, `\delta`, and `\tau` at once. |
| Progressive complexity: simple, then relative, then distributional, then conditional. | A conditional expectation before an unconditional one. |
| A `.section-break` every five to eight slides. | A 40-slide deck that reads as one block. |
| Two slides for a dense result: the statement with color and a forward pointer, then one slide per term with the intuition. | One slide holding a theorem and all its definitions. |
| Semantic colour fixed for the semester: treated `.yblue` (`#63aaff`), control `.ygray` (`#9aa0a6`), counterfactual dashed `.yred` (`#ffa07a`), the same hex values inside the figures. | A binary contrast shown in one colour, or a figure still carrying the old `#00356b`. |
| Box hierarchy honored: right block for the content, two per slide, at most three `.keyidea` in the deck. | Everything is a key idea, so nothing is. |
| Socratic embedding, two or three genuine questions minimum. | A deck with no questions, which is a lecture the students watched. |
| Visual first for anything hard: picture, then notation. | Notation introduced before the figure that motivates it. |
| Two-column comparison when the comparison is the point (ATT beside ATE, prediction beside decision). | Consecutive slides making the student hold one in memory. |
