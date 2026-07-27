# Numbered theorems, and the proof in the appendix

A formal result gets a real numbered environment, not one of the five teaching
boxes with a hand-typed label. Give the div a Quarto crossref id and write
nothing else:

```markdown
::: {#thm-paired}
Grade A and B on the *same* $n$ items from $\D$. Let $p_{10}$ be the chance A
passes where B fails, $p_{01}$ the reverse, and $\Delta = p_{10} - p_{01}$. Then
$$\se(\Sh_A - \Sh_B) = \sqrt{\frac{p_{10} + p_{01} - \Delta^2}{n}}.$$
:::
```

That renders as a pale-blue box, ringed rather than open on the right, with
`THEOREM 1` on the label line. The number is Quarto's, written into the HTML at
render time, so it renumbers itself when you insert a result above it and it
survives into the handout. Do not add a `[Theorem]{.label}` span: the number is
already there and you would get the title twice.

## The prefix family

| Prefix | Renders as | Counter |
|---|---|---|
| `#thm-` | Theorem 1 | its own |
| `#prp-` | Proposition 1 | its own |
| `#lem-` | Lemma 1 | its own |
| `#cor-` | Corollary 1 | its own |
| `#def-` | Definition 1, in the existing `.definition` box | its own |
| `#exm-` | Example 1, in the existing `.example` box | its own |

Four separate counters for the four result types, which is the convention, so
Theorem 2 can follow Lemma 1 without eating its number.

## The `#def-` and `#exm-` guard

`#def-` and `#exm-` are the two prefixes that collide with the teaching
vocabulary: Quarto lands `.theorem.definition` and `.theorem.example` on those
divs, and the theme's guard keeps them in the box they already have and gives
them only the numbered label. So `::: {.definition}` with a hand-written
`[Definition]{.label}` stays the right markup for vocabulary you will not point
back at, and `::: {#def-name}` is the one to use when you will.

Name a result after a person with `::: {#thm-cheb name="Chebyshev"}`, which
prints `THEOREM 1 (CHEBYSHEV)`.

Refer back with `@thm-paired`, which prints "Theorem 1" and is a live link:
clicking it navigates to the slide holding the statement, and it prints as a
page reference in the handout. That is the reason to use a crossref id even on a
result you state once.

## The proof goes behind a jump button

The proof goes on an appendix slide behind a jump button, which keeps the
statement slide clean and still puts the derivation one keypress away when the
room asks:

```markdown
## Overlapping intervals are the wrong test {#paired}

::: {#thm-paired}
...statement...
:::

::: {.aside-note}
A leaderboard publishes two marginal scores and nothing else.
:::

::: {.with-previous}
[Paired Standard Error]{.jump target="ap-paired"}
:::

## Where the paired standard error comes from {.appendix #ap-paired}

::: {.proof name="of @thm-paired"}
Write $D_i = X_i - Y_i$ for the difference of the two pass indicators...
:::

::: {.aside-note}
Substitute the sample disagreement shares to use it.
:::

::: {.with-previous}
[]{.jump-back}
:::
```

`::: {.proof}` is subordinate prose and not a box: a run-in italic `Proof.` in
muted gray, a thin slate rule down the left, and a QED square on its last
element. `name="of @thm-paired"` makes the title read `Proof (of Theorem 1).`
with the number resolved and linked back to the statement. Give the proof div no
id of its own: `#prf-` would number the proof as well, which nobody wants.
`.remark` and `.solution` arrive as `.proof` too and are the two that get no QED
square.

## Two things a future session would otherwise trip over

Quarto's crossref filter runs after `stage-slide.lua`, and the filter runs
citeproc itself, so citeproc sees `@thm-paired` inside that `name=` while it is
still a bare citation and prints `[WARNING] Citeproc: citation thm-paired not
found`. The reference resolves correctly afterwards; the warning is noise and
there is nothing to fix.

And the jump target is the appendix slide's own id (`ap-paired`), never the
theorem's (`thm-paired`), which belongs to a div inside a different slide.

## Why the numbering is Quarto's and not a CSS counter

Numbering is Quarto's and not a CSS counter, deliberately. reveal sets
`display: none` on every slide outside its view distance and a `display: none`
element does not increment a counter, so a counter would number results by where
the presenter happens to be standing. Same reason `stage-slide.lua` numbers the
section dividers in Lua.

## Budget for the box

At the 34px root a theorem box holding three lines of prose plus one display
equation is about 300px of the 700px canvas, so it leaves room for one paragraph
of consequence and an `.aside-note`, and nothing else. Anything longer takes the
two-slide treatment in the pedagogy patterns (`references/pedagogy.md`):
statement with color and a forward pointer, then one slide per term with the
intuition. Keep the proof off the lecture slide whichever way you go.
