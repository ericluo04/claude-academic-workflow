# IV lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-28.

## The F ladder (Keane-Neal Table 1)

What a sample robust first-stage F certifies about the population F at 95 percent confidence,
and the resulting worst-case two-tailed t size:

| Sample F | Certified population F | Max two-tailed size |
|---|---|---|
| 10 | 2.3 | 13.5% |
| 16.38 | 5.78 | 10% |
| 23.1 | 10 | 8.6% |
| 50 | 29.44 | 6.4% |
| 104.7 | 73.75 | 5% |

The sample F is a noisy noncentral draw around the population F and does not concentrate with
N; large N alone fixes nothing. With K instruments the F-50 target scales as roughly
50/K^(3/4). Below sample F = 3.84 the AR interval is unbounded, which is the design's verdict.

## The power asymmetry, mechanically

Two channels (Keane-Neal 2023): the second-stage residual variance is a quadratic in beta
minimized at OLS, so sigma-hat is smallest when the 2SLS estimate lands near OLS; and sample
covariance between the instrument and the structural error simultaneously inflates the apparent
first stage and pulls the estimate toward OLS. Together they make the 2SLS standard error
artificially small near OLS and large far from it (rank correlation of estimate and SE of
-0.92 at population F 73.75, rho 0.8). Consequences: one-sided t size is severely distorted at
any realistic strength (100 percent of null rejections land on the OLS-bias side at F = 10);
power against effects opposite the OLS bias is near zero (0.2 percent for a true beta of -0.3
at F = 2.3); with publication bias, the t-test manufactures a spurious literature-wide
consensus in the OLS direction. AR largely removes the asymmetry. Just-identified, it is UMPU
under homoskedastic normal errors (Moreira 2009). Moreira and Moreira (2019) are cited for
optimality under heteroskedasticity and autocorrelation, but that claim is unread here (neither
abstract was reachable), so treat it as unconfirmed.

## Prior-on-rho calibration (how strong must the instrument be?)

For any hypothesized beta_p, the implied rho is the correlation between the residuals of
(y - x beta_p on z) and the first stage; beta_p = 0 gives the reduced-form residual correlation
as the upper bound under suspected positive selection. With a uniform prior on rho in
[0, 0.45], 2SLS beats OLS in distance to truth only 26 percent of the time at population F 2.3,
47 percent at 10, 65 percent at 29.44 (Keane and Neal 2024, Table 5). The figures depend on
that prior. Severe suspected endogeneity relaxes the F-50
demand, but only when the severity is credible ex ante, from theory or the institutional
setting, never from the observed OLS-IV gap alone. When invoked, report the ladder position,
the rho argument, and AR/CLR intervals anyway; those remain valid at any instrument strength.
Mismeasured regressors can push rho negative, so include that side when measurement error is
live.

## Estimator and test menu

| Setting | Point estimate | Test and interval |
|---|---|---|
| Just-identified | 2SLS (= IV ratio = ILS) | AR (reduced-form robust t); interval by inversion |
| Overidentified, homoskedastic | LIML | CLR (Moreira 2003) |
| Overidentified, heteroskedastic/clustered | CUE (LIML + robust VCE as fallback) | Kleibergen 2005 GMM CLR |
| Many instruments | LIML (Bekker-consistent under homoskedasticity only; inconsistent with many instruments under heteroskedasticity), HFUL (Hausman et al. 2012, the heteroskedasticity-robust fix), JIVE, bias-corrected TSLS | jackknife AR (Mikusheva-Sun 2022) or jackknife LM (Matsushita-Otsu 2024); Yap 2025 under heterogeneous effects. CLR's critical values assume a fixed instrument count and do not hold here |
| Many weak + severe endogeneity | Fuller | same |
| Just-identified, first-stage sign known | Andrews-Armstrong 2017 unbiased estimator | AR |

Never attach CLR p-values to a 2SLS estimate; never screen on t before AR. TSLS and LIML are
identical just-identified and diverge exactly when instruments are weak or many, so their gap
is itself a diagnostic. With few clusters, use the wild bootstrap AR test of Wang and Zhang
(2024), which controls size even when identification is weak in every cluster; the cluster
count is held fixed and each cluster is large in their asymptotics.

