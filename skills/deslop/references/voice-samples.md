# Voice samples

The semantic pass (pass 2) rewrites AI-cadence prose into *your* cadence, in the
register that matches the input. `/deslop` auto-selects ONE of the two registers
below per the SKILL.md "Voice register" section (or honors `--voice=`), then
grounds the rewrite in that register's samples. Until a register is populated, it
falls back to your configured voice reference
(`personal_config.user.voice_style_ref`).

Keep each register to a few hundred words — quality over quantity. The skill reads
this file on every invocation, so updating it is the fastest way to retune.

---

## Register 1 — Correspondence (emails, short messages, cover letters)

> **Paste 2–4 short samples of your writing in this register here** — a couple of
> emails you sent that sound like you, a cover-letter paragraph, a note or reply.
> Until populated, this register falls back to
> `personal_config.user.voice_style_ref`.

Good samples to paste: a short email you're happy with; a passage where your
greeting / sign-off, hedging, and warmth are characteristic. Optionally note any
personal punctuation convention (e.g. a spaced hyphen instead of an em-dash) so
the register-conditional punctuation rule can honor it.

### Sample 1

<!-- paste here -->

### Sample 2

<!-- paste here -->

---

## Register 2 — Manuscript / grant (papers, sections, abstracts, proposals)

> **Paste 2–4 short samples of your formal academic writing here** — a paragraph
> from a paper intro / method / discussion, an abstract, a grant paragraph.
> Until populated, this register falls back to
> `personal_config.user.voice_style_ref` (the same reference `/draft` uses).

Good samples to paste: a paragraph you wrote and are happy with; a passage where
your hedging, sentence rhythm, citation style, and emphasis conventions are
characteristic. Em-/en-dashes in this register follow standard academic usage.

### Sample 1

<!-- paste here -->

### Sample 2

<!-- paste here -->
