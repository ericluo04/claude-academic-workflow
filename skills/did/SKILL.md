---
name: did
description: Design, estimate, validate, and write up a difference-in-differences analysis of a natural experiment, using the post-2018 heterogeneity-robust toolkit with an explicit statement of which parallel-trends assumption is imposed. Produces advice with citations, R estimation and diagnostics code, and a drafted methods paragraph. TRIGGER on "difference-in-differences", "diff-in-diff", "DiD", "TWFE", "two-way fixed effects", "event study", "staggered adoption", "parallel trends", "pre-trends", "Callaway-Sant'Anna", "HonestDiD", "triple differences", "PPML", "Poisson DiD", "heavy-tailed outcome", "log outcome", "nonlinear DiD", "binary outcome", or any panel/repeated-cross-section setting where some units become treated over time (policy rollout, staggered feature launch, state law changes). For a single treated unit or when pre-trends visibly fail, see the synthetic-control handoff inside. Design triage across methods belongs to causal-design.
---

# Difference-in-differences

An opinionated DiD workflow grounded in a read canon (references/canon.md, current as of
2026-08-26). The deliverable is threefold: the specification decision with the citation that
justifies it, the estimation and diagnostics code in R (Stata on request), and a methods
paragraph with citations placed and the limitation stated in first person at the point of the
choice. Where the literature is unsettled the skill names a default and the condition that moves
you off it, and where the canon genuinely disagrees it says so instead of faking consensus.

Refresh path: this literature moved fast in 2018-2024 and is still moving. To update, run the
litreview skill on "difference-in-differences" since the canon date and fold results into
references/canon.md as flagged addenda.

## Exemplar designs

Seven shapes worth recognizing on sight. Find the one your data looks like before writing a
specification; what each one teaches is in references/details.md.

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
inconsistent even as pre-periods grow while SC is consistent (Arkhangelsky-Hirshberg, via the
panel survey of Arkhangelsky and Imbens 2024). Synthetic DiD also lives there. Few treated
aggregate UNITS with failed pretrends exit to synthetic-control; few treated CLUSTERS of micro
units with plausible parallel trends stay here on the few-clusters inference map
(references/details.md). When parallel trends fails and the synthetic-control exit is also
infeasible (no credible donors, short pre-period), decline the design and route back to
causal-design; a failed gate is a verdict. If treatment timing is quasi-random, DiD is valid
but inefficient; use the efficient random-timing estimators (R package staggered,
Roth-Sant'Anna).

## Assumptions and treatment dating

Parallel trends is the assumption this skill argues about. Two others get stated and forgotten,
and both fail silently.

No anticipation: the treated group's outcome is Y(0) until treatment happens. An already-treated
baseline attenuates the estimate and nothing in the diagnostics battery flags it. In the
Mixtape's simulation (Cunningham, Causal Inference: The Remix, ch. 9) a contaminated baseline
returns 0.017 against a true ATT of 10 under constant effects and 15.017 against a true 20 under
dynamic effects. Make the baseline clean. When announcement precedes enforcement and behavior
can respond (pre-announced price changes, regulatory effective dates published
months ahead), date treatment to the announcement and state the two prices: the
ATT now averages over a longer post window including announced-but-unenforced periods, and
parallel trends is now stated against a different baseline.

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
| PT-all | all groups, all periods | yes (testable, and baked in) | BJS/Gardner/LWX imputation, Wooldridge ETWFE | `didimputation`, `did2s`, `etwfe` |

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
(Roth et al. 2023). A long covariate list is a further reason to move to imputation or
Wooldridge ETWFE, since the CS propensity score is estimated per cohort and with fifty
covariates common support gets hard to assess and harder to defend. The price is that imputation
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
outcomes to current treatment). The Mixtape (Cunningham, Causal Inference: The Remix, ch. 8)
teaches that they are the same thing, true as algebra and false as design. Route the second case
to causal-design's plain-panel-fixed-effects section; nothing below applies to it.

For the first case the canon disagrees, and the skill's position is a default with named dissent:

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

The weights do something the negative-weight framing hides. Goodman-Bacon weights combine a
sample share and the treatment-timing variance Dbar(1 - Dbar), which peaks at 0.25 for a cohort
treated at the panel midpoint, so TWFE upweights mid-panel cohorts and extending or truncating
the panel moves the estimate through the weights alone. Under constant effects TWFE is unbiased
for the variance-weighted ATT and not for the simple ATT. That also reconciles bacondecomp's
all-positive weights, which sit on 2x2 comparisons, with TwoWayFEWeights' negative ones, which
sit on unit-level treatment effects: both are right, and all-positive Bacon weights do not
license TWFE.

