# Causal-design lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-28.

## The sensitivity ladder, in full (Imbens 2024)

Three graded options when unconfoundedness carries the identification; report at least one,
chosen by how much structure you are willing to impose.

- Manski bounds: drop unconfoundedness entirely and bound the estimand by the logically
  possible outcome ranges. With a binary outcome the bounds have width one and always
  include zero, so they are honest but usually uninformative; their value is stating what
  the data alone can say.
- Calibrated confounder models: posit an unobserved binary confounder, parameterize its
  association with assignment and with outcomes via log odds ratios, and trace the
  estimate over a plausible range (rosenbaum1983assessing). Imbens (2003) calibrates the
  range against the strongest observed covariate, which is the move reviewers accept. The
  modern reporting standard descends from this: Cinelli-Hazlett robustness values
  (cinelli2020making; sensemakr gives the minimal reporting table: RV, partial R2 of the
  treatment, bounds against 1x/2x/3x the benchmark covariate). sensemakr works on a linear
  model, so for a forest AIPW estimate its RV belongs to a linear proxy, and the methods
  paragraph says so. The bounds for the doubly robust estimate itself are Chernozhukov,
  Cinelli, Newey, Sharma, and Syrgkanis (chernozhukov2026long, "Long Story Short"). They
  bound the omitted-variable bias of ATEs and other linear functionals by the explanatory
  power of the omitted variables. Python DoubleML implements them as sensitivity_analysis()
  (checked in the DoubleML 0.11 user guide); R DoubleML 1.0.2 has no equivalent.
- Oster's delta (oster2019unobservable) is dropped from the family's reporting standards.
  Masten and Poirier (masten2026effect) show that it can be much easier for omitted
  variables to flip a coefficient's sign than to drive it to zero. Whenever Oster's delta is
  large, a much smaller value already reverses the sign. Oster's delta assumes the omitted
  variables are uncorrelated with the included controls. Diegert, Masten, and Poirier
  (diegert2022assessing) give a sensitivity analysis that drops that assumption. Both papers
  implement their measures in the Stata module regsensitivity. When a coauthor or referee
  asks for Oster's delta, cite these two papers and report the Cinelli-Hazlett values.
- Rosenbaum sensitivity bounds (rosenbaum2002observational, ch. 4): bound only the odds of
  assignment (the Gamma parameter), leave the outcome association unrestricted; matched
  designs report the Gamma at which significance is lost. "Design sensitivity" is a
  different object, the limiting Gamma as the sample grows (rosenbaum2004design).

Failure semantics: an estimate that flips sign or loses significance under mild calibrated
confounding indicts the design; do not respond by switching estimators. M-bias from
conditioning on colliders is possible in principle but has produced few clear empirical
mistakes in economics (Imbens); the descendant rule catches the common error.

## Selection-on-observables facts worth citing

- Doubly robust = consistent if EITHER the outcome model or the propensity model is
  consistent (the AIPW estimator is robins1994estimation; bang2005doubly named the
  property). Slow ML-rate nuisances are allowed with cross-fitting when the product of the two
  error rates is o(n^-1/2), for example n^-1/4 each (chernozhukov2018double). grf meets this
  through out-of-bag nuisance predictions; a hand-rolled AIPW needs sample splitting.
- Fixed-number-of-matches matching is never fully efficient. With k continuous covariates
  its bias is of order N^(-1/k). With two or more, the bias does not vanish at the root-N
  rate and is no longer negligible against the standard error, so the estimator is not
  root-N consistent in general (abadie2006large);
  bias-corrected matching with a growing number of matches restores the efficiency bound.
- Weighting by the true propensity score is inefficient relative to the estimated one
  (hirano2003efficient); use the estimated score even in simulations.
- Overlap: the Crump et al. variance-minimizing trimming rule, commonly approximated by
  dropping units with estimated scores outside [0.1, 0.9] (crump2009dealing); overlap
  weights e(x)(1-e(x)) shift the estimand to the population with genuine treatment
  ambiguity (li2018balancing), often the policy-relevant one in targeting applications.
- PSM in marketing: used "for decades," now "called into question due to the technique's
  sensitivity to parametric assumptions" (AMA, citing Athey-Imbens); field replacements
  are AIPW, double ML, causal forests.
- Adaptive experiments: naive sample means are biased under adaptive assignment because
  adaptivity truncates the losing arms' samples early (Imbens 2024). The analysis route for
  bandit-collected data is adaptive weighting (hadad2021confidence). Hadad, Hirshberg, Zhan,
  Wager, and Athey reweight AIPW scores so that the test statistic is asymptotically
  unbiased and normal under weak conditions on the adaptive design. The CRAN package
  banditsCI (1.0.0) implements it. The design-side exits stay: a final non-adaptive
  confirmatory phase, or analysis restricted to a uniform-assignment holdout. field-experiment
  owns the design decision.
