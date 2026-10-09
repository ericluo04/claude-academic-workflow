---
name: did
description: Design, estimate, validate, and write up a difference-in-differences analysis, using the post-2018 heterogeneity-robust toolkit with an explicit statement of which parallel-trends assumption is imposed. TRIGGER on "difference-in-differences", "DiD", "TWFE", "event study", "staggered adoption", "staggered rollout", "parallel trends", "pre-trends", "Callaway-Sant'Anna", "Sun-Abraham", "imputation estimator", "Goodman-Bacon", "stacked DiD", "not-yet-treated", "repeated cross-section", "HonestDiD", "triple differences", "Poisson DiD", "nonlinear DiD", or any panel or repeated-cross-section setting where units become treated over time (policy rollout, staggered feature launch, state law changes). One or a few treated aggregate units: synthetic-control. No design chosen yet: causal-design.
---

# Difference-in-differences

An opinionated DiD workflow grounded in a read canon (references/canon.md).
Deliverable: the recommendation with its citation, the R estimation and diagnostics
code, and a methods paragraph. The skill stops at the four stop points in
../causal-design/references/shared-rules.md (section "Stop points") and puts each choice to the user.
Where the literature is unsettled the skill names a default and the condition that moves you off
it, and where the canon genuinely disagrees it says so instead of faking consensus.

Current as of 2026-10-09; refresh per shared-rules (../causal-design/references/shared-rules.md,
section "Refresh path").
Nothing enters the canon without the user's approval.

## Exemplar designs

Seven shapes worth recognizing on sight. Find the one your data looks like before writing a
specification; what each one teaches is in references/canon.md, section "Exemplar rows".

| Design shape | Canonical case | Marketing analogue | What kills it |
|---|---|---|---|
| Never-treated comparison with the full evidence battery | Miller, Johnson, and Wherry (2021) | a feature launched in some markets and withheld in others, with take-up data | a control group quietly exposed to the treatment |
| Staggered rollout across institutions, adoption dates rebuilt from an archive | Braghieri, Levy, and Makarin (2022) | a platform reaching accounts, regions, or partners on its own schedule | adoption dates that are wrong, or dated to enforcement when behavior moved at announcement |
| Forward engineering from estimand to estimator | Baker et al. (2026) Medicaid | any panel whose units differ enormously in size | reporting the weighted and the unweighted ATT as a robustness pair |
| Estimand first on a heavy-tailed outcome | Winkler et al. (2026) UMG-TikTok | streams, revenue, views, sessions | a log taken for convenience |
| Compositional change in repeated cross-sections | Hong (2013) Napster | brand trackers and refreshed survey panels | who is sampled moves with treatment timing |
| Triple differences | Gruber (1994) | an ineligible segment inside the same treated markets | reading the placebo DiD as a test that has to return zero |
| The idea, not the inference | Card and Krueger (1994) | a two-region holdout test | G = 2 with one treated cluster |

## Triage: three questions before anything else

From Roth, Sant'Anna, Bilinski, and Poe (2023), the most condensed decision object in the
literature:

1. **Is everyone treated at the same time?** Yes: TWFE is fine, static or dynamic, without
   covariates; with covariates see Covariates below. For two groups and two periods the
   estimator is interaction OLS or the long difference, clustered at the level of assignment.
   The identity of interaction OLS, TWFE, and the long difference holds exactly only in that
   2x2 with no covariates, and it is what makes people reach for TWFE-with-controls, where it
   no longer holds. Everything else in this skill still applies to a 2x2. No (staggered):
   default to a heterogeneity-robust estimator; TWFE only if you will defend effect
   homogeneity.
2. **Are you sure about parallel trends, and on which scale?** Justify levels vs logs (PT is
   functional-form dependent and generally cannot hold in both) and name the estimand the
   scale targets (Functional form below). If PT is plausible only conditional on
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
inconsistent even as pre-periods grow while SC is consistent (Arkhangelsky and Hirshberg 2023,
arXiv 2311.13575; Section 7.3.4 of the Arkhangelsky and Imbens 2024 survey relays it). A few
treated aggregate units with staggered timing go to synthetic-control, which tries scpi first
(Cattaneo, Feng, Palomba, and Titiunik 2025, `cattaneo2025uncertainty`, for the intervals;
`cattaneo2025scpi` for the package) or stagsynth (Cao, Lu, and Wu 2026, `cao2026synthetic`). Few
treated aggregate UNITS with failed pretrends exit to synthetic-control; few treated CLUSTERS of
micro units with plausible parallel trends stay here on the few-clusters inference map
(references/details.md), down to two treated clusters. With one treated cluster, the
cluster-level methods fail: CV1, CV3, and the wild cluster bootstrap. Prefer synthetic-control,
after aggregating the micro units to the treated unit, or Fallback B, the cluster-level Fisher
randomization test. When neither is feasible, use one of the two rescues on the map:
Ferman-Pinto, under its heteroskedasticity restriction, or the ordinary wild restricted
bootstrap with observation-level weights. If treatment timing is quasi-random, DiD is valid but
inefficient. Use the efficient random-timing estimators of Roth and Sant'Anna (2023,
`roth2023efficient`), in the R package staggered.