The Mixtape (ch. 10) rejects stacking estimators on one event-study plot: "These estimators all
have slightly different assumptions and should not be considered robustness checks for one
another." Two practices are in play. Reporting TWFE beside one robust estimator is asymmetric,
because TWFE is the estimator whose bias the exercise bounds, so agreement or divergence is
information about heterogeneity. Stacking four heterogeneity-robust estimators is symmetric,
they impose different PT variants and use different comparison groups, and the objection lands
there: choose ex ante by design, and if you genuinely cannot, pre-commit to reporting all.

## Event-study mechanics

Hard rules, mostly from Abadie, Angrist, Frandsen, and Pischke (2025):

- Feasible horizons: with panel end T and cohorts c(s), longest lag q = T - min c(s), longest
  lead m = max c(s) - 1. Here s indexes treatment cohorts and c(s) is cohort s's adoption
  period. The formulas assume periods renumbered 1..T, so calendar years must be reindexed
  first.
- Always omit event time -1. The Mixtape (ch. 9) gives the reason, that no anticipation requires
  an untreated baseline, and stops there; with never-treated units that single normalization
  identifies everything, and without them a second lead or lag must also be omitted, the linear
  component of the effect path is unidentified, and different second choices rotate the whole
  path around -1. Choose deliberately, never let the software's default drop decide, and show
  the path under at least two normalizations before interpreting dynamics.
- Short gaps versus long differences, a hard rule. OLS event studies mechanically use a
  universal baseline, so every coefficient is a long difference against t = -1.
  Callaway-Sant'Anna and dCDH can produce either, and a rolling baseline gives short gaps, which
  estimate a different quantity (Roth 2026). Stata's `csdid` defaults to short gaps and needs
  `long2`, `csdid2` defaults to long differences, R's `did` needs `base_period = "universal"`.
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
likely to outweigh the risks" and prescribes a sup-t joint test of the leads. The Mixtape (ch.
10) is a third position, nearer Roth than AAFP: "event studies were always only falsifications.
They weren't true tests", parallel trends is untestable, and honest DiD is not a test of it
either. Default here: run the sup-t pretest and report it, but never let a pass substitute for
the sensitivity analysis, and report the test's power against economically relevant violations
(R package pretrends). That pretest is not a claim that parallel trends is testable. It is a
claim that a joint test with a reported power curve is a better-calibrated version of the
eyeball heuristic everyone runs anyway.

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

## Why these units were treated

Answer that before reading the pre-trend picture. The assignment mechanism is learned outside
the dataset, from institutional detail, and it decides how the picture should be read (Ghanem,
Sant'Anna, and Wüthrich; Marx, Tamer, and Tang 2024, via the Mixtape ch. 9). Five mechanisms are
compatible with parallel trends: a common constant trend in Y(0), under which PT cannot be
violated however units were selected; selection on baseline Y(0); selection on fixed effects;
selection on observables, which is conditional PT and sends you to Covariates below; and
selection under imperfect foresight. One breaks PT: selection on realized gains, where units
take the treatment because they correctly infer it will help them. The table in
references/details.md separates what each does to pre-trends from what it does to PT.

Selection on baseline Y(0) is the case that misleads. Enrolling everyone below a threshold on
baseline Y does not violate PT and does break pre-trends mechanically, because the baseline is
both the selection point and the omitted category, which manufactures a dip for the treated
group at t = -1. There is no fix because there is no problem, and re-basing to t = -2 to make
the picture look right breaks PT, which held from the original baseline.

That collides with the HonestDiD mandate, and the resolution here is the skill's own judgment.
Relative magnitudes bounds post-treatment violations by M-bar times the largest pre-treatment
violation, so under a documented selection-on-baseline-outcome mechanism the anchor is inflated
by an artifact of the assignment rule and the skill would otherwise drive you to call a valid
design fragile. Prefer the smoothness restriction there, or compute the anchor from the
pre-treatment periods excluding the selection period, and say which you did. The reverse case is
worse: under selection on realized gains, clean pre-trends are no comfort at all.

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
unaffected), then use:

- **Doubly robust (default)**: `did::att_gt(est_method="dr")`, Sant'Anna-Zhao. Consistent if
  either the outcome-change model or the propensity model is right.
