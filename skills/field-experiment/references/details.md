# Field-experiment lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-28.

## Variance algebra

- Neyman: V-hat = s2_c/N_c + s2_t/N_t, upward biased for the randomization variance because
  the unit-level effect variance S2_tc/N is unidentifiable and dropped; unbiased if effects
  are constant or the estimand is the super-population ATE.
- HC2 on Y ~ W with binary W reproduces the Neyman estimator exactly; HC0/EHW differs by the
  degrees-of-freedom treatment and is anti-conservative with a rare arm (N_t = 4, N_c = 54:
  EHW 0.1215 vs Neyman 0.1400). Behrens-Fisher/Satterthwaite dof (Imbens-Kolesar) is the fix.
- Stratified: tau-hat = sum_g (N_g/N) tau-hat_g, V-hat = sum_g (N_g/N)^2 V-hat_g; the
  complete-randomization variance is valid but conservative.
- Paired: use the across-pair variance of pair differences (conservative for the sample ATE,
  right for the super-population one). Ignoring pairing raises the SE by about seventy
  percent in the Children's Television Workshop example (4.6 vs 7.8).
- Clustered: for the cluster-average estimand, difference in means on cluster means
  (equivalently unit-level WLS with weights 1/N_g); for the unit-average estimand,
  unweighted unit OLS with Liang-Zeger CR (CR2 small-sample correction and Satterthwaite
  dof), or cluster-level WLS with weights N_g. One mega-cluster can make the unit-weighted
  estimand essentially unlearnable.
- Clustered sampling with unit-level randomization is a different problem: Neyman for the
  sample ATE, clustered SEs only for the population ATE (abadie2023clustering).

## Power

Minimum N = (Phi^-1(beta) + Phi^-1(1 - alpha/2))^2 / ((tau^2/sigma^2) gamma (1 - gamma)),
gamma the treated share (1/2 optimal under homoskedasticity). Worked example: sigma = 6,
tau = 1, alpha = .05, power = .8 gives N = 1130; tau = 2 gives N = 282. Base R power.t.test
matches up to the t-vs-normal refinement; stratified and clustered designs by simulation
(DeclareDesign) or PowerUpR closed forms for cluster designs.

## Lin algebra and checks

- Efficiency: the interacted estimator's gain over uninteracted is
  ((2p_A - 1)^2 / (n p_A (1 - p_A))) times the variance of the covariate-explained part of
  the treatment effect; zero at equal arms or equal slopes. Variance gain over unadjusted is
  the 1 - R2 factor.
- For uninteracted adjustment to hurt with one covariate, more than three quarters of
  subjects must sit in one arm, or the covariate must covary more with the effect than with
  the outcome level. With more than two arms, pooled adjustment can hurt even balanced;
  separate per-arm regressions keep the guarantee.
- Bias is order 1/n; leading term is a covariance of outcomes with squared demeaned
  covariates, estimable by plug-in (ALO example: -0.0002 against SE 0.146). Report it when
  arms are small and covariates skewed.
- Zero-effect coverage simulation: hold outcomes fixed, assume no effect, re-randomize many
  times, compute empirical coverage for every planned estimator-variance pair. A coverage
  benchmark, not a permutation test.
- Sandwich sweep: HC0-HC3 agreed (94.4-95.1 percent coverage) in Lin's 250k-replication
  check; HC0 degrades first with leverage; the Guo-Basse Fatalities footnote has HC0
  undercovering for Lin's estimator, a concrete HC2-by-default argument.
- Poststratification is lm_lin with partition indicators; then the estimator is exactly
  unbiased over the randomization distribution.

## Noncollapsibility and standardization (binary outcomes)

- Section 9 inequality: with subject-level odds multiplier lambda > 1 and any variation in
  baseline risks, the pooled multiplier lies strictly between 1 and lambda. So
  |beta-hat| > |marginal Delta| whenever the covariate is prognostic; the gap is predicted,
  not evidence of bias.
- The calibration mechanism: logit score equations force arm-average fitted probabilities to
  equal arm-average outcomes; that plus randomization's covariate balance makes the plug-in
  consistent. Probit lacks it (small but nonzero asymptotic bias).
- Freedman's simulation anchors: n = 5000 coefficient bias 0.195 (truth 0.939); swapping the
  covariate drove the coefficient to about 3 against truth near 1.
