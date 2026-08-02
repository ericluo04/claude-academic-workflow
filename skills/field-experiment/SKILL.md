---
name: field-experiment
description: Design, analyze, and write up randomized experiments (field experiments, A/B tests, RCTs), covering stratified and clustered designs, randomization inference, covariate adjustment done right, noncompliance, attrition and gated outcomes, treatment-effect heterogeneity, and interference. Produces advice with citations, R estimation and diagnostics code, and a drafted methods paragraph. TRIGGER on "A/B test", "randomized experiment", "RCT", "field experiment", "holdout", "lift test", "randomization inference", "stratified randomization", "cluster randomized", "geo experiment", "power analysis", "MDE", "encouragement design", "noncompliance", "ITT", "attrition", "Lee bounds", "CUPED", "variance reduction", "uplift", "heterogeneous treatment effects", "causal forest" (experimental heterogeneity; observational causal forests belong to causal-design), "interference", "spillover", "SUTVA". Pre-registration documents belong to the preregister skill; design triage across methods belongs to causal-design.
---

# Field experiments

An opinionated experimental workflow grounded in a read canon (references/canon.md, current as
of 2026-07-28): the Athey-Imbens handbook chapter as the spine (randomization-based inference
first), Freedman's logistic-regression critique and Lin's repair for covariate adjustment,
Guo-Basse's generalization to nonlinear outcomes, and Lee's bounds for attrition and gated
outcomes. The deliverable is the design or analysis decision with the citation that justifies
it, the estimation and diagnostics code in R, and a methods paragraph with the limitation
stated in first person at the point of the choice.

Refresh path: run the litreview skill on the method since the canon date and fold results into
references/canon.md as flagged addenda.

## Design first: decisions that cannot be fixed ex post

- Stratify at design time instead of adjusting at analysis time. Ex ante stratification with
  equal treatment fractions weakly dominates complete randomization in expected squared error,
  even in small samples and even when the stratifier is useless; ex post regression adjustment
  can hurt when covariates are unpredictive. Stratify as finely as possible subject to at
  least two treated and two control units per stratum.
- The family's default is fine stratification with at least two treated and two control per
  stratum, not pairs: within-pair variances are not estimable (Athey-Imbens) and the
  pair-level variance is conservative for the sample ATE. Pairing remains a defensible
  design under later matched-pair work (Bai 2022). A study that pairs should cite that
  literature and must analyze as paired.
- Re-randomization is implicit stratification and is analyzable only if the acceptance rule
  was written down before drawing. No written rule means p-values are only interpretable as
  conservative. Prefer building balance into strata.
- Clustered assignment: choose the estimand before the estimator. The cluster-average effect
  and the unit-average effect differ whenever effects covary with cluster size, and with
  very unequal clusters the unit-weighted estimand can be nearly unlearnable while the
  cluster-average stays precise. Cluster-level analysis is the primary, most transparent
  specification; report both estimands when cluster sizes vary a lot. Geo experiments and
  store-level rollouts are exactly this case (average-store vs average-customer effect).
- Power before the experiment, with the closed-form minimum-N formula (worked example and
  algebra in references/details.md; a treated share of one half is optimal under
  homoskedasticity). For stratified and clustered designs, simulate the design instead
  (DeclareDesign). Ex-post power from observed effects is not a diagnostic anywhere in this
  family of skills.

Adaptive and bandit experiments are out of scope here and unrouted in the family: no canon
source covers adaptive inference. The caution stands regardless: naive sample means are biased
under adaptive assignment, because the arm that looked worse early gets its sample truncated
(the caution and its citation live in causal-design). The practical exits are a final
non-adaptive confirmatory phase or restricting analysis to a uniform-assignment holdout.
Beyond those two, this family declines.

## Analysis defaults

- Report a randomization-inference p-value and the Neyman difference in means with its
  conservative variance side by side. The Fisher exact test uses the difference in means by
  default, mean ranks under heavy tails or many zeros, and an omnibus quadratic form for
  multiple outcomes, all inside the same randomization distribution.