## Compliance shares and Balke-Pearl checks (binary Y, X, Z)

Shares from two conditional means: pi_a = pr(X=1|Z=0), pi_n = pr(X=0|Z=1),
pi_c = 1 - pi_a - pi_n. The first-stage ITT on treatment equals the complier share, so the
first-stage table doubles as the compliance table. The assumptions imply four testable
inequalities of the form pr(Y=1, X=0 | Z=1) <= pr(Y=1, X=0 | Z=0). Worked flu-encouragement
numbers (Imbens 2014): left side 30/1389 = 0.0216 vs right side 31/1472 = 0.0211, a slight
statistically insignificant violation, showing the tests have bite. Violation means at least
one assumption is false; passing proves nothing (no consistent test exists). Manski natural
bounds from the same 2x2x2 table travel with the LATE when the ATE was the target: flu ATE
bounds [-0.24, 0.64] against a complier LATE of -0.125 (0.090), complier share 0.119.

## Beyond-LATE extrapolation (MST 2018)

Mogstad-Santos-Torgovitsky 2018 (`mogstad2018using`); software companion Shea-Torgovitsky
2023 (`shea2023ivmte`).

The decomposition: every target parameter (ATE, ATT, ATU, any LATE, the PRTE class) and every
IV-like estimand (IV slope, TSLS components, OLS slope, saturated cell means) is a weighted
average of the same two marginal treatment response functions m0(u, x) = E[Y0 | U = u, X = x]
and m1(u, x) = E[Y1 | U = u, X = x], with identified weights; their difference is the MTE. The
LATE averages the MTE over u in (p(0), p(1)]; a policy parameter averages it elsewhere. The
extrapolated LATE(p(0), p(1) + alpha) is a convex weight on the point-identified LATE plus a
term integrating the MTE over (p(1), p(1) + alpha], so everything said beyond the complier
interval is a claim about that second term, and every feasible MTR pair still reproduces the
LATE (internal validity is never traded away). PRTE parameterizations with closed-form
weights: additive (participation up alpha points), proportional (up alpha percent), an
additive shift in one instrument component; get alpha from the planned rollout or an auxiliary
choice model. Bounds come from minimizing and maximizing the target over MTR pairs consistent
with the estimands and the stated restrictions, a linear program; bounds collapse to the LATE
as alpha goes to zero.

The assumption ladder, on their worked example (trinary instrument, binary outcome, target
LATE(0.35, 0.9), truth 0.046):

| Constraints on the MTR pairs | Bounds |
|---|---|
| IV slope only | [-0.421, 0.5] |
| IV + OLS slopes | [-0.411, 0.5] |
| all saturated (d,z)-cell estimands (sharp nonparametric) | [-0.138, 0.407] |
| + decreasing MTRs + ninth-degree polynomial | [0, 0.067] |

Sharpness rule (their Proposition 3): with discrete D and Z, the indicators of every (d, z)
cell, the information in a saturated regression of Y on D and Z, make the feasible set exactly
the MTR pairs matching E[Y|D,Z], which exhausts the data. Leaving estimands out leaves bounds
valid but wider than needed. Report the nonparametric bounds next to the restricted bounds so
the reader sees what each assumption bought, and bounds as a function of alpha (their Figure 8
is the template) so the reader sees how fast extrapolation is priced; a conclusion that
appears only at high polynomial rigidity is an assumption, not a finding. The same LP doubles
as the specification test: an empty feasible set with unrestricted MTRs falsifies the joint IV
assumptions (Balke-Pearl in general form), and restricted to zero average selection bias or
zero selection on gains, emptiness rejects that behavioral hypothesis.

## The fish-market numbers (price endogeneity in two lines)

