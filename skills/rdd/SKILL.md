---
name: rdd
description: Design, estimate, validate, and write up a regression discontinuity analysis, in both the continuity and local-randomization frameworks, with the full falsification battery and a refusal rule for designs that fail validation. TRIGGER on "regression discontinuity", "RDD", "running variable", "score cutoff", "rdrobust", "bandwidth selection", "McCrary test", "density test", "fuzzy RD", "regression kink", "local randomization", "donut", "geographic RD", "boundary discontinuity", "multiple cutoffs", "heaping", "rddensity", "rdlocrand", "RDHonest", or any setting where treatment switches at a known score threshold (loyalty tiers, spend thresholds, ranking cutoffs, algorithmic triggers, eligibility scores, age or tenure rules).
---

# Regression discontinuity

An opinionated RD workflow grounded in a read canon (references/canon.md, current as of
2026-07-28): the Cattaneo-Titiunik Annual Review of Economics survey and its applied companion,
the Cattaneo-Keele-Titiunik guide, which includes a real failed design this skill uses as its
refusal template. Deliverable: the recommendation with its citation, the R estimation and
diagnostics code, and a methods paragraph. The skill stops at the four stop points in
../causal-design/references/shared-rules.md (section "Stop points") and puts each choice to the user.

Refresh path: run litreview on the method since the canon date, then propose additions to
references/canon.md as flagged addenda.

## Design shapes and the case that anchors each

Each canonical case is a precedent a methods section can cite; details.md says what each teaches.

| Design shape | Canonical case | Marketing analogue | What kills it |
|---|---|---|---|
| Age or tenure eligibility rule | Card, Dobkin, Maestas 2008 | trial expiry, anniversary status rolloff | something else switches at the same threshold |
| Agency-measured score, sharp | Hansen 2015 | churn-score retention offers | reps or managers override the rule off-cutoff |
| Heaped or rounded score | Almond et al. 2010; Barreca et al. 2011, 2016 | spend thresholds recorded in whole dollars | excess mass at round values that the density test misses |
| Share crossing a fixed bar | Lee, Moretti, Butler 2004 | seller badge above an on-time-delivery rate | predetermined covariates already jump in the smallest window |
| Admission cutoff, fuzzy first stage | Hoekstra 2009 | lead-score outreach with rep discretion | a first stage too weak to carry the ratio |
| Boundary or geographic RD | Black 1999 | DMA advertising borders | the border sorts households, or ads spill across it |

## The design gate: is this an RD at all?

An RD requires a score, a known cutoff, and a treatment rule that existed ex ante and is
verifiable. Before any estimation, write the qualitative account: who computes the score, was
the cutoff public, can agents precisely control their score near it. Precise manipulation is the
most important threat. Lab-measured or third-party-computed scores resist it; self-influenced
scores (customer spend near a tier threshold, follower counts near a monetization bar) invite
exactly the sorting the density test detects, so the falsification battery carries more weight
in marketing settings than in the medical originals.

One more gate question, and the one sharp designs skip: list every rule, benefit, message, and
flag that changes at this exact threshold, and say which of them is the treatment. Medicare
starts at 65 and so does retirement, so Card, Dobkin, and Maestas (2008) went to a third dataset
on the same running variable (the pooled March CPS 1996-2004, pp. 2247-2248) and showed
employment does not jump. When
the confounder is not in your data, find a dataset on the same score where it is.

State the no-interference assumption: one unit's side of the cutoff does not change another
unit's outcome. A seller badge or a loyalty tier can shift the competitors and peers sitting
just below the cutoff. When that is plausible, the estimate mixes the direct effect with a
spillover onto the comparison group, and the price is that the RD no longer identifies the
direct effect alone. Name the channel in the write-up. Spillover designs belong to the
field-experiment skill's interference material.

