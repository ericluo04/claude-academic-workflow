# Synthetic-control canon

Current as of 2026-07-28. These sources are hand-picked; nothing enters this file without
explicit human approval. BibTeX keys point into ../../causal-design/references/causal.bib.
Refresh: litreview on the method since the date above, results proposed as flagged addenda.

## Abadie (2021)

Journal of Economic Literature 59(2): 391-425. Key: `abadie2021using`.

- Role: the practice manual by the method's originator; feasibility conditions, diagnostics,
  and the when-to-walk-away rules.
- Settles: the counterfactual is a convex donor combination (no extrapolation, sparse,
  nameable weights) while panel regression is implicitly SC with silently negative weights;
  DiD is the constant-loadings special case of the SC factor model; the bias bound holds
  under near-perfect predictor fit, so poor pre-fit means do not use SC and a long T0 does
  not rescue it; short-T0 or noisy-outcome fit can be overfitting, and a larger donor pool
  makes that easier; donor discipline (exclude own-intervention, shocked, and dissimilar
  units); predictors are pre-outcomes plus covariates, never pre-outcomes alone; V by
  cross-validation with non-uniqueness disclosed; weights are computable pre-post and can be
  locked like a pre-analysis plan; inference is design-based permutation on the post/pre
  RMSPE ratio with p floor 1/(J+1) and the spaghetti plot mandatory; backdating and
  leave-one-out are the standing placebos; spillover-exposed donors are dropped or the bias
  is signed and the estimate read as a bound; extensions map (penalized, bias-corrected,
  SDID, matrix completion, conformal/prediction intervals).
- Binds when: any SC analysis; the feasibility verdict; every diagnostics choice.
- Implement: names methods, not software; the package mapping (Synth/tidysynth/SCtools,
  augsynth, pensynth, synthdid, scpi, gsynth/fect, CausalImpact, scinference) is ours, in
  references/details.md.
- Quote: including units the analyst regards as unsuitable controls "is a recipe for bias";
  SC weights "can play a role similar to pre-analysis plans in randomized control trials";
  the recommendation against SC when the predictor-fit discrepancy is large.

## Arkhangelsky and Imbens (2024), boundary sections

Shared canon with did (key: `arkhangelsky2024causal`; full entry in the did skill's canon).
What this skill takes from it:

- The unified view: unconfoundedness regression, SC, DiD, and nuclear-norm matrix completion
  solve one imputation objective under different restrictions, so divergence across them is a
  diagnostic, not a nuisance.
- SDID = TWFE plus SC unit weights plus analogous time weights; in simulations calibrated to
  real panels it typically outperforms DiD, SC, and MC-NNM.
- The routing result: under selection on lagged outcomes with autocorrelated errors, DiD is
  inconsistent even with a long pre-period while SC is consistent (Arkhangelsky-Hirshberg).
  This is the citable rule for choosing SC over DiD when units select on recent outcomes.
- The backdating caveat: placebo-in-time assumes strict exogeneity and backfires under
  selection on past shocks.
- Frame guidance: single treated unit in a square/fat panel is SC territory; block assignment
  with both dimensions modestly large favors SDID/MC/IFE over TWFE; staggered adoption
  forecloses standard SC.

## Named positions the skill carries

1. Ferman-Pinto (imperfect pretreatment fit; demeaned SC) are the loyal opposition inside the
   canon: SC's properties degrade under imperfect fit, and demeaning moves the estimator
   toward DiD logic. The skill's response is the Abadie line (walk away or bias-correct) plus
   the SDID bridge, with the Ferman-Pinto caveat cited when fit is marginal.
2. A&I vs AAFP on whether to move past TWFE at all is carried in the did skill; here it only
   surfaces as the reason SDID and factor methods get a seat at the table.

## Primary papers cited through the canon

Resolver-verified entries in causal.bib (see the synthetic-control block there for keys and
PREPRINT flags): Abadie-Gardeazabal 2003 (origin); Abadie-Diamond-Hainmueller 2010 (the
estimator, bias bound, permutation inference) and 2015 (cross-validated V, in-time placebo,
reunification); Abadie-L'Hour 2021 (penalized SC); Ben-Michael-Feller-Rothstein 2021
(augmented SC); Arkhangelsky et al. 2021 (synthetic DiD); Athey et al. 2021 (matrix
completion); Xu 2017 (generalized SC / IFE); Doudchenko-Imbens 2016 (the synthesis, elastic
net); Ferman-Pinto 2021 (imperfect fit); Chernozhukov-Wuthrich-Zhu 2021 (conformal);
Cattaneo-Feng-Titiunik 2021 (prediction intervals); Brodersen et al. 2015 (BSTS /
CausalImpact); Firpo-Possebom 2018 (sensitivity, confidence sets); Heckman-Hotz 1989
(preprogram test); Amjad-Shah-Shen 2018 (robust SC denoising); Athey-Imbens 2017 (the
"most important innovation" framing); Klossner et al. 2018 (V non-uniqueness); Liu-Wang-Xu
2024 (counterfactual estimators guide, fect).
