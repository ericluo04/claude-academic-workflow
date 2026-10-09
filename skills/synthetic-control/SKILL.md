---
name: synthetic-control
description: Design, estimate, validate, and write up a synthetic control analysis, including synthetic difference-in-differences, augmented and penalized variants, and factor-model/matrix-completion relatives for panel counterfactuals. TRIGGER on "synthetic control", "synthetic DiD", "SDID", "donor pool", "comparative case study", "geo holdout", "CausalImpact", "matrix completion", "interactive fixed effects", "gsynth", "augmented synthetic control", "augsynth", "synthdid", "scpi", "generalized synthetic control", "fect", "penalized synthetic control", "augmented DiD", "forward DiD", "GeoLift", or any setting where one or a few aggregate units (a state, market, DMA, category, platform region) got treated and untreated units must form the counterfactual, including picking treated markets by synthetic control before a geo test. Many treated units with staggered timing belong to did; randomized geo experiments to field-experiment.
---

# Synthetic control

An opinionated synthetic-control workflow grounded in a read canon (references/canon.md,
current as of 2026-07-28): Abadie's JEL survey, the practice manual by the method's originator,
with the synthetic-DiD bridge and the DiD-vs-SC boundary supplied by the Arkhangelsky-Imbens
panel survey (shared with the did skill). Deliverable: the recommendation with its citation, the
R estimation and diagnostics code, and a methods paragraph. The skill stops at the four stop
points in ../causal-design/references/shared-rules.md (section "Stop points") and puts each
choice to the user.

Refresh path: run litreview on the method since the canon date, then propose additions to
references/canon.md as flagged addenda.

## Which precedent your design looks like

| Design shape | Canonical case | Marketing analogue | What kills it |
|---|---|---|---|
| One treated region, outcome co-moves across regions | Basque terrorism (Abadie and Gardeazabal 2003) | a single-market launch | donors whose outcome does not co-move with the treated region |
| One treated unit, a regulation, other units running their own versions of it | California Prop 99 (Abadie, Diamond, and Hainmueller 2010) | a regulation hitting one state's category sales | already-treated donors left in the pool |
| One treated unit, pool restricted to genuine peers | German reunification (Abadie, Diamond, and Hainmueller 2015) | a platform policy change in one country | a pool wide enough that fit gets bought from dissimilar donors |
| Mid-pack treated unit, smooth series, long pre-period | Texas prison construction (Cunningham, The Mixtape, online ch. 11 sec. 11.1) | a geo rollout in one DMA | a treated unit at the top or the bottom of the donor range |
| Comparison units picked by hand and defended in a footnote | Mariel Boatlift (Card 1990; Peri and Yasenov 2019) | a hand-picked matched-market holdout | no test exists on the hand-picked choice. Synthetic control replaces it |

references/details.md carries what each case is the precedent for.

## The feasibility gate: is SC usable here at all?

The method's originator is explicit that mechanical applications are risky and that there are
situations where the honest answer is to walk away. Check before estimating:

- One or a few treated AGGREGATE units (state, market, country, category), a donor pool of
  genuinely comparable untreated units, and outcomes that co-move across units.
- A long pre-period. But a long T0 cannot repair a bad fit: the bias bound is derived under
  (near-)perfect predictor fit. When pre-period fit is poor, do not use canonical SC. Take
  the imperfect-fit routes instead: SDID (boundary section) or augmented SC (Extensions).
- Enough post-intervention periods. Abadie (2021, sections 5 and 6) warns that effects can
  take time to emerge. His remedies are waiting for more post-period data or using surrogate
  outcomes, and he gives no count. This skill's judgment: a long pre-period with two
  post-periods does not pass this gate.
- The converse trap: good pre-period fit with a short T0 or a noisy outcome can be spurious
  overfitting on transitory shocks, and a larger donor pool makes overfitting easier, so a
  bigger J is not automatically better. Abadie (2021, footnote 9) adds that a large J can
  help when T0 is also large (Ferman 2021). The rule targets dissimilar donors; a small pool
  is not safer by itself.
