# DiD lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-08-26.

## Package index (verified 2026-07-28; CRAN versions and release dates re-checked 2026-08-26)

| Package | Where | Version seen | Role |
|---|---|---|---|
| did | CRAN; bcallaway11.github.io/did | 2.5.1 (2026-07-08) | Callaway-Sant'Anna att_gt/aggte; aggte types simple, group, calendar, dynamic |
| HonestDiD | CRAN; github.com/asheshrambachan/HonestDiD | 0.2.8 (2026-04-12) | Rambachan-Roth, both restrictions; README ships the aggte adapter |
| didimputation | CRAN; github.com/kylebutts/didimputation | 0.5.1 (2026-03-09) | BJS imputation |
| did2s | CRAN | 1.2.1 (2026-03-05) | Gardner two-stage |
| DRDID | CRAN; psantanna.com/DRDID | 1.3.0 (2026-06-10) | Sant'Anna-Zhao 2x2 doubly robust building block that did calls; drdid/ipwdid/ordid for a two-period design estimated directly |
| panelView | CRAN; yiqingxu.org/packages/panelview | 1.3.1 (2026-05-14) | treatment rollout plot, unit by period (Mou, Liu, and Xu 2023); design-stage step 3 |
| fixest | CRAN; lrberge.github.io/fixest | 0.14.2 (2026-06-26) | sunab (Sun-Abraham), TWFE (pinned also in iv's details; update the two pins together on refresh) |
| pretrends | GitHub ONLY: github.com/jonathandroth/pretrends | master | pretest power, slope_for_power |
| staggered | CRAN; github.com/jonathandroth/staggered | 1.2.2 (2025-01-09) | efficient random-timing estimators |
| TwoWayFEWeights | CRAN; github.com/Credible-Answers/twowayfeweights | 2.1.0 (2026-05-27) | dCDH negative-weight diagnostics |
| bacondecomp | CRAN; github.com/evanjflack/bacondecomp | 0.1.1 (2020-01-24) | Goodman-Bacon decomposition; last released 2020 and still the only R implementation |
| etwfe | CRAN; grantmcdermott.com/etwfe | 0.6.2 (2026-03-23) | Wooldridge extended TWFE, linear and nonlinear (family = "poisson", "logit", "negbin" through fixest::feglm); a nonlinear family forces ivar = NULL and enters cohort and period as explicit dummies (emfx cannot compute SEs with absorbed FEs in nonlinear models); controls on the RHS of fml are demeaned by cohort and the xvar moderator by cohort-by-period cell (source, not docs); nothing unit-level is used, so repeated cross sections run unchanged (run on simulated repeated-cross-section data 2026-08-26, pilot only); emfx returns APEs (predict = "response") or index-scale effects (predict = "link") and compresses to cohort-period cells above 500,000 rows unless compress = FALSE; verified 2026-08-26 |
| jwdid (Stata) | SSC; github.com/friosavila/stpackages | 2.0 (2024-05-04) | Wooldridge ETWFE; no ivar means repeated cross-section; method(poisson), method(logit), method(ppmlhdfe); covariates demeaned and interacted by default (xasis to disable); verified 2026-08-26 |
| ppmlhdfe (Stata) | SSC | | PPML with high-dimensional FEs (Correia-Guimarães-Zylkin 2020); R equivalent fixest::fepois |
| DIDmultiplegtDYN | CRAN; github.com/Credible-Answers | 2.4.0 (2026-06-30) | dCDH intertemporal, on/off treatments; the R port of Stata's did_multiplegt_dyn and the name to use. The older DIDmultiplegt (2.1.0, 2026-02-17) is the static estimator and is not the one the skill's reversal rule calls |
| csdid / csdid2 (Stata) | SSC (Rios-Avila) | | Callaway-Sant'Anna in Stata. csdid defaults to short gaps and needs `long2`; csdid2 defaults to long differences and is faster. Both from the Mixtape ch. 10 code blocks, option names not API-verified here |
| summclust | ARCHIVED from CRAN 2025-11-02; install from s3alfisc.r-universe.dev | 0.7.0 (r-universe build 2026-08-03; last CRAN release 0.7.2, 2023-08-10) | CV3 cluster-jackknife vcov, leverage, partial leverage, leave-one-cluster-out betas |
| fwildclusterboot | ARCHIVED from CRAN 2024-05-29; install from s3alfisc.r-universe.dev | 0.14.3 (r-universe build 2026-08-01; ahead of the last CRAN release 0.13.0) | boottest wild cluster bootstrap: WCR/WCU, Rademacher/Webb weights, MNW "33" variants |
| clubSandwich | CRAN | 0.7.0 (2026-05-04) | CR2 vcovCR + Satterthwaite coef_test, the CRAN-resident cross-check |
| sandwich | CRAN | 3.1-3 (2026-08-03) | vcovBS(type = "jackknife"), a CRAN-resident CV3 route for linear models, no leverage diagnostics |

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

## Exemplar designs: what each one teaches

The recognition table is in SKILL.md; this is the longer read on each row.

- Miller, Johnson, and Wherry (2021), ACA Medicaid expansion and near-elderly mortality. The
  Mixtape's model of a complete DiD paper: bite shown three ways (eligibility, enrollment, and
  the share uninsured, the last of which shows some enrollment came from people with no coverage
  at all), event studies, a same-outcome-alternative-group falsification on the 65-and-over
  population, main results (0.13pp, 9.3% of the sample mean), and a mechanism. Never-treated
  comparison states.