- Regression adjustment when overlap is weak (extrapolates the outcome model; say so).
- IPW when you understand selection better than outcome dynamics; noisy as control propensity
  scores approach 1. Histograms and kernel densities do not reveal explosive weights, so count
  the control units with a propensity score near 1 directly. In the Mixtape's CAPS data (ch. 10)
  one control municipality scores 0.999971, which is a weight of p/(1-p) = 34,481, and eleven
  control units sit above 0.995. Trim at 0.995 and keep the trim. R's did trims automatically
  and not every package does, so check what yours does before trusting the estimate.

Conditioning on lagged outcomes changes the identifying assumption from PT to unconfoundedness.
The two are non-nested; matching on lagged outcomes can create mean-reversion bias when groups
differ in levels but genuinely trend in parallel (Daw-Hatfield, via Roth et al. 2023). When they
disagree, the bracketing result bounds the truth: under unconfoundedness with treated-group
pre-treatment dominance, TWFE underestimates and lagged-outcome adjustment overestimates
(Arkhangelsky-Imbens 2024). Report both and say which selection story you believe.

## Triple differences

A design, not a falsification. DDD identifies the ATT when the non-parallel-trends bias of the
main DiD equals that of the placebo-group DiD (Olden and Møen 2022). Two consequences change
practice: the placebo DiD does not have to be zero, so a nonzero one is no reason to discard the
design; and if it is zero the main DiD was unbiased all along, DDD was never needed, and
presenting the placebo DiD as a same-outcome-alternative-group falsification is the stronger
paper (Miller, Johnson, and Wherry 2021 is the Mixtape's instance).

Estimate it as the saturated OLS three-way interaction or its event-study form with
group-by-year, unit-by-year, and group-by-unit fixed effects and the triple interaction with
year dummies (both in references/details.md), clustered at the level treatment was applied.
Keep the caveat that DDD is not simply the difference of two DiDs once covariates or staggered
not-yet-treated comparisons enter (Ortiz-Villavicencio and Sant'Anna, via Baker et al. 2026).

## Functional form and nonlinear outcomes

Parallel trends in logs precludes parallel trends in levels. Choose the transformation on
substantive grounds and own it: "DD identification strategies are inherently
transformation-dependent" (AAFP 2025), and "the data cannot tell you which holds" (Winkler et
al. 2026, after Roth-Sant'Anna). State PT on a named scale: additive in E[Y] for levels OLS,
multiplicative in the geometric mean for log OLS, multiplicative in the arithmetic mean (the
log-link index) for PPML. Do shocks add a fixed amount or scale with baseline size? Under heavy
tails the answer is typically scale (Winkler et al. 2026, whose argument for streams is that
recommendation and playlist boosts multiply a song's existing reach). Carrying that to sales,
views, and engagement counts is this skill's judgment, so state it as yours in the paper. Run the
Roth-Sant'Anna falsification test of insensitivity to functional form when the choice is
contestable, and plot pre-trends on both scales. Apparent transformation-robustness achieved
through rich time-varying controls usually means the controls, not the fixed effects, are
identifying the effect, which is regression conditioning, and some such controls are bad
controls.

Before choosing, diagnose concentration: Lorenz curve, Gini, or top-decile share of Y (in the
TikTok data the top 10% of songs carry 76% of streams). Under heavy tails the estimator's
implicit weighting often matters more than the transformation: log OLS weights observations equally
so the long tail decides, levels OLS and PPML weight by size so the head decides. Explicit
weights are a separate estimand choice and must be predetermined and tied to the target
(Solon-Haider-Wooldridge).

Default for heavy-tailed nonnegative outcomes when the question is population-total: PPML with a
log link (`fixest::fepois`, Stata `ppmlhdfe`). It is consistent for any nonnegative Y, count or
continuous, under a correct conditional mean. Equidispersion matters only for efficiency
(Wooldridge 1997, Santos Silva-Tenreyro 2006), so pair it with cluster-robust SEs. It handles zeros
natively. Log OLS fails twice. First, zeros: log(1+y) and asinh conclusions are unit-dependent
(Chen-Roth), and with many zeros the typical-unit estimand is gone, so PPML is the practical choice
even though it targets population-total. Second, variance shifts: E[log Y] = log E[Y] - Var(log
Y)/2 - higher cumulants, so treatment that compresses Var(log Y) pushes the mean-log DiD up by
-ΔΔVar(log Y)/2, and log OLS returns a positive significant coefficient under a true null on the
mean even with no zeros anywhere (Winkler et al. 2026, calibrated simulation). Diagnose it with the
Ciani-Fisher regression of squared log-OLS residuals on treat x post with the fixed effects. A
significant coefficient rules out log OLS for the population-total estimand. Weighted log OLS with
predetermined pre-period share weights is the transparency check on PPML when Y > 0 and log
variance is stable.

Levels OLS is sign-unstable when untreated outcomes grow proportionally and treated and control
baselines differ: the bias grows in the baseline gap and the growth rate and flips sign in a
calibrated grid (Winkler et al. 2026). Matching on baseline levels closes the gap, which is why
levels, logs, and PPML agree in matched samples. That agreement is a special case the design
created, evidence about the design and never proof the specifications are interchangeable. The
matching defense does not transport to synthetic DiD, which balances pre-period outcomes but allows
an intercept shift, so a levels SDID inherits the same baseline-gap sensitivity.

Binary and count outcomes (and fractional ones, Wooldridge 2023) get the Wooldridge nonlinear
recipe (2023 for panels, 2026 for repeated cross sections): one pooled QMLE in the linear
exponential family with the canonical link (Bernoulli-logit, Poisson-log; normal-identity is the
linear special case), cohort dummies, time dummies, covariates centered within cohort-period cells
and interacted with cohort, time, and treatment, and treatment dummies by cohort and period. PT is
imposed on the index G^{-1}(E[Y_t(0) | D, X]), the log odds or the log mean, and Wooldridge is
explicit that Callaway-Sant'Anna, BJS, and DNWZ state PT in levels. Index PT holds in levels only
under no selection (cohort effects and their covariate interactions all zero) or a stationarity
restriction, so the linear and nonlinear answers rest on different assumptions. Wooldridge
recommends fitting both and comparing them, with a divergence read as evidence about the PT scale.
Only the conditional mean has to be right. The estimator is robust to distributional
misspecification, and with a canonical link pooled QMLE equals imputation without the two-step
standard-error problem. ATT(g,t) are average partial effects of the treatment dummy on the response
scale, aggregated by exposure time with cell-size weights. The event study used to diagnose PT is
aggregated on the index scale (log odds, log mean), where the assumption lives. Report both the
lags-only and the leads-and-lags versions: they have different sensitivities to PT violations and
cannot be ranked on bias or efficiency. Cohort-specific linear trends are a contamination-free
pre-trend test when covariates enter flexibly, at a precision cost. When a cohort cell is thin,
collapse the cohort-by-period dummies to exposure-time dummies, or in the limit a single treatment
indicator, and compare with the flexible aggregate. R: etwfe (`family = "poisson"` or `"logit"`,
which makes it drop unit fixed effects and enter cohort and period as explicit dummies, then `emfx`
for the APEs). Stata: jwdid with `method(poisson)` or `method(logit)`.

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

Two Mixtape rules to disarm. Chapter 9 reads Card and Krueger's two-state minimum wage design off
a t-statistic of about 2 and calls it significant; at the assignment level that is G = 2 with one
treated cluster, every MacKinnon-Nielsen-Webb concern zone firing at once and a CV1 standard
error that can be too small by a factor of five or more. It is the canonical exemplar of the DiD
idea and not a template for inference, and a modern version of it lands on the few-clusters map
or the synthetic-control handoff. Chapter 8's rule of thumb, fewer than 30 clusters too small and
30 to 40 probably enough, is unsafe in both directions: CV1 can be reliable at G = 20 in
favorable cases and unreliable at G = 200 in unfavorable ones. Run the battery instead of
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
  fine without covariates; with covariates, test compositional stability (Sant'Anna-Xu
  Hausman-type check) before pooling. The failure is compositional change: who is sampled moves
  with treatment timing in a way correlated with Y(0), so PT breaks with nobody mistreated (Hong
  2013 on Napster, where internet users got older, poorer, and less likely to hold a degree as
  the treatment spread). Two diagnostics: covariate means across periods by group, and a DiD run
  with each strictly exogenous covariate as the outcome, where a significant interaction is
  differential compositional drift. Hong's fix is two period-specific propensity scores, one pre
  and one post, as inverse probability weights in a WLS DiD; Sant'Anna-Xu is the modern test.
  Unit fixed effects are unavailable, so the Wooldridge
  (2026) design puts cohort dummies in their place with covariates centered within
  cohort-period cells; it covers staggered adoption and nonlinear outcomes in one pooled QMLE,
  weights ATT(g,t) by the cell sizes N_gt when aggregating, and clusters at the assignment
  level (census tract, DMA) even under independent sampling (AAIW). Cell sizes govern whether
  the SEs are believable, so collapse thin cohorts to exposure-time effects. You cannot verify
  that covariates are time-invariant when each unit is seen once. Say so.

## The design stage, before you look at the outcome

In order, each finished before the next. Nothing before the last step needs the outcome, and
that deferral is the discipline (Rubin 2008's design trumps analysis, via the Mixtape ch. 10).

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
12. Falsifications, both families, read by the rule below.
13. Mechanism: why the effect happened, and evidence consistent with that story.

## The evidence battery

Bite comes first in time and is the cheapest thing in this file. Before estimating effects on the
outcome you care about, show the treatment changed what it was supposed to change: take-up,
exposure, eligibility, enrollment, price paid, impressions delivered. With no first stage there
is no reason to expect a reduced form, and the project can die here before the expensive
machinery runs. Snow tested the salt content of tap water himself when households did not know
their supplier: measure the treatment yourself and do not trust the merge.

Falsification has two families, the same outcome on an alternative group your treatment cannot
have touched and the same group on an alternative outcome your treatment cannot move. Read a
null as suggestive evidence for parallel trends, of the same evidentiary class as a clean
pre-trend; a rejection does not prove the main result spurious, it revives a rival explanation
you now have to answer. Mechanism is the third item: say why the effect happened and show
something consistent with it.

Falsifications and event studies answer different questions, and the Mixtape (ch. 9) ranks
falsifications higher for judging parallel trends. The event study plus HonestDiD bounds how
large a PT violation the conclusion survives; a falsification tests whether one named rival
explanation makes a prediction that fails. Run both.

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

etwfe takes as never-treated any cohort value above max(period), else below min(period), so
the did-style 0 works when periods start at 1. With `cgroup = "never"` an in-range value
errors. Leads exist only under `cgroup = "never"` (`"notyet"` sets them to zero mechanically,
and `post_only` is read only for `"notyet"` fits). etwfe demeans controls by cohort, the
Wooldridge 2023 panel form; the 2026 cohort-period centering changes only the raw index
coefficients, never the ATTs. Above 500,000 rows emfx compresses to cohort-period cells
(`compress = "auto"`), exact for `y ~ 0` and an approximation once controls enter, so set
`compress = FALSE` then.

Stata equivalents on request: csdid, did_imputation, eventstudyinteract, jwdid, honestdid, boottest
for wild bootstrap, ppmlhdfe for PPML, and jwdid with `method(poisson|logit)` for the nonlinear
recipe (no `ivar` means repeated cross-section; covariates are demeaned by default). The Baker et
al. AEA replication package (aeaweb.org/articles/materials/25430, 25431) is a full R and Stata
template.

## Methods paragraph template

Adapt, keeping the first-person limitation at the point of the choice:

> Treatment is staggered and effects are plausibly heterogeneous, so static and dynamic two-way
> fixed effects estimands can place negative weights on some group-time effects (Roth,
> Sant'Anna, Bilinski, and Poe 2023; Goodman-Bacon 2021). Following the forward-engineering
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
> [level], the level at which treatment is independently assigned (Roth et al. 2023).

Every claim in the paragraph must trace to a canon entry; references/canon.md maps claims to
papers and BibTeX keys in the shared causal-design/references/causal.bib. Verify any primary
paper cited beyond the canon with bibcheck before submission.

## Handoffs

- causal-design: design triage before this skill; shared inference material.
- synthetic-control: few treated units, long pre-period, selection on lagged outcomes, failed
  pretests ("sidesteps collinearity concerns while allowing for divergent nonlinear trends",
  AAFP citing Abadie 2021). Synthetic DiD is that skill's bridge topic, not this one's. A
  levels SDID inherits the baseline-gap sensitivity of levels DiD (Winkler et al. 2026), so the
  scale question travels with the handoff.
- field-experiment: when rollout timing was actually randomized, randomization-based tools
  apply; the staggered estimator itself is documented here (R package staggered, Roth-Sant'Anna).
- iv: share-balance pre-trend scrutiny for shift-share exposure designs lands here; the
  parallel-trends toolkit applies to share balance.
- rdd: policy-date designs masquerading as RD in time arrive here when many units switch at a
  date; treat the date as an event study, not a cutoff.
- preregister: pre-specifying a DiD analysis of a known upcoming natural experiment.