- Analyze as randomized: stratified designs get within-stratum differences averaged with
  stratum weights, paired designs the across-pair variance, clustered designs the
  cluster-level machinery or Liang-Zeger with small-sample correction (CR2). Ignoring a
  paired design raised the standard error by about seventy percent in the canon's worked
  example.
- HC2 is the default variance everywhere (it reproduces the Neyman estimator exactly for a
  binary treatment); with a rare treatment arm Eicker-Huber-White (EHW, i.e. HC0) is
  anti-conservative, so use HC2 with Behrens-Fisher/Satterthwaite degrees of freedom.
  Small-cell pricing and email tests live in exactly this regime.
- One caveat carried honestly: exact tests of the sharp null are exact, but inverting
  Fisher-Pitman permutation tests into CIs for the ATE can undercover under heterogeneous
  effects with unbalanced designs. Test sharp nulls by permutation; interval-estimate the ATE
  with Neyman/HC2 machinery.
- Continuous monitoring and optional stopping are not covered by the canon. The design-time
  answer is a stopping rule fixed in the preregistration (the preregister skill's field). If
  the platform peeked at interim results, fixed-sample p-values are invalid, and this family
  has no always-valid inference route to offer.

## Covariate adjustment, the settled version

- The unadjusted difference in means comes first in every table. It is the hands-above-the-
  table number, visibly not the product of a specification search.
- If adjusting with OLS: demeaned covariates, full treatment-by-covariate interactions, HC2.
  That estimator cannot hurt asymptotic precision relative to the difference in means (Lin
  2013); both conditions are load-bearing, and uncentered interactions lose the guarantee
  entirely. With near-equal arms the uninteracted legacy specification is asymptotically
  harmless; with a 90/10 holdout the interactions are what protect you. estimatr::lm_lin is
  the reference implementation.
- Choose covariates for outcome prediction, fixed before outcomes are seen. A pre-period
  measure of the outcome is the one covariate reliably worth having (this is what CUPED-style
  industry variance reduction adjusts for; same estimator family).
- Binary outcomes: the logit coefficient on treatment is inconsistent for the marginal effect
  even under a true model, because the odds ratio is noncollapsible (Freedman 2008). Never
  report exp(beta) from a covariate-adjusted logit as the lift, and never compare odds ratios
  across specifications or samples with different covariates. Primary analysis is the
  difference in proportions with HC2, which is the linear probability model in saturated
  form: under randomization its coefficient IS the marginal effect, read directly off the
  table, and lm_lin on a binary outcome is the covariate-adjusted LPM with the same
  guarantee (the classic LPM objections have no force here; details.md). For precision,
  standardize an interacted logistic working model to the marginal risk difference, which is
  the average marginal effect, never the marginal effect at the mean. With multiple arms,
  OLS on arm dummies reads out each contrast directly; multi-arm logit coefficients stay
  conditional.
- Nonlinear outcomes generally (Guo-Basse 2023): impute each arm's missing potential outcomes
  from separate per-arm fits and average. Routing by outcome type: binary to logistic
  imputation, counts to Poisson (45 percent shorter intervals than linear adjustment in their
  worked example), skewed-positive (revenue) to log-OLS with second-stage-OLS recalibration,
  otherwise Lin. Canonical links calibrate automatically; anything else gets recalibrated.
  Three pre-trust checks: no separation (fitted values near 0/1), per-arm R2 not both near 1,
  model flexibility small relative to arm sizes. There is NO universal never-worse guarantee
  for nonlinear imputation; platforms that want one use linear imputation or no-harm
  calibration. Never report a log-scale coefficient as the level-scale effect.

## Noncompliance

ITT is the only analysis randomization alone justifies; report it always, and it is the
headline when assignment is the policy lever. The LATE (ITT over first stage) adds exclusion
and monotonicity, which randomization does not deliver; argue them with the iv skill's
discipline (exclusion by compliance type, monotonicity by instrument direction). As-treated
and per-protocol comparisons are uninterpretable mixtures, ruled out entirely: exposed-vs-
unexposed comparisons in ad experiments are this error. Report compliance shares, Balke-Pearl
bounds when exclusion is doubtful, and, before generalizing beyond compliers, the two
Bertanha-Imbens comparability tests (always-takers vs treated compliers, never-takers vs
untreated compliers). Ghost ads and PSA holdouts are one-sided noncompliance: ITT is lift on
assignment, LATE is lift on exposure.

## Attrition and gated outcomes (the Lee block)

Any outcome observed only conditional on a post-treatment event (spend given retention,
satisfaction given response, wages given employment, order value given purchase) triggers
this block. Conditioning on the gate is conditioning on a post-treatment variable, and a
perfect experiment identifies nothing about the gated outcome without more assumptions.

1. Compute the differential observation rate between arms first.
2. Near zero: run the monotonicity balance test (baseline covariates balanced within the
   selected subsample). If it passes, report the selected-sample difference labeled as the
   effect for the always-observed stratum; the untrimmed estimate is the efficient choice
   there.
3. Otherwise Lee bounds are the primary analysis: trim the higher-observation arm's outcome
   distribution by the excess share p0 = (s_T - s_C)/s_T from the top for the lower bound and
   the bottom for the upper bound; sharp under randomization plus monotone selection, no
   exclusion restriction and no bounded support needed. Report the Imbens-Manski interval
   (the effect is the target, and it is narrower than set coverage). Tighten with cells built
   from predicted-outcome quintiles on baseline covariates.
4. Every bounds writeup carries one signed-selection sentence: who the marginal observed
   units are and therefore which end of the interval is credible (a retention intervention
   keeping marginal low-spenders biases the survivor comparison down, so the upper end is the
   credible one).
5. Horowitz-Manski worst-case bounds appear once as the assumption-free outer benchmark
   (Lee's were 1/14th their width in Job Corps). Heckman-style corrections only with a
   credible excluded instrument for selection, which field experiments rarely have.

Monotonicity failure (imbalance among the selected despite equal rates) means two-way flows,
and the bounds themselves are compromised; there is no within-model fix.

## Heterogeneity and multiple testing

- Pre-specified subgroups: stratified analysis plus a multiple-testing correction that
  exploits correlation across tests (List-Shaikh-Xu bootstrap; Romano-Wolf stepdown), not
  Bonferroni. Multiple outcomes: omnibus statistic or corrected p-values; uncorrected
  per-outcome stars are the failure mode.
- Data-driven heterogeneity requires honesty: any CI you will report needs sample splitting
  (one sample picks the partition, an independent one estimates). Coverage survives high
  dimension; MSE does not. Honest trees for interpretable subgroups, causal forests for the
  CATE surface with pointwise inference, plus the rank-average-treatment-effect test for
  detectable heterogeneity; this is also the uplift-modeling stack.
- The constant-effect test (series regression of both arms' conditional means) tells you
  whether a single ATE is an incomplete summary; rejection routes to the toolkit above.
- Quantile effects are differences of marginal quantiles, never quantiles of unit-level
  differences (unidentified). The bootstrap fails at mass points (30 percent zeros made a
  bootstrap SE of exactly 0 in the canon's example); pair QTE estimates with an exact test
  using the QTE as the statistic.

## Interference

When units interact, SUTVA fails and the simple ATE misstates the policy effect. Contained
interactions: randomize at the group level (markets, stores). Direct-vs-indirect effects:
two-stage saturation designs (randomize treated fractions across groups, then units within);
if within-market treatment-control differences vary with the market-level treated share,
displacement is present, the marketplace-cannibalization check. One general network: exact
randomization tests with focal, buffer, and auxiliary units, since there is no coherent
large-network asymptotic. Platform experiments should default to market-level clustering
when cannibalization or budget spillover is plausible. Marketplace and two-sided settings:
multiple randomization designs assign treatment to buyer-seller pairs (Bajari et al. 2023;
Johari et al. 2022 analyzes the bias of one-sided designs).

## Diagnostics battery

1. Covariate balance table with exact p-values, run even on clean randomizations (the Lalonde
   benchmark hides an imbalance at p = 0.002); post-attrition imbalance means the analyzed
   sample is no longer the randomized sample, which routes to the Lee block.
2. Adjusted vs unadjusted side by side: adjustment should barely move the point estimate and
   shrink the SE by roughly sqrt(1 - R2). A large movement signals compromised
   randomization, attrition, or specification problems, and is never a precision story.
3. Design-consistent variance check: the design-aware variance should be weakly smaller than
   the complete-randomization one; larger means the analysis mis-specifies the design.
4. Both cluster estimands when cluster sizes vary; the gap between them is itself evidence
   that effects covary with cluster size.
5. Zero-effect coverage simulation before reporting: hold outcomes fixed, re-randomize, check
   empirical coverage of every planned estimator-variance pair. Minutes of compute; catches
   small-sample and skewness failures.
6. Leading-term bias estimate for regression adjustment (sample-moment formula); a value that
   is a nontrivial fraction of the SE means drop the adjustment or coarsen covariates.
7. Compliance and attrition accounting: first-stage table (equals the compliance-share
   table), differential response rate, and the Lee machinery when it is nonzero.

## R implementation

The complete runnable pipeline is scripts/experiment_template.R (assignment, RI + Neyman
analysis, lm_lin and nonlinear imputation, noncompliance, Lee bounds, heterogeneity, power),
with every call verified against package documentation. The core:

```r
library(randomizr); library(estimatr)
Z <- block_ra(blocks = strata, prob = 0.5)          # design: stratified assignment
difference_in_means(y ~ z, blocks = strata, data = df)   # analyze as randomized
lm_lin(y ~ z, covariates = ~ pre_y + x1, data = df)      # Lin adjustment, HC2 default
# binary outcome, marginal risk difference via standardization:
fit <- glm(y ~ z * (pre_y + x1), family = binomial, data = df)
marginaleffects::avg_comparisons(fit, variables = "z")
```

Package index with versions, links, and traps in references/details.md.

## Methods paragraph template

> We randomized [units] to [arms] within strata of [X] with equal treatment fractions, and we
> analyze the experiment as randomized: we report randomization-inference p-values alongside
> the difference in means with HC2 standard errors [and Behrens-Fisher degrees of freedom,
> given arm sizes of N_t and N_c] (Athey and Imbens 2017). The unadjusted estimate comes
> first; for precision we adjust with the fully interacted, demeaned-covariate regression of
> Lin (2013) [/ for our binary outcome, we standardize an interacted logistic working model to
> the marginal risk difference, since the logit coefficient targets a noncollapsible
> conditional estimand (Freedman 2008; Guo and Basse 2023)]. [Noncompliance: we report
> intention-to-treat effects and the complier average effect, with exclusion argued by
> compliance type.] [Gated outcome: because [outcome] is observed only given [gate] and
> assignment moves [gate] rates by [x] points, we report Lee (2009) bounds with the
> Imbens-Manski interval; the marginal observed units are [who], so the [end] of the interval
> is the credible one. This estimand covers the always-observed stratum, a limitation of the
> data and not the design, and I do not extrapolate to units whose observation status
> responds to treatment.]

Every claim traces to references/canon.md; keys live in causal-design/references/causal.bib.

## Handoffs

- preregister: the pre-analysis plan document itself; this skill supplies what to
  pre-specify (strata, covariates, estimators, subgroups, gates).
- iv: exclusion and monotonicity discipline for LATE claims; weak-instrument inference when
  the first stage is thin.
- causal-design: whether to experiment at all; clustering questions shared across designs.
- did / synthetic-control: staggered rollouts and geo designs analyzed observationally when
  randomization was infeasible or broken.