- The expected effect must be large relative to unit-specific outcome volatility. Compare
  the effect you expect against the treated unit's pre-period residual volatility (for
  instance the pre-period RMSPE, or the outcome's detrended SD) and report that comparison.
  Sales and attention data are volatile, and when the effect is not clearly larger,
  pre-filter unit-specific noise (denoising a la robust SC) or concede the effect is
  undetectable. The judgment and its basis go in the writeup.
- No anticipation, or shift T0 earlier than any plausible anticipation. Backdating does not
  mechanically bias the per-period effects, because the effect path is unrestricted (Abadie
  2021, section 5). It has two costs. An averaged post-period effect now includes null
  periods, and the pre-period left for fitting and for the overfitting screen gets shorter.
  Forward-buying before an announced price change is the marketing version of the problem.
- No interference: donors exposed to the treatment (neighboring markets, national campaign
  spillover) are handled in design (drop them, check the fit cost) or kept with the bias
  signed and the estimate reported as a bound.
- The treated unit should be plausibly inside the donors' convex hull; weights are
  nonnegative and sum to one, so SC never extrapolates. Extreme treated units in levels
  need an outcome transformation (differences, growth rates, pre-mean deviations) or SDID,
  and differencing inflates the noise share of variance, which raises overfitting risk.
- A treated unit that is the largest unit in the panel (a national market, the top platform)
  fails the convex-hull bullet by construction, and no donor mix reaches its level. First try
  the outcome transformation, SDID, or augmented DiD (the extensions map below). When the
  level itself is the estimand, use CausalImpact (its own series plus unaffected covariates),
  or HCW OLS (unconstrained regression weights) when donors are few relative to pre-periods.
  The price: both give up the no-extrapolation guarantee, so the counterfactual is an
  extrapolation the reader has to accept.

When the gate fails, first check the extensions map. Too short a pre-period points to forward
DiD, a treated outcome outside the convex hull to augmented DiD, and few donors relative to
pre-periods to HCW OLS. When none fits, say so, decline to estimate, and route back to
causal-design.

## Donor pool discipline

Exclude donors treated with similar interventions in the window, donors hit by large
idiosyncratic shocks that would not have hit the treated unit, and donors dissimilar on
observed or suspected unobserved attributes. The canon's line: including units the analyst
regards as unsuitable controls "is a recipe for bias." The worked precedents: dropping US
states with their own tobacco programs (Prop 99), restricting the reunification donor pool to
OECD economies.

## Estimator anatomy and researcher degrees of freedom

The counterfactual is a convex combination of donors chosen so the synthetic unit matches the
treated unit's pre-intervention predictors, with predictor-importance weights V. The
constraints buy transparency and sparsity. Suppose the treated unit lies outside the donors'
convex hull and the donor columns are in general position. Then at most k donors get positive
weight (Abadie 2021, section 5), and you can name them. Panel regression on the same data is
implicitly a synthetic control whose weights sum to one but can be negative, so it
extrapolates silently. In Abadie's (2021) reunification example with a 16-country pool, four
donor countries get negative regression weights.

The degrees of freedom, each with a discipline:

- Predictors: pre-intervention outcomes PLUS substantive covariates. Pre-outcomes alone push
  excluded covariates into the unobserved loadings and raise the bias bound. Including the
  entire pre-treatment outcome path as predictors has become increasingly popular (Kaul,
  Klößner, Pfeifer, and Schieler 2022, JBES 40(3): 1362-1376). This skill rejects the drift
  because the excluded covariates are what inflate Abadie's bias bound. Kaul et al. also show
  that entering every pre-period outcome as a separate predictor makes all covariates
  irrelevant to the weights. Use a few pre-period outcome summaries (window means, selected
  years), never all lags as the main specification. Report the all-lags fit beside it as the
  benchmark that Ferman, Pinto, and Possebom (2020) recommend. The exception is an outcome
  series known to be driven by strongly co-moving common factors, which is why one pre-period
  average sufficed for reunification.
