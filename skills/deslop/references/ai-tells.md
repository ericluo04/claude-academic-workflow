# AI-writing tells — detection taxonomy

This is the tunable, versionable detection set for `/deslop`. The taxonomy is
derived from the Wikipedia essay **"Signs of AI writing"**
(<https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing>), CC BY-SA. The
delve-list and the stock-phrase set drift over time as models change — update
this file rather than hard-coding patterns into the skill prose.

Two principles run through everything below:

1. **Frequency, not presence.** A single em-dash, one legitimate triplet, one
   "additionally" is fine. The signal is density. Tune thresholds; do not zero
   out a construction just because it appears once.
2. **Domain whitelist wins.** Before flagging a delve-list word, check
   `domain-whitelist.md`. A word adjacent to a stats/econometrics anchor is
   suppressed (e.g. "robust standard errors", "leverage points", "significant
   at the 5% level" are NOT tells).

---

## MECHANICAL pass (regex / word-list — high precision, deterministic)

### 1. Delve-list vocabulary (flag by density; suppress on domain anchor)

Count occurrences across the text. Flag when density is high (rough rule:
more than ~1 per 200 words, or 3+ of these clustered in one paragraph). Always
run each candidate through the domain whitelist first.

```
delve            underscore       tapestry         pivotal
multifaceted     nuanced          realm            landscape
testament        navigate         foster           fostering
garner           showcase         showcasing       intricate
intricacies      meticulous       meticulously     vibrant
boast            boasts           bolster          enduring
enhance          enhancing        exemplifies      indelible
"deeply rooted"  leverage(verb)   align with       interplay
```

Notes:
- "leverage" as a **verb** ("leverage a dataset", "leverage this insight") is a
  tell. "leverage" as a **noun** in a regression sense (leverage points, hat
  values, high-leverage observations) is whitelisted — see `domain-whitelist.md`.
- "nuanced", "interplay", "key", "robust", "significant", "comprehensive",
  "specification", "identification", "valid/validity" are conditionally
  whitelisted near a stats anchor — they are legitimate quant-marketing /
  econometrics terms.

### 1b. Extended LLM-frequency vocabulary (PNAS 2026 — flag by density/context)

A PNAS (2026) study — <https://www.pnas.org/doi/10.1073/pnas.2605754123> —
compiled a large set of words whose frequency rose sharply in academic prose
after LLMs became widespread. Treat this as an EXTENSION of the delve-list in
§1, governed by the SAME two rules: flag by **density**, not single presence,
and **suppress legitimate technical/domain use**. A useful standing rule for this
list: the default is avoid, but a word that genuinely fits the situation is fine.

Many entries are ordinary academic vocabulary (frameworks, insights, broader,
primarily, thereby, alongside, interpretable, interpretability, notable, notably,
crucial, rigor, serves, validates) — do NOT auto-strip these. Flag only when they
cluster, or when used in the promotional/filler sense (e.g. "unlocks new
insights", "a seamless framework", "showcases the prowess of", "revolutionizing
the field", "underscores the pivotal role"). In pass 2, rewrite the filler sense
to plain fact; keep the technical sense.

```
achieves, achieving, acknowledges, adaptable, addressing, adept, adeptly,
adjustments, adjusts, advancements, advancing, advocating, aiding, align,
aligning, aligns, alongside, amidst, amplifies, avenues, boasting, boasts,
bolster, bolstering, bolsters, broader, capitalizes, captivating, captures,
capturing, categorizes, categorizing, commendable, complexities, complicates,
complicating, compromising, consolidates, contextualize, contextually,
cornerstone, crucial, culminating, delineates, delve, delved, delves, delving,
dependencies, diminishes, discernible, downturns, dynamically, elucidates,
elucidating, emphasising, emphasizes, emphasizing, employs, enabling,
encapsulates, encompass, encompassed, encompasses, encompassing, endeavors,
enhance, enhancements, enhances, enhancing, ensures, ensuring, equipping, equips,
escalate, escalating, exacerbates, exacerbating, exceeding, excelled, excelling,
excels, exemplifies, exhibits, facilitating, featuring, formidable, fortifying,
fostering, fosters, foundational, frameworks, garnered, garnering, grappling,
groundbreaking, harnessing, heighten, heightened, heightening, heightens,
highlighting, highlights, hinges, imperatives, inadequately, inadvertently,
incentivizes, incentivizing, incorporates, incorporating, inefficiencies,
inherently, insights, integrates, integrating, intensifies, intensifying,
interpretability, interpretable, intricacies, intricacy, intricate, intricately,
introduces, juncture, leverage, leverages, leveraging, meticulous, meticulously,
mitigate, mitigates, mitigating, multifaceted, navigates, navigating,
necessitate, necessitates, necessitating, notable, notably, nuanced, nuances,
offering, offers, outperforming, overlook, overlooking, overlooks, overreliance,
overseeing, oversight, oversimplify, paving, pinpointing, pivotal, poised,
posits, practicality, preserving, primarily, prioritise, prioritize, prioritizes,
prioritizing, promise, prowess, reaffirming, realm, redefines, refine, refines,
refining, reflecting, reinforces, reliance, renowned, reshapes, reshaping,
revolutionize, revolutionizing, rigor, safeguard, safeguarding, safeguards,
seamless, seamlessly, serves, showcases, showcasing, signifying, situates,
situating, sourced, strategically, streamline, streamlined, streamlining,
strengthens, struggle, stylistic, surpasses, surpassing, symbolizing, synthesizes,
thereby, thoroughness, thoughtfully, thrives, timelines, transcends,
transitioning, underexplored, undermines, underperform, underperformed, underpins,
underscore, underscored, underscores, underscoring, unlock, unlocking, utilizes,
validates, warranting, workflows
```

Domain note (quant-marketing / econometrics writing): several of these are
load-bearing and should be KEPT in the technical sense — "interpretable /
interpretability" (interpretable ML), "frameworks", "insights", "validates /
validation", "necessitate", "primarily", "thereby", "alongside". The §1 domain
whitelist still applies on top of this list (robust, leverage-noun, significant,
etc.). When unsure, prefer flagging in `--report` mode over silently rewriting.

### 2. Stock phrases (flag on match; near-always rewrite or cut)

```
"it's important to note that"      "it's worth noting"
"it's important to remember"       "in conclusion"
"in summary"                       "stands as a testament"
"serves as a reminder"             "plays a vital role"
"plays a pivotal role"             "plays a crucial role"
"in the heart of"                  "rich cultural heritage"
"diverse array"                    "in today's fast-paced world"
"evolving landscape"               "leaves an indelible mark"
"a rich tapestry of"               "commitment to excellence"
"groundbreaking"                   "in the realm of"
```

### 3. Negative parallelism (regex)

```
not only .* but
not just .* but
it'?s not .*,? it'?s
no .*, no .*, just
```

A single negative-parallel construction can be rhetorically fine; flag when 2+
appear, or when one appears in otherwise-plain technical prose where it reads as
ornament.

### 4. Vague attributions (flag; demand a named source or cut)

```
studies show              experts say
experts argue             observers have cited
some critics argue        industry reports
research suggests         it is widely regarded
several sources           modern researchers
scholarship describes
```

In academic prose these must resolve to a real `\citep{}` / named author or be
cut. Never invent a citation to satisfy the rule — flag and route to `/cite`.

### 5. Connective-opener overuse (flag by frequency)

Sentence-initial:

```
Additionally,    Moreover,    Furthermore,    Notably,    Importantly,
```

One or two across a long section is normal academic prose. Flag when the same
opener repeats, or when 3+ sentences in a paragraph start with a connective.

### 6. Trailing "-ing" significance clauses (regex)

```
, \w+ing .*\.$
```

Targets the "..., further enhancing its significance" / "..., highlighting the
broader implications" tail. These usually smuggle in unattributed opinion. Cut
the clause or convert to a direct claim.

### 7. AI-tool artifacts (HARD FAIL — near-certain, always strip)

These are machine remnants. Any match is a hard fail regardless of frequency.

```
oaicite            oai_citation       contentReference
:contentReference[ turn0search        turn0news
grok_card          attributableIndex  attached_file
```

Also: a stray `utm_source=` (or other tracking params) inside a cited URL —
strip the tracking suffix, keep the canonical URL.

### 8. Punctuation / formatting tells

- **Em-dash density.** Distinguish `—` (em) from `-` (hyphen) and `–` (en).
  Flag when `—` density exceeds ~1 per 150 words, or 2+ em-dashes in a single
  paragraph. Rewrite to commas, parentheses, or sentence splits — do not delete
  every em-dash; one well-placed em-dash is fine.
- **Curly quotes where straight expected.** In LaTeX / code / plain technical
  contexts, `“ ” ‘ ’` should usually be straight or LaTeX `` `` '' ``. Flag
  curly quotes that crept in from a word processor. (Do not "fix" quotes inside
  prose meant for typeset output where curly is correct — context-dependent.)
- **Bold-colon list pattern.** `**Bold label:** description` repeated down a
  list is an LLM formatting tic. Flag the pattern; in prose, convert to running
  sentences or a clean list without the bold-colon.
- **Title Case In Every Heading.** Headings where every major word is
  capitalized → convert to sentence case (capitalize first word + proper nouns
  only), unless the venue's style guide mandates title case.
- **Emoji in headings / section titles** → strip (academic context).
- **Thematic break before a heading.** A `---` horizontal rule immediately
  preceding a heading is an LLM artifact → remove.

### 9. Rule of three (flag triplet density)

Detect `X, Y, and Z` triplet constructions. A single substantive triplet is
fine. Flag when triplets cluster (the "comprehensive, robust, and scalable"
adjective-pile). In the semantic pass, prune the filler third item when it adds
no information.

---

## SEMANTIC pass (LLM judgment — applied in pass 2, in the user's voice)

- **Promotional / significance puffery → plain statement of fact.**
  "stands as a vibrant hub of innovation" → "is a town" (or whatever the fact
  actually is). "groundbreaking framework" → "framework".
- **Hedging filler → direct claim or deletion.** "It's important to note that
  the effect is positive" → "The effect is positive." (Note: keep the author's
  *substantive* hedges — the genuine epistemic qualifiers in their own voice
  samples — those are voice, not slop. Strip only the empty throat-clearing.)
- **Vague attribution → named source or cut.** "studies show" → `\citep{...}`
  or remove the claim.
- **AI cadence → the user's cadence.** Kill forced synonym-swapping / elegant
  variation (the lexical-diversity tic where the same noun is renamed every
  sentence to avoid repetition). Kill the "Challenges and Future Prospects"
  conclusion frame ("Despite its X, it faces challenges... but the future looks
  bright").
- **"is"-avoidance verb inflation → plain copula.** "serves as / stands as /
  boasts / represents / features / maintains" where the sentence just means
  "is" → use "is". Keep the inflated verb only when it carries real meaning.

---

## Anti-over-scrub guardrails (apply to BOTH passes)

- Frequency is the signal, not presence. Tune thresholds; never zero out a
  construction.
- **Preserve direct quotations and titles verbatim.** Never scrub inside a
  quoted passage or a paper / book title.
- **Preserve domain technical terms** (see `domain-whitelist.md`).
- **Never invent facts** to "improve" a sentence. If puffery is removed and the
  underlying fact is unknown, leave a neutral placeholder or flag it — do not
  fabricate.
- Preserve the author's genuine voice markers. The goal is to remove the
  machine's fingerprints, not to flatten the writer's own style.