Imbens (2014) reports these numbers on Graddy's Fulton whiting data, the data Angrist, Graddy,
and Imbens (2000) use to say what the IV elasticity means. OLS of log quantity on log price:
-0.54 (0.18), a variance-weighted mix of supply and demand slopes with ambiguous sign.
Stormy-weather supply-shifter IV: demand elasticity -1.08 (0.46); TSLS with the trivalued
instrument -1.014 (0.384), LIML -1.016 (0.384). OLS understates the demand elasticity by
half. A supply shifter identifies demand and
a demand shifter identifies supply; without one side's shifter, that side stays unidentified.

What the number is. The IV elasticity belongs to the compliers whose purchases the instrument
moved, so a storm-instrumented elasticity describes buyers who responded to storm-driven price
increases (Angrist, Graddy, and Imbens 2000). It need not be the elasticity a firm faces when it
sets price itself. Cunningham (The Mixtape, online ch. 7 sec. 7.7) makes the point that a firm
lowering its price will not do so using storms. The same section runs the data with a binary
Stormy instrument and day-of-week dummies (Table 7.14) and reports 2SLS -1.119 (0.431) against
OLS -0.563 (0.152) at N = 111, so the two-line demonstration above is robust to the
specification. Hand a pricing team that number only with the complier population named,
and take a planned price change to the PRTE ladder instead.

## Leniency designs: the trace algebra and the worked numbers (GHK 2026)

Goldsmith-Pinkham, Hull, and Kolesár 2026 (`goldsmithpinkham2026leniency`); their own software is the
ManyIV row in the package index below.

Every estimator built on a relative leniency measure Gx, i.e. betahat_G = y'Gx / x'Gx with
Gx = ltilde + G nu, has approximate bias under homoskedastic errors

    E[betahat_G] - beta ~= tr(G) / (K(E[F] - 1) + tr(G)) * cov(eps_i, nu_i) / var(nu_i),

using the identity sum_i ltilde_i^2 / var(nu_i) = K(E[F] - 1) = n R^2 / (1 - R^2). The trace
carries the whole comparison, with H the projection on the residualized instruments, M the
covariate annihilator, L the number of controls, and K the number of decision-makers:

| Estimator | G | tr(G) | Approximate bias |
|---|---|---|---|
| OLS | M | n - L | (1 - R^2) cov/var |
| 2SLS | H | K | (1/E[F]) cov/var, i.e. 1/((1 - R^2) E[F]) of the OLS bias |
| JIVE1 | M(I - D_Q)^-1 (H_Q - D_Q) | -L | -L/(K(E[F] - 1) - L) cov/var, the 2SLS bias times -E[F]/(K(E[F] - 1)/L - 1) |
| IJIVE | M(I - diag(H))^-1 (H - diag(H))M | sum_i H_ii(1 - M_ii)/(1 - H_ii) | small in practice, so IJIVE tracks UJIVE |
| UJIVE | H - diag(H_ii/(M_ii - H_ii))(M - H) | 0 | 0 |

JIVE's residualized leniency subtracts the cell's overall grant rate, which itself depends on
i's own treatment, so own-observation bias returns with the opposite sign to 2SLS. The JIVE
bias is negligible when L is far below K, and UJIVE and JIVE coincide when there are no
controls beyond a constant. The formula also gives the one-step implementation: UJIVE needs only the
two projection diagonals, the fitted values Hx, and the residuals (M - H)x, all obtained from
regressing x on the residualized instruments and on (z, w) separately.

Delta-method standard errors survive weak instruments more often than the textbook worry
suggests. Angrist-Kolesár (2024) show that delta-method inference turns overly optimistic only
when the correlation between the numerator and the denominator of the estimator,

    rho = (Sigma_12 - Sigma_22 beta*) / sqrt(Sigma_22(Sigma_11 - 2 beta* Sigma_12 + beta*^2 Sigma_22)),

is high. As long as |rho| < 0.76, rejection rates for nominal 5 percent tests stay below 10
percent at any instrument strength. GHK extend this to UJIVE with many instruments and
controls, where rho no longer maps to the endogeneity parameter (Sigma picks up extra terms),
but Sigma is consistently estimable, so rho can be plugged in for any particular null.

Reanalysis of Farre-Mensa, Hegde, and Ljungqvist (2020) on patent examiners and startup
outcomes: 32,514 first-time applications, art unit by year fixed effects, approval rate 0.649.
Standard errors in parentheses. Column 2 uses their constructed approval-rate leniency
measure, column 3 the full examiner dummy set.