- V: inverse-variance as the simple default; better, minimize pre-period MSPE or pick V by a
  training/validation split of the pre-period. Cross-validated V is not always unique, so show
  the estimate is stable across reasonable V choices.
- Weights are computed from pre-intervention data only, so the design can be locked, even
  preregistered, before post-treatment outcomes are seen; the canon compares this to a
  pre-analysis plan. Use that: fix the specification before looking at effects.

Stop before fitting. Present the donor pool, the predictor set, and the V choice to the user, each
with its reason. This is the "before estimation" stop point in shared-rules.md.

## The boundary: DiD, SC, or synthetic DiD

One continuous decision path, not competing methods:

- DiD is the special case of the SC factor model with constant factor loadings. If the treated
  unit's pre-trend parallels a plausible comparison average, use did, provided more than one
  unit is treated. With one treated cluster, the cluster-level methods fail: CV1, CV3, and the
  wild cluster bootstrap. Prefer this skill, after aggregating the micro units to the treated
  unit, or did's Fallback B, the cluster-level Fisher randomization test. When neither is
  feasible, use one of the two rescues on did's map: Ferman-Pinto, under its heteroskedasticity
  restriction, or the ordinary wild restricted bootstrap with observation-level weights.
  Long pre-periods are key for SC identification. DiD needs one pre-period to identify the
  ATT and more only for credibility, so the SC pre-period gate does not transfer to a DiD
  routing decision.
- When the pre-period plot shows the donor average diverging from the treated unit before
  treatment, parallel trends has already failed and SC is the tool. The sharpest known
  routing result: under selection on lagged outcomes with autocorrelated errors, DiD is
  inconsistent even as the pre-period grows while SC is consistent (Arkhangelsky and
  Hirshberg 2023, arXiv 2311.13575). If units select into treatment on recent outcomes,
  that is the SC
  regime.
- Synthetic DiD is SC with unit weights plus analogous time weights and a DiD-style
  adjustment: it does not require the pre-fit to be perfect, it differences the remaining gap
  out. The price is a stable-bias assumption on that gap. In simulations calibrated to real
  panels, SDID typically outperforms DiD, SC, and matrix completion. Practical default: run
  canonical SC when the gate passes cleanly; when level fit is the sticking point, move to
  SDID and say why. Reporting discipline: plot the time weights beside the trajectory figure
  so readers see which pre-years carry the counterfactual, and plot the unit weights so they
  see which donors do. The intercept means the treated and synthetic series will not overlay,
  so the visual pre-fit check canonical SC leans on is weaker here. No accepted substitute
  exists yet. The four assumptions SDID actually makes are in references/details.md.
- Staggered adoption forecloses the standard SC estimator. With a few treated units, first
  try the staggered SC routes. One is scpi's prediction intervals for multiple treated units
  and staggered adoption (Cattaneo, Feng, Palomba, and Titiunik 2025, REStat,
  `cattaneo2025uncertainty`; the package is `cattaneo2025scpi`). The other is stagsynth,
  which implements Cao, Lu, and Wu (2026). With many treated units it is did territory, or
  multisynth (Ben-Michael, Feller, and Rothstein 2022) and the factor-model estimators below.
  Staggered SDID is the exception. Its sources are section 8 of arXiv v4 of Arkhangelsky et
  al. (2021) and section 2.3 of the Stata Journal SDID article (Clarke, Pailanir, Athey, and
  Imbens 2024). Porreca (2022) and the sequential SDID of Arkhangelsky and Samkov (2024)
  extend it. No CRAN
  package covers staggered SDID; the sources and code links are in references/details.md.

## Inference

The primary mode is design-based permutation, honest about its limits:

- In-space placebos: reassign treatment to each donor, refit, pool the gaps. The test
  statistic is the post/pre RMSPE ratio, which corrects for placebos that fit badly
  pre-period; p is the treated unit's rank among J+1 ratios. Report the spaghetti plot of
  placebo gaps, never only p; the plot carries the magnitude.