Two red flags come from the failed Oncotype-DX application in Cattaneo-Keele-Titiunik (2023).
The guide read the take-up jumps at scores 24 and 25 as evidence the guideline was not followed.
It rejected the design on the weak first stage (F = 1.51) and on imbalance in the smallest
windows. Treating the first flag as disqualifying on its own is this skill's judgment. Off-cutoff
jumps mean the official cutoff is not the rule that assigns treatment.

1. Treatment take-up jumps at score values away from the official cutoff (the rule was soft:
   reps contact leads below the threshold, managers grant status matches early). Plot take-up
   against the score before anything else.
2. Covariate imbalance already in the smallest window around the cutoff: disqualifying when
   the imbalanced covariate plausibly drives the outcome (the balance battery's standard,
   below), otherwise a serious flag that demands an explanation before proceeding.

When a design fails, say so and decline to report an effect; the guide's own verdict on its
failed application ("the evidence does not support an RD analysis") is the template. Route the
question back to causal-design for another identification strategy.

## Triage: two frameworks, and which one leads

Sharp vs fuzzy is a fact of the institution, not a choice: sharp when the rule binds
mechanically (a trial expires, a discount ends at an anniversary), fuzzy whenever anyone can
cross their assignment (overrides, opt-ins). Under fuzziness always report both ITT effects (on
take-up and on the outcome) alongside the fuzzy ratio.

Continuity vs local randomization is decided by the score:

- Continuous score, many observations near the cutoff: continuity framework with local
  polynomials leads; local randomization is the robustness complement.
- Discrete score (rule of thumb: roughly 30 or fewer distinct values) or very few observations
  near the cutoff: local randomization leads. Continuity methods there extrapolate from the
  nearest mass points and their effective sample size is the number of mass points, not the
  number of observations. Discrete running variables (weeks of tenure, order counts, months
  since signup) are the norm in marketing data, which makes this branch more common than the
  econ literature suggests.
- Local randomization needs a stronger and different assumption (potential outcomes unrelated
  to the score inside the window), which must be argued. The two are not nested: local
  randomization stays valid for discrete scores where continuity methods may fail
  (Cattaneo-Keele-Titiunik 2023, sec. 2.3).

When both frameworks apply, run both; agreement is a robustness result, and the local
randomization CIs covering the continuity point estimate counts as consistency. Expect the
window to be far narrower than the bandwidth (in the guide's HIV application, 121 patients vs
2,593), so a local-randomization null alongside a significant continuity estimate can be a power
difference, not a contradiction.

## The consensus recipe (continuity framework)

Local linear regression, triangular kernel, MSE-optimal bandwidth, robust bias-corrected
confidence intervals (Calonico-Cattaneo-Titiunik). Report both the conventional and the robust
interval. The one-line justification: in the survey's back-of-the-envelope calculation
(Cattaneo and Titiunik 2022), conventional 95 percent intervals at the MSE-optimal bandwidth
cover only about 80 percent, and bias correction with the matching variance adjustment
restores coverage at the same bandwidth. Two things get called robust: Cunningham, The Mixtape,
online ch. 6 sec. 6.6, moves between heteroskedasticity-robust OLS standard errors
and rdrobust's Robust row without flagging the difference, and this skill keeps them apart
because HC-robust errors leave the point estimate alone while rdrobust's Robust row recenters on
the bias-corrected estimate and widens the interval by the variance of the bias estimate.

Hard rules from the review, stated as prohibitions because that is how it states them:

- Bandwidths must be data-driven and criterion-optimal; choosing one by hand "is discouraged."
  MSE-optimal for the point estimate, CE-optimal when the interval is the object. Distinct
  left/right bandwidths are available when curvature differs by side. The Mixtape (online ch. 6
  sec. 6.6) replicates Hansen 2015 with hand-picked bandwidths and a rectangular kernel, which
  is how RD was done before 2014; this skill refuses that as a primary specification and keeps it only
  for reproducing a paper that predates the criterion-optimal machinery.