| Outcome | UJIVE | 2SLS, FMHL leniency | 2SLS, examiner dummies | OLS |
|---|---|---|---|---|
| any subsequent application | 0.173 (0.055) | 0.265 (0.023) | 0.232 (0.016) | 0.234 (0.006) |
| log(1 + subsequent applications) | 0.323 (0.100) | 0.456 (0.037) | 0.374 (0.027) | 0.357 (0.009) |
| any citation to subsequent patents | 0.183 (0.049) | 0.210 (0.020) | 0.173 (0.014) | 0.164 (0.005) |

The many-dummy 2SLS standard errors are 3 to 4 times smaller than UJIVE's (0.055/0.016 = 3.4,
0.100/0.027 = 3.7, 0.049/0.014 = 3.5), which the paper calls "statistical pathology rather than
efficiency gains": overfitting pulls the 2SLS estimate toward OLS and shrinks its standard
error at the same time, so the estimator mimics OLS in both. The examiner-dummy 2SLS estimates
sit between OLS and UJIVE, the predicted signature. The 2SLS estimates on the constructed
leniency measure run larger than UJIVE, which GHK read as many-covariate bias because that
construction resembles JIVE. Balance coefficients in their Table 2 run about 10 times smaller
than the treatment effects (venture capital funding: -0.024 with a standard error of 0.035),
which is the magnitude comparison that makes a balance table informative.

## Shift-share checklists (BHJ 2025, worked examples attached)

Shift path (worked on Autor-Dorn-Hanson 2013):
1. Name the confounder OLS suffers from; describe the idealized shift-level experiment.
2. Bridge observed to ideal shifts with shift-level controls entered as s-weighted aggregates
   and unit-level controls; ask whether the proxy-to-ideal gap is itself confounded (ADH's
   non-US import growth passes; classic Bartik national growth rates do not).
3. Control the sum of shares if incomplete, interacted with period FE in stacked designs; do
   not renormalize. This control alone shrinks ADH's total-employment effects.
4. Lag shares to the start of the natural experiment; with serially correlated shifts, use
   innovations or lag to the first shocked period. Lagging does not fix dynamic effects
   (Jaeger-Ruist-Stuhler); panels need the appendix treatment.
5. Report shift-level descriptives including the effective number of shifts 1/sum s_k^2
   (cluster-level if shifts correlate within clusters); treat the shifts as the sample.
6. Balance-test at both levels: g_k on shift-level confounder proxies; predetermined unit
   variables on z_i with exposure-robust SEs.
7. Estimate with exposure-robust inference (AKM/AKM0 or the ssaggregate shift-level equivalent
   regression, which reproduces the unit-level coefficient exactly and gives the honest F);
   check stability across control sets and weighting.

Share path (worked on Card 2009 immigration):
1. Argue shares are tailored to the treatment (they mediate only shocks to x), ideally with
   quasi-experimental share variation, not mere lagging.
2. Control sums of share groups so identification comes from composition, not level (control
   total migrant share; identify from origin mix).
3. Compute Rotemberg weights; name the carrying shares (Mexico about half the weight for
   high-school-equivalent workers).
4. Balance-test the instrument and the high-weight shares on pre-period outcomes (the
   Philippines share fails in all periods, the caught example).
5. Check sensitivity across pooling schemes (one share at a time, TSLS/GMM, visual-IV plot,
   Sargan-Hansen), switching to JIVE/LIML/HFUL/bias-corrected TSLS when K is large. Dispersion
   among high-F high-weight shares is the red flag; interpret under the heterogeneity rule.

Network-exposure designs (fraction of friends treated) are shift-share with shares =
normalized adjacency and shifts = treatment dummies; wrap the randomized rollout in the shift
path and control the sum of shares when some nodes were ineligible. When the treatment itself
is shift-share (OLS exposure designs), the same frameworks apply with x = z.

## Recentering mechanics (Borusyak-Hull 2023)

