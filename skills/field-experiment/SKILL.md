---
name: field-experiment
description: Design, analyze, and write up randomized experiments (field experiments, A/B tests, RCTs): stratified and clustered designs, randomization inference, covariate adjustment done right, noncompliance, attrition and gated outcomes, treatment-effect heterogeneity, and interference. TRIGGER on "A/B test", "randomized experiment", "RCT", "field experiment", "randomized holdout", "lift test", "randomization inference", "stratified randomization", "matched pairs", "rerandomization", "cluster randomized", "geo experiment", "switchback", "randomized rollout", "stepped wedge", "power analysis", "MDE", "sequential test", "peeking", "ratio metric", "encouragement design", "noncompliance", "ITT", "attrition", "Lee bounds", "CUPED", "uplift", "GATES", "heterogeneous treatment effects", "interference", "spillover", "SUTVA". Observational causal forests belong to causal-design.
---

# Field experiments

An opinionated experimental workflow grounded in a read canon (references/canon.md):
the Athey-Imbens handbook chapter as the spine (randomization-based inference
first), Freedman's logistic-regression critique and Lin's repair for covariate adjustment,
Guo-Basse's generalization to nonlinear outcomes, and Lee's bounds for attrition and gated
outcomes. Deliverable: the recommendation with its citation, the R estimation and diagnostics
code, and a methods paragraph. The skill stops at the four stop points in
../causal-design/references/shared-rules.md (section "Stop points") and puts each choice to the user.
Before any estimation, stop and confirm three things with the user: the estimand (cluster-average
or unit-average under clustering), the pre-specified covariate list, and whether outcomes have
been seen.

Current as of 2026-10-09; refresh per shared-rules (../causal-design/references/shared-rules.md,
section "Refresh path").
Nothing enters the canon without the user's approval.
The same refresh checks every pin in the package index of references/details.md against CRAN
and reads the NEWS of any package with a new major version.

## Design first: decisions that cannot be fixed ex post

- Stratify at design time instead of adjusting at analysis time. Ex ante stratification with
  equal treatment fractions weakly dominates complete randomization in expected squared error,
  even in small samples and even when the stratifier is useless; ex post regression adjustment
  can hurt when covariates are unpredictive. Stratify as finely as possible subject to at
  least two treated and two control units per stratum. The dominance holds in expectation,
  for a sample drawn from a large population, so within-stratum outcomes cannot be negatively
  correlated. A particular stratification can still do worse ex post. The price is a noisier
  variance estimator, since each stratum spends degrees of freedom. The complete-randomization
  variance remains a valid, conservative fallback (Athey and Imbens 2017).
- The family's default is fine stratification with at least two treated and two control per
  stratum, not pairs: within-pair variances are not estimable (Athey-Imbens) and the
  pair-level variance is conservative for the sample ATE. Pairing remains a defensible
  design on optimality grounds (Bai 2022). A study that pairs must analyze as paired. Bai,
  Romano, and Shaikh (2022) show that the two-sample and the paired t-tests are both
  conservative there. Their variance estimator, built from pairs of pairs, gives exact
  asymptotic size. Covariate adjustment with pairs uses pair fixed effects (Bai et al. 2024).
- Re-randomization (Morgan and Rubin 2012) is implicit stratification and is analyzable only
  if the acceptance rule was written down before drawing. Morgan and Rubin's unbiasedness
  result needs equal arm sizes and a rule that treats both arms alike. With the rule written
  down, the randomization test replays it, and Li, Ding, and Rubin (2018) give large-sample
  intervals for its non-normal limit. No written rule means p-values are only interpretable
  as conservative. Prefer building balance into strata.
- Clustered assignment: choose the estimand before the estimator. The cluster-average effect
  and the unit-average effect differ whenever effects covary with cluster size. With very
  unequal clusters the unit-average estimand can be far less precise than the cluster-average
  one. Cluster-level analysis is the primary, most transparent
  specification; report both estimands when cluster sizes vary a lot. Geo experiments and
  store-level rollouts are exactly this case (average-store vs average-customer effect).
  Su and Ding (2021) give the design-based version. For the unit-average effect, regress
  scaled cluster totals on treatment, cluster size, and cluster-level covariates, with
  robust standard errors. For the cluster-average effect, use the unweighted regression on
  cluster means, with centered cluster-level covariates and their interactions with
  treatment. Weighting that regression by cluster size targets the unit-average effect
  instead. Their adjusted cluster-total estimator loses robustness when cluster sizes
  vary a lot.