- Never cluster standard errors on the running variable. Lee 2008 and Lee and Card 2008
  recommended the practice. This skill states it as a prohibition because Kolesar and Rothe 2018
  show that the confidence interval clustered on a discrete score can undercover, with coverage
  as low as 58 percent at a nominal 95 percent (p. 2279). Use heteroskedasticity-robust
  variance, honest intervals for a discrete score (RDHonestBME, below), and cluster only on a
  real assignment unit that is not the score. Replicating or refereeing an older RD, expect to
  find this and fix it. The family's clustering and multiplicity rules (cluster level, few
  clusters, a multiplicity statement for the balance battery) are in
  ../causal-design/references/shared-rules.md.
- Global polynomial fits are visualization only, never estimation (Gelman-Imbens): boundary
  behavior, counterintuitive weighting, overfitting.
- Polynomial order: p = 1 default, p = 2 as the robustness check, never high order. Underfitting
  biases in the other direction, and the Mixtape's cubic simulation with a true zero effect makes
  it vivid (online ch. 6 sec. 6.3, Table 6.1): -176,368.30 from a linear fit and 61,866.33 from
  a quadratic against 1.14 from the cubic. Curvature is handled by narrowing the window, since
  the common MSE-optimal bandwidth shrinks as the curvature difference across the cutoff
  rises (Imbens and Kalyanaraman 2012). h_MSE
  also grows with p, so the p = 2 check runs on a wider window and a different effective sample.
  In the Mixtape's Table 6.8 (online ch. 6 sec. 6.6) the left bandwidth goes 0.020, 0.033,
  0.038 and the effective N 13,794, 16,774, 17,545 as the fit goes from no polynomial term to BAC
  to BAC and BAC-squared. When p = 2 moves the estimate, check the window.
- Covariates are for precision only (Calonico, Cattaneo, Farrell, and Titiunik 2019); they
  cannot restore identification of the canonical RD parameter, and adjusting an invalid design
  changes the parameter rather than rescuing it. The point estimate should barely move when
  covariates enter; a large move signals imbalance.

## The local-randomization recipe

Select the window by nested covariate-balance tests, then difference in means inside it, with
Fisherian randomization inference when the window holds few observations (exact under the sharp
null) and Neyman or super-population inference when it is well populated. Window-selection
mechanics, thresholds, and what a narrow window does to power: references/details.md.

## Fuzzy designs: the IV discipline applies

The fuzzy estimand is a complier average effect at the cutoff under relevance, exclusion, and
monotonicity, so the iv skill's habits transfer:

- Test the first stage inside the bandwidth or window, never on the full sample; the full-sample
  F overstates strength. The guide's contrast is the anchor: F around 698 in the valid design
  against F = 1.51 in the failed one, where the first-stage effect is 0.15 with a Fisherian
  p-value of 0.32. An in-bandwidth first-stage F that is neither the strong nor the hopeless
  extreme goes to the iv skill's ladder for reading F. The weak-first-stage intervals come from
  RD-native tools. In the window, use rdrandinf(fuzzy = list(d, "ar")), whose default statistic
  is Anderson-Rubin. In the continuity framework, use the bias-aware confidence sets of Noack and
  Rothe (2024), which are built like Anderson-Rubin sets and stay valid under weak
  identification. Do not report the 2SLS t.
- Argue exclusion qualitatively and concretely: it fails if crossing the cutoff changes behavior
  through anything other than treatment (a low churn score triggering a retention call AND a
  flag another team acts on).
- Monotonicity: safe when crossing the threshold moves treatment in one direction only; suspect
  when overrides run in both directions (the failed-design pattern above, reps contacting
  below-threshold leads while managers grant early crossings, is exactly the defiers case);
  one-sided noncompliance buys it for free.
- Run fuzzy-ratio balance tests: instrument strength amplifies covariate bias, so imbalance
  invisible to ITT balance can surface in the ratio.
- Use one MSE-optimal bandwidth for the ratio, not separate ones for numerator and denominator.

## Falsification battery

Run them in this order. Each check's bandwidth convention and what its failure means are in
references/details.md.

