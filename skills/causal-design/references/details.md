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
  modern reporting standards descend from this: Oster's coefficient-stability delta
  (oster2019unobservable; note it assumes proportional selection and R-squared targets,
  state both), Cinelli-Hazlett robustness values (cinelli2020making; sensemakr gives the
  minimal reporting table: RV, partial R2 of the treatment, bounds against 1x/2x/3x the
  benchmark covariate), plus Masten-Poirier and Chernozhukov et al. long-story bounds as
  further options.
- Rosenbaum design sensitivity (rosenbaum2002observational): bound only the odds of
  assignment (the Gamma parameter), leave the outcome association unrestricted; matched
  designs report the Gamma at which significance is lost.

Failure semantics: an estimate that flips sign or loses significance under mild calibrated
confounding indicts the design; do not respond by switching estimators. M-bias from
conditioning on colliders is possible in principle but has produced few clear empirical
mistakes in economics (Imbens); the descendant rule catches the common error.

## Selection-on-observables facts worth citing

- Doubly robust = consistent if EITHER the outcome model or the propensity model is
  consistent; tolerates slow (ML-rate) convergence of both nuisances (Imbens 2024, on
  bang2005doubly and the DML literature).
- Fixed-number-of-matches matching is never fully efficient, and with many covariates its
  bias does not vanish asymptotically (Abadie-Imbens 2006, via Imbens 2024);
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
  adaptivity truncates the losing arms' samples early (Imbens 2024). The family has NO
  analysis route for bandit-collected data; the adaptive-reweighting literature is outside
  the canon. Practical exits: a final non-adaptive confirmatory phase, or restricting
  analysis to a uniform-assignment holdout.
- Surrogate index (athey2026surrogate): estimate the relation of long-run outcome to
  surrogates in observational data, apply it to experimental surrogate movements; valid
  only when all causal paths from treatment to the long-run outcome pass through the
  measured surrogates, which is the assumption to argue and the limitation to state. The
  family ships no estimation template; Athey, Chetty, Imbens, and Kang's own empirical
  implementation is the recipe, and the deliverable stops at the validity argument.

## SDID inference by data shape (pointer)

The authoritative statement lives in synthetic-control's details, absorbed there from the
AMA piece with "permutation" mapped to the placebo estimator.

## The AMA exemplar table (method -> published marketing application)

Use these to argue a method is accepted practice in marketing journals.

| Method | Application |
|---|---|
| DiD | app monetization free-to-paid (Cao, Chintagunta, Li 2023 JM); nudges on purchases and returns (Ghose et al. 2024) |
| Factor models / gsynth | physician payment disclosure and prescribing (Guo, Sriram, Manchanda 2020 MktSci); newspaper paywalls (Pattabhiramaiah, Sriram, Manchanda 2019 MktSci); advertising and earned word of mouth (Lovett, Peres, Xu 2019) |
| Synthetic DiD | TV advertising and online sales (Lambrecht, Tucker, Zhang 2024); soda taxes and marketing conduct (Keller, Guyts, Grewal 2024) |
| Matrix completion | misinformation and the brand premium (Bronnenberg, Dube, Sanders 2020) |
| AIPW | advertising measurement at Facebook (Gordon et al. 2019 MktSci) |
| Causal forest | restaurant survival from consumer photos (Zhang, Luo 2023); digital-engagement spillovers on print subscriptions (Pattabhiramaiah, Overby, Xu 2022); targeted campaigns (Ellickson, Kar, Reeder 2023) |
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
  on the outcome loss); the dispute, the replacement, and the TI-estimator carve-out live
  in causal-unstructured.
- Outcome: consistency fails when the measurement model was trained on all the data (each
  unit's inferred outcome then depends on other units' treatments); split-sample
  measurement is the fix (egami2022make; this is Feder's consistency framing of the rule
  whose authoritative statement, the FPCILV, lives in causal-unstructured). Randomizing
  treatment fixes ignorability and positivity here, not consistency.
- Treatment: treatment discovery vs prespecified latent aspects; disentangle the aspect
  from correlated aspects of the same text; random assignment of texts leaves reader-side
  confounding.
- No real-world ground-truth causal benchmarks exist for text; semi-synthetic benchmark
  wins never validate a real estimate.