1. Partition determinants into shocks g (willing to call exogenous) and exposure w
   (predetermined, endogenous).
2. Specify the shock assignment process. RCT: the protocol. Natural experiment:
   exchangeability, i.e. permute realized shocks within strata of similar shocks (the HSR
   application permutes completion among built and unbuilt lines with the same number of
   cross-prefecture links).
3. Draw S counterfactual shock vectors (1,999 there; any fixed S identifies, variance cost at
   most (S+1)/S), recompute z_i under each, average to mu_i.
4. Instrument with z - mu, or control for mu. Experiment: recenter, then controls for
   precision. Natural experiment: control for several candidate mu_i (double robustness; a
   wrong candidate cannot introduce bias where none existed). Each extra candidate is one more
   control that absorbs instrument variation and widens the interval, so add only candidates
   from assignment processes you can defend (our judgment).
5. Same draws give the balance test (regress recentered z on predetermined covariates; RI joint
   p from the sum-of-squared-fitted-values statistic; HSR geography R2 drops 0.824 to 0.083,
   joint p 0.443) and RI intervals by Hodges-Lehmann inversion of
   T = (1/N) sum (z_i - mu_i)(y_i - b x_i) (interval inversion assumes a constant-effect
   model; under heterogeneous effects with unbalanced designs report the sharp-null test plus
   Neyman-style intervals instead, per field-experiment). Never use the distribution of the
   estimator across re-randomized shocks (the re-randomized instrument has a true first stage
   of zero).
6. Heterogeneous effects: recentered IV is a convex complier-type average with weights
   proportional to Var(z_i - mu_i | w); rescale by that variance for unweighted estimands.
7. Do not substitute simple observables (friend counts, latitude polynomials) for mu unless the
   protocol makes them exactly proportional; unit FE purge exposure bias only when mu is
   time-invariant (stationary shocks, stable exposure), which growing networks violate.
8. Endogenous treatment case: build the candidate instrument by zeroing the endogenous
   argument, x = h(g, w, u) instrumented by recentered h(g, w, 0).

Caveat the paper itself flags: passing the RI balance tests supports the counterfactual
specification, and does not directly certify shock exogeneity; the placebo-outcome test is the
check aimed at that assumption.

## The six designs, and what each canonical case teaches

The recognition table in SKILL.md indexes designs by what kills them. This is the longer form,
with the lesson each canonical case carries.

| Design | Canonical case | What it teaches |
|---|---|---|
| Randomized encouragement with noncompliance | Oregon Medicaid lottery (Finkelstein et al. 2012; Baicker et al. 2013) | lottery IV under voluntary take-up, with the ITT and the LATE reported side by side across financial, utilization, and health outcomes; winning the lottery raised Medicaid enrollment by about 26 points |
| Leniency routing | Philadelphia bail magistrates (Stevenson 2018) | the design end to end, where OLS finds nothing and IV carries the paper; in Cunningham's replication of the data (The Mixtape, online ch. 7 sec. 7.7, Table 7.12), 331,971 cases and eight judges, OLS -0.001 with time controls (0.029 with defendant controls) and IV 15 to 21 percent on guilty pleas. Stevenson's own headline is a 13 percent rise in conviction |
| Shift-share exposure | Bartik 1991; Autor-Dorn-Hanson 2013 | shares and shifts are two different identification claims, each with its own estimator, balance test, and disqualifier |
| Formula or network exposure | Borusyak-Hull 2023, China high-speed rail | a formula-built instrument inherits endogeneity from its nonrandom exposure weights: 0.23 collapses to 0.08 after recentering |
| Cost shifter for price | Wright 1928; Graddy's Fulton fish market (Graddy 2006) | simultaneity: observed price-quantity pairs are equilibria, a supply shifter identifies demand, and the elasticity recovered belongs to the instrument's compliers |
| Access or distance | the McClellan-Newhouse differential-distance trick | condition on generic distance and instrument with the specific version, because raw distance proxies everything |

## Marketing translations