1. Qualitative manipulation account, written before estimation (who computes the score, who
   knows the cutoff).
2. Density continuity test (rddensity, robust bias-corrected) plus the exact binomial count test
   in small windows. A discontinuous density demands an explanation, and the sorting behind it
   can be administrative rather than strategic. When it cannot be explained, report the
   manipulation-robust bounds of Gerard, Rokkanen, and Rothe (2020) or walk away.
3. Heaping: plot the raw histogram of the score at its finest granularity before any formal
   test. The density test can pass while heaping biases the estimate, so run the donut whatever
   the density test says (Almond et al. 2010; Barreca et al. 2011, 2016).
4. Covariate and placebo-outcome balance: the full RD machinery with each predetermined
   covariate as the outcome, a fresh MSE-optimal bandwidth per covariate, robust p-values. A
   failure on a covariate that plausibly drives the outcome invalidates the design, and the
   verdict is to walk away rather than to adjust.
5. Placebo cutoffs, one side of the true cutoff at a time so treatment effects do not
   contaminate the placebo.
6. Donut hole: drop the observations at and immediately adjacent to the cutoff, keep the
   original bandwidth, re-estimate. The donut estimate is a different parameter, local to a
   wider neighborhood, and the write-up should describe it as one.
7. Bandwidth and window sensitivity: instability at or below the chosen bandwidth is the warning
   sign, failure far above it is expected by construction.

When a null matters, report minimum detectable effects (rdpower), never ex-post power from the
observed effect.

## The live dispute, carried honestly

