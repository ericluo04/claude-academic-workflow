---
name: did
description: Design, estimate, validate, and write up a difference-in-differences analysis of a natural experiment, using the post-2018 heterogeneity-robust toolkit with an explicit statement of which parallel-trends assumption is imposed. Produces advice with citations, R estimation and diagnostics code, and a drafted methods paragraph. TRIGGER on "difference-in-differences", "diff-in-diff", "DiD", "TWFE", "two-way fixed effects", "event study", "staggered adoption", "parallel trends", "pre-trends", "Callaway-Sant'Anna", "HonestDiD", "triple differences", or any panel/repeated-cross-section setting where some units become treated over time (policy rollout, staggered feature launch, state law changes). For a single treated unit or when pre-trends visibly fail, see the synthetic-control handoff inside. Design triage across methods belongs to causal-design.
---

# Difference-in-differences

An opinionated DiD workflow grounded in a read canon (references/canon.md, current as of
2026-07-29). The deliverable is threefold: the specification decision with the citation that
justifies it, the estimation and diagnostics code in R (Stata on request), and a methods
paragraph with citations placed and the limitation stated in first person at the point of the
choice. Where the literature is unsettled the skill names a default and the condition that moves
you off it, and where the canon genuinely disagrees it says so instead of faking consensus.

Refresh path: this literature moved fast in 2018-2024 and is still moving. To update, run the
litreview skill on "difference-in-differences" since the canon date and fold results into
references/canon.md as flagged addenda.

## Triage: three questions before anything else

From Roth, Sant'Anna, Bilinski, and Poe (2023), the most condensed decision object in the
literature:

1. **Is everyone treated at the same time?** Yes: TWFE is fine, static or dynamic; nothing new
   is needed. No (staggered): default to a heterogeneity-robust estimator; TWFE only if you will
   defend effect homogeneity.
2. **Are you sure about parallel trends?** Justify levels vs logs (PT is functional-form
   dependent and generally cannot hold in both). If PT is plausible only conditional on
   covariates, use regression adjustment, IPW, or doubly robust, never bare TWFE-with-controls.
   Always pair the event study with a Rambachan-Roth sensitivity analysis, a universal mandate
   this skill family hardens beyond the canon's best-practice advice because the analysis is
   cheap and the pretest is low-powered.
3. **Do you have many treated and untreated clusters?** Yes: cluster at the level at which
   treatment is independently assigned. No: pick a few-clusters method by which homogeneity
   assumption you believe (references/details.md has the map), or fall back to a cluster-level
   Fisher randomization test. Before picking, run the MacKinnon, Nielsen, and Webb (2023)
   battery (CV1, CV3 jackknife, and a restricted wild cluster bootstrap side by side):
   agreement means stop, disagreement means escalate to the map.