- Price endogeneity: cost shifters and Hausman-style other-market prices routinely land F in
  the 10-30 band, where 2SLS beats OLS less than half the time absent severe endogeneity; a
  demand elasticity near OLS with a significant t is the suspect configuration. Model-implied
  optimal instruments and cost shocks aggregated through nonrandom input shares are formula
  instruments and need recentering.
- Advertising exposure: randomized encouragement (ghost ads, PSA holdouts) is the flu-letter
  design; reach-based vs exposure-based effects is ITT vs LATE. Media-coverage instruments
  (transmitter placement x terrain) are on the formula-instrument list.
- Platform and network spillovers: fraction-of-friends-treated regressions in influencer
  seeding and referral programs need the mu adjustment even with randomized seeding, because
  connected users are mechanically more exposed. Staggered platform rollouts with
  audience-overlap shares are shift-share.
- Retail demand: Jaravel-style category demand growth instrumented by national sociodemographic
  shifts weighted by the category's sales shares across groups is the scanner-data template.
  Generic category-mix or channel-mix shares are generic shares and cannot carry the share
  path; shares built from the treatment's specific diffusion channel can.
- Content moderation and review routing: examiner designs; interrogate monotonicity (strict
  reviewer's approvals must nest the lenient one's), and note the leniency instrument has a
  composite flavor that invites the recentering audit.
- Distance instruments (store, warehouse, delivery coverage): condition on generic distance,
  instrument with the specific version (the McClellan-Newhouse trick).

## Package index (verified against package docs 2026-07-28; the ivmte row on 2026-07-29;
the ManyIV row against the cloned source and a live run on its `fhl` data on 2026-08-04;
versions and publication dates re-checked against crandb and the GitHub HEADs on 2026-08-26
and again on 2026-10-08; on 2026-10-08 scripts/iv_template.R sections 1 through 10 ran on
simulated data under R 4.6.1 with every version below, plus lpSolveAPI 5.5.2.0-17.15. This
index is the one place the template's pins live)

