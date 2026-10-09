# Field-experiment lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-10-09.

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
  unweighted unit OLS with Liang-Zeger CR (with few clusters, the family's small-G rule in
  ../../causal-design/references/shared-rules.md: CV3 plus the wild cluster restricted
  bootstrap first, CR2 with Satterthwaite dof as the cross-check), or cluster-level WLS
  with weights N_g. One mega-cluster can make the unit-average estimand far less precise
  than the cluster-average one.
- Clustered sampling with unit-level randomization is a different problem: Neyman for the
  sample ATE, clustered SEs only for the population ATE (abadie2023clustering).

## Power

Minimum N = (Phi^-1(beta) + Phi^-1(1 - alpha/2))^2 / ((tau^2/sigma^2) gamma (1 - gamma)),
gamma the treated share (1/2 optimal under homoskedasticity). Worked example: sigma = 6,
tau = 1, alpha = .05, power = .8 gives N = 1130; tau = 2 gives N = 282. The chapter prints
1,302 for tau = 1, which does not follow from its own formula (the formula gives 1,130, and
power.t.test gives 566 per arm); its tau = 2 value matches. Base R power.t.test
matches up to the t-vs-normal refinement; stratified and clustered designs by simulation
(DeclareDesign) or PowerUpR closed forms for cluster designs.

## Lin algebra and checks

- Efficiency: the interacted estimator's gain over uninteracted is
  ((2p_A - 1)^2 / (n p_A (1 - p_A))) times the variance of the covariate-explained part of
  the treatment effect; zero at equal arms or equal slopes. Variance gain over unadjusted is
  the 1 - R2 factor.
- For uninteracted adjustment to hurt with one covariate, more than three quarters of
  subjects must sit in one arm, or the covariate must covary more with the effect than with
  the outcome level. With more than two arms, pooled adjustment can hurt even in a balanced
  design when effects are heterogeneous (Freedman 2008, AoAS, `freedman2008several`,
  Section 4). Separate per-arm regressions keep the guarantee (Negi and Wooldridge 2021 for
  two arms; Negi and Wooldridge 2025 for more).
- Bias is order 1/n; leading term is a covariance of outcomes with squared demeaned
  covariates, estimable by plug-in (ALO example: -0.0002 against SE 0.146). Report it when
  arms are small and covariates skewed.
- Zero-effect coverage simulation: hold outcomes fixed, assume no effect, re-randomize many
  times, compute empirical coverage for every planned estimator-variance pair. A coverage
  benchmark, not a permutation test.
- Sandwich sweep: HC0-HC3 agreed (94.4-95.1 percent coverage) in Lin's 250k-replication
  check; HC0 degrades first with leverage. In the Guo-Basse Fatalities example (footnote 8)
  HC0 had poor coverage and they used HC3; the footnote says nothing about HC2. The HC2
  default rests on Lin: HC2 equals the Neyman estimator (his remark (v)), and his Table 3
  sweep gives 94.4 to 95.1 percent coverage.
- Poststratification is lm_lin with partition indicators; then the estimator is exactly
  unbiased over the randomization distribution.

## Noncollapsibility and standardization (binary outcomes)

- Section 9 inequality: with subject-level odds multiplier lambda > 1 and any variation in
  baseline risks, the pooled multiplier lies strictly between 1 and lambda. So
  |beta-hat| > |marginal Delta| whenever the covariate is prognostic; the gap is predicted,
  not evidence of bias.
- The calibration mechanism: logit score equations force arm-average fitted probabilities to
  equal arm-average outcomes; that plus randomization's covariate balance makes the plug-in
  consistent. Probit lacks it (nonzero asymptotic bias).
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

- The classic anti-LPM objections have no force for ATE estimation in an experiment:
  heteroskedasticity is handled by the HC2 default, and fitted probabilities outside [0, 1]
  only matter when predicted probabilities are consumed, which the ATE never does. (If
  calibrated predictions are the deliverable, that is a different task; use the logistic
  working model for it.)
- AME vs MEM: what a logit needs before it says anything interpretable. The average marginal
  effect (AME) averages unit-level risk differences over the sample and equals the
  g-computation risk difference; avg_comparisons computes it, and it is the standardization
  target everywhere in this skill. The marginal effect at the mean (MEM) evaluates the
  effect at the mean covariate vector, a profile that may describe no actual unit; under
  nonlinearity MEM does not equal AME. Older Stata habits (margins, atmeans) produce the
  MEM; do not report it.
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
  summaries, rank_average_treatment_effect as the modern detectable-heterogeneity test
  (RATE with AUTOC or Qini weights; Yadlowsky et al. 2025).
- Generic ML (Chernozhukov, Demirer, Duflo, and Fernandez-Val 2025; GenericML 0.2.3):
  GenericML(Z, D, Y, learners_GenericML, num_splits, quantile_cutoffs, ...), then
  get_BLP, get_GATES, and get_CLAN. Pass the known propensity in experiments
  (learner_propensity_score = "constant" is the default). The package reports level
  1 - 2 alpha. The published Econometrica paper recommends the nominal 1 - alpha level,
  so pass significance_level = 0.025 for 95 percent intervals.
- Romano-Wolf by resampling: the template codes a stratified bootstrap stepdown over
  assignment units with HC2 (Neyman) t-statistics across an outcome family. With few
  clusters, use a wild cluster bootstrap stepdown (Westfall-Young or Romano-Wolf);
  wildrwolf does this for fixest models (archived from CRAN, r-universe 0.7.0).
  hdm::p_adjust(method = "RW") does not qualify: it draws Gaussian vectors from the
  homoskedastic vcov of one lm fit, with no resampling and no HC2 (hdm 0.3.2 source).