- The smallest attainable p is 1/(J+1). A tiny donor pool cannot deliver conventional
  significance, and pretending otherwise is the error. One-sided versions of the statistic
  add real power in small pools.
- Uniform permutation is a benchmark, not a model of assignment; sensitivity to non-uniform
  assignment and test-inversion confidence sets exist (Firpo-Possebom).
- Model-based complements when intervals are wanted: conformal inference (Chernozhukov et
  al.) and prediction intervals (scpi). For SDID, placebo, jackknife, and bootstrap variance
  estimators ship with the estimator. The data-shape conditions for choosing among them are
  in references/details.md.

## Diagnostics battery

1. Pre-period fit, the entry gate: table the treated unit's predictor values against the
   synthetic unit's and plot both trajectories over the whole pre-period. Visible gaps in
   either mean do not proceed (tighten the pool, change predictors or transformation,
   bias-correct, move to SDID, or abandon). The balance table has one value per variable per
   group, so it is a display, not a test. Li and Shankar (2024) give a formal test of the SC
   pretrends assumption, with a second step that picks the estimator. Report it beside the
   plot when a marketing referee will ask for a test.
2. Backdating (in-time placebo, the Heckman-Hotz preprogram test): move the intervention date
   back, re-estimate on pre-data only. Pass has two parts: no effect opens during the fake
   post-period, and the gap still opens at the true date with the same sign and shape. A
   pre-gap estimates the bias's direction and size. Caveat carried from the panel survey:
   backdating assumes strict exogeneity and backfires under selection on recent shocks (the
   AMA Marketing News routing source (Li, Luo, and Pattabhiramaiah 2024; 'AMA' hereafter)
   states this exercise as one of two mandatory best practices; the strict-exogeneity caveat
   here governs when it is informative).
3. In-space placebos with the RMSPE ratio (above).
4. Leave-one-out on positive-weight donors: refit dropping each in turn; the conclusion must
   not hinge on one donor. When it does, check whether that donor had its own intervention or
   shock.
5. Robustness across predictor sets, V choices, and tightened donor pools; drift as the pool
   tightens signals interpolation bias from dissimilar donors. Searching over pre-treatment
   lag choices raises the false-positive rate (Ferman, Pinto, and Possebom 2020), so
   pre-commit the predictor set or report every specification tried, with the all-lags fit as
   the benchmark. A test across all specifications is valid only with a combined test
   statistic (Ferman, Pinto, and Possebom 2020, p. 522).
6. Outcome-transformation check when levels are hard to match (levels vs differences vs
   growth rates vs pre-mean deviations), remembering the noise-amplification tradeoff and
   that matching changes alone is not credible when the level itself drives dynamics.
7. Spillover accounting: with and without exposed donors; when kept, sign the bias and
   interpret the estimate as a bound.

## Extensions, and when to reach for them

- Imperfect fit on a unit that must stay in: bias-corrected/augmented SC (ridge outcome
  model on the residuals; augsynth), or penalized SC.
- Many treated or disaggregated units: one SC per treated unit, aggregated; the penalized
  estimator (pensynth) restores uniqueness and sparsity for inside-the-hull units and spans
  pure SC to one-to-one matching; multisynth handles staggered timing.
- Both N and T modestly large: interactive fixed effects and matrix completion (gsynth,
  fect, MC-NNM) relax the convex-combination restriction entirely; the panel survey's
  unified view is that DiD, SC, unconfoundedness, and matrix completion are one imputation
  objective under different restrictions, so divergence across them is diagnostic.
- Volatile single-market outcomes with a Bayesian time-series counterfactual: CausalImpact
  (Brodersen et al. 2015). Abadie (2021) lists it among related work he does not cover. Treat
  its output with this skill's diagnostics, and note that its counterfactual leans on one
  unit's own time series plus covariates.
- SC-type weights with many controls and few pre-periods need regularization; unregularized
  in-sample fit can be perfect and meaningless.