- Refusal: with fewer than two clusters per arm (two geos, two stores), no design-based
  variance exists. Decline the inferential claim and say why. Few clusters go to the small-G
  rule in ../causal-design/references/shared-rules.md and did's few-cluster map. One treated
  cluster goes to synthetic-control.
- Power before the experiment, with the closed-form minimum-N formula (worked example and
  algebra in references/details.md; a treated share of one half is optimal under
  homoskedasticity). For stratified and clustered designs, simulate the design instead
  (DeclareDesign). Ex-post power from observed effects is not a diagnostic anywhere in this
  family of skills.
- Interference is a design decision: when units interact (marketplaces, shared budgets,
  networks), pick the randomization unit and the design in section "Interference" below
  before anything is assigned.

Adaptive and bandit experiments are out of scope here: no canon source covers adaptive
inference, and causal-design carries the route. The caution stands regardless: naive sample
means are biased under adaptive assignment, because the arm that looked worse early gets its
sample truncated. Hadad et al. (2021) show this, and they show that the IPW and AIPW
estimators need not be asymptotically normal there either. Their adaptively weighted AIPW
restores valid intervals; this skill does not implement it. The practical exits are a final
non-adaptive confirmatory phase or restricting analysis to a uniform-assignment holdout.
causal-design's details.md carries the analysis route (adaptive weighting, Hadad et al. 2021,
CRAN banditsCI). This skill owns the design decision and the two design-side exits.

## Analysis defaults

- Report a randomization-inference p-value and the Neyman difference in means with its
  conservative variance side by side. The Fisher exact test uses the difference in means by
  default, mean ranks under heavy tails or many zeros, and an omnibus quadratic form for
  multiple outcomes, all inside the same randomization distribution.
- Analyze as randomized: stratified designs get within-stratum differences averaged with
  stratum weights, paired designs the across-pair variance, clustered designs the
  cluster-level machinery or Liang-Zeger with small-sample correction. With few clusters,
  the family's small-G rule applies (../causal-design/references/shared-rules.md, section
  "Clustering": CV3 plus the wild cluster restricted bootstrap first, CR2 with Satterthwaite
  dof as the cross-check). Ignoring a
  paired design raised the standard error by about seventy percent in the canon's worked
  example.
- HC2 is the default variance everywhere (it reproduces the Neyman estimator exactly for a
  binary treatment); with a rare treatment arm Eicker-Huber-White (EHW, i.e. HC0) is
  anti-conservative, so use HC2 with Behrens-Fisher/Satterthwaite degrees of freedom.
  Small-cell pricing and email tests live in exactly this regime. Only difference_in_means
  reports Welch degrees of freedom. For a covariate-adjusted regression, lm_lin and lm_robust
  report N minus k, so compute the Imbens-Kolesar degrees of freedom with
  dfadjust::dfadjustSE (Imbens and Kolesar 2016) on the same specification fit with lm.
- Ratio metrics (clicks per page view, revenue per session) under user-level randomization
  have an analysis unit below the randomization unit. Treating page views as independent
  understates the variance. Write the metric as a ratio of two user-level means and use the
  delta method (Deng, Knoblich, and Lu 2018).
- One caveat carried honestly: exact tests of the sharp null are exact, but inverting
  Fisher-Pitman permutation tests into CIs for the ATE can undercover under heterogeneous
  effects with unbalanced designs. Test sharp nulls by permutation; interval-estimate the ATE
  with Neyman/HC2 machinery.
- Continuous monitoring and optional stopping are not covered by the canon. The design-time
  answer is a stopping rule fixed in the preregistration, which the user writes themselves. If
  the platform peeked at interim results, fixed-sample p-values are invalid. The valid route
  is a confidence sequence, which holds at any stopping time. Always-valid p-values from the
  mixture sequential probability ratio test are one form (Johari, Koomen, Pekelis, and Walsh
  2022). Asymptotic confidence sequences for the ATE are another (Waudby-Smith et al. 2024).
  Design-based confidence sequences cover finite-population estimands, A/B tests included,
  with an asymptotic guarantee (Ham et al. 2026). The template does not implement any of
  them.