Two exits from DiD entirely, both routed to the synthetic-control skill: only one or a handful
of treated units, or selection on lagged outcomes with autocorrelated errors, where DiD is
inconsistent even as pre-periods grow while SC is consistent (Arkhangelsky-Hirshberg, via the
panel survey of Arkhangelsky and Imbens 2024). Synthetic DiD also lives there. Few treated
aggregate UNITS with failed pretrends exit to synthetic-control; few treated CLUSTERS of micro
units with plausible parallel trends stay here on the few-clusters inference map
(references/details.md). When parallel trends fails and the synthetic-control exit is also
infeasible (no credible donors, short pre-period), decline the design and route back to
causal-design; a failed gate is a verdict. If treatment timing is quasi-random, DiD is valid
but inefficient; use the efficient random-timing estimators (R package staggered,
Roth-Sant'Anna).

## Estimand before estimator

Weights define the target parameter, not the specification (Baker et al. 2026). An unweighted
ATT answers "effect on the average treated county"; a population-weighted ATT answers "effect on
the average treated person." In the Baker et al. Medicaid 2x2 these are +0.1 and -2.6 deaths per
100,000: different questions, not a robustness check of each other. In marketing panels where
units differ enormously in size (DMAs, stores, channels), decide by the business or policy
question and, if you report both, report them as different estimands.

Write the target in potential-outcomes notation before touching code: which ATT(g,t) cells, and
which aggregation (event-time, calendar-time, overall; cohort-share or population weights).

## The parallel-trends menu and the estimator it implies

State explicitly which PT assumption you impose (Baker et al. 2026 make this a requirement).
Three variants under staggered adoption, with the estimator crosswalk:

| PT variant | Comparison group | Pre-trends restricted? | Estimators | R |
|---|---|---|---|---|
| PT-Nev | never-treated | no | Callaway-Sant'Anna (never), Sun-Abraham | `did::att_gt(control_group="nevertreated")`, `fixest::sunab()` |
| PT-NYT | not-yet-treated | no | Callaway-Sant'Anna (NYT), dCDH instantaneous | `did::att_gt(control_group="notyettreated")` |
| PT-all | all groups, all periods | yes (testable, and baked in) | BJS/Gardner/LWX imputation, Wooldridge ETWFE | `didimputation`, `did2s`, `etwfe` |

Default: **Callaway-Sant'Anna with not-yet-treated controls**, Baker et al.'s own choice for
their application. Move to never-treated when the not-yet-treateds' timing plausibly responded
to recent outcomes; move to imputation (PT-all) when you will defend parallel pre-trends over
the whole panel and errors are near-serially-uncorrelated, where it buys real efficiency
(Roth et al. 2023). If Y(0) is close to a random walk, the CS last-pre-period baseline is the
efficient choice and imputation's pre-period averaging buys nothing (Harmon's caveat: averaging
is not guaranteed more precise). If PT is implausible for one specific cohort, drop that cohort
rather than average over it.

"Never-treated" operationally means "not treated by the end of the sample." If all units are
eventually treated, drop periods from when the last cohort adopts and use that cohort as the
comparison, and drop units treated in the first period.

## The TWFE question, stated honestly

The canon disagrees, and the skill's position is a default with named dissent:

- Baker et al. (2026): TWFE under staggered adoption has "well-understood, potentially serious,
  and easily remedied problems, and we do not recommend using it."
- Arkhangelsky and Imbens (2024): "we recommend against the current routine use of the standard
  TWFE estimator or related estimators," though under block assignment TWFE still estimates the
  ATT, and they think negative-weight concerns "have perhaps been exaggerated."
- Abadie, Angrist, Frandsen, and Pischke (2025): the pathologies "are unlikely to derail DD or
  event-study designs in practice"; in the divorce data BJS and TWFE match. Their prescription
  is TWFE event studies with BJS as a check.

Default here: estimate the robust estimator as the headline number and report TWFE alongside it.
Agreement is affirmative evidence the simple model suffices (AAFP); divergence means
heterogeneity is doing real work and the robust estimate stands. The only way to know TWFE would
have been fine is to run the robust estimator anyway, at which point you report it (Baker et
al.). Run the building-block heterogeneity scan (2x2 DiDs by cohort, gap, and time since
adoption, Arkhangelsky-Imbens) rather than trusting any single robust estimator blindly.

## Event-study mechanics

Hard rules, mostly from Abadie, Angrist, Frandsen, and Pischke (2025):

- Feasible horizons: with panel end T and cohorts c(s), longest lag q = T - min c(s), longest
  lead m = max c(s) - 1. Here s indexes treatment cohorts and c(s) is cohort s's adoption
  period. The formulas assume periods renumbered 1..T, so calendar years must be reindexed
  first.
- Always omit event time -1. With never-treated units that single normalization identifies
  everything. Without them, a second lead or lag must be omitted, the linear component of the
  effect path is unidentified, and different second choices rotate the whole path around -1.
  Choose deliberately, never let the software's default drop decide, and show the path under at
  least two normalizations before interpreting dynamics.