| Package | Version | Role | Traps |
|---|---|---|---|
| ivreg | 0.6-8 (CRAN, 2026-07-10) | TSLS with diagnostics rows (weak instruments, Wu-Hausman, Sargan); successor to AER::ivreg | three-part form is y ~ exogenous \| endogenous \| instruments; in the two-part form, controls not repeated after the pipe silently become instruments; vcov. must be a function when diagnostics = TRUE |
| ivmodel | 1.9.1 (CRAN, 2023-04-09) | AR.test and CLR with inversion CIs (matrix of interval rows; unions and unbounded sets happen), KClass/LIML/Fuller, heteroSE and clusterID options | KClass has a capital K; single endogenous regressor; takes data vectors, not formulas |
| ivDiag | 1.0.6 (CRAN, 2023-09-17; yiqingxu.org/packages/ivDiag; maintenance unconfirmed: CRAN 1.0.6 is the last release and the GitHub repository xuyiqing/ivDiag returned 404 on 2026-10-08) | one-call audit: F.standard/robust/cluster/bootstrap/effective, AR with inverted CI, tF (Lee et al.), ltz local-to-zero. The components are also exported one at a time: `eff_F()` returns the Montiel Olea-Pflueger effective F alone, `AR_test()` the AR test with its inverted CI alone, and `plot_coef()` draws the estimator comparison (OLS, 2SLS, and the AR interval), which is what the Mixtape's code calls (online ch. 7 sec. 7.6). The template calls the omnibus `ivDiag()` and reads `$F_stat`, `$AR`, and `$tF` off one fit, so reach for the components only when you want a single number without the bootstrap | every variable passed as a name string; pulls the lfe dependency chain |
| ShiftShareSE | 1.1.0 (CRAN, 2022-04-24, Kolesar) | reg_ss / ivreg_ss with method = "akm" / "akm0" (AKM0 = null-imposed, better small-K coverage); sector_cvar clusters shocks | X is the aggregated shift-share vector, shares go in W, the instrument never appears in the formula; the akm0 "se" is a normalized CI length, never a t-stat input |
| ssBartik | 0.1.1 (CRAN, 2026-07-19, Iwasaki; github.com/takuma1102/ssBartik) | an end-to-end shift-share pipeline organized around the share path (Goldsmith-Pinkham, Sorkin, and Swift) and the shift path (BHJ, AKM), wrapping ShiftShareSE (a Suggests dependency) for exposure-robust inference when it is installed; a candidate replacement for the hand-coded Rotemberg block and the dev-only ssaggregate dependency | not run by us; check its AKM output against ShiftShareSE and its Rotemberg weights against the template before relying on it |
| ssaggregate | GitHub kylebutts/ssaggregate (0.0.0.9000, HEAD 22df939 dated 2025-11-02) | BHJ shock-level aggregation for the equivalent shift-level regression and the exposure-robust F | dev version, no CRAN release or visible tests; n/s/l/t are strings while vars/controls are formulas; template keeps a hand-coded fallback |
| bpbounds | 0.1.8 (CRAN, 2026-07-13) | Balke-Pearl inequality checks and ACE bounds (binary Y, X; Z with 2-3 categories) | xtabs order is positional treatment-outcome-instrument with margin = 3 on the instrument |
| ManyIV | GitHub kolesarm/ManyIV (0.0.2.9000, HEAD 0b82852 dated 2025-06-17; source read and run 2026-08-04) | the leniency-design workhorse and the package `goldsmithpinkham2026leniency` uses for its own checklist: `ujive(formula, data, subset, na.action, tol = 1e-8, dropleverage = TRUE)` with formula `y ~ d + controls \| instruments`, returning class `IVResults` whose `$estimate` is a data frame with rows ols / tsls / ujive / "old ujive" / ijive1 / jive1 and columns `estimate`, `se_text` (textbook robust), `se_hte` (heteroskedasticity- and treatment-effect-heterogeneity-robust, the column the paper's tables report, and it absorbs the Bekker many-instrument term), plus `$IVData$F` (homoskedastic first-stage F), `$IVData$k` (instruments after collinear drops), `$IVData$l` (controls), `$IVData$n`, `$drop_obs`. Also `IVreg(..., inference = )`, a vector drawn from "standard" (TSLS, LIML, and MBTSLS with homoskedastic, robust, and heterogeneity-robust SEs), "re", "il", and "lil" (LIML SEs from the random-effects likelihood Hessian, the invariant likelihood Hessian, and the limited-information likelihood information matrix), and "md" (Kolesár 2018 minimum-distance many-instrument SEs, JoE 204(1):86-100, distinct from Kolesár-Rothe 2018 on discrete running variables in the rdd skill; man page checked 2026-10-09) and `IVoverid()` for Sargan + modified Cragg-Donald | the endogenous variable must be the FIRST right-hand term (put it second and another regressor is silently treated as endogenous, verified by running both orders); NO cluster argument, so clustered assignment goes to clusterIV (row below) or a hand-coded leave-own-cluster-out UJIVE; `IVoverid()` takes the fitted `IVreg` object, not a formula; no null-imposed SE, so the Yap (2025) weak-IV test is hand-coded too; `dropleverage = TRUE` silently drops leverage-one and singleton-dummy rows, `FALSE` returns NaN for UJIVE with a warning; no weights argument; rough dev API (man pages still carry TODOs); for single-endogenous LIML/Fuller use ivmodel |
| clusterIV | 0.2.0 (CRAN, 2026-10-01, Katawazi) | `cjive()`, the cluster-jackknife IV of Frandsen, Leslie, and McIntyre 2025, and `cjar()`, a cluster-jackknife AR test (Ligtenberg 2025, arXiv 2306.08559), with controls and absorbed fixed effects; formula `y ~ d \| instruments \| fe`, `cluster = ~id`; run on simulated data 2026-10-08 | stops on instruments collinear with the fixed effects (examiners nested in cells), so pool one reference examiner per cell first; formula sections accept bare names only; not checked whether CJIVE carries UJIVE's many-control correction, so confirm in the source before reporting it as the headline |
| gmm | 1.9-1 (CRAN, 2025-08-26) | CUE via `gmm(y ~ d + x, ~ z + x, type = "cue")`; momentfit 1.0 (CRAN, 2025-08-26) is the successor framework; gmm call run on simulated data 2026-10-08 | not validated by us under clustering; pair with LIML(heteroSE = TRUE) |
| AER | 1.2-17 (CRAN, 2026-07-11) | legacy ivreg (two-part formula only), kept for compatibility notes | superseded by the ivreg package |
| lfe | 3.1.1 (CRAN, 2025-02-11) | `felm(y ~ x \| fe \| (d ~ z))`, the IV route in the Mixtape's bail code (online ch. 7 sec. 7.7) | superseded by fixest, which is faster, is maintained, and gives the first stage and fitstat keywords the template uses |
| SteinIV | 0.1-1 (CRAN, 2016-01-26) | `jive.est(y, X, Z)`, the JIVE the Mixtape runs on the Stevenson data (online ch. 7 sec. 7.7) | JIVE only, with no UJIVE and no heterogeneity-robust SE; superseded by ManyIV, which returns OLS, 2SLS, UJIVE, IJIVE, and JIVE from one call. Unchanged on CRAN since 2016 |
| ivmte | 1.4.0 (CRAN, 2021-09-17; GitHub jkcshea/ivmte slightly ahead, last commit 2024-08-27) | MST bounds and extrapolation, single entry point ivmte(): target 'ate'/'att'/'atu'/'late'/'genlate' with genlate.lb/.ub the u-interval (the alpha dial) or custom target.weight0/1; MTR space via m0/m1 formulas with uSpline(degree, knots, intercept); ivlike list of regression formulas as the estimands; shape flags m0/m1/mte .lb/.ub/.inc/.dec enforced on the audit grid (initgrid.nx/.nu, audit.nx/.nu); bootstraps for inference; cite `shea2023ivmte` | needs one of gurobi/rmosek/lpsolveapi (cplexAPI was archived from CRAN 2021-11-05); lpSolveAPI is the free CRAN solver, but ivmte warns that lp_solve is outdated and potentially unreliable, so confirm headline bounds with Gurobi or MOSEK (free academic licences), and it is roughly an order of magnitude slower and cannot run the regression-based direct criterion (QCQP, Gurobi or MOSEK only), so with it always supply ivlike moments; ivmte re-evaluates its call outside the caller's frame, so `min(df$y)` in an argument hits stats::df and a wrapper function's own arguments are not found (pass precomputed scalars through do.call, as the template does; reproduced 2026-10-08); point = TRUE forces GMM and silently ignores every shape constraint; the unobservable in m0/m1 must match uname (default u); m0/m1 bounds default to the observed outcome range, which is the bounded-outcome assumption |

Shared with other causal skills: fixest, for 2SLS with fixed effects and clustered SEs. Version and
family-wide traps are in ../../causal-design/references/packages.md. Traps specific to this skill:
the first stage comes from summary(est, stage = 1), and the fitstat keywords are lowercase
(fitstat(~ ivf1 + ivwald1 + sargan + wh)).

gmm::gmm(type = "cue") and momentfit implement CUE in R (rows above); we have not validated
either under clustering, so for the overidentified heteroskedastic case pair it with
LIML(heteroSE = TRUE) and report the Stata route for the canon's CUE + CLR recipe (ivreg2 with
cue, then weakiv) when it matters. Rotemberg weights: reference implementation at
github.com/paulgp/bartik-weight (Stata and R code, not a CRAN package); the template
hand-codes the just-identified GPSS
decomposition and labels it as our implementation.

Stata mirror (the Keane-Neal workflow is Stata-first): ivregress 2sls/liml, ivreg2 (cue, J),
weakiv (AR/CLR inversion, Finlay-Magnusson-Schaffer), weakivtest (Pflueger-Wang effective F),
twostepweakiv (Sun, AR intervals after 2sls, the pairing the Mixtape's code uses in online ch. 7
sec. 7.6), ssaggregate, bartik_weight, manyiv, and fejiv (Lei and Słoczyński, FEJIV in MATLAB,
R, and Stata, listed in the software table of Słoczyński, Sun, and Uysal 2026). These are names
and roles only: unlike the R rows above, no Stata API
here has been verified against its help file.
