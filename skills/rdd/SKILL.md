---
name: rdd
description: Design, estimate, validate, and write up a regression discontinuity analysis, in both the continuity and local-randomization frameworks, with the full falsification battery and a refusal rule for designs that fail validation. Produces advice with citations, R estimation and diagnostics code, and a drafted methods paragraph. TRIGGER on "regression discontinuity", "RDD", "RD design", "running variable", "cutoff", "threshold", "rdrobust", "bandwidth", "McCrary test", "density test", "fuzzy RD", "regression kink", or any setting where treatment switches at a known score threshold (loyalty tiers, spend thresholds, ranking cutoffs, algorithmic triggers, eligibility scores, age or tenure rules). Design triage across methods belongs to causal-design.
---

# Regression discontinuity

An opinionated RD workflow grounded in a read canon (references/canon.md, current as of
2026-07-28): the Cattaneo-Titiunik Annual Review of Economics survey and its applied companion,
the Cattaneo-Keele-Titiunik guide, which includes a real failed design this skill uses as its
refusal template. The deliverable is the specification decision with the citation that justifies
it, the estimation and diagnostics code in R (Stata and Python exist for the whole suite), and a
methods paragraph with the limitation stated in first person at the point of the choice.

Refresh path: run the litreview skill on the method since the canon date and fold results into
references/canon.md as flagged addenda.

## The design gate: is this an RD at all?

An RD requires a score, a known cutoff, and a treatment rule that existed ex ante and is
verifiable. Before any estimation, write the qualitative account: who computes the score, was
the cutoff public, can agents precisely control their score near it. Precise manipulation is the
most important threat. Lab-measured or third-party-computed scores resist it; self-influenced
scores (customer spend near a tier threshold, follower counts near a monetization bar) invite
exactly the sorting the density test detects, so the falsification battery carries more weight
in marketing settings than in the medical originals.

Two red flags, the first disqualifying on its own (from the failed Oncotype-DX application in
Cattaneo-Keele-Titiunik 2023):

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
- Local randomization needs a strictly stronger assumption (potential outcomes unrelated to the
  score inside the window), which must be argued, not assumed.

When both frameworks apply, run both; agreement is a robustness result, and the local
randomization CIs covering the continuity point estimate counts as consistency. Expect the
window to be far narrower than the bandwidth (in the guide's HIV application, 121 patients vs
2,593), so a local-randomization null alongside a significant continuity estimate can be a power
difference, not a contradiction.

## The consensus recipe (continuity framework)

Local linear regression, triangular kernel, MSE-optimal bandwidth, robust bias-corrected
confidence intervals (Calonico-Cattaneo-Titiunik). Report both the conventional and the robust
interval. The one-line justification: conventional 95 percent intervals at the MSE-optimal
bandwidth cover only about 80 percent, and bias correction with the matching variance adjustment
restores coverage at the same bandwidth.

Hard rules from the review, stated as prohibitions because that is how it states them:

- Bandwidths must be data-driven and criterion-optimal; choosing one by hand "is discouraged."
  MSE-optimal for the point estimate, CE-optimal when the interval is the object. Distinct
  left/right bandwidths are available when curvature differs by side.
- Global polynomial fits are visualization only, never estimation (Gelman-Imbens): boundary
  behavior, counterintuitive weighting, overfitting.
- Polynomial order: p = 1 default, p = 2 as the robustness check, never high order.
- Covariates are for precision only; they cannot restore identification of the canonical RD
  parameter, and adjusting an invalid design changes the parameter rather than rescuing it. The
  point estimate should barely move when covariates enter; a large move signals imbalance.

## The local-randomization recipe

Select the window by nested covariate-balance tests: start from the smallest window with at
least about 10 observations per side, enlarge until balance rejects, using a deliberately loose
threshold (p < 0.15, no multiplicity correction, since over-rejection just shrinks the window).
Then difference in means inside the window, with Fisherian randomization inference when the
window holds few observations (exact under the sharp null; point estimates and CIs then require
a constant-effect model), Neyman or super-population inference when it is well populated.

## Fuzzy designs: the IV discipline applies

The fuzzy estimand is a complier average effect at the cutoff under relevance, exclusion, and
monotonicity, so the iv skill's habits transfer:

- Test the first stage inside the bandwidth or window, never on the full sample; the full-sample
  F overstates strength. The guide's contrast is the anchor: F around 698 in the valid design,
  F = 1.51 (Fisherian p = 0.32) in the failed one. An in-bandwidth first-stage F that is neither
  the strong nor the hopeless extreme goes to the iv skill's ladder: read it against the F
  targets there and report Anderson-Rubin/CLR intervals rather than the 2SLS t.
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

