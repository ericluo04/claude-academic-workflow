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
-0.92 at population F 29.4, rho 0.8). Consequences: one-sided t size is severely distorted at
any realistic strength (100 percent of null rejections land on the OLS-bias side at F = 10);
power against effects opposite the OLS bias is near zero (0.2 percent for a true beta of -0.3
at F = 2.3); with publication bias, the t-test manufactures a spurious literature-wide
consensus in the OLS direction. AR largely removes the asymmetry and is UMPU just-identified
(Moreira 2009), keeping optimality under heteroskedasticity and autocorrelation
(Moreira-Moreira 2019).

## Prior-on-rho calibration (how strong must the instrument be?)

For any hypothesized beta_p, the implied rho is the correlation between the residuals of
(y - x beta_p on z) and the first stage; beta_p = 0 gives the reduced-form residual correlation
as the upper bound under suspected positive selection. With a uniform prior on rho over the
plausible range, 2SLS beats OLS in distance to truth only 26 percent of the time at population
F 2.3, 47 percent at 10, 65 percent at 29.44. Severe suspected endogeneity relaxes the F-50
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
| Many instruments | LIML (Bekker-consistent), JIVE, HFUL, bias-corrected TSLS | CLR; Hansen J alongside CUE |
| Many weak + severe endogeneity | Fuller, Andrews-Armstrong unbiased | same |

Never attach CLR p-values to a 2SLS estimate; never screen on t before AR. TSLS and LIML are
identical just-identified and diverge exactly when instruments are weak or many, so their gap
is itself a diagnostic. With few clusters the F and chi2 versions of AR can diverge; check
both (our own operational note, not from the canon).

## Compliance shares and Balke-Pearl checks (binary Y, X, Z)

Shares from two conditional means: pi_a = pr(X=1|Z=0), pi_n = pr(X=0|Z=1),
pi_c = 1 - pi_a - pi_n. The first-stage ITT on treatment equals the complier share, so the
first-stage table doubles as the compliance table. The assumptions imply four testable
inequalities of the form pr(Y=1, X=0 | Z=1) <= pr(Y=1, X=0 | Z=0). Worked flu-encouragement
numbers (Imbens 2014): left side 30/1389 = 0.0216 vs right side 31/72 = 0.0211, a slight
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

OLS of log quantity on log price in the Fulton whiting data: -0.54 (0.18), a variance-weighted
mix of supply and demand slopes with ambiguous sign. Stormy-weather supply-shifter IV: demand
elasticity -1.08 (0.46); TSLS with the trivalued instrument -1.014 (0.384), LIML -1.016
(0.384). OLS understates the demand elasticity by half. A supply shifter identifies demand and
a demand shifter identifies supply; without one side's shifter, that side stays unidentified.

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
   wrong candidate cannot introduce bias where none existed).
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

## Package index (verified against package docs 2026-07-28; the ivmte row on 2026-07-29)

| Package | Version | Role | Traps |
|---|---|---|---|
| fixest | 0.14.2 (CRAN) | 2SLS with FE and clustered SEs; first stage via summary(est, stage = 1); fitstat(~ ivf1 + ivwald1 + sargan + wh) | IV part must be the LAST formula element, after fixed effects; fitstat keywords lowercase (pinned also in did's details; update the two pins together on refresh) |
| ivreg | 0.6-8 (CRAN) | TSLS with diagnostics rows (weak instruments, Wu-Hausman, Sargan); successor to AER::ivreg | three-part form is y ~ exogenous \| endogenous \| instruments; in the two-part form, controls not repeated after the pipe silently become instruments; vcov. must be a function when diagnostics = TRUE |
| ivmodel | 1.9.1 (CRAN) | AR.test and CLR with inversion CIs (matrix of interval rows; unions and unbounded sets happen), KClass/LIML/Fuller, heteroSE and clusterID options | KClass has a capital K; single endogenous regressor; takes data vectors, not formulas |
| ivDiag | 1.0.6 (CRAN; yiqingxu.org/packages/ivDiag) | one-call audit: F.standard/robust/cluster/bootstrap/effective, AR with inverted CI, tF (Lee et al.), ltz local-to-zero | every variable passed as a name string; pulls the lfe dependency chain |
| ShiftShareSE | 1.1.0 (CRAN, Kolesar) | reg_ss / ivreg_ss with method = "akm" / "akm0" (AKM0 = null-imposed, better small-K coverage); sector_cvar clusters shocks | X is the aggregated shift-share vector, shares go in W, the instrument never appears in the formula; the akm0 "se" is a normalized CI length, never a t-stat input |
| ssaggregate | GitHub kylebutts/ssaggregate (0.0.0.9000, pushed 2025-11) | BHJ shock-level aggregation for the equivalent shift-level regression and the exposure-robust F | dev version, no CRAN release or visible tests; n/s/l/t are strings while vars/controls are formulas; template keeps a hand-coded fallback |
| bpbounds | 0.1.8 (CRAN) | Balke-Pearl inequality checks and ACE bounds (binary Y, X; Z with 2-3 categories) | xtabs order is positional treatment-outcome-instrument with margin = 3 on the instrument |
| ManyIV | GitHub kolesarm/ManyIV (0.0.2.9000) | many-instrument SEs (Kolesár 2018 minimum distance, JoE 204(1):86-100, distinct from Kolesár-Rothe 2018 on discrete running variables in the rdd skill), JIVE/UJIVE, Sargan + modified Cragg-Donald overid | rough dev API (man pages carry TODOs); for single-endogenous LIML/Fuller use ivmodel instead |
| AER | 1.2-17 (CRAN) | legacy ivreg (two-part formula only), kept for compatibility notes | superseded by the ivreg package |
| ivmte | 1.4.0 (CRAN, 2021-09-17; GitHub jkcshea/ivmte slightly ahead, last commit 2024-08-27) | MST bounds and extrapolation, single entry point ivmte(): target 'ate'/'att'/'atu'/'late'/'genlate' with genlate.lb/.ub the u-interval (the alpha dial) or custom target.weight0/1; MTR space via m0/m1 formulas with uSpline(degree, knots, intercept); ivlike list of regression formulas as the estimands; shape flags m0/m1/mte .lb/.ub/.inc/.dec enforced on the audit grid (initgrid.nx/.nu, audit.nx/.nu); bootstraps for inference; cite `shea2023ivmte` | needs one of gurobi/cplexapi/rmosek/lpsolveapi; the only fully free solver (lpSolveAPI) is roughly an order of magnitude slower and cannot run the regression-based direct criterion (QCQP, Gurobi or MOSEK only), so with it always supply ivlike moments; point = TRUE forces GMM and silently ignores every shape constraint; the unobservable in m0/m1 must match uname (default u); m0/m1 bounds default to the observed outcome range, which is the bounded-outcome assumption |

R has no reliable CUE implementation; for the overidentified heteroskedastic case the canon's
CUE + CLR recipe runs in Stata (ivreg2 with cue, then weakiv), with LIML(heteroSE = TRUE) as
the R fallback. Rotemberg weights: reference implementation at github.com/paulgp/bartik-weight
(Stata and R code, not a CRAN package); the template hand-codes the just-identified GPSS
decomposition and labels it as our implementation.

Stata mirror (the Keane-Neal workflow is Stata-first): ivregress 2sls/liml, ivreg2 (cue, J),
weakiv (AR/CLR inversion, Finlay-Magnusson-Schaffer), weakivtest (effective F), ssaggregate,
bartik_weight, manyiv.
