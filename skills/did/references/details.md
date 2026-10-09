# DiD lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-10-09.

## Package index (verified 2026-07-28; CRAN versions and release dates re-checked 2026-08-26)

| Package | Where | Version seen | Role |
|---|---|---|---|
| did | CRAN; bcallaway11.github.io/did | 2.5.1 (2026-07-08) | Callaway-Sant'Anna att_gt/aggte; aggte types simple, group, calendar, dynamic. Since 2.5, faster_mode = TRUE and aggte's default type is "group", both changed from the 2.1.x tutorials |
| HonestDiD | CRAN; github.com/asheshrambachan/HonestDiD | 0.2.8 (2026-04-12) | Rambachan-Roth, both restrictions; README ships the aggte adapter |
| didimputation | CRAN; github.com/kylebutts/didimputation | 0.5.1 (2026-03-09) | BJS imputation |
| did2s | CRAN | 1.2.1 (2026-03-05) | Gardner two-stage |
| DRDID | CRAN; psantanna.com/DRDID | 1.3.0 (2026-06-10) | Sant'Anna-Zhao 2x2 doubly robust building block that did calls; drdid/ipwdid/ordid for a two-period design estimated directly |
| panelView | CRAN; yiqingxu.org/packages/panelview | 1.3.1 (2026-05-14) | treatment rollout plot, unit by period (Mou, Liu, and Xu 2023); design-stage step 3 |
| pretrends | GitHub ONLY: github.com/jonathandroth/pretrends | master | pretest power, slope_for_power |
| staggered | CRAN; github.com/jonathandroth/staggered | 1.2.2 (2025-01-09) | efficient random-timing estimators |
| TwoWayFEWeights | CRAN; github.com/Credible-Answers/twowayfeweights | 2.1.0 (2026-05-27) | dCDH negative-weight diagnostics |
| bacondecomp | CRAN; github.com/evanjflack/bacondecomp | 0.1.1 (2020-01-24) | Goodman-Bacon decomposition; last released 2020 and still the only R implementation |
| etwfe | CRAN; grantmcdermott.com/etwfe | 0.6.2 (2026-03-23) | Wooldridge extended TWFE, linear and nonlinear (family = "poisson", "logit", "negbin" through fixest::feglm); a nonlinear family forces ivar = NULL and enters cohort and period as explicit dummies (emfx cannot compute SEs with absorbed FEs in nonlinear models); controls on the RHS of fml are demeaned by cohort and the xvar moderator by cohort-by-period cell (source, not docs); nothing unit-level is used, so repeated cross sections run unchanged (run on simulated repeated-cross-section data 2026-08-26, pilot only); emfx returns APEs (predict = "response") or index-scale effects (predict = "link") and compresses to cohort-period cells above 500,000 rows unless compress = FALSE; verified 2026-08-26 |
| jwdid (Stata) | SSC; github.com/friosavila/stpackages | 2.0 (2024-05-04) | Wooldridge ETWFE; no ivar means repeated cross-section; method(poisson), method(logit), method(ppmlhdfe); covariates demeaned and interacted by default (xasis to disable); verified 2026-08-26 |
| ppmlhdfe (Stata) | SSC | | PPML with high-dimensional FEs (Correia-Guimarães-Zylkin 2020); R equivalent fixest::fepois |
| DIDmultiplegtDYN | CRAN; github.com/Credible-Answers | 2.4.0 (2026-06-30) | dCDH intertemporal, on/off treatments; the R port of Stata's did_multiplegt_dyn and the name to use. The older DIDmultiplegt (2.1.0, 2026-02-17) is the static estimator and is not the one the skill's reversal rule calls. Loading it requires the `polars` R package from rpolars.r-universe.dev (template section 8b) |
| triplediff | CRAN | 0.2.4 (2026-06-13) | doubly robust triple differences with covariates and staggered adoption, `ddd()` and `agg_ddd()` (Ortiz-Villavicencio and Sant'Anna 2025, `ortizvillavicencio2025better`); template section 8c |
| csdid / csdid2 (Stata) | SSC (Rios-Avila) | | Callaway-Sant'Anna in Stata. csdid 2.0.0 defaults to `base_period(universal)` (long differences); 1.8x defaulted to varying (short gaps), so on 1.8x pass `long2`, which 2.0.0 keeps only as a deprecated compatibility name. csdid 2.0.0 also made not-yet-treated units the default comparison group, where 1.82 used never-treated; pass `nevertreated` to restore the old group (changelog at psantanna.com/csdid/news.html, checked 2026-10-09). The csdid2 default is unverified |
| summclust | ARCHIVED from CRAN 2025-11-02; install from s3alfisc.r-universe.dev | 0.7.0 (r-universe build 2026-09-02; last CRAN release 0.7.2, 2023-08-10) | CV3 cluster-jackknife vcov, leverage, partial leverage, leave-one-cluster-out betas |
| fwildclusterboot | ARCHIVED from CRAN 2024-05-29; install from s3alfisc.r-universe.dev | 0.14.3 (r-universe build 2026-09-14; ahead of the last CRAN release 0.13.0) | boottest wild cluster bootstrap: WCR/WCU, Rademacher/Webb weights, MNW "33" variants |
| clubSandwich | CRAN | 0.7.0 (2026-05-04) | CR2 vcovCR + Satterthwaite coef_test, the CRAN-resident cross-check |

Shared with other causal skills: fixest (sunab for Sun-Abraham, and TWFE) and sandwich
(vcovBS(type = "jackknife") as the CRAN-resident CV3 route). Versions and family-wide traps are in
../../causal-design/references/packages.md.

Never-treated coding by package: did and didimputation use 0 (didimputation also accepts NA);
staggered uses Inf; sunab treats any cohort value outside the observed periods as never-treated
(the fixest example data uses 10000). etwfe takes as reference any cohort value above
max(tvar), else any below min(tvar), else (only with cgroup = "notyet") the largest cohort; so
the did-style 0 works when periods start at 1, reads as a real cohort if a period is numbered
0, and with cgroup = "never" an in-range value errors. Leads are estimated only under
cgroup = "never" (every cohort-period cell except g-1 gets a dummy); "notyet" sets them to zero
mechanically. Recode per package; never recycle blindly.

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
| Conley-Taber | treated clusters share controls' error distribution (fails under heterogeneous effects or unequal sizes) | many controls, few treated; RI-beta-like. When treated clusters are systematically larger or smaller than controls, neither RI-beta nor RI-t performs well; RI-t usually does better, and it may need a much larger G than the WCR bootstrap (MNW Section 6.2; MacKinnon and Webb 2020, `mackinnon2020randomization`) |
| Ferman-Pinto | heteroskedasticity only from observables (size); the restriction is exactly why it can work with one treated cluster (MNW p. 287) | Conley-Taber setting plus size variation |
| Hagemann permutation (REStat 2025, 107(4), `hagemann2025permutation`) | bound on maximal relative heterogeneity; no cluster-specific trend heterogeneity in Y(0); G1 >= 4 and G - G1 >= 4 | few clusters both sides |
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
   with randomization inference. RI-t degrades less than RI-beta under cluster-size
   heterogeneity, but when treated clusters are systematically larger or smaller neither works
   well (MNW Section 6.2).

Concern zones, verbatim thresholds (p. 290): "few but balanced clusters (say, G <= 12)";
"balanced but few treated (or few control) clusters (say G1 <= 6 or G - G1 <= 6)"; "seriously
unbalanced cluster sizes (even when G is quite large)"; "treated clusters that are unusually
large or small"; "any sort of heterogeneity that causes a few clusters to have high leverage".
Three of the five can fire at large G. Reporting is part of the method: "it is therefore
absolutely essential to report the number of clusters, G, whenever inference is based on a
CRVE. This is even more important than reporting N." G and the leverage diagnostics go in the
paper alongside N.

## Two Mixtape rules to disarm

Moved from SKILL.md (section "Inference").

Two Mixtape rules to disarm. Chapter 9 reads Card and Krueger's two-state minimum wage design off
a t-statistic of about 2 and calls it significant (Cunningham, The Mixtape, online ch. 9 sec.
9.4); at the assignment level that is G = 2 with one
treated cluster, every MacKinnon-Nielsen-Webb concern zone firing at once and a CV1 standard
error that can be too small by a factor of five or more. It is the canonical exemplar of the DiD
idea and not a template for inference, and a modern version of it lands on the few-clusters map
or the synthetic-control handoff. Chapter 8's rule of thumb, fewer than 30 clusters too small and
30 to 40 probably enough (online ch. 8, footnote 5), is unsafe in both directions: CV1 can
be reliable at G = 20 in favorable cases and unreliable at G = 200 in unfavorable ones. Run
the battery instead of
counting clusters.

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

## Selection mechanisms and parallel trends (Ghanem-Sant'Anna-Wüthrich; Marx-Tamer-Tang)

Sources: `ghanem2022selection` and Marx, Tamer, and Tang (2024, `marx2024parallel`), as
organized in Cunningham, The Mixtape, online ch. 9 sec. 9.8. The two columns come apart, which is the
whole point of the table: a mechanism can leave PT intact and still wreck the pre-trend picture.

| Mechanism | Parallel trends | Pre-trends | What to do |
|---|---|---|---|
| Common constant trend in Y(0) | cannot be violated, for any assignment rule | clean | nothing; covariates are unnecessary here |
| Selection on baseline Y(0) (enrolled below a threshold on Y) | holds only under the martingale condition E[Y_2(0) given the unit effect and the baseline shock] = Y_1(0), a unit-root restriction on the shocks (Ghanem, Sant'Anna, and Wüthrich, arXiv 2203.09001, Corollary 3.3); fails when Y(0) mean-reverts (the Ashenfelter dip) | broken mechanically, a dip at t = -1, because the baseline is both the selection point and the omitted category | under the martingale condition, no fix: do not re-base to t = -2, since PT held from the original baseline (see the HonestDiD note below). Under mean reversion the dip is a real PT violation, before and after treatment, and needs a design that handles it |
| Selection on fixed effects (only certain types enroll) | holds | clean | nothing |
| Selection on observables | holds conditional on X | clean given X | conditional PT: RA, IPW, or DR |
| Imperfect foresight about own gains | holds | clean | nothing |
| Selection on realized gains (Perfect Doctor, essential heterogeneity) | broken | E[Y(0)] diverges before and after, so pre-trends usually show it | DiD is biased by construction; clean pre-trends are no defense. Route out to causal-design (SKILL.md refusal list, case 3) |

HonestDiD interaction, the skill's own judgment and stated in neither source: relative
magnitudes anchors on the largest pre-treatment violation, so a mechanical baseline dip from
selection on baseline Y(0) inflates the anchor and the robust interval with it. That
inflation happens only under the martingale (random-walk) condition in the table. In that case,
prefer smoothness. Alternatively, recompute the anchor from the pre-treatment periods excluding
the selection period, and say which you did. Under mean reversion, the dip is a real violation
and the relative-magnitudes anchor is correct. The mirror-image failure is that under selection
on realized gains the pretest-plus-HonestDiD chain passes a design that is biased by
construction.

## Triple differences: assumption and specifications (Olden and Møen 2022; Gruber 1994)

Identifying assumption (parallel bias), with D the treatment level (experimental vs
non-experimental states) and G the group (eligible vs placebo):

    E[dY(0) | D=1, G=1] - E[dY(0) | D=0, G=1] = E[dY(0) | D=1, G=0] - E[dY(0) | D=0, G=0]

The main DiD equals ATT plus its own non-parallel-trends bias, the placebo-group DiD equals its
non-parallel-trends bias alone, and subtracting the second from the first leaves the ATT when
the two biases match. Eight averages and seven subtractions. The placebo DiD is not required to
be zero; a zero one means the main DiD was already unbiased.

Saturated OLS (Gruber's own form), with tau the post dummy, delta the eligible-group dummy, and
D the treated-unit dummy:

    Y = a + b2 tau + b3 delta + b4 D + b5 (delta x tau) + b6 (tau x D) + b7 (delta x D)
        + b8 (delta x tau x D) + e

b8 is the DDD estimate, and only in exactly this saturated specification. Event-study form:
replace the post dummy with period dummies (t = -1 omitted) throughout, so the regression carries
group-by-period, unit-by-period, and group-by-unit fixed effects plus the triple interaction with
each period dummy; the DDD leads and lags are the coefficients on that last set. Cluster at the
level at which treatment was applied. Present the main DiD event study, the placebo-group event
study, and the DDD event study together, since the design's claim is that the first two share a
bias term.

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
  trim, use bias correction (Ma-Sasaki-Wang) if trimming more aggressively. Only the control
  group is weighted, which is why extreme scores matter on that side only. The arithmetic is
  brutal and hides inside a histogram: p = 0.99991 gives 0.99991/0.00009 = 11,110, and in the
  Mixtape's CAPS data (Cunningham, The Mixtape, online ch. 10 sec. 10.14) p = 0.999971 gives
  34,481, so one control unit outweighs thousands. Eleven
  CAPS control municipalities sat above 0.995. Count the near-1 control scores by hand, since
  a density plot hides them, and check whether your package trims: R's did does, and Stata
  routines vary.
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
fine with the estimand reinterpreted (ATT among units sampled post), provided missingness is
independent of Y(0) given X. That is weaker than missing at random (Wooldridge 2010) and it is
the condition that matters, because PT is a statement about Y(0). When dropout is caused by the
outcome (churned users, delisted stores, closed accounts, the worker who leaves because earnings
fell), PT breaks and forcing balance by dropping units does not fix it: reason about the
mechanism instead. Options once the mechanism is understood are imputation of the missing
untreated cells (Heckman 1979; Athey et al. 2021; BJS 2024) and the chained DiD of Bellégo,
Benatia, and Dortet-Bernadet (2025, Journal of Econometrics 248, 105783, `bellego2025chained`),
which chains short-run effects across adjacent-period overlaps and so discards nothing. The R
package `cdid` (CRAN 0.1.1) implements it. Report attrition rates by cohort either way, since
differential attrition is itself a PT diagnostic. With covariates: if the
joint distribution of (D, X) is time-invariant, pool across periods for precision; if
composition may change, do not pool, target ATT(2 | sampled in 2), and run the Sant'Anna-Xu
Hausman-type comparison. Staggered warning: the Sun-Abraham regression with unit FEs on
unbalanced data no longer equals the CS estimator; replace unit FEs with group dummies.

## Estimator-to-assumption crosswalk (code level)

- did::att_gt(control_group="nevertreated") imposes PT-GT-Nev.
- did::att_gt(control_group="notyettreated") imposes PT-GT-NYT (Baker et al.'s preference).
- etwfe / jwdid, did2s, didimputation, and any pre-period-averaging estimator impose PT-GT-all
  (parallel pre-trends become a testable overidentifying restriction, and are baked in).
- etwfe / jwdid with a nonlinear family impose PT-GT-all on the index scale (log odds under
  logit, log mean under Poisson), which in general does not hold in levels (Wooldridge 2026;
  the exceptions are no selection and stationarity). Wooldridge recommends fitting the linear
  and the nonlinear model and comparing them, as a comparison of assumptions.
- fixest::sunab equals CS-never numerically on balanced panels; on unbalanced panels the
  equivalence fails (see above).
- lpdid (local projections DiD; Dube, Girardi, Jordà, and Taylor 2025, Journal of Applied
  Econometrics 40(7): 741-758, `dube2025local`): the reweighted LP-DiD, which recovers an
  equally weighted ATT, equals the CS-NYT estimator. The baseline variance-weighted LP-DiD
  equals the Cengiz et al. stacked regression instead. State which version you ran.
- dCDH weight diagnostics (TwoWayFEWeights) are not a staggered-adoption tool. Any within
  regression with a time-varying treatment and heterogeneous effects has an implicit weighting
  problem, so the diagnostic is available to a plain fixed-effects fit on an on/off treatment
  too, even with no cohorts and no adoption date. The template files it under divergence
  diagnostics because that is where it usually earns its run, not because staggering is required.
- Stacked regression (clean-controls stacks) appears in marketing practice and in the AMA
  Marketing News routing source (Li, Luo, and Pattabhiramaiah 2024; AMA (causal-design canon)).
  Wing, Freedman, and Hollingsworth (2024, NBER 32054, `wing2024stacked`) show that the basic
  stacked regression identifies no average causal effect, because its implicit weights mix
  sub-experiments in proportions set by their sample sizes and treatment shares. Their
  corrective sample weights restore an ATT (code at github.com/hollina/stacked-did-weights).
  Prefer Callaway-Sant'Anna or Sun-Abraham, or run the stack only with those weights applied
  and reported.

## Estimand and estimator under heavy tails (Winkler et al. 2026, companion Steps 1-4)

Source: `winkler2026tiktok`, pp. 26-27. Estimand first ("dictated by the research question, not
by the data"), concentration diagnostic second (Lorenz curve, Gini, top-decile share of Y),
estimator third.

| Estimator | Estimand | Implicit weighting | Use when |
|---|---|---|---|
| Levels OLS | ΔΔE[Y] | squared-residual objective; large outcomes drive the fit | additive PT in levels; treated and control similar in baseline scale (or matched) |
| Log OLS | ΔΔE[log Y] | equal weight per observation; many low-volume units can dominate | Y > 0, Var(log Y) stable across treatment x time, typical-unit interpretation wanted |
| Weighted log OLS | weighted ΔΔE[log Y] | explicit pre-period outcome shares; the head dominates | Y > 0; close to PPML when log-scale variance is stable; sensitivity check |
| PPML, log link (default) | ΔΔ log E[Y] | score equations weight by E[Y given X]; large units dominate | population-total % under heavy tails; robust to variance misspecification; handles Y = 0 natively |

Decision nodes. Proportional estimand: (1) many zeros in Y? yes, PPML (log(1+Y) and asinh
coefficients are unit-dependent, Chen-Roth); no, continue. (2) Does treatment shift Var(log Y)?
Regress squared log-OLS residuals on treat x post with the fixed effects (Ciani-Fisher 2019,
eq. 5 in the paper, θ̂ = -0.0016, SE 0.0002 in the TikTok data); significant, PPML for
population-total; not significant, log OLS for typical-unit, weighted log OLS or PPML for
population-total. Level estimand: PT in levels or logs is a substantive choice (do shocks add a
fixed amount or scale with baseline size? under heavy tails, scale); levels, levels OLS; logs,
PPML and translate the proportional effect to levels.

The cumulant argument (fn. 18): log E[exp Z] = E[Z] + Var(Z)/2 + higher cumulants for
Z = log Y, so ΔΔE[log Y] ≈ ΔΔ log E[Y] - ΔΔVar(log Y)/2 - ΔΔ(higher cumulants). A compression
of log variance among treated post makes the second term positive and pushes log OLS up. In
the calibrated simulation (N = 10,000, T = 20, true effect -0.0556 in the top virality decile
and exactly zero in deciles 1-9, σ_mult = 0.94) log OLS returns +0.0008 with p < 0.001 on the
zero-effect deciles, PPML -0.0001 (n.s.).

Levels bias under proportional growth: with Y_it = m_it U_it and log m_it = q_i + g(t-1) +
τ_it, relative bias of the levels TWFE coefficient grows in the treated-control baseline gap
and in g, with a sign-flip region (Figs. 10-11); log TWFE and PPML are flat at zero across the
grid. At zero gap the bias vanishes, which is why baseline matching rescues levels in the
matched sample, and why that rescue is a special case. Baseline-scaling test: unit-level DiD
contrast Δ_i regressed on the unit's pre-period mean; a nonzero slope (b̂ = -0.1172, SE 0.0010)
rejects constant-absolute incidence.

Reporting: all candidate specifications in one table with the estimand each targets; the
levels coefficient scaled by the pre-period mean (-4,661 streams on 142,545 = -3.27%); log
points with exp(δ̂) - 1 stated; the implicit weighting named; the concentration numbers (top
10% of songs = 76% of streams, 96% of TikTok creations); effects split by pre-treatment
intensity decile with model-free within-decile series; a mechanism-absent placebo group.

## Nonlinear DiD with repeated cross sections (Wooldridge 2026)

Source: `wooldridge2026nonlinear`, pp. 75-79; the panel version is `wooldridge2023simple`.

Model, eq. (6): E[Y | D, X] = G(α + Σ_g β_g D_g + Xκ + Σ_g (D_g · Ẋ_g) η_g + Σ_s γ_s f_s +
Σ_s (f_s · X) π_s + Σ_g Σ_{s>=g} δ_gs (W · D_g · f_s) + Σ_g Σ_{s>=g} (W · D_g · f_s · Ẋ_g) ξ_gs),
with D_g cohort dummies, f_s period dummies, W the post-adoption indicator, and Ẋ_g short for
Ẋ_tg = X_t - E(X_t | D_g = 1), the covariates centered about cohort-period means (p. 76). Line one is selection (cohort main
effects and their covariate interactions), line two secular and heterogeneous trends, line
three the treatment effects with moderators. A never-treated cohort is assumed; no exit.

Assumptions: conditional no anticipation (eq. 3) and conditional PT on the index (eq. 4),
G^{-1}(E[Y_t(∞) | D, X_t]) linear in the terms above. Index PT holds in levels only if
β_g = η_g = 0 for all g (no selection) or covariates and γ_t, π_t are time-constant.

Procedure 1: (i) pooled QMLE of (6) on all observations with the canonical LEF pair
(normal-identity, Bernoulli-logit, Poisson-exponential); (ii) τ̂_gt as the average partial
effect of the binary W over the (g,t) cells. δ̂_gs are ATTs on the log odds (logit) or
proportionate ATTs (exponential), equal to τ̂_gs only in the linear case. Under canonical
links pooled QMLE equals imputation, without the two-step SE problem.

Leads-and-lags (eq. 7): add D_g · f_s and D_g · f_s · Ẋ_g for s = 1, ..., g-2, with g-1 the
reference; the coefficients on D_g · f_s are average pre-trends by cohort and period. LO and
L&L cannot be ranked on efficiency or on bias under CPT violation; report both.

Aggregation: weights vary by g and t through the cell sizes N_gt; averaging the APEs over the
observed rows in the chosen subsample does this automatically (exposure-time aggregation
averages over rows with s - g = 0, 1, 2, ...). Aggregated pre-trends: multiply the eq. (7)
terms by NW = 1 - W and take the APE with respect to NW. The event-study plot for diagnosing
PT aggregates the δ̂_gs on the index scale.

Inference: QMLE-robust (sandwich) SEs under independent sampling; cluster at the sampling
cluster under cluster sampling, and at the assignment level (census tract, PUMA) whenever
assignment is clustered (AAIW), with sampling weights under stratification. Cell sizes N_gt
have to be large enough for the SEs to mean anything even without clustering; with small
treated cohorts collapse D_g · f_s to exposure-time dummies (s - g), or to the single W, and
compare with the flexible aggregate.

Cohort-specific trends: with two or more pre-periods per cohort add D_g · t (and
D_g · t · Ẋ_g); their coefficients test pre-trends without contamination bias when covariates
enter flexibly, at a precision cost from collinearity with the treatment dummies; pretesting
to decide whether to keep them is as problematic as in L&L.

Software: only Stata's APE facilities are named. The etwfe and jwdid rows in the package index
implement the panel form (Wooldridge 2023), which coincides with the 2026 estimator once unit
FEs are dropped. etwfe centers controls by cohort, the 2023 form; that changes only the raw
δ̂ coefficients, since centering does not affect the ATTs (p. 76).

## The TWFE question in full

Moved from SKILL.md (section "The TWFE question, stated honestly").

The Mixtape calls within, fixed effects, and two-way fixed
effects *"the same thing"* (Cunningham, The Mixtape, online ch. 8 sec. 8.1). Section 9.2 adds
that DiD and TWFE were long *"thought to be the same thing"*. That is true as algebra and false
as design.

For the first case the canon disagrees, and the skill's position is a default with named dissent:

- Baker et al. (2026): TWFE under staggered adoption has "well-understood, potentially serious,
  and easily remedied problems, and we do not recommend using it."
- Arkhangelsky and Imbens (2024): "we recommend against the current routine use of the standard
  TWFE estimator or related estimators," though under block assignment TWFE still estimates the
  ATT, and they think negative-weight concerns "have perhaps been exaggerated."
- Abadie, Angrist, Frandsen, and Pischke (2025): the pathologies "are unlikely to derail DD or
  event-study designs in practice"; in the divorce data BJS and TWFE match. Their prescription
  is TWFE event studies with BJS as a check.

The only way to know TWFE would
have been fine is to run the robust estimator anyway, at which point you report it (Baker et
al.). Run the building-block heterogeneity scan (2x2 DiDs by cohort, gap, and time since
adoption, Arkhangelsky-Imbens) rather than trusting any single robust estimator blindly.

The weights do something the negative-weight framing hides. Goodman-Bacon weights combine a
sample share and the treatment-timing variance Dbar(1 - Dbar), which peaks at 0.25 for a cohort
treated at the panel midpoint, so TWFE upweights mid-panel cohorts and extending or truncating
the panel moves the estimate through the weights alone. With effects that differ across units
but not over time, TWFE identifies the variance-weighted ATT, which differs from the simple ATT
(Goodman-Bacon 2021). That also reconciles bacondecomp's
all-positive weights, which sit on 2x2 comparisons, with TwoWayFEWeights' negative ones, which
sit on unit-level treatment effects: both are right, and all-positive Bacon weights do not
license TWFE.

The Mixtape rejects stacking estimators on one event-study plot: *"These estimators all
have slightly different assumptions and should not be considered robustness checks for one
another"* (Cunningham, The Mixtape, online ch. 10 sec. 10.13). Two practices are in play.
Reporting TWFE beside one robust estimator is asymmetric, because TWFE is the estimator whose
bias the exercise bounds, so agreement or divergence is
information about heterogeneity. Stacking four heterogeneity-robust estimators is symmetric,
they impose different PT variants and use different comparison groups, and the objection lands
there: choose ex ante by design, and if you genuinely cannot, pre-commit to reporting all.

## Anticipation: the Mixtape simulation

Moved from SKILL.md (section "Assumptions and treatment dating").

In the
Mixtape's simulation (Cunningham, The Mixtape, online ch. 9 sec. 9.3, Table 9.11) a
contaminated baseline returns 0.017 against a true ATT of 10 under constant effects. It returns
15.017 against a true 20 under dynamic effects.

## Functional form and nonlinear outcomes in full

Moved from SKILL.md (section "Functional form and nonlinear outcomes").

Parallel trends generally cannot hold in both logs and levels. Roth and Sant'Anna (2023,
`roth2023functional`) show PT is insensitive to functional form only under restrictive
conditions. Roughly, treatment must be as good as randomly assigned, or the distribution of
Y(0) must be stable over time, or a mix of the two must hold. Choose the transformation on
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
continuous, under a correct conditional mean (Gourieroux, Monfort, and Trognon 1984,
`gourieroux1984pseudo`). Equidispersion matters only for efficiency (Santos Silva-Tenreyro
2006), so pair it with cluster-robust SEs. It handles zeros
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

## Repeated cross-sections in full

Moved from SKILL.md (section "Beyond the absorbing binary treatment").

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

## etwfe behavior

Moved from SKILL.md (section "R implementation").

etwfe takes as never-treated any cohort value above max(period), else below min(period), so
the did-style 0 works when periods start at 1. With `cgroup = "never"` an in-range value
errors. Leads exist only under `cgroup = "never"` (`"notyet"` sets them to zero mechanically,
and `post_only` is read only for `"notyet"` fits). etwfe demeans controls by cohort, the
Wooldridge 2023 panel form; the 2026 cohort-period centering changes only the raw index
coefficients, never the ATTs. Above 500,000 rows emfx compresses to cohort-period cells
(`compress = "auto"`), exact for `y ~ 0` and an approximation once controls enter, so set
`compress = FALSE` then.

## The evidence battery

Moved from SKILL.md (section "The evidence battery").

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

Falsifications and event studies answer different questions. The Mixtape (Cunningham, The
Mixtape, online ch. 9 sec. 9.6) calls both suggestive evidence and ranks neither higher.
Section 9.8 adds only that falsifications *"might be more valuable"* when selection on
baseline Y(0) breaks the pre-trends.
The event study plus HonestDiD bounds how
large a PT violation the conclusion survives; a falsification tests whether one named rival
explanation makes a prediction that fails. Run both.

## Pre-trends and honest sensitivity in full

Moved from SKILL.md (section "Pre-trends and honest sensitivity").

Pre-trend tests are underpowered. Roth (2022, `roth2022pretest`) calibrates simulations to
papers in three top journals. There, linear violations that the pretest detects only 50% of the
time can produce bias larger than the estimated effect in the extreme case. The nominal 95%
confidence interval then covers the true effect only 24% of the time. The figure of a spurious
significant effect about half the time is different: it comes from his stylized one-lead,
one-lag, equal-variance example (p. 318), not from the calibration. Quote from Roth et al.
(2023): "the lack of a significant pre-trend does not necessarily imply the validity of the
parallel trends assumption." Also the converse (Kahn-Lang and Lang's bar mitzvah example):
parallel pre-trends do not imply parallel post-trends.

Ghanem, Sant'Anna, and Wüthrich (2026, `ghanem2026when`) derive necessary and sufficient
conditions for pre-trends and post-treatment trends to be parallel, with and without covariates.
Even with no structural break, a pretest can be uninformative about parallel trends unless
selection into treatment meets specific restrictions. Reading a pretest therefore needs an
argument about how units selected into treatment (next section), and the pretest cannot replace
the economic argument for PT. They flag further problems when the specification controls for
pre-treatment values of time-varying covariates.

The canon splits on pretesting itself. Roth (2022) shows conditioning on passing adds selection
bias; AAFP's cost-benefit analysis concludes "the bias-mitigation benefits of pretesting are
likely to outweigh the risks" and prescribes a sup-t joint test of the leads. The Mixtape is a
third position, nearer Roth than AAFP in this skill's reading: *"event studies were always only
falsifications. They weren't true tests"* (Cunningham, The Mixtape, online ch. 10 sec. 10.13).
Parallel trends is untestable, and honest DiD *"is not a test of whether parallel trends is
violated"* either (sec. 10.14). Default here: run the sup-t pretest and report it, but never
let a pass substitute for the sensitivity analysis, and report the test's power against
economically relevant violations
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

Scope of the mandate, this skill's judgment. It covers event studies on a universal baseline:
Callaway-Sant'Anna (the template's adapter), TWFE in a common-timing design, and Sun-Abraham.
Imputation pre-period coefficients are not comparable to CS ones (Roth 2026). For a BJS or
Gardner headline, run HonestDiD on the CS event study of the same data and say so. The
nonlinear etwfe event study on the index scale has no HonestDiD adapter. Report its leads in
both the lags-only and the leads-and-lags versions, and pair them with HonestDiD on the linear
CS fit, naming the scale of each.

The template runs HonestDiD on the event study aggregated across cohorts. Liu (2025, arXiv
2509.01829, `liu2025cohort`) shows this can mislead when pre-trends differ across cohorts,
because the mix of cohorts changes across event times. His cohort-anchored version imposes the
restrictions on each cohort's bias relative to its fixed initial control group. Run it as a check
when there are many cohorts, each precisely estimated, with visibly different pre-trends.

## Why these units were treated in full

Moved from SKILL.md (section "Why these units were treated").

Answer that before reading the pre-trend picture. The assignment mechanism is learned outside
the dataset, from institutional detail, and it decides how the picture should be read (Ghanem,
Sant'Anna, and Wüthrich, `ghanem2022selection`; Marx, Tamer, and Tang 2024, `marx2024parallel`).
Five mechanisms are
compatible with parallel trends: a common constant trend in Y(0), under which PT cannot be
violated however units were selected; selection on baseline Y(0), but only under the martingale
condition of Ghanem, Sant'Anna, and Wüthrich (Corollary 3.3, below); selection on fixed effects;
selection on observables, which is conditional PT and sends you to Covariates in SKILL.md; and
selection under imperfect foresight. One breaks PT: selection on realized gains, where units
take the treatment because they correctly infer it will help them. The table in section
"Selection mechanisms and parallel trends" separates what each does to pre-trends from what it
does to PT.

Selection on baseline Y(0) is the case that misleads, and whether it breaks PT depends on how
untreated outcomes evolve. Ghanem, Sant'Anna, and Wüthrich (arXiv 2203.09001, Corollary 3.3)
show that PT survives selection on baseline Y(0) only under a martingale condition. Their 2026
note (AEA Papers and Proceedings 116: 64-69) covers when pre-trends should be parallel. Under
the martingale condition, the expected next-period Y(0), given the unit effect and the baseline
shock, equals the baseline Y(0). That is a unit-root restriction on the idiosyncratic shocks.
When it holds, enrolling everyone below a threshold on baseline Y leaves PT intact and still
breaks pre-trends mechanically, because the baseline is both the selection point and the omitted
category. That manufactures a dip for the treated group at t = -1. In this case there is nothing
to fix, and re-basing to t = -2 to make the picture look right breaks PT, which held from the
original baseline. When Y(0) mean-reverts, the same selection rule is the Ashenfelter dip. PT
then fails after treatment as well as before, and the dip is a real violation (see the
Daw-Hatfield discussion in SKILL.md, section "Covariates"). Argue the random-walk case from
the outcome's time-series behavior before dismissing a dip as mechanical.

That collides with the HonestDiD mandate, and the resolution here is the skill's own judgment.
Relative magnitudes bounds post-treatment violations by M-bar times the largest pre-treatment
violation, so under a documented selection-on-baseline-outcome mechanism that satisfies the
martingale condition above the anchor is inflated
by an artifact of the assignment rule and the skill would otherwise drive you to call a valid
design fragile. Prefer the smoothness restriction there, or compute the anchor from the
pre-treatment periods excluding the selection period, and say which you did. The reverse case is
worse: under selection on realized gains, clean pre-trends are no comfort at all.

## Triple differences in full

Moved from SKILL.md (section "Triple differences").

A design, not a falsification. DDD identifies the ATT when the non-parallel-trends bias of the
main DiD equals that of the placebo-group DiD (Olden and Møen 2022). Two consequences change
practice: the placebo DiD does not have to be zero, so a nonzero one is no reason to discard the
design; and if it is zero the main DiD was unbiased all along, DDD was never needed, and
presenting the placebo DiD as a same-outcome-alternative-group falsification is the stronger
paper (Miller, Johnson, and Wherry 2021 is the Mixtape's instance; Cunningham, The Mixtape,
online ch. 10 sec. 10.2).

With common timing and no covariates, estimate it as the saturated OLS three-way interaction or
its event-study form with group-by-year, unit-by-year, and group-by-unit fixed effects and the
triple interaction with year dummies (both in section "Triple differences: assumption and
specifications"), clustered at the level
treatment was applied. Once covariates or staggered adoption enter, DDD is not simply the
difference of two DiDs and the saturated OLS is invalid (Ortiz-Villavicencio and Sant'Anna 2025,
arXiv 2505.09942, `ortizvillavicencio2025better`; relayed by Baker et al. 2026). Pooling
not-yet-treated units in a staggered DDD adds bias too. Use the doubly robust
`triplediff::ddd()` and `agg_ddd()` there (template section 8c).

## Beyond the absorbing binary treatment in full

Moved from SKILL.md (section "Beyond the absorbing binary treatment").

- Treatments that turn on and off (promotions, price changes): dCDH estimators require
  no-carryover; for advertising and pricing that assumption is usually wrong, so check it and
  prefer the intertemporal extension (`DIDmultiplegtDYN` in R, `did_multiplegt_dyn` in Stata).
- Continuous treatment intensity: ATT(d|d) is identified under standard PT, but causal-response
  parameters need strong PT across doses (Callaway, Goodman-Bacon, Sant'Anna).
- Exposure designs (baseline exposure share times a national change): the linear-interaction
  coefficient is an average marginal effect, roughly kappa + 2 phi E[M], not E[tau_s]; add the
  squared-exposure interaction when heterogeneity is plausible and report both (AAFP 2025).