## Covariate adjustment, the settled version

- The unadjusted difference in means comes first in every table. It is the hands-above-the-
  table number, visibly not the product of a specification search.
- If adjusting with OLS: demeaned covariates, full treatment-by-covariate interactions, HC2.
  Under complete randomization that estimator cannot hurt asymptotic precision relative to
  the difference in means (Lin 2013); both conditions are key, and uncentered interactions
  lose the guarantee entirely. Lin's guarantee does not carry over to stratified assignment.
  There, the interacted regression without stratum terms can have a larger variance than
  the unadjusted estimator (Cytrynbaum 2024). For stratified designs, center the covariates
  and the stratum indicators within strata and interact both with treatment. Under equal
  treatment fractions within strata, this estimator keeps the guarantee (Liu and Yang 2020).
  In estimatr, add factor(stratum) to the lm_lin covariates. Matched-pair designs get pair
  fixed effects (Bai, Jiang, Romano, Shaikh, and Zhang 2024). With near-equal arms the
  uninteracted legacy specification is asymptotically harmless; with a 90/10 holdout the
  interactions are what protect you. estimatr::lm_lin is the reference implementation.
- Choose covariates for outcome prediction, fixed before outcomes are seen. If the covariates
  or subgroups are chosen after outcomes were seen, label the analysis exploratory and write no
  confirmatory claim. A list fixed in a preregistration before outcomes were seen is exempt.
  A pre-period
  measure of the outcome is the one covariate reliably worth having. CUPED, the industry
  variance reduction, adjusts for pre-experiment data and belongs to the same estimator
  family (Deng, Xu, Kohavi, and Walker 2013).
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
  worked example), nonnegative outcomes with zeros (revenue per user) to Poisson
  quasi-likelihood imputation, strictly positive skewed outcomes to log-OLS with
  second-stage-OLS recalibration, otherwise Lin. The log route is closed to outcomes with
  zeros: log(y) is undefined at zero, and log-like transforms of such outcomes do not
  identify a percentage effect (Chen and Roth 2024). Canonical links calibrate automatically.
  Any other link gets recalibrated.
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
comparability tests (always-takers vs treated compliers, never-takers vs untreated
compliers). Bertanha and Imbens (2020) build these tests for fuzzy RD at the threshold, and
Athey and Imbens (2017) apply them to the LATE in experiments. Ghost ads (Johnson, Lewis, and
Nubbemeyer 2017) and PSA holdouts are one-sided noncompliance: ITT is lift on assignment,
LATE is lift on exposure.

## Attrition and gated outcomes (the Lee block)

Any outcome observed only conditional on a post-treatment event (spend given retention,
satisfaction given response, wages given employment, order value given purchase) triggers
this block. Conditioning on the gate is conditioning on a post-treatment variable, and a
perfect experiment identifies nothing about the gated outcome without more assumptions.

1. Compute the differential observation rate between arms first. The rate comparison
   alone is not a test of internal validity (Ghanem, Hirshleifer, and Ortiz-Becerra 2026).
   With baseline outcomes, run their tests before any trimming. The respondent test
   compares baseline outcome distributions across arms within respondents and within
   attritors. The population test compares them across all four arm-by-response
   cells. Stata's attregtest implements both; no R package was found. A rejection of the
   respondent test sends the analysis to the Lee bounds in step 3.
2. Near zero: run the monotonicity balance test (baseline covariates balanced within the
   selected subsample). If it passes, report the selected-sample difference labeled as the
   effect for the always-observed stratum; the untrimmed estimate is the efficient choice
   there.
3. Otherwise Lee bounds are the primary analysis: trim the higher-observation arm's outcome
   distribution by the excess share p0 = (s_T - s_C)/s_T from the top for the lower bound and
   the bottom for the upper bound; sharp under randomization plus monotone selection, no
   exclusion restriction and no bounded support needed. Report the Imbens-Manski interval
   (the effect is the target, and it is narrower than set coverage). Stoye (2009) shows that
   this interval assumes superefficient estimation of the bound width. When the width is
   near zero relative to its standard error, say so, and use Stoye's interval if the claim
   rests on it; the template does not implement it. Tighten with cells built from
   predicted-outcome quintiles on baseline covariates.