Refusal list. In five cases the skill declines the design and routes back to causal-design. A
failed gate is a verdict.

1. Always-treated units carry the estimand and cannot be dropped.
2. No period has an untreated or not-yet-treated comparison unit.
3. Institutional detail documents selection on realized gains: units took the treatment because
   they correctly expected it to help them. Clean pre-trends are no defense (see "Why these
   units were treated"). causal-design checks whether an instrument for take-up exists (iv).
4. One treated cluster, and none of synthetic-control, Fallback B, or the two rescues on the
   map is feasible.
5. Parallel trends fails on every candidate scale (levels, logs, the nonlinear index), and the
   synthetic-control exit is infeasible (no credible donors, short pre-period).

## The design stage, before you look at the outcome

In order, each finished before the next. Nothing before the last step needs the outcome, and
that deferral is the discipline (Rubin 2008, `rubin2008objective`: design trumps analysis).

1. Write the target parameter in potential outcomes: which population, which weights.
2. Count units per cohort, including never-treated and always-treated, with cohort shares. A
   cohort holding a sixth of the treated units dominates every aggregation, and always-treated
   units have to be found and dropped before anything else runs.
3. Plot the treatment rollout, unit by period (`panelView`, Mou, Liu, and Xu 2023).
4. Choose the control group and commit before results exist. The more random the assignment, the
   less the choice matters; the less random, the more selection drives it.
5. Choose unconditional or conditional parallel trends.
6. Check covariate balance and overlap.
7. Only now plot average outcomes by cohort.

## Assumptions and treatment dating

Parallel trends is the assumption this skill argues about. Two others get stated and forgotten,
and both fail silently.

No anticipation: the treated group's outcome is Y(0) until treatment happens. An already-treated
baseline attenuates the estimate and nothing in the diagnostics battery flags it. The Mixtape's
simulation numbers are in references/details.md, section "Anticipation: the Mixtape simulation".
Make the baseline clean. When announcement precedes enforcement and behavior can respond
(pre-announced price changes, regulatory effective dates published months ahead), date treatment
to the announcement and state the two prices: the ATT now averages over a longer post window
including announced-but-unenforced periods, and parallel trends is now stated against a
different baseline.

SUTVA: no interference between units, and the treatment is the same thing for every treated
unit. Panel threats are spillover to adjacent control markets, substitution across one firm's
own units, and the announcement-versus-enforcement gap, which makes "announced" and "announced
and enforced" two treatments. Interference contaminates the control group's Y(0), so the
comparison understates the effect or reverses its sign. Buffer or drop adjacent controls, or
model exposure and make the exposure the treatment.

## Estimand before estimator

Weights define the target parameter, not the specification (Baker et al. 2026). An unweighted
ATT answers "effect on the average treated county"; a population-weighted ATT answers "effect on
the average treated person." In the Baker et al. Medicaid 2x2 these are +0.1 and -2.6 deaths per
100,000: different questions, not a robustness check of each other. In marketing panels where
units differ enormously in size (DMAs, stores, channels), decide by the business or policy
question and, if you report both, report them as different estimands.

Write the target in potential-outcomes notation before touching code: which ATT(g,t) cells, and
which aggregation (event-time, calendar-time, overall; cohort-share or population weights).
Callaway-Sant'Anna aggregates the same building blocks four ways: simple, one average over all
feasible group-times; group, ATT(g), the effect on each cohort; calendar, ATT(t), the effect in
each period, which is the target when the question is about a season, a platform change, or a
macro shock; and dynamic, ATT(l), the event study. Those are four parameters, not four
robustness checks, and the feasible (g,t) set shrinks at long horizons, so each covers a
different slice of the data.

Name the aggregation weights too, since they define the reported number. Deb, Norton,
Wooldridge, and Zabel (2025, NBER 34331, `deb2025aggregating`) show that the standard
Callaway-Sant'Anna software weights cells by counts that include observations in the reference
pre-period. The weights are therefore not the counts of treated observations in treated periods
alone. They discuss when this choice moves the aggregate. When the target is the average over
treated unit-periods, aggregate the ATT(g,t) cells yourself with treated-period counts and
report both aggregates (this skill's judgment).

Functional form and weights are estimand choices too (Winkler, Hotz-Behofsits, Wlömert, Papies,
and Liaukonytė 2026). Three parameters get reported as if they were one: the typical-unit
proportional effect ΔΔE[log Y] (log OLS), the population-total proportional effect ΔΔ log E[Y]
(PPML), and the level effect ΔΔE[Y] (levels OLS). Under heavy-tailed outcomes they differ in
magnitude and can differ in sign with no staggered-timing problem anywhere: in the UMG-TikTok
withdrawal, a clean two-group single-date design with 53,753 matched song pairs, unweighted log
OLS gives +0.0063 and PPML gives -0.0310 on the same panel, and reweighting the log OLS toward
the head gives -0.0286 without touching the transformation. Pick the estimand from the question
("did per-user usage rise 5%?" is typical-unit, "did total revenue rise 5%?" is
population-total, "did this add $2M?" is level), then the estimator. Levels-vs-logs is never a
robustness check: an appendix that reports both without naming the estimand each targets is
reporting two parameters as one. The heterogeneity-robust estimator question and the
estimand-scale question are orthogonal, and both get answered.

## The parallel-trends menu and the estimator it implies

State explicitly which PT assumption you impose (Baker et al. 2026 make this a requirement).
Three variants under staggered adoption, with the estimator crosswalk:

| PT variant | Comparison group | Pre-trends restricted? | Estimators | R |
|---|---|---|---|---|
| PT-Nev | never-treated | no | Callaway-Sant'Anna (never), Sun-Abraham | `did::att_gt(control_group="nevertreated")`, `fixest::sunab()` |
| PT-NYT | not-yet-treated | no | Callaway-Sant'Anna (NYT), dCDH instantaneous | `did::att_gt(control_group="notyettreated")` |
| PT-all | all groups, all periods | yes (testable, and baked in) | BJS/Gardner imputation, Liu-Wang-Xu (2024, `liu2024practical`) FEct imputation, Wooldridge ETWFE | `didimputation`, `did2s`, `fect`, `etwfe` |

Sun-Abraham sits under PT-Nev for a reason worth naming at the point of use: its cohort 2x2s use
the last-treated cohort or the never-treated, never the not-yet-treated. Against a CS-NYT default
the `sunab` cross-check in the template therefore compares two assumptions, and neither agreement
nor divergence is a robustness result.

Default: **Callaway-Sant'Anna with not-yet-treated controls**, Baker et al.'s own choice for
their application. That default is licensed by no anticipation among the not-yet-treated: if
their behavior already responds to the treatment they are about to get, they are not clean
controls. Move to never-treated when the not-yet-treateds' timing plausibly responded
to recent outcomes; move to imputation (PT-all) when you will defend parallel pre-trends over
the whole panel and errors are near-serially-uncorrelated, where it buys real efficiency
(Roth et al. 2023). Each move has a price. The never-treated are a subset of the not-yet-treated
pool, so the comparison group shrinks and the bands widen. A never-treated group can also
differ from the treated in levels and in why it never adopted, which makes PT harder to
argue. Imputation buys its efficiency by
assuming PT in every pre-period. A long covariate list is a further reason to move to Wooldridge
ETWFE with covariate interactions, since the CS propensity score is estimated per cohort and with
fifty covariates common support gets hard to assess and harder to defend. Imputation is no route
for covariates: BJS takes them only in levels and does not implement conditional PT
(references/details.md, RA / IPW / DR mechanics). A further price of imputation is that its
event-study plots are not comparable to CS or TWFE plots, because fitting the counterfactual on
the whole pre-period puts a mechanical kink at t = -1, so do not overlay them. If Y(0) is close
to a random walk, the CS last-pre-period baseline is the
efficient choice and imputation's pre-period averaging buys nothing (Harmon's caveat: averaging
is not guaranteed more precise). If PT is implausible for one specific cohort, drop that cohort
rather than average over it.

"Never-treated" operationally means "not treated by the end of the sample." If all units are
eventually treated, drop periods from when the last cohort adopts and use that cohort as the
comparison, and drop units treated in the first period.

## The TWFE question, stated honestly

The same regression is two designs. With an adoption date and units that are never or not-yet
treated, `y ~ treat | unit + period` is a DiD and the assumption is parallel trends. With a
treatment that varies within unit over time and no comparison group at all, the identical
regression is the within estimator and the assumption is strict exogeneity conditional on the
unit effect, non-nested with parallel trends and failing differently (feedback from past
outcomes to current treatment). Route the second case to causal-design's
plain-panel-fixed-effects section; nothing below applies to it. For a binary treatment that
switches on and off, plain FE applies when all units switch together, so no period has both
treated and untreated units. Otherwise the treatment stays here, on the dCDH route (section
"Beyond the absorbing binary treatment").

For the first case the canon disagrees, and the skill's position is a default with named dissent
(the dissent, the Goodman-Bacon weights, and the rule against stacking estimators on one plot
are in references/details.md, section "The TWFE question in full").

Default here: estimate the robust estimator as the headline number and report TWFE alongside it.
Agreement is affirmative evidence the simple model suffices (AAFP); divergence means
heterogeneity is doing real work and the robust estimate stands.

## Event-study mechanics

Hard rules, mostly from Abadie, Angrist, Frandsen, and Pischke (2025):

- Feasible horizons: with panel end T and cohorts c(s), longest lag q = T - min c(s), longest
  lead m = max c(s) - 1. Here s indexes units (states in AAFP) and c(s) is unit s's adoption
  period, its cohort. The formulas assume periods renumbered 1..T, so calendar years must be
  reindexed first.
- Always omit event time -1. The Mixtape gives the reason, that no anticipation requires an
  untreated baseline, and stops there (Cunningham, The Mixtape, online ch. 9 sec. 9.5, Eq.
  9.25). With never-treated units that single normalization identifies everything. Without them
  a second lead or lag must also be omitted, because the linear component of the effect path is
  unidentified (Borusyak, Jaravel, and Spiess 2024, `borusyak2024revisiting`, relayed by AAFP).
  Different second choices rotate the whole path around -1. Choose deliberately, never let
  the software's default drop decide, and show the path under at least two normalizations
  before interpreting dynamics.
- Short gaps versus long differences, a hard rule. OLS event studies mechanically use a
  universal baseline, so every coefficient is a long difference against t = -1.
  Callaway-Sant'Anna and dCDH can produce either, and a rolling baseline gives short gaps, which
  estimate a different quantity (Roth 2026). Stata's `csdid` 2.0.0 defaults to
  `base_period(universal)`, which gives long differences; on csdid 1.8x pass `long2`, a name
  2.0.0 keeps only for compatibility. csdid 2.0.0 also made not-yet-treated units the default
  comparison group, where 1.82 used never-treated, so state the group you pass. The `csdid2`
  default is unverified. R's `did` needs
  `base_period = "universal"`.
  Reader-side tell in someone else's paper: a confidence interval at t = -1 means a rolling
  baseline, since t = -1 cannot be its own baseline, and the leads top out one period earlier.
- Reading the coefficients out loud. A lead of +1.5 means the treated group's change from that
  period to the omitted baseline ran 1.5 outcome units above the control group's. A lag is the
  ATT for that period, valid only under PT from the baseline to it, no anticipation, and an
  untreated comparison group. Plot disconnected points with whiskers: connecting the bands makes
  the intervals appear to narrow toward the omitted period, where nothing was estimated.
- Bin leads and lags beyond the horizon where only a few units identify the coefficient (AAFP
  use +/-15 with 41 periods). Clustered SEs fail at long horizons through leverage: a lone late
  adopter can identify the longest leads, and coverage collapses.
- Report simultaneous sup-t uniform bands, computed separately for leads and lags, not only
  pointwise bands (recipe in references/details.md; the did package produces them by multiplier
  bootstrap). Avoid a clustered joint F over many leads. The clustered variance is biased
  downward, and the resulting over-rejection grows with the number of restrictions (AAFP, citing
  Pustejovsky and Tipton 2018,
  `pustejovsky2018small`, and MacKinnon, Nielsen, and Webb 2023). AAFP use individual t tests
  with sup-t bands instead.
- Under staggered timing, build the event study from a robust estimator, never from dynamic
  TWFE: cross-lag contamination means TWFE lead coefficients can be nonzero under valid PT and
  zero under violations (Sun-Abraham, via Roth et al. 2023).
- Check composition: cohorts entering and leaving event times can manufacture dynamics. Use the
  balanced-in-event-time aggregation or a fixed cohort set when in doubt.

## Pre-trends and honest sensitivity

Pre-trend tests are underpowered, and a pass is weak, suggestive evidence that does not establish
parallel trends (Roth 2022, `roth2022pretest`). Ghanem, Sant'Anna, and Wüthrich (2026,
`ghanem2026when`) show that a pretest can be uninformative about PT unless selection into
treatment meets specific restrictions. Reading a pretest therefore needs the assignment argument
in the next section. Run the sup-t pretest and report its power (pretrends), but never let a pass
replace the sensitivity analysis.