- Deployment shift tests (invariance: perturb what should not matter, predictions must not
  move; sensitivity: minimal label-flipping edits, predictions must move) now live in
  causal-unstructured's diagnostics battery; this line is a pointer.

## Package index (verified against docs/source 2026-07-28, CRAN versions re-checked 2026-08-26; the observables and plain-FE branches only, method skills carry their own)

| Tool | Version | Role | Traps |
|---|---|---|---|
| grf | 2.6.1 | causal_forest + average_treatment_effect (AIPW default, TMLE binary-only option); best_linear_projection (HC3); rank_average_treatment_effect; policy scores | treatment argument is W; clusters= at FIT time is what makes ATE SEs cluster-robust; target.sample="overlap" = Li-Morgan-Zaslavsky ATO, the documented poor-overlap fallback; RATE priorities need a held-out forest; hist(cf$W.hat) is the documented overlap check (pinned also in field-experiment's details; update the two pins together on refresh) |
| policytree | 1.2.5 | double_robust_scores(forest) -> policy_tree(X, Gamma, depth = 2) | Gamma columns = actions in order (1 control, 2 treated); predict returns the column index, not 0/1; exact search exponential in depth |
| sensemakr | 0.1.6 | Cinelli-Hazlett sensitivity: robustness values, benchmark bounds, ovb_minimal_reporting (latex/html) | treatment looked up by coefficient name, so factor treatments FAIL (undocumented, in source): code treatment numeric 0/1; kd defaults to 1, pass kd = 1:3 for the standard table; lm objects (fixest method on GitHub) |
| WeightIt | 2.0.0 | balancing weights, estimand = "ATO" for overlap weights (method = "glm") | ATO not available for every method (check ?method_<name>); downstream is lm_weightit/glm_weightit + marginaleffects::avg_comparisons (M-estimation SEs account for estimated weights); plain lm + vcovCL treats weights as fixed; keep.mparts=TRUE default enables the M-estimation SEs |
| marginaleffects | 0.32.0 | g-computation/contrasts on weightit fits (native support) | no grf support; use grf's own estimators for forests (pinned also in field-experiment's details; update the two pins together on refresh) |
| DoubleML | 1.0.2 | explicit double/debiased ML when nuisance-learner control is wanted (mlr3) | heavier setup; the grf route covers the default DR case |
| MatchIt | 4.7.2 | matching as preprocessing when a matched design is wanted | same author ecosystem as WeightIt; matching never fully efficient (Imbens), prefer DR estimation after |
| estimatr | 1.0.6 | lm_robust with HC/CR SEs (shared with field-experiment); lm_robust(y ~ d, fixed_effects = ~unit, clusters = unit, se_type = "stata") is the within fit with Stata's FE standard errors, the Mixtape's own route | design-based defaults; already the family's experiment workhorse (pinned also in field-experiment's details; update the two pins together on refresh); the argument is fixed_effectS, and the Mixtape's `fixed_effect = ~id` runs only because lm_robust has no dots and R partial-matches the name; clusters takes a BARE unquoted name while fixed_effects takes a right-sided formula; se_type = "stata" means HC1 when clusters is absent and Stata's cluster-robust variant when it is present, so it matches xtreg, fe only with clusters supplied (the default is HC2 without clusters and CR2 with) |
| fixest | 0.14.2 | feols for the within estimator on a time-varying treatment: feols(y ~ d \| unit, cluster = ~unit); etable() prints pooled OLS and within side by side (the plain-panel-fixed-effects section of SKILL.md) | the bar separates fixed effects from regressors, so the treatment stays to its left; cluster takes a formula (~unit), unlike estimatr's bare name; units with no within variation in d are absorbed and dropped without a message, which is why that section runs the zero-variance count first |

Docs: grf-labs.github.io/grf, grf-labs.github.io/policytree, carloscinelli.com/sensemakr,
ngreifer.github.io/WeightIt, marginaleffects.com.

Clustered-SE incantation on any plain lm: lmtest::coeftest(fit, vcov =
sandwich::vcovCL(fit, cluster = ~ id)) with cluster as a formula (multiway: ~ firm + year);
default type HC1 for lm objects.