4. Every bounds writeup carries one signed-selection sentence: who the marginal observed
   units are and therefore which end of the interval is credible (a retention intervention
   keeping marginal low-spenders biases the survivor comparison down, so the upper end is the
   credible one).
5. Horowitz-Manski worst-case bounds appear once as the assumption-free outer benchmark
   (Lee's were 1/14th their width in Job Corps). Heckman-style corrections only with a
   credible excluded instrument for selection, which field experiments rarely have.

Monotonicity failure (imbalance among the selected despite equal rates) means two-way flows,
and the bounds themselves are compromised. The next step is to test monotonicity within
covariate cells. Generalized Lee bounds (Semenova 2025) allow the direction of selection to
differ across cells and need monotonicity only conditional on covariates. The template does
not implement them. Horowitz-Manski bounds are the fallback only when conditional
monotonicity also fails.

## Heterogeneity and multiple testing

- Pre-specified subgroups: stratified analysis plus a multiple-testing correction that
  exploits correlation across tests (List-Shaikh-Xu bootstrap; Romano-Wolf stepdown), never
  Bonferroni, which Holm dominates at zero cost. Multiple outcomes: omnibus statistic or
  corrected p-values; uncorrected per-outcome stars are the failure mode. The staged policy
  this instantiates (screen with FDR, confirm with a resampling FWER method, gate across
  stages) is in causal-design's shared rules (../causal-design/references/shared-rules.md).
  For Romano-Wolf, resample: a wild cluster bootstrap stepdown (Westfall-Young or
  Romano-Wolf) or a stratified unit or cluster bootstrap with HC2 t-statistics, coded by
  hand as in the template. wildrwolf does this for fixest models, but it was archived
  from CRAN and installs from r-universe. hdm::p_adjust(method = "RW") does not qualify.
  It draws Gaussian vectors from the homoskedastic vcov of one lm fit, with no resampling
  and no HC2.
- Data-driven heterogeneity requires honesty: any CI you will report needs sample splitting
  (one sample picks the partition, an independent one estimates). Coverage survives high
  dimension; MSE does not. Honest trees for interpretable subgroups, causal forests for the
  CATE surface with pointwise inference, plus the rank-weighted average treatment effect
  (RATE; Yadlowsky et al. 2025) for detectable heterogeneity; this is also the
  uplift-modeling stack.
- For RCT heterogeneity in economics journals, report the generic machine-learning route
  beside grf (the family's judgment; Chernozhukov, Demirer, Duflo, and Fernandez-Val
  2025). Any ML proxy of the CATE feeds three outputs. The best linear predictor (BLP)
  tests whether the proxy tracks real heterogeneity. GATES are average effects by proxy
  quantile group. CLAN compares covariate means between the most and least affected
  groups. Inference aggregates over repeated sample splits by medians. The published paper
  recommends the nominal 1 - alpha level. GenericML reports 1 - 2 alpha, so pass
  significance_level = 0.025 for 95 percent intervals. State which level a table uses.
- The constant-effect test of Crump, Hotz, Imbens, and Mitnik (2008) tells you whether a
  single ATE is an incomplete summary; rejection routes to the toolkit above.
- Quantile effects are differences of marginal quantiles, never quantiles of unit-level
  differences (unidentified). The bootstrap fails at mass points (30 percent zeros made a
  bootstrap SE of exactly 0 in the canon's example); pair QTE estimates with an exact test
  using the QTE as the statistic.

## Interference

When units interact, SUTVA fails and the simple ATE misstates the policy effect. Contained
interactions: randomize at the group level (markets, stores). Direct-vs-indirect effects:
two-stage saturation designs (randomize treated fractions across groups, then units within;
Hudgens and Halloran 2008; Baird, Bohren, McIntosh, and Ozler 2018 give power and the
optimal saturations); if within-market treatment-control differences vary with the
market-level treated share, displacement is present, the marketplace-cannibalization check
(Crepon et al. 2013). One general network: define each unit's exposure through an exposure
mapping (Aronow and Samii 2017), then run exact randomization tests with focal, buffer, and
auxiliary units (Athey, Eckles, and Imbens 2018). Exact tests are the default because
large-network asymptotics need extra assumptions. Leung (2022) assumes interference that
decays with network distance, and his network HAC variance is conservative. Savje, Aronow,
and Hudgens (2021) assume a bounded amount of unknown interference. Clustered SEs do not
substitute for the exact test. Platform experiments should default to market-level clustering
when cannibalization or budget spillover is plausible. Marketplace and two-sided settings:
multiple randomization designs assign treatment to buyer-seller pairs (Bajari et al. 2023;
Johari, Li, Liskovich, and Weintraub 2022 analyze the bias of one-sided designs). Temporal
interference (pricing, dispatch, or matching algorithms that act on a whole market) calls
for a switchback design, which randomizes treatment over time periods. Bojinov, Simchi-Levi,
and Zhao (2023) give the optimal design for a stated carryover order, with exact and
conservative asymptotic randomization inference.

## Diagnostics battery

1. Covariate balance table with exact p-values, run even on clean randomizations (the Lalonde
   benchmark hides an imbalance at p = 0.002); post-attrition imbalance means the analyzed
   sample is no longer the randomized sample, which routes to the Lee block.
2. Adjusted vs unadjusted side by side: adjustment should barely move the point estimate and
   shrink the SE by roughly sqrt(1 - R2). A large movement signals compromised
   randomization, attrition, or specification problems, and is never a precision story.
3. Design-consistent variance check, for stratified and paired designs only: the
   design-aware variance should be weakly smaller than the complete-randomization one;
   larger means the analysis mis-specifies the design. Under clustered assignment the
   design-aware variance is larger by construction (Abadie et al. 2023), and this check
   does not apply.
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
Z <- block_ra(blocks = df$stratum, prob = 0.5)      # design: stratified assignment
difference_in_means(y ~ z, blocks = stratum, data = df)   # analyze as randomized
lm_lin(y ~ z, covariates = ~ pre_y + x1 + factor(stratum), data = df)  # stratified Lin, HC2
# binary outcome, marginal risk difference via standardization:
fit <- glm(y ~ z * (pre_y + x1), family = binomial, data = df)
marginaleffects::avg_comparisons(fit, variables = "z")
```

Package index with versions, links, and traps in references/details.md.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

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
> data and not the design, and we do not extrapolate to units whose observation status
> responds to treatment.]

Every claim traces to references/canon.md; keys live in ../causal-design/references/causal.bib.

## Handoffs

- Preregistration: the user writes it themselves; this skill supplies what to
  pre-specify (strata, covariates, estimators, subgroups, gates).
- iv: exclusion and monotonicity discipline for LATE claims; weak-instrument inference when
  the first stage is thin.
- causal-design: whether to experiment at all; clustering questions shared across designs.
- did / synthetic-control: staggered rollouts and geo designs analyzed observationally when
  randomization was infeasible or broken. Choosing treated markets by synthetic control
  before a geo test belongs to synthetic-control, in its section "Choosing treated markets
  before a geo test".
- Randomized rollouts (stepped wedge), which did sends here: this skill owns them. The
  adoption dates were randomized, so inference is design-based, by randomization inference
  over the rollout schedule. The efficient estimator for randomized timing is Roth and
  Sant'Anna (2023), in the R package staggered; did documents its use.
- conjoint: profile experiments randomizing multiple attributes within alternatives, and
  the per-component estimand family. The seam cuts both ways: collapsing arms of any
  multi-factor design on one dimension estimates an implicit AMCE averaged over the other
  factors' assignment distribution, and the full machinery (averaging-distribution
  disclosure, corrections, claims firewall) lives there.
- Text or model-generated stimuli as treatments carry a latent-treatment identification problem,
  so randomize over many stimuli instead of one, and correct any machine-coded outcome against a
  human-labeled subsample before it enters an estimate.
- Stimuli produced by intervening on a model's internals carry a coherence confound. Run the
  manipulation checks at the logged intervention strength and audit the damage on both the
  intended and the unintended channel. Whether the intervention itself is valid is a separate
  question from whether the experiment is.