Mandatory companion to every event study: Rambachan-Roth honest inference (HonestDiD), this
family's hardening of the canon's best-practice advice. Use relative magnitudes when the worry is
shocks like those seen pre-treatment, and smoothness when it is a smoothly evolving confound.
Report the identified set, the robust CI, and the breakdown value, and read them economically.
Scope: event studies on a universal baseline (Callaway-Sant'Anna, common-timing TWFE,
Sun-Abraham). For a BJS or Gardner headline, run HonestDiD on the CS event study of the same data.
For the nonlinear etwfe event study, report both lead versions and pair them with HonestDiD on the
linear CS fit. With many cohorts, each precisely estimated, with visibly different pre-trends,
run the cohort-anchored version of Liu (2025, `liu2025cohort`) as a check. The full section is in
references/details.md, section "Pre-trends and honest sensitivity in full".

## Why these units were treated

Answer that before reading the pre-trend picture, from institutional detail (Ghanem, Sant'Anna,
and Wüthrich, `ghanem2022selection`; Marx, Tamer, and Tang 2024, `marx2024parallel`). Selection
on realized gains breaks PT, and clean pre-trends are no defense. Selection on baseline Y(0)
leaves PT intact only under the martingale condition (Corollary 3.3), a unit-root restriction on
the shocks. Then the dip at t = -1 is mechanical: do not re-base to t = -2, and prefer the
smoothness restriction or an anchor that excludes the selection period, and say which you did.
When Y(0) mean-reverts, the dip is the Ashenfelter dip and a real PT violation. Argue the
random-walk case from the outcome's time-series behavior before dismissing a dip as mechanical.
The mechanism table is in references/details.md, section "Selection mechanisms and parallel
trends", and the full argument in section "Why these units were treated in full".