- Bin leads and lags beyond the horizon where only a few units identify the coefficient (AAFP
  use +/-15 with 41 periods). Clustered SEs fail at long horizons through leverage: a lone late
  adopter can identify the longest leads, and coverage collapses.
- Report simultaneous sup-t uniform bands, computed separately for leads and lags, not only
  pointwise bands (recipe in references/details.md; the did package produces them by multiplier
  bootstrap). Never use a clustered joint F over many leads.
- Under staggered timing, build the event study from a robust estimator, never from dynamic
  TWFE: cross-lag contamination means TWFE lead coefficients can be nonzero under valid PT and
  zero under violations (Sun-Abraham, via Roth et al. 2023).
- Check composition: cohorts entering and leaving event times can manufacture dynamics. Use the
  balanced-in-event-time aggregation or a fixed cohort set when in doubt.

## Pre-trends and honest sensitivity

Pre-trend tests are underpowered: in simulations calibrated to three top journals, linear
violations detected only 50% of the time produce bias as large as the estimated effect and a
spurious significant effect about half the time (Roth 2022). Quote from Roth et al. (2023): "the
lack of a significant pre-trend does not necessarily imply the validity of the parallel trends
assumption." Also the converse (Kahn-Lang and Lang's bar mitzvah example): parallel pre-trends
do not imply parallel post-trends.

The canon splits on pretesting itself. Roth (2022) shows conditioning on passing adds selection
bias; AAFP's cost-benefit analysis concludes "the bias-mitigation benefits of pretesting are
likely to outweigh the risks" and prescribes a sup-t joint test of the leads. Default here: run
the sup-t pretest and report it, but never let a pass substitute for the sensitivity analysis,
and report the test's power against economically relevant violations (R package pretrends).

Mandatory companion to every event study: Rambachan-Roth honest inference (HonestDiD), in one
or both of its restrictions, a universality that is this family's own hardening of the canon's
best-practice endorsement (cheap to run, against a low-powered pretest). Relative magnitudes
bounds post-treatment violations by M-bar times
the largest pre-treatment violation; use it when the worry is shocks like those already seen
pre-treatment. Smoothness bounds deviations from a linear extrapolation of the pre-trend by M;
use it when the worry is a smoothly evolving confound. Report the identified set, the robust CI,
and the breakdown value at which the conclusion dies, then read it economically: robustness to
M-bar = 2 is strong in a calm period and weak if treatment coincided with a shock larger than
anything pre-treatment. Worked template numbers (Baker et al.): largest one-period pre-trend 4,
identified set -2.6 +/- 4 = [-6.6, 1.4], robust CI [-11.1, 5.1].

## Covariates

Never bare TWFE-with-controls: even in the 2x2 it identifies the ATT only under constant effects
across covariate strata, weights strata non-convexly, and adds three misspecification bias terms
(Caetano-Callaway, via Baker et al. 2026). Choose covariates from theory (determinants of
untreated trends or of selection), check they are unaffected by treatment (a time-varying
covariate is fine only if its whole path is unaffected), then use:

- **Doubly robust (default)**: `did::att_gt(est_method="dr")`, Sant'Anna-Zhao. Consistent if
  either the outcome-change model or the propensity model is right.
- Regression adjustment when overlap is weak (extrapolates the outcome model; say so).
- IPW when you understand selection better than outcome dynamics; noisy as control propensity
  scores approach 1. The did/DRDID packages trim above 0.995 by default; keep the trim and plot
  the propensity distributions by group first.

Conditioning on lagged outcomes changes the identifying assumption from PT to unconfoundedness.
The two are non-nested; matching on lagged outcomes can create mean-reversion bias when groups
differ in levels but genuinely trend in parallel (Daw-Hatfield, via Roth et al. 2023). When they
disagree, the bracketing result bounds the truth: under unconfoundedness with treated-group
pre-treatment dominance, TWFE underestimates and lagged-outcome adjustment overestimates
(Arkhangelsky-Imbens 2024). Report both and say which selection story you believe.

