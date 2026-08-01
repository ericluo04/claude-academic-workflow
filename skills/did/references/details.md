# DiD lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-29.

## Package index (verified 2026-07-28)

| Package | Where | Version seen | Role |
|---|---|---|---|
| did | CRAN; bcallaway11.github.io/did | 2.5.1 | Callaway-Sant'Anna att_gt/aggte |
| HonestDiD | CRAN; github.com/asheshrambachan/HonestDiD | 0.2.8 | Rambachan-Roth, both restrictions; README ships the aggte adapter |
| didimputation | CRAN; github.com/kylebutts/didimputation | 0.5.1 | BJS imputation |
| did2s | CRAN | | Gardner two-stage |
| fixest | CRAN; lrberge.github.io/fixest | 0.14.2 | sunab (Sun-Abraham), TWFE (pinned also in iv's details; update the two pins together on refresh) |
| pretrends | GitHub ONLY: github.com/jonathandroth/pretrends | master | pretest power, slope_for_power |
| staggered | CRAN; github.com/jonathandroth/staggered | 1.2.2 | efficient random-timing estimators |
| TwoWayFEWeights | CRAN; github.com/Credible-Answers/twowayfeweights | 2.1.0 | dCDH negative-weight diagnostics |
| bacondecomp | CRAN; github.com/evanjflack/bacondecomp | 0.1.1 | Goodman-Bacon decomposition |
| etwfe | CRAN | | Wooldridge extended TWFE |
| DIDmultiplegt / did_multiplegt_dyn | CRAN/SSC; github.com/Credible-Answers | | dCDH intertemporal, on/off treatments |
| summclust | ARCHIVED from CRAN 2025-11-02; install from s3alfisc.r-universe.dev | 0.7.0 | CV3 cluster-jackknife vcov, leverage, partial leverage, leave-one-cluster-out betas |
| fwildclusterboot | ARCHIVED from CRAN 2024-05-29; install from s3alfisc.r-universe.dev | 0.14.3 | boottest wild cluster bootstrap: WCR/WCU, Rademacher/Webb weights, MNW "33" variants |
| clubSandwich | CRAN | 0.7.0 | CR2 vcovCR + Satterthwaite coef_test, the CRAN-resident cross-check |
| sandwich | CRAN | | vcovBS(type = "jackknife"), a CRAN-resident CV3 route for linear models, no leverage diagnostics |

Never-treated coding by package: did and didimputation use 0 (didimputation also accepts NA);
staggered uses Inf; sunab treats any cohort value outside the observed periods as never-treated
(the fixest example data uses 10000). Recode per package; never recycle blindly.

Cluster-inference rows verified 2026-07-29. Install the archived pair with
install.packages(c("summclust", "fwildclusterboot"), repos = "https://s3alfisc.r-universe.dev").
boottest's fixest method takes feols objects only and disallows weights with fixed effects.

## Few-clusters map (choose by the homogeneity you believe)

Map from Roth et al. (2023) Section 5 (`roth2023whats`); execution order, thresholds, and
failure signatures from MacKinnon, Nielsen, and Webb (2023, `mackinnon2023cluster`; MNW in
the rows). Each method with the assumption that is its price:

| Method | Needs | Works when |
|---|---|---|
| CV3 cluster jackknife with t(G-1) | across-cluster independence only | the default first line at any G, not a few-clusters specialist; sometimes under-rejects; still fails with very few treated clusters |
| CR2 with Satterthwaite dof | a working model for the dof (identity or random-effects variance); the Imbens-Kolesar variant fails with absorbed cluster FEs | confirmation tool, not first line; the dof can fall far below G-1 |
| Donald-Lang | homoskedastic Gaussian cluster shocks | few treated and few untreated (the one row MNW do not discuss) |
| Conley-Taber | treated clusters share controls' error distribution (fails under heterogeneous effects or unequal sizes) | many controls, few treated; RI-beta-like, so under cluster-size heterogeneity prefer RI-t (MacKinnon-Webb 2020b) |
| Ferman-Pinto | heteroskedasticity only from observables (size); the restriction is exactly why it can work with one treated cluster (MNW p. 287) | Conley-Taber setting plus size variation |
| Hagemann permutation | bound on maximal relative heterogeneity; no cluster-specific trend heterogeneity in Y(0); G1 >= 4 and G - G1 >= 4 | few clusters both sides |
| Cluster wild bootstrap (WCR) | homogeneity conditions that fail with cluster-and-time FEs or heterogeneous effects (Canay-Santos-Shaikh) | not a general fix. With few treated it under-rejects (every other method over-rejects); a bimodal bootstrap distribution is the tell; use Webb 6-point weights plus enumeration when 2^G is small; the rescue is the ordinary wild restricted (WR, observation-level weights) bootstrap |
| Long-T methods (Canay-Romano-Shaikh, Ibragimov-Mueller, conformal) | limited time-series dependence, PT over many periods; CRS needs treated and control observations inside every cluster (merge clusters, pay power); IM infeasible when treatment is cluster-invariant | T genuinely large |
| Fallback A | none beyond honesty | treat the cluster shock as a PT violation inside HonestDiD |
| Fallback B: cluster-level Fisher randomization test | timing as good as random; exact under the sharp null | arbitrary heterogeneity allowed; a null is informative |

## Few-clusters battery (MacKinnon, Nielsen, and Webb 2023)

Run before reaching for the map; the map is the escalation path when the battery disagrees.
Condensed from `mackinnon2023cluster` Section 9:

1. List plausible clustering levels; decide by the assignment-level rule and the largest-SE
   rule (score-variance tests and placebo regressions optional; picking the level by test is
   pre-testing).
2. Report G and the cluster-size distribution for every plausible level.
3. Report leverage, partial leverage, influence, and the effective number of clusters for the
   key specification.
4. Run CV3 (cluster jackknife) and at least one WCR bootstrap alongside CV1, for tests and
   intervals, as a matter of course. Agreement means finite-sample problems are probably not
   severe. Disagreement means try more variants and the map.
5. With few or atypical treated (or control) clusters, even CV3 and WCR are unreliable; verify
   with randomization inference (RI-t degrades less than RI-beta under cluster-size
   heterogeneity).

Concern zones, verbatim thresholds (p. 290): "few but balanced clusters (say, G <= 12)";
"balanced but few treated (or few control) clusters (say G1 <= 6 or G - G1 <= 6)"; "seriously
unbalanced cluster sizes (even when G is quite large)"; "treated clusters that are unusually
large or small"; "any sort of heterogeneity that causes a few clusters to have high leverage".
Three of the five can fire at large G. Reporting is part of the method: "it is therefore
absolutely essential to report the number of clusters, G, whenever inference is based on a
CRVE. This is even more important than reporting N." G and the leverage diagnostics go in the
paper alongside N.

## Sup-t uniform band recipe (AAFP 2025, four steps)

1. Estimate the leads (or lags), save coefficients and their full covariance matrix.
2. Simulate many draws from N(0, Sigma-hat).
3. For each draw take the maximum absolute t-statistic across coefficients.
4. The 1-alpha quantile of that distribution is the critical value; band = estimate +/- cv * se.

Compute separately for leads and lags. Expect true size above nominal with clustered SEs (0.146
at nominal 5% in AAFP's calibrated design). Wild-bootstrap variant (null imposed, Rademacher
weights, 999 reps, bootstrap the max-t via Stata boottest): near-nominal size 0.049, power only
0.31; use when a false rejection is costlier than a miss.

## Pretesting cost-benefit (AAFP 2025)

Unconditional bias delta * theta vs screened bias delta_s * P[divergent | pass]. Screening
reduces bias when |delta_s| (1-pi) / ((1-pi) theta + (1-alpha)(1-theta)) < delta; at power 0.5
and nominal size, screening pays when |delta_s| / (2 - theta) < delta. Caveat carried with it:
screened BJS can be more biased than screened regression under linear divergent trends, because
BJS baselines on the whole pre-period average (short lags worst).

## Covariate balance: normalized differences

(X-bar_T - X-bar_C) / sqrt((S_T^2 + S_C^2)/2), reported for baseline levels and for pre-period
changes, weighted and unweighted (Imbens-Rubin via Baker et al.). Flags: |nd| > 0.25
problematic, 0.1 already worrisome for a covariate known to matter. A Delta-X balance check is
literally a 2x2 DiD with X as the outcome, so a change-imbalance indicates a PT violation only
if X is strictly exogenous; if treatment can move X, the imbalance may be a treatment effect.

## RA / IPW / DR mechanics (Baker et al. 2026)

- RA: fit E[dY | X, D=0] on controls, average predictions over treated-unit X. Survives weak
  overlap by extrapolation; credibility rests on that extrapolation.
- IPW: reweight control trends by p(X)/(1-p(X)) so the control covariate distribution matches
  the treated. Noisy as control p(X) approaches 1; trim at 0.995 (package default), keep the
  trim, use bias correction (Ma-Sasaki-Wang) if trimming more aggressively.
- DR: combine; consistent if either model is right, efficient if both are (Sant'Anna-Zhao).
- Event studies: long differences Y_t - Y_{g-1}; propensity model period-invariant, outcome
  model per-period. Staggered: group-time propensity P(G=g | X, in g or not-yet-treated at t).
- BJS and dCDH take covariates only in levels, so they do not implement conditional PT proper;
  Wooldridge ETWFE with interactions does.

## Exposure-design estimand (AAFP 2025)

With tau_s = kappa + phi M_s, the linear-interaction regression estimates approximately the
average marginal effect kappa + 2 phi E[M_s], twice as sensitive to exposure as the
random-coefficient average E[tau_s] = kappa + phi E[M_s]. Nunn-Qian numbers: pooled OLS 0.81,
weighted average of tau_s about 0.55, computed AME about 0.75 (matching OLS). Which target is
right depends on whether tau_s rising with M_s is itself causal. When heterogeneity is
plausible, add the exposure-squared interaction and report both.

## Minimal teaching counterexamples (AAFP 2025)

- Dynamic heterogeneity: two states, true effects 1 on impact and 4 thereafter; static DD
  returns -0.5 because already-treated units serve as controls.
- Cross-sectional heterogeneity: constant per-state effects of 1 and 4 produce an event-study
  tau_1 = -2 through the implicit cross-state extrapolation.

## Repeated cross-sections and unbalanced panels (Baker et al. 2026)

Unconditional DiD needs only group-time means: repeated cross-sections and unbalanced panels are
fine with the estimand reinterpreted (ATT among units sampled post). With covariates: if the
joint distribution of (D, X) is time-invariant, pool across periods for precision; if
composition may change, do not pool, target ATT(2 | sampled in 2), and run the Sant'Anna-Xu
Hausman-type comparison. Staggered warning: the Sun-Abraham regression with unit FEs on
unbalanced data no longer equals the CS estimator; replace unit FEs with group dummies.

## Estimator-to-assumption crosswalk (code level)

- did::att_gt(control_group="nevertreated") imposes PT-GT-Nev.
- did::att_gt(control_group="notyettreated") imposes PT-GT-NYT (Baker et al.'s preference).
- etwfe / jwdid, did2s, didimputation, and any pre-period-averaging estimator impose PT-GT-all
  (parallel pre-trends become a testable overidentifying restriction, and are baked in).
- fixest::sunab equals CS-never numerically on balanced panels; on unbalanced panels the
  equivalence fails (see above).
- lpdid (local projections DiD) is equivalent to the CS-NYT plug-in (Dube-Girardi-Jorda-Taylor).
- Stacked regression (clean-controls stacks) appears in marketing practice and in the AMA
  Marketing News routing source (Li, Luo, and Pattabhiramaiah 2024; 'AMA' hereafter); its
  implicit variance weights are a known problem (Baker et al.), so prefer Callaway-Sant'Anna
  or Sun-Abraham unless the stack weights are examined and reported.
