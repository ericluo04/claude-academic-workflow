# Synthetic-control canon

Current as of 2026-10-09. The user picked these sources. BibTeX keys point into
../../causal-design/references/causal.bib.
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

Added 2026-08-26 from the Mixtape's synthetic-control chapter (Cunningham, The Mixtape, online
ch. 11), Crossref-verified, keys merged into causal.bib: Ferman-Pinto-Possebom
2020 (`ferman2020cherry`, JPAM 39(2): 510-532; specification search over pre-treatment lag
choices raises the false-positive rate. Their Recommendations subsection (p. 522) asks for
results across many specifications, always with the all-lags specification as the benchmark.
A test across all specifications is not valid without a combined test statistic); Porreca 2022 (`porreca2022synthetic`, Economics Letters 220:
110874;
SDID with staggered treatment timing, code at
github.com/zachporreca/staggered_adoption_synthdid); Clarke-Pailanir-Athey-Imbens 2024
(`clarke2024synthetic`, Stata Journal 24(4): 557-598; the Stata `sdid` implementation, with
the staggered-timing discussion in section 2.3). Author order on the last one: Crossref and
the published article put Clarke first, while the Mixtape's reference list gives it as "Athey,
Clarke, Imbens, and Pailanir"; cite the published order.

## Addenda, 2026-10-09 (tier 2 audit, approved by the user)

Each entry was written from the abstract page (Crossref, arXiv, or the publisher) checked on
2026-10-09. Bodies were not read unless a section is named.

- Kaul, Klößner, Pfeifer, and Schieler 2022 (`kaul2022standard`, JBES 40(3): 1362-1376). Role:
  the published result behind the predictor rule. Settles: entering every pre-period outcome
  as a separate predictor makes all covariates irrelevant to the weights. Binds at: the
  predictor bullet in SKILL.md. Caveat: Ferman, Pinto, and Possebom still want the all-lags
  fit reported as a benchmark.
- Kim, Lee, and Gupta 2020 (`kim2020bayesian`, JMR 57(5): 831-852). Role: Bayesian SC, the
  marketing-journal SC method paper. Settles: shrinkage priors replace the simplex constraints
  and MCMC gives the inference; the soda-tax application finds a 5.5 to 5.8 percent sales
  drop. Binds at: the Bayesian SC row in details.md. Caveat: this skill found no CRAN package.
- Abadie and Vives-i-Bastida 2025 (`abadie2025synthetic`, Advances in Economics and
  Econometrics, Twelfth World Congress, pp. 195-224; arXiv 2203.06279). Role: the originator's
  newer practice principles. Settles: rules on overfitting bias, interpretability, and
  validation exercises, derived from the estimator's formal properties. Binds at: the gate and
  the diagnostics battery, as the refresh of Abadie 2021. Caveat: read from the abstract only.
- Alvarez, Ferman, and Wüthrich 2025 (`alvarez2025inference`, arXiv 2504.19841, v3 2026).
  Role: survey of inference with few treated units, cross-section and panel. Settles: which
  procedures stay valid with one or a few treated units, with finite-sample modifications.
  Binds at: the inference section. Caveat: preprint.
- Li and Shankar 2024 (`li2024two`, Management Science 70(6): 3734-3747). Role: a formal test
  of the SC pretrends assumption. Settles: step one tests the pretrends; step two picks the
  estimator that trades bias against efficiency. Binds at: diagnostics item 1. Caveat: one
  paper, not yet a field standard.
- Chernozhukov, Wüthrich, and Zhu 2026 (`chernozhukov2026debiasing`, JPE 134(9): 2740-2777).
  Role: debiased inference on average effects. Settles: K-fold cross-fitting removes the bias,
  and a self-normalized t-statistic gives valid tests with stationary or non-stationary data.
  Binds at: the scinference rows in details.md. Caveat: scinference is research code.
- Bottmer, Imbens, Spiess, and Warnick 2024 (`bottmer2024design`, JBES 42(2): 762-773). Role:
  the design-based reading of SC. Settles: under random assignment the standard SC estimator
  is generally biased; MUSC is unbiased with an exact variance. Binds at: the design-based
  framing in details.md. Caveat: the results need random assignment.
- Ben-Michael, Feller, and Rothstein 2022 (`benmichael2022synthetic`, JRSS-B 84(2): 351-381;
  NBER w28886, 2021). Role: the source for multisynth. Settles: partially pooled SC for
  staggered adoption. Binds at: the staggered bullet and the multisynth rows.
- Ferman 2021 (`ferman2021properties`, JASA 116(536): 1764-1772). Role: the large-J caveat.
  Settles: with many pre-periods and many controls, diluted weights can recover the treated
  unit's factor loadings, and SC is then asymptotically unbiased even under selection on
  time-varying unobservables. Binds at: the "bigger J" gate bullet.

Also cited inline from this pass: Cattaneo, Feng, Palomba, and Titiunik 2025
(`cattaneo2025uncertainty`, REStat, DOI 10.1162/rest_a_01588, the prediction intervals for
staggered adoption; `cattaneo2025scpi`, JSS 113(1), the scpi package); Cao, Lu, and Wu
2026 (`cao2026synthetic`, Econometrics Journal 29(3): 323-342, implemented by stagsynth);
Arkhangelsky and Samkov 2024 (`arkhangelsky2024sequential`, arXiv 2404.00164, sequential
SDID); Abadie and Zhao 2026 (`abadie2026synthetic`, REStat, SC designs for choosing treated
markets).

## Exemplar rows

The recognition table's worked precedents. The three Abadie rows (Basque terrorism, California
Prop 99, German reunification) are already in the primary-papers paragraph above as
`abadie2003economic`, `abadie2010synthetic`, and `abadie2015comparative`, and the Texas prison row
is the Mixtape's own data exercise with no paper behind it (Cunningham, The Mixtape, online
ch. 11 sec. 11.1) and the excellent-fit case where augmented SC equals classic SC. The two
remaining rows were Crossref-verified and merged into causal.bib 2026-08-26.

- Card 1990 (`card1990impact`), comparison units picked by hand and defended in a footnote, the
  Mariel Boatlift design that motivated the method because no test exists on the hand-picked four.
- Peri and Yasenov 2019 (`peri2019labor`), the synthetic-control redo of that same design, which is
  the precedent for replacing a hand-picked holdout with a weighted donor pool.

## AMA panel family

Moved from causal-design on 2026-10-09 (tier-3 audit pass): ownership of these keys and of the
Li-Sonnier statement. The text below is causal-design/references/canon.md's, verbatim apart
from two lead-ins ("Keys:" and "What the AMA piece settles for this family:"). AMA is
defined in the causal-design canon. causal-design keeps the routing fan-out in its SKILL.md;
estimator details are in references/details.md here.

- Keys: the AMA
  panel family (`hsiao2012panel`, `li2020inference`, `li2023augmented`, `li2024forward`,
  `li2023statistical` for Li-Sonnier).
- What the AMA piece settles for this family: the data-shape fan-out within
  the panel branch: convex-hull failure -> augmented DiD (Li-Van den Bulte), outcome in
  range but too few pre-periods -> forward DiD (Li), controls far fewer than pre-periods
  -> HCW OLS (Hsiao-Ching-Wan), many treated units or short panels -> generalized
  synthetic control / matrix completion, unit and time reweighting both wanted -> SDID
  with inference procedure chosen by data shape; the Li-Sonnier result that the gsynth
  parametric bootstrap gives biased coverage when treated and control error variances
  differ ("false precision or false imprecision... lead to
  incorrect business decisions").