## Functional form

Parallel trends in logs precludes parallel trends in levels. Choose the transformation on
substantive grounds and own it: "DD identification strategies are inherently
transformation-dependent" (AAFP 2025). Run the Roth-Sant'Anna falsification test of
insensitivity to functional form when the choice is contestable. Apparent
transformation-robustness achieved through rich time-varying controls usually means the controls,
not the fixed effects, are identifying the effect, which is regression conditioning rather than
DiD, and some such controls are bad controls. For revenue, spend, and engagement outcomes the
zeros problem is endemic; log(1+y) conclusions are unit-dependent (Chen-Roth), so prefer levels,
Poisson, or an extensive/intensive margin split.

## Inference

Cluster at the level at which treatment is independently assigned (state policies: state). This
is the design-based rule (`rambachan2025design`, the DiD instance of
`abadie2023clustering`),
and group fixed effects do not get you out of it: adding them "allows for group-specific linear
trends in the underlying potential outcomes series but does not change the answer to the
question whether one needs to adjust for clustering" (AAIW, on the common-timing case, which
reduces to a cross-sectional regression of the change in unit-level average outcomes),
and it also answers "what is the superpopulation" when the sample is the population. With few
treated clusters, no method is assumption-free: the map in references/details.md lists each
option with the homogeneity assumption it needs, which is the selection criterion (Roth et al.
2023). The honest fallbacks are folding the cluster shock into the HonestDiD violation bound, or
a cluster-level Fisher randomization test, exact under the sharp null when timing is as good as
random.

## Beyond the absorbing binary treatment

- Treatments that turn on and off (promotions, price changes): dCDH estimators require
  no-carryover; for advertising and pricing that assumption is usually wrong, so check it and
  prefer the intertemporal extension (`DIDmultiplegt`/`did_multiplegt_dyn`).