- Treated outcome outside the donor convex hull: augmented DiD (Li and Van den Bulte 2023),
  a different method from Ben-Michael's ridge-augmented SC in augsynth despite the
  near-identical name. Too few pre-periods: forward DiD (Li 2024); controls far fewer than
  pre-periods: HCW OLS (Hsiao, Ching, and Wan 2012). Fuller map in references/details.md.

## Choosing treated markets before a geo test

When the treated markets are not yet chosen and only one or a few can be treated, the
synthetic control design picks treated and comparison markets jointly (Abadie and Zhao 2026).
They show that with aggregate units this design can reduce bias substantially relative to
randomizing treatment. GeoLift (github.com/facebookincubator/GeoLift, built on augsynth) is
the practitioner tool for this step, with market selection and power calculators. It does not
implement Abadie and Zhao's estimator. This skill
owns that design step. Randomized geo experiments belong to field-experiment.

## R implementation

The complete runnable pipeline is scripts/synth_template.R (canonical SC with the full
diagnostics battery, SDID, augmented and penalized variants, factor-model robustness,
conformal and prediction intervals), with every call verified against package documentation.
The core:

```r
library(tidysynth)                       # canonical ADH workflow with built-in placebos
out <- df |>
  synthetic_control(outcome = y, unit = unit, time = year,
                    i_unit = "TREATED", i_time = T0, generate_placebos = TRUE) |>
  generate_predictor(time_window = pre_window, ...) |>
  generate_weights(optimization_window = pre_window) |>
  generate_control()
plot_trends(out); plot_placebos(out); grab_significance(out)   # RMSPE-ratio table

library(synthdid)                        # the SDID branch
setup <- panel.matrices(panel, unit = "unit", time = "year",
                        outcome = "y", treatment = "treated")
tau <- synthdid_estimate(setup$Y, setup$N0, setup$T0)
sqrt(vcov(tau, method = "placebo"))
```

Package index with versions, links, and traps in references/details.md.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

> [Treatment] hit [treated unit] at [date]; no comparable unit did, so I construct a
> synthetic control from [J] donors, excluding [units] for [own interventions / shocks /
> spillovers] (Abadie 2021). Predictors are [pre-period outcomes and covariates]; predictor
> weights are chosen by [cross-validation on the pre-period], and the resulting synthetic
> unit puts weight on [named donors]. Pre-period fit is [shown in table/figure]. The
> estimated effect of [effect] compares with a pre-period [RMSPE / detrended SD] of [value]
> for [treated unit]. I report permutation inference with the post/pre RMSPE ratio over
> in-space placebos (Abadie, Diamond, and Hainmueller 2010); with [J] donors the smallest
> attainable p is 1/(J+1), [which is a limitation of the donor count: statistical
> significance in the conventional sense is out of reach, and I lean on magnitude and the
> placebo distribution].
> I validate with backdating, leave-one-out donor exclusion, and robustness across predictor
> sets and donor pools. [If fit is imperfect: because the synthetic unit cannot match
> pre-period levels exactly, I use synthetic difference-in-differences (Arkhangelsky et al.
> 2021), which differences out the remaining gap; I note this trades the perfect-fit
> requirement for the assumption that the gap would have been stable, which I cannot test
> directly.] The estimand is the effect on [treated unit] alone, and I generalize to
> [other units] only [not at all / under the stated assumption].

Most claims trace to references/canon.md; keys live in ../causal-design/references/causal.bib.

## Handoffs

- did: parallel pre-trends hold with two or more treated units, or staggered adoption with
  many treated units; synthetic DiD lives HERE, did points back for it.
- causal-design: whether any panel counterfactual is credible; the taxonomy that routes
  between did, SC, and factor models.
- rdd: policy-date designs masquerading as RD in time arrive here when one or a few aggregate
  units switch at a date; treat the date as the event, not a cutoff.
- field-experiment: randomized geo experiments and customer-level experiments. Choosing
  treated markets by synthetic control before a geo test stays here (section "Choosing
  treated markets before a geo test").
- Preregistration: the user writes it themselves; this skill supplies the fields to lock (donor pool,
  weights, specification) before post-period outcomes exist.