In the order the guide applies them, with each check's bandwidth convention:

1. Qualitative manipulation account (who computes the score, who knows the cutoff).
2. Density continuity test (rddensity, robust bias-corrected) plus the exact binomial count
   test in small windows (framework-free, works for discrete scores; keep the window narrow
   enough that a constant assignment probability is sensible). A discontinuous density is
   neither necessary nor sufficient for invalidity, but it demands an explanation; sorting can
   be administrative rather than strategic.
3. Covariate and placebo-outcome balance: the full RD machinery with each predetermined
   covariate as the outcome, a fresh MSE-optimal bandwidth per covariate, robust p-values. A
   failure on a covariate that plausibly drives the outcome invalidates the design. The
   equivalence-test formulation (null of imbalance) is the more honest variant when you want to
   claim balance affirmatively.
4. Placebo cutoffs: re-run at artificial cutoffs, one side of the true cutoff at a time so
   treatment effects do not contaminate the placebo.
5. Donut hole: drop the observations at and immediately adjacent to the cutoff, keep the
   original bandwidth, re-estimate. Binds hardest where agents can time their crossing (spend
   thresholds). Large swings mean the effect rides on the most manipulable observations.
6. Bandwidth and window sensitivity: instability at or below the chosen bandwidth is the
   warning sign; failure far above it is expected by construction and not damning.

Ex-post power calculations from observed effects are unreliable; when a null matters, report
minimum detectable effects instead (rdpower).

## The live dispute, carried honestly

Robust bias correction (this canon's school) vs honest uniform-in-bias inference
(Armstrong-Kolesar, Imbens-Wager; R package RDHonest). The honest school bounds the second
derivative by a constant M and gets uniformly valid intervals; the canon's objection is that a
data-driven M destroys the uniformity that motivates the method, and a manual M is equivalent to
choosing the bandwidth by hand. Default here: RBC. When a referee or coauthor asks for honest
intervals, report RDHonest alongside with the M choice justified in text, and cite both sides.

## Extensions, briefly

- Kink designs: same machinery on first derivatives; identification is more delicate.
- Multiple cutoffs or scores (tiered loyalty programs; geographic borders such as DMA
  boundaries): cutoff-specific effects or normalize-and-pool (rdmulti), with the pooled
  estimand's interpretation checked.
- RD in time: hard to justify as standard RD; the local-randomization framework is the
  adaptation when it works at all. Prefer did or synthetic-control for policy-date designs.
- Extrapolation beyond the cutoff LATE needs added assumptions: multi-cutoff variation,
  pre-period outcomes, ignorability-based, or derivative-based local extrapolation. Say which
  when claiming anything away from the cutoff.

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
w <- rdwinselect(x, Z, c = cutoff)            # local-randomization window
rdrandinf(y, x, cutoff = cutoff, wl = w$w_left, wr = w$w_right)
```

Package index with versions and links in references/details.md. Stata and Python mirrors of the
whole suite live at rdpackages.github.io; the guide ships full replication code in all three.

## Methods paragraph template

> Treatment assignment changes discontinuously at [cutoff] in [score], a rule set by
> [institution] before the outcomes we study, and units [cannot / can only imprecisely] control
> their score near it. We estimate the RD effect with local linear regression, a triangular
> kernel, and an MSE-optimal bandwidth, and report robust bias-corrected confidence intervals
> (Calonico, Cattaneo, and Titiunik 2014; Cattaneo and Titiunik 2022). We validate the design
> with the Cattaneo-Jansson-Ma density test and an exact binomial test, covariate balance at the
> cutoff with per-covariate bandwidths, placebo cutoffs, donut-hole estimates, and bandwidth
> sensitivity [and, for the fuzzy design, verify first-stage strength within the estimation
> bandwidth and report intention-to-treat effects alongside the complier estimate]. The estimate
> is local to the cutoff; a limitation of this design is that it does not identify effects for
> [units far from the threshold], and I extrapolate only [not at all / under the stated
> assumption], which costs [generalizability across the score distribution].

Every claim traces to references/canon.md; keys live in causal-design/references/causal.bib.

## Handoffs

- causal-design: whether an RD exists at all; where to go when the design gate fails.
- iv: the fuzzy branch's in-bandwidth first stage and exclusion argument live here;
  weak-instrument inference (the F ladder, AR/CLR intervals) lives in iv, along with
  many-instrument and shift-share logic.
- did / synthetic-control: policy-date designs masquerading as RD in time.
- preregister: pre-specifying an RD on an upcoming threshold change.