- Continuous treatment intensity: ATT(d|d) is identified under standard PT, but causal-response
  parameters need strong PT across doses (Callaway, Goodman-Bacon, Sant'Anna).
- Exposure designs (baseline exposure share times a national change): the linear-interaction
  coefficient is an average marginal effect, roughly kappa + 2 phi E[M], not E[tau_s]; add the
  squared-exposure interaction when heterogeneity is plausible and report both (AAFP 2025).
- Triple differences: not simply the difference of two DiDs once covariates or staggered NYT
  comparisons enter (Ortiz-Villavicencio and Sant'Anna, via Baker et al.).
- Repeated cross-sections (brand trackers, surveys): fine without covariates; with covariates,
  test compositional stability (Sant'Anna-Xu Hausman-type check) before pooling.

## Diagnostics battery

Report with every DiD analysis, in roughly this order:

1. Raw group-mean time-series plot (the anatomy plot; it contains every number the estimator
   uses) and the ATT(g,t) matrix in calendar and event time.
2. Event study from the robust estimator with sup-t bands, binned horizons, deliberate
   normalization.
3. Sup-t joint pretest of the leads, plus its power against a relevant violation (pretrends).
4. HonestDiD identified set, robust CI, breakdown M-bar, economic reading.
5. Covariate balance as normalized differences, levels and pre-period changes; flag |nd| > 0.25
   (0.1 if the covariate is known to matter). A change-imbalance reads as a PT violation only if
   the covariate is strictly exogenous.
6. Propensity overlap plot when covariates enter.
7. TWFE alongside the robust estimator; if they diverge, Goodman-Bacon decomposition
   (bacondecomp) and dCDH negative-weight diagnostics (TwoWayFEWeights) to show why.
8. Building-block heterogeneity scan by cohort, gap, and time since adoption.
9. Composition checks: balanced event time, fixed cohort set.
10. Functional-form check when the transformation is contestable.

## R implementation

The complete runnable pipeline is scripts/did_template.R: estimation, both HonestDiD
restrictions with the official adapter included verbatim, pretest power, TWFE and Sun-Abraham
cross-checks, divergence diagnostics, imputation, the efficient random-timing estimator, and
balance. Every call signature in it was verified against the package source on 2026-07-28
(versions pinned in the script). The core, with the two settings that are easy to get wrong:

```r
library(did)
atts <- att_gt(yname = "y", tname = "period", idname = "unit",
               gname = "first_treated",         # 0 = never-treated (did's convention)
               xformla = NULL,                   # or ~ x1 + x2 for conditional PT
               control_group = "notyettreated",  # states the PT variant you impose
               est_method = "dr", clustervars = "cluster",
               base_period = "universal",        # REQUIRED for the honest_did chain
               data = df)
es <- aggte(atts, type = "dynamic", min_e = -15, max_e = 15, cband = TRUE)
```

Cross-package traps the script handles explicitly: never-treated is coded 0 in did and
didimputation, Inf in staggered, and any out-of-range value in fixest::sunab, so one recycled
cohort variable silently misclassifies units; aggte's default type is "group", so event studies
need type = "dynamic"; pretrends installs from GitHub only. Package links live in
references/details.md.

Stata equivalents on request: csdid, did_imputation, eventstudyinteract, jwdid, honestdid,
boottest for wild bootstrap. The Baker et al. AEA replication package
(aeaweb.org/articles/materials/25430, 25431) is a full R and Stata template.

## Methods paragraph template

Adapt, keeping the first-person limitation at the point of the choice:

> Treatment is staggered and effects are plausibly heterogeneous, so static and dynamic two-way
> fixed effects estimands can place negative weights on some group-time effects (Roth,
> Sant'Anna, Bilinski, and Poe 2023; Goodman-Bacon 2021). Following the forward-engineering
> approach of Baker, Callaway, Cunningham, Goodman-Bacon, and Sant'Anna (2026), I define the
> target as [unit/person-weighted] group-time ATTs and their event-study aggregation, impose
> parallel trends with respect to [not-yet-treated] units [conditional on X], and estimate with
> the doubly robust procedure of Callaway and Sant'Anna (2021), reporting uniform confidence
> bands. I assess sensitivity to parallel-trends violations following Rambachan and Roth (2023):
> bounding post-treatment violations by the largest pre-treatment trend difference ([value])
> gives an identified set of [set] and a robust confidence interval of [CI]; the conclusion
> survives violations up to M-bar = [breakdown]. A limitation of this design is [the specific
> PT variant imposed / the few treated clusters / the transformation choice], which costs
> [what it costs]; I address it by [sensitivity/fallback]. Standard errors are clustered at the
> [level], the level at which treatment is independently assigned (Roth et al. 2023).

Every claim in the paragraph must trace to a canon entry; references/canon.md maps claims to
papers and BibTeX keys in the shared causal-design/references/causal.bib. Verify any primary
paper cited beyond the canon with bibcheck before submission.

## Handoffs

- causal-design: design triage before this skill; shared inference material.
- synthetic-control: few treated units, long pre-period, selection on lagged outcomes, failed
  pretests ("sidesteps collinearity concerns while allowing for divergent nonlinear trends",
  AAFP citing Abadie 2021). Synthetic DiD is that skill's bridge topic, not this one's.
- field-experiment: when rollout timing was actually randomized, randomization-based tools
  apply; the staggered estimator itself is documented here (R package staggered, Roth-Sant'Anna).
- iv: share-balance pre-trend scrutiny for shift-share exposure designs lands here; the
  parallel-trends toolkit applies to share balance.
- rdd: policy-date designs masquerading as RD in time arrive here when many units switch at a
  date; treat the date as an event study, not a cutoff.
- preregister: pre-specifying a DiD analysis of a known upcoming natural experiment.
