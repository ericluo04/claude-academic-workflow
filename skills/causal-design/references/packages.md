# Packages shared across the causal family

This file is the one place the version of a package used by two or more causal skills lives.
Each skill's own package index in `references/details.md` keeps the packages only that skill
uses, and for a shared package it keeps a skill-specific trap and a pointer here. On a refresh,
update the version and date here once.

Versions and CRAN publication dates re-checked against the CRAN package pages on 2026-10-08.
The versions are the ones the per-skill tier-1 workers ran their templates on that day.

| Package | Version | CRAN date | Used in | Trap that applies everywhere |
|---|---|---|---|---|
| fixest | 0.14.2 | 2026-06-26 | causal-design, did, iv | The formula reads regressors, then `\|` fixed effects, then `\|` the IV part, and the IV part must come last. `cluster` takes a one-sided formula (`~unit`), unlike estimatr's bare name. Units with no within variation in the treatment stay in the sample, the fixed-effect count, and the R2 without a message. |
| estimatr | 2.0.0 | 2026-09-16 | causal-design, field-experiment, conjoint | 2.0.0 is a ground-up rewrite by a new maintainer (Coppock), written with AI assistance per its NEWS. Signatures are kept except `horvitz_thompson`, and numbers match 1.x to 1e-12, so state the version in replication notes. The default variance is HC2 without clusters and CR2 with clusters. `clusters` takes a bare unquoted name, and `fixed_effects` (plural) takes a right-sided formula. |
| grf | 2.6.1 | 2026-03-04 | causal-design, field-experiment | Arguments are dot-separated (`num.trees`, `W.hat`), and the treatment argument is `W`. `clusters=` at fit time is what makes the ATE standard errors cluster-robust. RATE priorities must come from a held-out forest; the man page requires it and the signature does not enforce it. |
| marginaleffects | 1.0.0 | 2026-09-03 | causal-design, field-experiment | 1.0.0 removed `byfun` and `autodiff()`. There is no grf support, so forests use grf's own estimators. |
| sandwich | 3.1-3 | 2026-08-03 | causal-design, did, rdd, field-experiment | `vcovCL` takes the cluster as a formula (`~id`, multiway `~firm + year`). `vcovBS(type = "jackknife")` is a CRAN-resident CV3 route for linear models with no leverage diagnostics. |

Packages pinned in one skill only (did, HonestDiD, WeightIt, cobalt, and the rest) stay in that
skill's own index.