## Covariates

Never bare TWFE-with-controls: even in the 2x2 it identifies the ATT only under constant effects
across covariate strata, weights strata non-convexly, and adds three misspecification bias terms
(Caetano-Callaway, via Baker et al. 2026). Choose covariates from theory (determinants of
untreated trends or of selection), and ask domain experts what ordinarily drives untreated
trends in this outcome, since that is the arm of the DAG nobody guesses well. If you select
covariates from the data, run the selection on untreated units only, so only Y(0) informs it
(Borgschulte and Vogler 2020). State the covariate list before you see results: the choice can
swing the estimate and a DAG does not protect against specification search. Check the covariates
are unaffected by treatment (a time-varying covariate is fine only if its whole path is
unaffected). When PT needs a covariate that treatment moves, dropping it is often ill-advised
(Caetano, Callaway, Payne, and Sant'Anna 2026, arXiv 2608.03881, `caetano2026bad`). They give
conditions under which CS with the covariate's pre-treatment values is valid. Under covariate
unconfoundedness they add imputation and double machine learning estimators, extended to
staggered adoption with pretests (R package badcontrols, CRAN 1.0.1). Otherwise use:

- **Doubly robust (default)**: `did::att_gt(est_method="dr")`, Sant'Anna-Zhao. Consistent if
  either the outcome-change model or the propensity model is right.
- Regression adjustment when overlap is weak (extrapolates the outcome model; say so).
- IPW when you understand selection better than outcome dynamics; noisy as control propensity
  scores approach 1. Histograms and kernel densities do not reveal explosive weights, so count
  the control units with a propensity score near 1 directly. In the Mixtape's CAPS data
  (Cunningham, The Mixtape, online ch. 10 sec. 10.14) one control municipality scores
  0.999971, which is a weight of p/(1-p) = 34,481. Eleven control units sit above 0.995.
  Trim at 0.995 and keep the trim. R's did trims automatically
  and not every package does, so check what yours does before trusting the estimate.

Conditioning on lagged outcomes changes the identifying assumption from PT to unconfoundedness.
The two are non-nested; matching on lagged outcomes can create mean-reversion bias when groups
differ in levels but genuinely trend in parallel (Daw and Hatfield 2018, `daw2018matching`).
When they disagree, the two estimates bracket the truth. With the treated group above the
controls before treatment, TWFE is too low if unconfoundedness holds. Lagged-outcome adjustment
is too high if PT holds (Arkhangelsky-Imbens 2024, Section 5.6). Ding and Li (2019,
`ding2019bracketing`) prove the bracketing nonparametrically and extend it to inverse
probability weighting. Their abstract states the mirror case for a positive effect. Assuming PT
overestimates if ignorability holds, and assuming ignorability underestimates if PT holds. That
sign matches a treated group below the controls before treatment, the Angrist-Pischke case
(this skill's reading of the abstract; the theorem's sign condition is unconfirmed here).
Report both estimates and say which selection story you believe.

## Triple differences

DDD is a design, not a falsification, and the placebo DiD need not be zero (Olden and Møen 2022).
Use the saturated OLS only with common timing and no covariates. Once covariates or staggered
adoption enter, use `triplediff::ddd()` and `agg_ddd()` (Ortiz-Villavicencio and Sant'Anna 2025,
`ortizvillavicencio2025better`; template section 8c). The full section is in
references/details.md, section "Triple differences in full".

## Functional form and nonlinear outcomes

Parallel trends generally cannot hold in both logs and levels (Roth and Sant'Anna 2023,
`roth2023functional`). Choose the scale on substantive grounds and state PT on that named scale.
Pick the estimand from the question, then the estimator (Winkler et al. 2026). Under heavy tails
shocks typically scale with baseline size. Carrying that from streams to sales, views, and
engagement is this skill's judgment, so state it as yours. The full argument, the simulations, and
the Wooldridge recipe are in references/details.md, section "Functional form and nonlinear
outcomes in full".

1. Diagnose concentration first: Lorenz curve, Gini, or top-decile share of Y.
2. Population-total estimand on a heavy-tailed nonnegative outcome: PPML with a log link
   (`fixest::fepois`, Stata `ppmlhdfe`) and cluster-robust SEs. It is consistent under a correct
   conditional mean (`gourieroux1984pseudo`). With many zeros use PPML too, because log(1+y) and
   asinh conclusions are unit-dependent (Chen-Roth).
3. A log outcome is reported: run the Ciani-Fisher variance-shift regression. A significant
   coefficient rules out log OLS for the population-total estimand.
4. Levels OLS is sign-unstable under proportional growth with a treated-control baseline gap.
   Agreement across scales in a matched sample is a special case, and a levels SDID inherits the
   gap.
5. Binary, count, or fractional outcome: the Wooldridge nonlinear recipe, one pooled QMLE with the
   canonical link and PT on the index scale. Fit the linear and the nonlinear model and compare
   them as assumptions. Report the lags-only and the leads-and-lags event studies on the index
   scale. R: etwfe. Stata: jwdid with `method(poisson)` or `method(logit)`.
6. Contestable transformation: run the Roth-Sant'Anna falsification test and plot pre-trends on
   both scales. Explicit weights are predetermined and tied to the target.

## Inference

Cluster at the level at which treatment is independently assigned (state policies: state), the
design-based rule (`rambachan2025design`, the DiD instance of `abadie2023clustering`), and group
fixed effects do not get you out of it. With few treated clusters no method is assumption-free:
the map in references/details.md lists each option with the homogeneity assumption it needs,
which is the selection criterion (Roth et al. 2023). The honest fallbacks are folding the
cluster shock into the HonestDiD violation bound, or a cluster-level Fisher randomization test,
exact under the sharp null when timing is as good as random.
Full argument: ../causal-design/references/shared-rules.md.

The Mixtape's Card-Krueger significance reading and its 30-cluster rule of thumb are both unsafe
(references/details.md, section "Two Mixtape rules to disarm"). Run the battery instead of
counting clusters.

## Beyond the absorbing binary treatment

- Treatments that turn on and off (promotions, price changes): dCDH estimators require
  no-carryover; for advertising and pricing that assumption is usually wrong, so check it and
  prefer the intertemporal extension (`DIDmultiplegtDYN` in R, `did_multiplegt_dyn` in Stata).
- Continuous treatment intensity: ATT(d|d) is identified under standard PT, but causal-response
  parameters need strong PT across doses (Callaway, Goodman-Bacon, Sant'Anna).
- Exposure designs (baseline exposure share times a national change): the linear-interaction
  coefficient is an average marginal effect, roughly kappa + 2 phi E[M], not E[tau_s]; add the
  squared-exposure interaction when heterogeneity is plausible and report both (AAFP 2025).
- Repeated cross-sections (brand trackers, surveys, transaction data with one row per unit):
  fine without covariates. The failure is compositional change: who is sampled moves with
  treatment timing in a way correlated with Y(0) (Hong 2013). With covariates, run the Sant'Anna-Xu
  Hausman-type test before pooling. Without unit fixed effects, use the Wooldridge (2026) design,
  clustered at the assignment level. You cannot verify that covariates are time-invariant when each
  unit is seen once. Say so. Full item: references/details.md, section "Repeated cross-sections
  in full".

The full items are in references/details.md, section "Beyond the absorbing binary treatment in
full".

## Diagnostics battery

Report with every DiD analysis, in roughly this order. Items 1 to 10 ask whether the estimator
is doing what it claims; 11 to 13 ask whether something other than the treatment produced the
pattern, and 11 runs before any of the rest:

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
   (bacondecomp) and dCDH negative-weight diagnostics (TwoWayFEWeights) to show why. Run the
   weight diagnostics to explain a divergence, never as a standing robustness table, and do not
   read all-positive Bacon weights as a licence for TWFE.
8. Building-block heterogeneity scan by cohort, gap, and time since adoption.
9. Composition checks: balanced event time, fixed cohort set.
10. Outcome concentration (Lorenz, Gini, top-decile share) and the estimand each reported
    specification targets; the Ciani-Fisher variance-shift regression whenever a log outcome
    is reported; the Roth-Sant'Anna functional-form check when the transformation is
    contestable; for nonlinear models, the event study on the index scale.
11. Bite: evidence that the treatment changed the thing it was supposed to change.
12. Falsifications, both families, read by the rule in references/details.md, section
    "The evidence battery".
13. Mechanism: why the effect happened, and evidence consistent with that story.

Bite comes first in time. A falsification null is weak, suggestive evidence of the same class as
a clean pre-trend, and a pretest pass can be uninformative about PT (Ghanem, Sant'Anna, and
Wüthrich 2026). A rejection revives a rival explanation without proving the main result
spurious. Run falsifications and the event study with HonestDiD both, since they answer
different questions.

## R implementation

The complete runnable pipeline is scripts/did_template.R: estimation, both HonestDiD
restrictions with the official adapter included verbatim, pretest power, TWFE and Sun-Abraham
cross-checks, divergence diagnostics, imputation, the efficient random-timing estimator, and
balance. Call signatures were verified on 2026-07-28, and sections 8b and 8c on 2026-10-08
(the template header records that run).
The core, with the two settings that are easy to get wrong:

```r
library(did)
atts <- att_gt(yname = "y", tname = "period", idname = "unit",
               gname = "first_treated",         # 0 = never-treated (did's convention)
               xformla = NULL,                   # or ~ x1 + x2 for conditional PT
               control_group = "notyettreated",  # states the PT variant you impose
               est_method = "dr", clustervars = "cluster",
               base_period = "universal",        # long differences, not short gaps (Roth 2026);
                                                 # the honest_did chain also requires it
               data = df)
es <- aggte(atts, type = "dynamic", min_e = -15, max_e = 15, cband = TRUE)
```

Cross-package traps the script handles explicitly: never-treated is coded 0 in did and
didimputation, Inf in staggered, and any out-of-range value in fixest::sunab, so one recycled
cohort variable silently misclassifies units; aggte's default type is "group", so event studies
need type = "dynamic"; pretrends installs from GitHub only. Package links live in
references/details.md.

Nonlinear outcomes and repeated cross sections (template section 11; etwfe 0.6.2, signatures
verified against the reference pages and source on 2026-08-26):

```r
library(etwfe)
nl <- etwfe(fml = y ~ 0, tvar = period, gvar = first_treated, data = df,
            cgroup = "notyet", family = "poisson",   # or "logit"; lags-only version
            vcov = ~cluster)                   # no ivar: a nonlinear family forces ivar = NULL,
                                               # cohort and period enter as explicit dummies, and
                                               # nothing unit-level is used, so repeated cross
                                               # sections run unchanged
emfx(nl, type = "event")                       # ATT by exposure time, response scale (APEs)
ll <- etwfe(fml = y ~ 0, tvar = period, gvar = first_treated, data = df,
            cgroup = "never", family = "poisson", vcov = ~cluster)
emfx(ll, type = "event", predict = "link")     # leads and lags on the index scale
```

etwfe's never-treated coding, its lead rules, and the `compress` trap are in references/details.md,
section "etwfe behavior".

Stata equivalents on request: csdid, did_imputation, eventstudyinteract, jwdid, honestdid, boottest
for wild bootstrap, ppmlhdfe for PPML, and jwdid with `method(poisson|logit)` for the nonlinear
recipe (no `ivar` means repeated cross-section; covariates are demeaned by default). The Baker et
al. AEA replication package (aeaweb.org/articles/materials/25430, 25431) is a full R and Stata
template.

Python route: `moderndid` (PyPI 0.2.0) and `diff-diff` (PyPI 3.12.0) both implement
Callaway-Sant'Anna and HonestDiD (PyPI pages checked 2026-10-09). Neither has been run against
this template, so reproduce one headline number in R before relying on either.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

Adapt, keeping the first-person limitation at the point of the choice:

> Treatment is staggered and effects are plausibly heterogeneous, so static and dynamic two-way
> fixed effects estimands can place negative weights on some group-time effects (de
> Chaisemartin and D'Haultfoeuille 2020; Sun and Abraham 2021 for the dynamic case; Roth,
> Sant'Anna, Bilinski, and Poe 2023). Following the forward-engineering
> approach of Baker, Callaway, Cunningham, Goodman-Bacon, and Sant'Anna (2026), I define the
> target as [unit/person-weighted] group-time ATTs and their event-study aggregation on the
> [level / log-mean / mean-log] scale, which is the [level / population-total proportional /
> typical-unit proportional] effect the research question asks for (Winkler, Hotz-Behofsits,
> Wlömert, Papies, and Liaukonytė 2026) [or, for a binary outcome, on the log-odds index
> (Wooldridge 2023, 2026)], impose parallel trends with respect to [not-yet-treated] units
> [conditional on X] on that scale, and estimate with [the doubly robust procedure of
> Callaway and Sant'Anna (2021) / pooled Poisson or logit quasi-maximum likelihood with
> cohort-by-period treatment effects (Wooldridge 2023, 2026)], reporting uniform confidence
> bands. I assess sensitivity to parallel-trends violations following Rambachan and Roth (2023):
> bounding post-treatment violations by the largest pre-treatment trend difference ([value])
> gives an identified set of [set] and a robust confidence interval of [CI]; the conclusion
> survives violations up to M-bar = [breakdown]. A limitation of this design is [the specific
> PT variant imposed / the few treated clusters / the transformation choice], which costs
> [what it costs]; I address it by [sensitivity/fallback]. Standard errors are clustered at the
> [level], the level at which treatment is independently assigned (Abadie, Athey, Imbens, and
> Wooldridge 2023), with G = [n] clusters, [G1] of them treated, and cluster sizes from [min] to
> [max] (median [m]).

Every claim in the paragraph must trace to a canon entry; references/canon.md maps claims to
papers and BibTeX keys in the shared ../causal-design/references/causal.bib. Verify any primary
paper cited beyond the canon with bibcheck before submission.

## Handoffs

- causal-design: design triage before this skill; shared inference material.
- synthetic-control: few treated units, long pre-period, selection on lagged outcomes, failed
  pretests ("sidesteps collinearity concerns while allowing for divergent nonlinear trends",
  AAFP citing Abadie 2021). Synthetic DiD is that skill's bridge topic, not this one's. A
  levels SDID inherits the baseline-gap sensitivity of levels DiD (Winkler et al. 2026), so the
  scale question travels with the handoff.
- field-experiment: owns randomized staggered rollouts (stepped wedge), where the adoption
  dates were randomized and inference is design-based. This skill documents the estimator
  for randomized timing (R package staggered, Roth and Sant'Anna 2023, `roth2023efficient`).
- Machine-coded variables: an outcome or treatment coded by an LLM or a classifier (sentiment of
  reviews, topics of posts, labels on images). The DiD design stays here, and the measurement
  correction is added to it: prediction-powered inference on a gold-standard subsample for
  a coded outcome, DSL or Battaglia et al. 2025 for a coded treatment
  (../causal-design/references/shared-rules.md).
- iv: share-balance pre-trend scrutiny for shift-share exposure designs lands here; the
  parallel-trends toolkit applies to share balance.
- rdd: policy-date designs masquerading as RD in time arrive here when many units switch at a
  date; treat the date as an event study, not a cutoff.
- Preregistration: the user writes it themselves; this skill supplies the DiD field list for a known upcoming natural experiment.
