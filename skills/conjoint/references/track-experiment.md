# Conjoint: the randomized-experiment track

Loaded from SKILL.md (section "Estimation: the randomized-experiment track"). The sections
below moved from SKILL.md on 2026-10-09 without rewording, except one "above" that now
names SKILL.md, section "Estimands". Paths to this skill's files start at the skill root, as
in SKILL.md. Paths to other skills are relative to this file.

## Interactions: the AMIE, full statement

- Interactions BETWEEN attributes get their own estimand, the AMIE (Egami and Imai 2019).
  A regression interaction coefficient estimates the conventional interaction effect,
  whose relative magnitude depends on which level was named the baseline, and conjoint
  attributes (gender, religion, occupation) rarely have a natural one. The mechanical
  consequence is sharper than the interpretive one: any conventional interaction involving
  a baseline level is identically zero, so an arbitrary coding decision blanks out a row
  and a column of the interaction table. The AMIE subtracts the two AMEs instead of
  conditioning at baseline, which makes relative magnitudes baseline-invariant, decomposes
  any treatment-combination effect into main effects plus interactions of every order with
  no residual, and returns the conditional effect of one attribute at a level of another as
  AME plus AMIE. It marginalizes, so it carries the same averaging-distribution discipline
  as the AMCE. This is the quantity inside the uAMCE-pAMCE gap (SKILL.md, "Estimands"):
  when that gap is what routes you to the pAMCE, the AMIE is what says which interactions
  and how large. Testing
  whether ANY interaction exists is baseline-free either way, since all AMIEs are zero
  exactly when all conventional interactions are, so the global F-test can use either.

## Design-based pAMCE randomization

- When a target distribution is defensible, prefer design-based pAMCE randomization: the
  three-design ladder (joint, marginal, mixed) keyed to what population data exist, with
  the effective-sample-size check run before fielding (de la Cuesta, Egami, and Imai
  2022; ladder details and the ESS formula in references/details.md).

## Estimation and inference

- One OLS of the choice indicator on all attribute dummies (reference level omitted per
  attribute) gives every AMCE at once; nonparametric despite the OLS routine. Standard
  errors cluster by respondent, always. The reason is the sampling design: respondents are
  the sampled units, and every task and profile is drawn within a respondent, so the
  respondent is the cluster at which the sample was drawn (the design rule in
  ../../causal-design/references/shared-rules.md, section "Clustering"). Within-respondent
  correlation in outcomes is a consequence of that design (Hainmueller, Hopkins, and
  Yamamoto 2014 cluster by respondent as well). With hundreds of respondents, CR2
  clustered SEs are adequate. With few respondents (a pilot) or very unbalanced task
  counts across respondents, the family's small-G rule governs: CV3 with the wild cluster
  restricted bootstrap, CR2 as the cross-check (shared-rules.md, section "Clustering").
  The template's
  hand-rolled sections run this regression on the profile-stacked HHY structure with
  clustered SEs, valid because it is the estimator HHY themselves use; choice-level
  analysis remains the skill's default for choice modeling.
- Under restricted or weighted (dependent) randomization, plain dummies silently change
  the estimand: include the linked-attribute interactions and report the probability-
  weighted coefficient combination over admissible strata (the eq. 9 machinery; worked
  form in references/details.md).
- Measurement error: never assume it away. Shown the identical task twice, respondents
  agree with themselves only about 75% of the time in every study examined (IRR 73 to
  81% across eight from-scratch replications), which attenuates every AMCE by roughly
  30% (the factor 1 - 2*tau at tau near 0.15) and can flip subgroup differences
  (Clayton et al. 2026). Estimate IRR (repeated task; for existing data, extrapolate
  from task-pair agreement; or borrow with sensitivity), correct via projoint, and
  report both raw and corrected estimates. The correction is for binary forced choice
  ONLY; refuse to extend it to ratings, rankings, or choose-one-of-many, citing the
  authors' own warning. A write-up reporting no IRR is assuming tau = 0, which was
  false everywhere it has been checked.
- Multiple testing: never report an uncorrected forest of AMCE stars. Under a global
  null at a realistic design size (41 tests), the standard pipeline yields at least one
  significant AMCE in over 90% of experiments (Liu and Shiraito 2023). The family rule
  applies (../../causal-design/references/shared-rules.md, section "Multiplicity, staged by
  what a false positive costs"). For
  screening, adaptive shrinkage (ashr) on the estimates and clustered SEs when priors about
  which effects exist are weak, or Benjamini-Hochberg at the family's FDR level, q = .10.
  For confirmatory work with a preregistered family, Romano-Wolf stepdown with the
  respondent block bootstrap is the default, because AMCEs estimated on the same
  respondents are correlated tests and resampling recovers the power Holm gives up. Holm
  is the fallback where the bootstrap is impractical. Corrected and uncorrected shown
  side by side, every status change discussed. Never plain Bonferroni. Screening uses plain
  BH; the adaptive BKY variant is not used. BH controls FDR under positive regression
  dependence on a subset (PRDS; Benjamini and Yekutieli 2001). BKY proved control under
  independence and showed positive dependence only by simulation (Benjamini, Krieger, and
  Yekutieli 2006). That AMCE tests satisfy PRDS is the skill's judgment and is unproven.
  The reasoning: levels of one attribute share a reference marginal mean, so their
  estimates correlate positively. Across attributes, independent randomization leaves
  correlations near zero. A latent screen over machine-generated candidates is the case
  that flips the choice. Composing the tau correction with the
  multiple-testing correction is mechanically fine (ash consumes any estimate-SE pairs)
  but unstudied; label the combination as our own judgment.
- Interaction search is a worse multiplicity problem than the AMCE forest (every level pair
  across every factor pair), and it takes a different instrument. Regularize the estimates
  and report bootstrap selection probabilities instead of corrected p-values (Egami and Imai
  2019, who decline family-wise error control explicitly and use a 90% selection cutoff).
  Valid inference after level collapsing is unsolved, so a confirmatory interaction claim
  needs a held-out half: collapse and select on one, estimate and build intervals on the
  other. Screening this way is exploratory by construction, and the write-up says so.
- Subgroups, the danger zone twice over. For preference description: differences in
  conditional AMCEs conflate preferences with feelings about the arbitrary reference
  category, so their sign, size, and significance are artifacts (Leeper, Hobolt, and
  Tilley 2020). Estimate conditional marginal means, difference those, and test
  "groups agree overall" with the nested-model F over group-by-level interactions. For
  measurement error: IRR varies by respondent characteristics, so correct each
  subgroup with its own tau before differencing; roughly 5% of subgroup differences
  flipped sign under correction (Clayton et al. 2026).
- Individual-level heterogeneity, when the subgroups are not known in advance. Zhirkov
  (2022) estimates respondent-specific marginal component effects (IMCEs) with no added
  assumptions, and he recommends some changes to the task design. Robinson and Duch
  (2024) estimate IMCEs by BART and partition them afterward to find the subgroups (CRAN
  package cjbart). The skill's judgment: treat both as exploratory description, and
  confirm a subgroup found this way by conditional marginal means on fresh data or a
  held-out half.