- Surrogate index (athey2026surrogate): estimate the relation of long-run outcome to
  surrogates in observational data, apply it to experimental surrogate movements. It needs
  three assumptions, each to argue and each a limitation to state: unconfoundedness in the
  experiment, surrogacy (all causal paths from treatment to the long-run outcome pass
  through the measured surrogates), and comparability of the experimental and observational
  samples. The
  family ships no estimation template; Athey, Chetty, Imbens, and Kang's own empirical
  implementation is the recipe, and the deliverable stops at the validity argument.

## Plain panel fixed effects: the Mixtape's Table 8.2 columns

The Mixtape (Cunningham, The Mixtape, online ch. 8) presents columns 3 and 4 of
its Table 8.2, from Cornwell and Rupert (1997), which add job tenure and then
quadratics in years married and walk the marriage premium from the column 1 FGLS 0.083 to
0.033, as evidence about time-varying unobserved heterogeneity. Under this skill's rule those
columns are inadmissible, because years married and job tenure are plausibly consequences of
marriage, so they condition on descendants of the treatment, which is verbatim the error
Imbens (2024) calls the most common one.

The chapter assumes constant effects and declares that scope. A non-absorbing time-varying
treatment with heterogeneous effects has left it, the implicit weighting is live, and the dCDH
weight diagnostic in did applies. Random effects, Mundlak-Chamberlain devices, and dynamic
panel estimators stay out, and Wooldridge (2010) is the shelf for them.

## SDID inference by data shape (pointer)

The authoritative statement lives in synthetic-control's details, absorbed there from the
AMA piece with "permutation" mapped to the placebo estimator.

## The AMA exemplar table (method -> published marketing application)

Use these to argue a method is accepted practice in marketing journals.

| Method | Application |
|---|---|
| DiD | no marketing exemplar in the AMA piece (it cites Cao, Chintagunta, Li 2023 JMR and Ghose et al. 2024 JMR as randomized experiments); stacked-regression sources Cengiz et al. 2019 QJE, Gormley and Matsa 2011 RFS |
| Factor models / gsynth | physician payment disclosure and prescribing (Guo, Sriram, Manchanda 2020 MktSci); newspaper paywalls (Pattabhiramaiah, Sriram, Manchanda 2019 JM); advertising and earned word of mouth (Lovett, Peres, Xu 2019) |
| Synthetic DiD | TV advertising and online sales (Lambrecht, Tucker, Zhang 2024); soda taxes and marketing conduct (Keller, Guyt, Grewal 2024) |
| Matrix completion | misinformation and the brand premium (Bronnenberg, Dube, Sanders 2020) |
| AIPW | advertising measurement at Facebook (Gordon et al. 2019 MktSci) |
| Causal forest | information disclosure and industry payments to physicians (Guo, Sriram, Manchanda 2021 JMR); restaurant survival from consumer photos (Zhang, Luo 2023); digital-engagement spillovers on print subscriptions (Pattabhiramaiah, Overby, Xu 2022); targeted campaigns (Ellickson, Kar, Reeder 2023) |
| Augmented DiD | Li and Van den Bulte 2023 (MktSci) |
| Forward DiD | Li 2024 (MktSci Frontiers) |

These are the AMA piece's citations, not bib entries of this family; pull the full
references from the piece when one is needed in a paper.

## Interference routing (pointer)

Designs, estimators, and diagnostics live in field-experiment.

- Clustered interference: two-stage randomization over clusters (hudgens2008toward,
  crepon2013labor).
- Network interference: exposure mappings (aronow2017estimating) with exact tests of the
  sharp null (athey2018exact).
- Marketplaces and two-sided platforms: multiple randomization designs over buyer-seller
  pairs (bajari2023experimental, johari2022experimental).
- The 61-million-person Facebook voting experiment (Bond et al. 2012) is the scale anchor
  for network experiments; cite from Imbens 2024.

## Marketing vocabulary glossary (AMA; write for reviewers in these terms)

- Design rigor vs statistical rigor: randomization buys the former; quasi-experimental
  methods compensate with the latter.
- Clean controls: comparison units never treated (or not-yet-treated) during the
  estimation window; staggered designs must justify them.
- False precision / false imprecision: CIs too narrow / too wide from an inference
  procedure the data shape does not support (the Li-Sonnier gsynth bootstrap result).
- ATT-first: marketing quasi-experiments default to the effect on the treated, matching
  what the panel estimators identify.
- Parallel trends "is a statement about the treatment counterfactual": only its
  pretreatment shadow is testable, by visual inspection plus statistical tests.
- SUTVA decomposed for marketers: no interference (a state law must not move control-state
  outcomes) and no hidden treatment versions; justified by "logical argumentation based on
  institutional knowledge."

## Text-role warnings (Feder; detail behind the fourth triage question)