- Braghieri, Levy, and Makarin (2022), the staggered rollout of TheFacebook across colleges and
  student mental health. The staggered exemplar: treatment dates built from the Wayback Machine
  (the platform announced each new school on its front page) and linked to an existing
  repeated-cross-section student survey, with the outcome z-scored so effects read in standard
  deviations. Also the Mixtape's instance of the multi-estimator plot it argues against.
- Baker, Callaway, Cunningham, Goodman-Bacon, and Sant'Anna (2026), Medicaid. The build order,
  forward-engineered from estimand to estimator, with the AEA replication package (materials
  25430, 25431) as a working R and Stata template.
- Winkler et al. (2026), UMG's TikTok withdrawal. Estimand first on a heavy-tailed outcome:
  53,753 matched song pairs, log OLS +0.0063 against PPML -0.0310 on the same panel.
- Hong (2013), Napster and music spending in the Consumer Expenditure Survey. Compositional
  change in a repeated cross-section: internet users got older, poorer, and less likely to hold
  a college degree between 1997 and 2000, and those covariates predict Y(0), so who is sampled
  breaks parallel trends without anyone being mistreated.
- Gruber (1994), state-mandated maternity benefits. The origin of triple differences, with the
  ineligible group (single men aged 20-40 and older workers) inside the same states.
- Card and Krueger (1994), NJ versus PA fast food. The exemplar of the DiD idea, the bite figure
  (mass at the new minimum), and primary data the authors collected twice themselves. Not an
  inference template: at the assignment level it is G = 2 with one treated cluster.

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

## Selection mechanisms and parallel trends (Ghanem-Sant'Anna-Wüthrich; Marx-Tamer-Tang)

Source: the Mixtape ch. 9 section on treatment assignment mechanisms, which reads
`ghanem2022selection` and Marx, Tamer, and Tang (2024). The two columns come apart, which is the
whole point of the table: a mechanism can leave PT intact and still wreck the pre-trend picture.

| Mechanism | Parallel trends | Pre-trends | What to do |
|---|---|---|---|
| Common constant trend in Y(0) | cannot be violated, for any assignment rule | clean | nothing; covariates are unnecessary here |
| Selection on baseline Y(0) (enrolled below a threshold on Y) | holds | broken mechanically, a dip at t = -1, because the baseline is both the selection point and the omitted category | no fix, because no problem. Do not re-base to t = -2: PT held from the original baseline. See the HonestDiD note below |
| Selection on fixed effects (only certain types enroll) | holds | clean | nothing |
| Selection on observables | holds conditional on X | clean given X | conditional PT: RA, IPW, or DR |
| Imperfect foresight about own gains | holds | clean | nothing |
| Selection on realized gains (Perfect Doctor, essential heterogeneity) | broken | E[Y(0)] diverges before and after, so pre-trends usually show it | DiD is biased by construction; clean pre-trends are no defense. Route out |

HonestDiD interaction, the skill's own judgment and stated in neither source: relative
magnitudes anchors on the largest pre-treatment violation, so a mechanical baseline dip from
selection on baseline Y(0) inflates the anchor and the robust interval with it. Prefer
smoothness there, or recompute the anchor from the pre-treatment periods excluding the selection
period, and say which. The mirror-image failure is that under selection on realized gains the
pretest-plus-HonestDiD chain passes a design that is biased by construction.

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
  Mixtape's CAPS data p = 0.999971 gives 34,481, so one control unit outweighs thousands. Eleven
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
untreated cells (Heckman 1979; Athey et al. 2021; BJS 2024) and the chained DiD of Bellego,
Benatia, and Dortet-Bernadet (2024), which chains short-run effects across adjacent-period
overlaps and so discards nothing. Report attrition rates by cohort either way, since
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
- lpdid (local projections DiD) is equivalent to the CS-NYT plug-in (Dube-Girardi-Jorda-Taylor).
- dCDH weight diagnostics (TwoWayFEWeights) are not a staggered-adoption tool. Any within
  regression with a time-varying treatment and heterogeneous effects has an implicit weighting
  problem, so the diagnostic is available to a plain fixed-effects fit on an on/off treatment
  too, even with no cohorts and no adoption date. The template files it under divergence
  diagnostics because that is where it usually earns its run, not because staggering is required.
- Stacked regression (clean-controls stacks) appears in marketing practice and in the AMA
  Marketing News routing source (Li, Luo, and Pattabhiramaiah 2024; 'AMA' hereafter); its
  implicit variance weights are a known problem (Baker et al.), so prefer Callaway-Sant'Anna
  or Sun-Abraham unless the stack weights are examined and reported.

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