Robust bias correction (this canon's school) vs honest uniform-in-bias inference
(Armstrong-Kolesar, Imbens-Wager; R package RDHonest). The honest school bounds the second
derivative by a constant M and gets uniformly valid intervals; the canon's objection is that a
data-driven M destroys the uniformity that motivates the method, and a manual M is equivalent to
choosing the bandwidth by hand. RDHonest has two data-driven routes. RDSmoothnessBound()
estimates a lower bound on M, and RDHonest() falls back to the Armstrong-Kolesár (2020) rule
of thumb when M is omitted (MROT, confirmed in the 1.0.2 CRAN source). Default here: RBC. When a
referee or coauthor asks for honest intervals, report RDHonest alongside with the M choice
justified in text, and cite both sides.

The honest school's fuzzy answer is Noack and Rothe (2024). Their bias-aware confidence sets
match the usual procedures under strong identification and a continuous score. They stay valid
with a discrete score, a donut, or a weak first stage, where the delta-method interval relies
on approximations that can fail. Report them when the in-bandwidth first stage is weak. They
are not on CRAN (index checked 2026-10-09). The authors' FRD package is a Windows binary on
Noack's site, and we have not checked it. A 2025 preprint (Ghosh, Imbens, and Wager, PLRD)
argues that widely used RD intervals often behave suboptimally in simulations calibrated to
twelve published applications. In its v3, rdrobust's RBC intervals undercover in some
calibrated designs and at n = 500 (Tables 1 and 3).

## Extensions, briefly

- Kink designs: same machinery on first derivatives; identification is more delicate.
- Multiple cutoffs or scores (tiered loyalty programs): cutoff-specific effects or
  normalize-and-pool (rdmulti), with the pooled estimand's interpretation checked.
- Geographic or boundary RD (DMA advertising borders): rd2d (Cattaneo, Titiunik, and Yu 2025)
  estimates effects along the boundary from each unit's two-dimensional location, with uniform
  inference over boundary points.
- Heterogeneity (subgroup effects at the cutoff): rdhte (Calonico, Cattaneo, Farrell, Palomba,
  and Titiunik 2025) fits a fully interacted local linear model with robust bias-corrected
  inference and tests group differences, where applied work has used ad hoc approaches.
- Repeated thresholds (monthly tier evaluations, where a unit can cross the cutoff many times):
  a static RD misreads the long-run effect. Hsu and Shen (2024) give identification and
  inference for dynamic RD under heterogeneous effects.
- RD in time: hard to justify as standard RD; the local-randomization framework is the
  adaptation when it works at all. Prefer did or synthetic-control for policy-date designs.
- Extrapolation beyond the cutoff LATE needs added assumptions, and the menu is in
  references/details.md. Say which one when claiming anything away from the cutoff. Absent one,
  the methods paragraph says the estimate is local to the cutoff, full stop.

## R implementation

The complete runnable pipeline is scripts/rdd_template.R (estimation in both frameworks, fuzzy
diagnostics, the full falsification battery, power/MDE), with every call verified against the
rdpackages suite. The core:

```r
library(rdrobust); library(rddensity); library(rdlocrand)
rdplot(y, x, c = cutoff)                      # anatomy first
summary(rdrobust(y, x, c = cutoff))           # sharp: local linear, triangular, MSE-h, RBC
summary(rdrobust(d, x, c = cutoff))           # first stage / ITT on take-up
summary(rdrobust(y, x, c = cutoff, fuzzy = d))# fuzzy ratio
summary(rddensity(x, c = cutoff))             # manipulation
w <- rdwinselect(x, Z, cutoff = cutoff)       # local-randomization window
rdrandinf(y, x, cutoff = cutoff, wl = w$w_left, wr = w$w_right)
```

Four figures carry a credible RD: the density of the score, take-up against the score, covariate
balance, and the outcome in bin means. If you cannot see the effect in the bin means you are
underpowered or it is not there. Report the estimate against the mean of the dependent variable,
so a small coefficient on a large base reads as a precise null (0.6 points on an 84.6 percent
base, in the Mixtape's balance table, online ch. 6 sec. 6.6, Table 6.6).

Package index with versions and links in references/details.md. Stata and Python mirrors of the
whole suite live at rdpackages.github.io; the guide ships full replication code in all three.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

> Treatment assignment changes discontinuously at [cutoff] in [score], a rule set by
> [institution] before the outcomes we study, and units [cannot / can only imprecisely] control
> their score near it. The estimand is [the average effect of treatment for units at the cutoff
> (sharp) / the average effect for compliers at the cutoff (fuzzy)]. We estimate the RD effect
> with local linear regression, a triangular kernel, and an MSE-optimal bandwidth of [h] on
> [each side / the left and right] ([N_left] and [N_right] observations inside it), and report
> robust bias-corrected confidence intervals (Calonico, Cattaneo, and Titiunik 2014; Cattaneo
> and Titiunik 2022). Standard errors use [the nearest-neighbor heteroskedasticity-robust
> variance / CR3 variance clustered by [unit], with [G] clusters]. [In the local-randomization
> framework, the window [w_left, w_right] holds [N_w] observations, and the Fisherian
> difference in means is [estimate] (p = [p]).] We validate the design
> with the Cattaneo-Jansson-Ma density test and an exact binomial test, covariate balance at the
> cutoff with per-covariate bandwidths, placebo cutoffs, donut-hole estimates, and bandwidth
> sensitivity [and, for the fuzzy design, verify first-stage strength within the estimation
> bandwidth and report intention-to-treat effects alongside the complier estimate]. The estimate
> is local to the cutoff; a limitation of this design is that it does not identify effects for
> [units far from the threshold], and I extrapolate only [not at all / under the stated
> assumption], which costs [generalizability across the score distribution].

Every claim traces to references/canon.md; keys live in ../causal-design/references/causal.bib.

## Handoffs

- causal-design: whether an RD exists at all; where to go when the design gate fails.
- iv: the fuzzy branch's in-bandwidth first stage and exclusion argument live here;
  weak-instrument inference (the F ladder, AR/CLR intervals) lives in iv, along with
  many-instrument and shift-share logic.
- did / synthetic-control: policy-date designs masquerading as RD in time.
- Preregistration: the user writes it themselves; this skill supplies the RD field list for an
  upcoming threshold change.
