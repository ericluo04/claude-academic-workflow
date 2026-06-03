# Domain whitelist — do not nuke legitimate econometrics / quant-marketing terms

Several delve-list words are also load-bearing technical vocabulary in empirical
social science. `/deslop` must NOT strip them when they are used in their
technical sense. This file is the tunable suppression list. Edit it to fit your
field (`--domain=marketing|econ|generic`).

## The whitelist (suppress the flag when used technically)

| Term | Technical meaning (KEEP) | Slop meaning (FLAG) |
|---|---|---|
| **robust** | robust standard errors; robustness check; heteroskedasticity-robust | "a robust solution", "robust growth" |
| **leverage** (noun) | regression leverage; hat values; high-leverage observations | "leverage a dataset", "leverage this insight" (verb → FLAG) |
| **significant** | statistically significant; significance level; p-value | "a significant milestone", "significantly impactful" |
| **comprehensive** | comprehensive controls; comprehensive appendix; comprehensive set of fixed effects | "comprehensive solution", "comprehensive overview" |
| **specification** | model specification; specification curve; specification check | (rarely slop) |
| **identification** | identification strategy; identifying assumption; point-identified | (rarely slop) |
| **estimand / estimator / estimate** | the target parameter; the estimator; the point estimate | (rarely slop) |
| **valid / validity** | internal/external validity; valid instrument; valid inference | "a valid point" |
| **interplay** | interplay between treatment and covariates (if specific) | "the interplay of forces" (vague → FLAG) |
| **nuanced** | a nuanced estimand / nuanced heterogeneity (if specific) | "a nuanced take" (vague → FLAG) |
| **key** | key identifying assumption; key parameter | "key takeaway", "plays a key role" |

## Anchor logic

A delve-list word is **SUPPRESSED** (not flagged) when it appears within a few
tokens (rough window: ±4 words) of one of these stats anchors:

```
standard errors    check              regression         diagnostic
p-value            identification     estimate           estimator
instrument         appendix           controls           specification
fixed effects      confidence interval   covariates      assumption
heteroskedastic    clustered          inference          treatment effect
```

Examples:

- "We report heteroskedasticity-**robust** standard errors" → SUPPRESS (anchor:
  "standard errors").
- "The model is **robust** to alternative **specifications**" → SUPPRESS
  (anchor: "specification").
- "Our **comprehensive** set of **controls**" → SUPPRESS (anchor: "controls").
- "high-**leverage** observations in the **regression**" → SUPPRESS (noun +
  anchor: "regression").
- "We **leverage** a rich dataset" → FLAG (verb sense, no stats anchor).
- "This robust framework delivers robust results" → FLAG (no anchor; promotional).

## Domain modes

- `--domain=econ` / `--domain=marketing` (default for this user): full whitelist
  above active. These fields use this vocabulary constantly.
- `--domain=generic`: relax the whitelist — only suppress when the stats anchor
  is *immediately* adjacent (±2 tokens). Use for emails, cover letters, and
  non-technical prose where "robust growth" really is puffery.

## Tuning

When the scrubber over-flags a legitimate term, add it (with its anchor set) to
the table above rather than weakening the global delve-list. Keep the slop
sense flaggable — the goal is precision, not blanket exemption.