- Constant-effect test (Crump, Hotz, Imbens, and Mitnik 2008): series fit of both
  conditional means, test equality of coefficients.
- Complier comparability pair: E[Y(1)] equal for always-takers vs treated compliers; E[Y(0)]
  equal for never-takers vs untreated compliers; test separately, possibly after covariate
  adjustment. Bertanha and Imbens (2020) build the tests for fuzzy RD and state the LATE
  case as a lemma; the Athey-Imbens chapter applies them to experiments.
- QTE: marginal-quantile differences; bootstrap invalid at mass points (0.10 quantile
  bootstrap SE exactly 0 with 30 percent zeros); use the exact test with the QTE statistic.

## Marketing translations

The rest of the marketing cases (small-cell tests, 90/10 holdouts, conversion lifts,
retention, uplift, geo tests apart from the displacement check below) are stated in SKILL.md at the rule they instantiate.

- CUPED: fixed-slope regression adjustment on pre-period outcomes in Lin's survey-sampling
  framing (Deng et al. 2013); lm_lin with the pre-period metric is the design-based version.
- Revenue per user: skewed, zero-inflated; Poisson quasi-likelihood imputation per arm,
  reported in levels or as a share of the control mean (Chen and Roth 2024). Log-OLS with
  second-stage recalibration only when every value is positive. Never the
  log-coefficient-as-lift.
- Geo experiments: run displacement checks before scaling a winning arm.
- Interference instances: marketplace cannibalization, social-ad spillovers, referral
  programs, livestream network effects.

## Package index (versions checked against CRAN; template run end to end on these versions)

| Package | Version | Role | Traps |
|---|---|---|---|
| randomizr | 2.0.1 (CRAN, 2026-08-27) | complete_ra / block_ra / cluster_ra / block_and_cluster_ra, declare_ra for ri2 | block_ra has no N (inferred from blocks); per-block counts are block_m, not m_each; 2.0 added declare_ra arguments before permutation_matrix, so name every argument past the first few |
| ri2 | 0.5.0 (CRAN, 2026-07-29) | conduct_ri Fisher tests with declared designs; custom test statistics via test_function | data argument must be named; IPW = TRUE by default; versions before 0.5.0 gave anti-conservative null distributions when the assignment enters more than one formula term (y ~ z * x), so pin at least 0.5.0 |
| DeclareDesign | 1.1.1 (CRAN) | design declaration and power by simulation (diagnose_design) | estimator method arg is .method (with dot); declare_estimand is the deprecated alias of declare_inquiry |
| RobinCar | 1.2.0 (CRAN) | covariate adjustment under covariate-adaptive randomization (ANOVA/ANCOVA/ANHECOVA) | strata argument is car_strata_cols; quoted column names, unlike estimatr's bare names |
| dfadjust | 1.1.0 (CRAN, 2024-12-18) | dfadjustSE: HC2 with Imbens-Kolesar (or Bell-McCaffrey) degrees of freedom for regressions with a rare arm | takes an lm object, not an estimatr fit; the template refits the lm_lin specification with lm |
| qte | 2.0.0 (CRAN, 2026-07) | QTE with bootstrap inference | ci.qte deprecated in 2.0.0; use unc_qte(yname, dname, xformla = ~1); all pre-2026-07 tutorials show the dead API |
| GenericML | 0.2.3 (CRAN, 2026-07-03) | BLP, GATES, and CLAN with repeated sample splitting (Chernozhukov et al. 2025) | reports confidence level 1 - 2 alpha and doubles p-values; learners are mlr3 strings ("mlr3::lrn('ranger')"); slow at the default num_splits = 100 |
| wildrwolf | 0.7.0 (r-universe; ARCHIVED from CRAN 2024-05) | Romano-Wolf stepdown p-values by wild cluster bootstrap | needs archived fwildclusterboot; accepts only fixest models; the template's hand-coded bootstrap stepdown is the route that needs no archived package |
| PowerUpR | 1.1.0 (CRAN Archive; ARCHIVED 2026-03) | mdes.cra2/power.cra2/mrss.cra2 cluster-power closed forms | off CRAN; prefer hand-coding DEFF = 1 + (m-1) ICC in templates |
| Lee bounds | none | no CRAN package implements Lee 2009 trimming bounds (checked the full index; ATbounds/bpbounds/rbounds/plausibounds are different things); vsemenova/leebounds is a replication archive, not installable, and its README example does not run against its own code | hand-roll (the template does) with a full-pipeline bootstrap |

Shared with other causal skills: estimatr, grf, and marginaleffects. Versions and family-wide traps
are in ../../causal-design/references/packages.md. Traps specific to this skill: estimatr's
difference_in_means auto-detects blocked, clustered, and matched-pair designs, accepts only
se_type "default" or "none" (HC and CR strings error there), and lm_lin takes Y ~ Z only, with
covariates in a separate one-sided formula. Pass the known W.hat to grf in experiments.
marginaleffects has no "oravg"; use comparison = "lnoravg" with transform = exp, and vcov accepts
the "HC2" and "HC3" strings.

Stata mirror: ritest (randomization inference), mhtexp (List-Shaikh-Xu), rwolf, leebounds
(Tauchmann 2014, the standard Lee-bounds implementation with tight() and cieffect), ivdesc
(complier profiling).