- Standardization recipe: fit y ~ w * covariates with family = binomial; average predictions
  with w set to 1 and to 0 over ALL units; report the risk-difference (or the log odds of
  the averaged probabilities, Freedman's Delta-tilde). marginaleffects::avg_comparisons is
  the packaged route; the design-based interval is the Guo-Basse residual t-interval.
- Guo-Basse conditions: prediction unbiasedness + stability -> consistency; + entropy
  condition -> asymptotic normality; CI = tau-hat +/- t * sqrt(MSE_1/n_1 + MSE_0/n_0),
  conservative, exact under the sharp null with the same model class per arm. Degenerate
  when both arms' R2 near 1. Isotonic imputation needed ~600 units per arm for near-nominal
  coverage.

## The LPM case, stated plainly: binary outcomes only (house framing)

Scope: everything in this section is specific to binary outcomes, the only setting where an
LPM-versus-logit choice exists. The difference in means is unbiased for the ATE under
randomization for any outcome type; what is binary-specific is reading that coefficient as a
probability-scale marginal effect and the noncollapsibility trap in the logit alternative.
For counts and skewed-positive outcomes the analogous contrast is OLS versus Poisson or
log-scale models, and the same three-tier logic applies through the Guo-Basse routing
(nonlinear coefficients are never read; nonlinear models serve only as imputation engines).

- Choosing the LPM over a logit is declining to assume a functional form, not assuming a
  linear one: OLS of the binary outcome on the treatment dummy is the linear probability
  model in saturated form and equals the difference in proportions, so under randomization
  the coefficient is unbiased for the risk difference (the ATE) with no functional-form
  assumption doing any work, while the logit imposes a shape whose coefficient still needs
  AME post-processing before it is interpretable. The LPM is the nonparametric estimator
  here, and the applied-econometrics preference for it is fully vindicated in the
  design-based frame.
- The classic anti-LPM objections have no force for ATE estimation in an experiment:
  heteroskedasticity is handled by the HC2 default, and fitted probabilities outside [0, 1]
  only matter when predicted probabilities are consumed, which the ATE never does. (If
  calibrated predictions are the deliverable, that is a different task; use the logistic
  working model for it.)
- lm_lin on a binary outcome is the covariate-adjusted LPM. Nothing in Lin's agnostic theory
  assumes a continuous outcome, so the never-hurts-precision guarantee and the sandwich
  validity apply verbatim.
- AME vs MEM: what a logit needs before it says anything interpretable. The average marginal
  effect (AME) averages unit-level risk differences over the sample and equals the
  g-computation risk difference; avg_comparisons computes it, and it is the standardization
  target everywhere in this skill. The marginal effect at the mean (MEM) evaluates the
  effect at the mean covariate vector, a profile that may describe no actual unit; under
  nonlinearity MEM does not equal AME. Older Stata habits (margins, atmeans) produce the
  MEM; do not report it.
- Discrete and multivalued treatments: OLS on arm dummies reads out each arm's risk
  difference against control directly. Multi-arm logit coefficients are conditional log-odds
  contrasts carrying the same noncollapsibility problem, and per Lin the multi-arm OLS
  adjustment should be separate per-arm regressions (pooled adjustment can hurt even in
  balanced designs beyond two arms).
- The three-tier summary of this skill's position: LPM coefficients are read directly
  (primary); logit coefficients are never read (banned); the logit as an imputation engine
  whose coefficient is never read is an optional precision upgrade (Guo-Basse, with its
  checks and the no-guarantee caveat).

## Lee bounds mechanics

- p0 = (s_T - s_C)/s_T where s is the observation rate; trim the higher-observation arm by
  p0: top for the lower bound, bottom for the upper bound. Sharp for
  E[Y1 - Y0 | always observed] under randomization + monotone selection.
- Estimator: sample trimming share, quantile threshold, trimmed mean; root-n normal with a
  three-part variance (trimmed mean, quantile, trimming share); the third part was largest
  in Job Corps. Bootstrap over the whole pipeline is the practical route (our judgment).
- Imbens-Manski interval covers the effect (default); the set-coverage interval is wider and
  only for identified-set claims.
- Covariate tightening: cells from quintiles of OLS-predicted outcomes, trim within cells,
  average over the control-selected covariate distribution (Chamberlain minimum distance for
  the variance); weakly narrower by construction, 13 percent in Job Corps. If it widens,
  the cells are too fine.
- Anchors: week 208 log-wage bounds [-0.019, 0.093] at 6.8 percent trimming vs
  Horowitz-Manski [-0.746, 0.802] (1/14th the width); week 90 with p0 near zero, bounds
  [0.042, 0.043] vs untrimmed 0.043 (se 0.011); monotonicity balance test joint p = 0.851.
- Bound width must track the differential observation rate across horizons; if it does not,
  suspect the implementation.
- Discrete outcomes: sort, drop whole observations to the greatest-integer trimming count,
  cumulating design weights to the target share.
- Under conditional-on-X randomization the machinery runs within cells, and the p0-zero
  balance test is unavailable.

## Heterogeneity toolkit

- List-Shaikh-Xu bootstrap exploits cross-test correlation and beats Bonferroni; Romano-Wolf
  stepdown is the general-purpose version.
- Honest trees: sample-split so the partition sample and estimation sample are independent;
  within-leaf means inherit randomization justification. Causal forests: pointwise
  asymptotic normality; average_treatment_effect, best_linear_projection for interpretable
  summaries, rank_average_treatment_effect as the modern detectable-heterogeneity test.
- Constant-effect test (Crump-Hotz-Imbens-Mitnik): series fit of both conditional means,
  test equality of coefficients.
- Bertanha-Imbens LATE-generalization pair: E[Y(1)] equal for always-takers vs treated
  compliers; E[Y(0)] equal for never-takers vs untreated compliers; test separately,
  possibly after covariate adjustment.
- QTE: marginal-quantile differences; bootstrap invalid at mass points (0.10 quantile
  bootstrap SE exactly 0 with 30 percent zeros); use the exact test with the QTE statistic.

## Interference designs

- Cluster at the interaction boundary (markets, stores, social clusters).
- Saturation (partial-population) designs: randomize the treated fraction across groups,
  then units within; identifies direct and indirect effects (Hudgens-Halloran). The Crepon
  displacement check: within-market differences varying with market-level treated share.
- General networks: exact tests of sharp nulls with focal units, buffer units, and auxiliary
  assignments (Athey-Eckles-Imbens); no coherent large-network asymptotics, so do not
  substitute clustered SEs for the exact test.
- Marketing instances: marketplace cannibalization, social-ad spillovers, budget-constrained
  auctions, referral programs, two-sided marketplace network effects.

## Marketing translations

- Small-cell email/pricing tests: rare-arm HC2 + Behrens-Fisher regime.
- 90/10 holdouts: the imbalanced-arms case where Lin's interactions are load-bearing.
- CUPED: fixed-slope regression adjustment on pre-period outcomes in Lin's survey-sampling
  framing; lm_lin with the pre-period metric is the design-based version.
- Conversion/click/churn lifts: report percentage-point risk differences, never adjusted
  odds ratios; noncollapsibility breaks cross-segment and cross-platform OR comparisons.
- Revenue per user: skewed, zero-inflated; log-OLS imputation with second-stage
  recalibration, never the log-coefficient-as-lift.
- Retention experiments: post-period behavior among survivors is the Lee case; differential
  churn is the trimming share.
- Uplift modeling: honest forests + policy learning; report the RATE test before claiming
  targetable heterogeneity.
- Geo experiments: cluster-level analysis primary, both estimands when market sizes vary;
  displacement checks before scaling a winning arm.

## Package index (verified against package docs 2026-07-28)

| Package | Version | Role | Traps |
|---|---|---|---|
| randomizr | 1.0.1 (CRAN) | complete_ra / block_ra / cluster_ra / block_and_cluster_ra, declare_ra for ri2 | block_ra has no N (inferred from blocks); per-block counts are block_m, not m_each |
| estimatr | 1.0.6 (CRAN) | difference_in_means (auto-detects blocked/clustered/matched-pair designs), lm_robust, lm_lin, iv_robust | difference_in_means se_type is only "default"/"none" (HC/CR strings error there); lm_lin formula is Y ~ Z only, covariates in a separate one-sided formula; CR2 is the clustered default (pinned also in causal-design's details; update the two pins together on refresh) |
| ri2 | 0.4.1 (CRAN, 2025-10, maintained) | conduct_ri Fisher tests with declared designs; custom test statistics via test_function | data argument must be named; IPW = TRUE by default |
| DeclareDesign | 1.1.1 (CRAN) | design declaration and power by simulation (diagnose_design) | estimator method arg is .method (with dot); declare_estimand is the deprecated alias of declare_inquiry |
| grf | 2.6.1 (CRAN) | causal_forest, average_treatment_effect, best_linear_projection, rank_average_treatment_effect, test_calibration | dot-separated args (num.trees, W.hat); pass known W.hat in experiments; RATE priorities must come from a held-out forest (man page requires, signature does not enforce) (pinned also in causal-design's details; update the two pins together on refresh) |
| marginaleffects | 0.32.0 (CRAN) | avg_comparisons for standardization (risk difference; lnoravg for the marginal log OR) | "oravg" does not exist; use comparison = "lnoravg" with transform = exp; vcov accepts "HC2"/"HC3" strings (pinned also in causal-design's details; update the two pins together on refresh) |
| RobinCar | 1.2.0 (CRAN) | covariate adjustment under covariate-adaptive randomization (ANOVA/ANCOVA/ANHECOVA) | strata argument is car_strata_cols; quoted column names, unlike estimatr's bare names |
| qte | 2.0.0 (CRAN, 2026-07) | QTE with bootstrap inference | ci.qte deprecated in 2.0.0; use unc_qte(yname, dname, xformla = ~1); all pre-2026-07 tutorials show the dead API |
| wildrwolf | 0.7.0 (r-universe; ARCHIVED from CRAN 2024-05) | Romano-Wolf stepdown p-values | needs archived fwildclusterboot; accepts only fixest models; budget the p.adjust(holm) fallback |
| PowerUpR | 1.1.0 (CRAN Archive; ARCHIVED 2026-03) | mdes.cra2/power.cra2/mrss.cra2 cluster-power closed forms | off CRAN; prefer hand-coding DEFF = 1 + (m-1) ICC in templates |
| Lee bounds | none | no CRAN package implements Lee 2009 trimming bounds (checked the full index; ATbounds/bpbounds/rbounds/plausibounds are different things); vsemenova/leebounds is a replication archive, not installable, and its README example does not run against its own code | hand-roll (the template does) with a full-pipeline bootstrap |

Stata mirror: ritest (randomization inference), mhtexp (List-Shaikh-Xu), rwolf, leebounds
(Tauchmann 2014, the standard Lee-bounds implementation with tight() and cieffect), ivdesc
(complier profiling).