- Confounder: conditional ignorability becomes "the NLP model measured all confounding
  aspects of the text," untestable, argued from domain expertise. Positivity audit: if the
  representation predicts treatment nearly perfectly, overlap has failed; narrow the
  estimand or re-specify. The family's revision: the banned part of Feder's recommended
  Veitch-style fine-tuning is the treatment-prediction loss (GPI's own deconfounder trains
  on the outcome loss). The dispute, the replacement, and the TI-estimator carve-out belong
  to the text-causal literature and are out of scope for this skill.
- Outcome: consistency fails when the measurement model was trained on all the data (each
  unit's inferred outcome then depends on other units' treatments); split-sample
  measurement is the fix (egami2022make; this is Feder's consistency framing of the rule
  stated authoritatively as the FPCILV). Randomizing treatment fixes ignorability and
  positivity here, not consistency.
- Treatment: treatment discovery vs prespecified latent aspects; disentangle the aspect
  from correlated aspects of the same text; random assignment of texts leaves reader-side
  confounding.
- No real-world ground-truth causal benchmarks exist for text; semi-synthetic benchmark
  wins never validate a real estimate.
- Deployment shift tests (invariance: perturb what should not matter, predictions must not
  move; sensitivity: minimal label-flipping edits, predictions must move) belong to the
  diagnostics battery for the measurement model, run before it feeds a causal estimate.

## Package index (CRAN versions re-checked 2026-10-08; the observables and plain-FE branches only, method skills carry their own; the version list for this skill's own packages, which scripts/unconfoundedness_template.R points to; shared packages such as grf and marginaleffects are pinned in packages.md)

| Tool | Version | Role | Traps |
|---|---|---|---|
| policytree | 1.2.5 | double_robust_scores(forest) -> policy_tree(X, Gamma, depth = 2) | Gamma columns = actions in order (1 control, 2 treated); predict returns the column index, not 0/1; exact search exponential in depth |
| sensemakr | 0.1.6 | Cinelli-Hazlett sensitivity: robustness values, benchmark bounds, ovb_minimal_reporting (latex/html) | treatment looked up by coefficient name, so factor treatments FAIL (undocumented, in source): code treatment numeric 0/1; kd defaults to 1, pass kd = 1:3 for the standard table; lm objects (the fixest method is GitHub only, not on CRAN 0.1.6); works on a linear model, so for a forest AIPW estimate the RV belongs to a linear proxy (DR route: Python DoubleML sensitivity_analysis()) |
| WeightIt | 2.1.0 | balancing weights, estimand = "ATO" for overlap weights (method = "glm") | ATO not available for every method (check ?method_<name>); downstream is lm_weightit/glm_weightit + marginaleffects::avg_comparisons (M-estimation SEs account for estimated weights); plain lm + vcovCL treats weights as fixed; keep.mparts=TRUE default enables the M-estimation SEs |
| cobalt | 5.0.0 | bal.tab(w) balance table after weighting (standardized mean differences, KS) | thresholds = c(m = .1) flags imbalance at the conventional 0.1 SMD; takes the weightit object directly |
| DoubleML | 1.0.2 | explicit double/debiased ML when nuisance-learner control is wanted (mlr3) | heavier setup; the grf route covers the default DR case |
| MatchIt | 4.8.1 | matching as preprocessing when a matched design is wanted | same author ecosystem as WeightIt; matching never fully efficient (Imbens), prefer DR estimation after |

Shared with other causal skills: grf, marginaleffects, estimatr, fixest, and sandwich. Versions
and the family-wide traps are in packages.md. Traps specific to this skill: grf's
target.sample = "overlap" is the Li-Morgan-Zaslavsky ATO and the documented poor-overlap
fallback, and hist(cf$W.hat) is the documented overlap check. marginaleffects runs
g-computation on weightit fits. estimatr's lm_robust(y ~ d, fixed_effects = ~unit,
clusters = unit, se_type = "stata") is the within fit with Stata's FE standard errors, where
se_type = "stata" means HC1 without clusters and Stata's cluster-robust variant with them. The
Mixtape's own FE call (online ch. 8 sec. 8.1, sex-work R code) has no clusters argument
(only its demeaned OLS call has `clusters = id`), and its `fixed_effect = ~id` runs only
because R partial-matches the name.
fixest's feols(y ~ d | unit, cluster = ~unit) is the plain-FE fit, and the plain-FE section of
SKILL.md runs the zero-variance count first because fixest keeps units with no within
variation without a message.

Docs: grf-labs.github.io/grf, grf-labs.github.io/policytree, carloscinelli.com/sensemakr,
ngreifer.github.io/WeightIt, marginaleffects.com.

Clustered-SE incantation on any plain lm: lmtest::coeftest(fit, vcov =
sandwich::vcovCL(fit, cluster = ~ id)) with cluster as a formula (multiway: ~ firm + year);
default type HC1 for lm objects.
