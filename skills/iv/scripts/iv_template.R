# IV analysis template. Runnable end to end; every call signature verified against package
# documentation on 2026-07-28 (fixest 0.14.2, ivreg 0.6-8, ivmodel 1.9.1, ivDiag 1.0.6,
# ShiftShareSE 1.1.0, bpbounds 0.1.8, all CRAN; ssaggregate from GitHub; ivmte
# 1.4.0, CRAN, verified 2026-07-29; ManyIV 0.0.2.9000 from GitHub, verified against the
# source and run on its own fhl data 2026-08-04). Adapt CONFIG and run section by section.
#
# API traps older tutorials get wrong:
#   - fixest: the IV part (endo ~ inst) must be the LAST formula element, after fixed effects
#   - ivmodel: the k-class function is KClass (capital K); data vectors, not formulas
#   - ivDiag: every variable is passed as a name string, never a formula
#   - ShiftShareSE: X = the aggregated shift-share vector, the share matrix goes in W, and the
#     instrument never appears in the formula; the "akm0" se is a normalized CI length, NOT a
#     standard error, so never build a t-stat from it
#   - ivreg two-part formula: controls must be repeated after the pipe or they silently become
#     excluded instruments; the three-part form (y ~ ex | en | in) avoids this
#   - ivmte: point = TRUE silently ignores every shape constraint; the only fully free solver
#     (lpSolveAPI) cannot run the regression-based direct criterion, so pass ivlike moments
#   - ManyIV::ujive: the endogenous variable must be the FIRST right-hand term, before the
#     controls; put it second and the package silently treats another variable as endogenous

## ---- CONFIG ----------------------------------------------------------------
df <- your_data              # replace
# y  = outcome; d = endogenous treatment; z = instrument(s); x1, x2 = exogenous controls;
# cl = cluster id at the level of INSTRUMENT assignment (Imbens 2014's flu example:
# physicians were randomized, so cluster on physician, not patient).
# Section 6 adds two: examiner = decision-maker id (factor), cell = the strata within
# which assignment is as good as random (factor, e.g. art unit by year).
set.seed(94305)

library(fixest); library(ivmodel); library(ivDiag)

## ---- 1. OLS next to IV, always ---------------------------------------------
# Report OLS alongside IV in every table; the OLS-vs-IV gap is data, and the
# OLS-proximity audit (section 3) needs it.
# vcov = ~cl is fixest's CR1; fine here because inference runs through AR/CLR, not
# the 2SLS t. With few clusters (judge/examiner designs) use CR2 or wild bootstrap
# for any coefficient you report directly.
ols <- feols(y ~ d + x1 + x2, data = df, vcov = ~cl)
est <- feols(y ~ x1 + x2 | d ~ z, data = df, vcov = ~cl)   # 2SLS; IV part last
summary(est, stage = 1)                    # first stage (stage = 1; default prints stage 2)
fitstat(est, ~ ivf1 + ivwald1 + wh)        # first-stage F, robust Wald, Wu-Hausman
# With fixed effects: feols(y ~ x1 | firm + year | d ~ z, ...) -- IV part still last.

## ---- 2. Weak-IV-robust inference (the headline inference) -------------------
# AR at every instrument strength; CIs only by inversion (Keane-Neal 2024).
m <- ivmodel(Y = df$y, D = df$d, Z = df[, c("z"), drop = FALSE],
             X = df[, c("x1", "x2")])
# Heteroskedastic / clustered variants: ivmodel(..., heteroSE = TRUE) or
# ivmodel(..., clusterID = df$cl). Single endogenous regressor only.
# With few clusters the F and chi2 versions of AR can diverge; check both (references/details.md).
AR.test(m)     # $ci is a matrix of interval rows: possibly a union, possibly unbounded.
CLR(m)         # coincides with AR when just-identified; the overidentified default test.
# An unbounded AR set is the design's verdict (identification not established at 95%),
# never something to suppress by quoting the bounded t-interval instead.
LIML(m); Fuller(m, b = 1)      # overidentified / many-weak point estimates
KClass(m, k = c(0, 1))         # OLS and TSLS in one call (capital K)

## ---- 3. One-call audit: F ladder, effective F, tF, AR ------------------------
g <- ivDiag(data = df, Y = "y", D = "d", Z = "z",
            controls = c("x1", "x2"), cl = "cl", nboots = 1000)
g$F_stat   # F.standard / F.robust / F.cluster / F.bootstrap / F.effective
g$AR       # AR test + inversion CI
g$tF       # Lee et al. (2022) tF on the effective F, for the referee who asks
# Read F.robust against the Keane-Neal ladder (references/details.md): 50 certifies ~29,
# 10 certifies only 2.3. Below 3.84, stop: do not run IV.
# OLS-proximity audit: if the 2SLS estimate is near OLS, F is in the 10-50 band, and only
# the t-test is significant, treat significance as suspect until AR confirms.
# Sensitivity to exclusion violations (local-to-zero, prior on the direct effect):
# ltz(data = df, Y = "y", D = "d", Z = "z", controls = c("x1", "x2"), prior = c(0, 0.05))
# prior = c(0, 0.05) is an illustrative placeholder: set the prior on the direct effect
# from your setting's plausible violation size.

## ---- 4. Compliance shares, Balke-Pearl checks, Manski bounds (binary d, z) ---
pi_a <- mean(df$d[df$z == 0])              # always-takers
pi_n <- mean(1 - df$d[df$z == 1])          # never-takers
pi_c <- 1 - pi_a - pi_n                    # compliers = the first-stage ITT
c(pi_a = pi_a, pi_n = pi_n, pi_c = pi_c)
# A thin complier slice means wide CIs and honest extrapolation language, not a bug.
# Balke-Pearl inequality checks + ACE bounds (needs binary y too):
library(bpbounds)
bp_tab <- xtabs(~ d + y01 + z, data = df)  # POSITIONAL: treatment, outcome, instrument
summary(bpbounds(prop.table(bp_tab, margin = 3)))   # margin = 3 conditions on z
# $inequality FALSE = at least one IV assumption is internally inconsistent; stop and
# rework the exclusion argument. bplb/bpub are the Manski-style ACE bounds to report
# NEXT TO the LATE whenever the ATE was the stated target.

## ---- 5. Overidentified designs ----------------------------------------------
library(ivreg)   # maintained successor to AER::ivreg; three-part formula
fit <- ivreg(y ~ x1 + x2 | d | z1 + z2, data = df)   # exogenous | endogenous | instruments
summary(fit, diagnostics = TRUE)   # Weak instruments, Wu-Hausman, Sargan rows
# TSLS-LIML divergence is a cheap weak/many-instrument alarm (they are identical
# just-identified): compare coef(fit) with LIML(m2)$point.est where m2 <- ivmodel(...,
# Z = df[, c("z1","z2")]). Under heteroskedasticity the canon wants CUE + CLR; R has no
# reliable CUE, so use LIML with heteroSE = TRUE and report the Stata route
# (ivreg2, cue + weakiv) when it matters. Interpret a Sargan/J rejection under the
# heterogeneity rule (SKILL.md): divergent instruments may move different compliers.
# Many instruments: many-instrument-valid SEs (Kolesár 2018 minimum distance, JoE
# 204(1):86-100; a different paper from Kolesár-Rothe 2018 on discrete running variables,
# which belongs to rdd) live in remotes::install_github("kolesarm/ManyIV"):
# IVreg(y ~ d + x1 | z1 + z2, data = df, inference = "standard"), then IVoverid() --
# dev-version API, check before relying on it. When the many instruments are
# decision-maker dummies, go to section 6 instead: the estimator changes to UJIVE.

## ---- 6. Leniency / examiner / judge designs (UJIVE) --------------------------
# Trigger: treatment is decided by a decision-maker (examiner, judge, doctor, reviewer,
# content moderator) assigned as good as randomly within a cell, and the K decision-maker
# dummies are the instruments. K is large and so is the control count L (the cell fixed
# effects). That combination is what breaks 2SLS.
# UJIVE is the estimator (Goldsmith-Pinkham, Hull, and Kolesár 2026). It instruments d
# with a leave-one-out estimate of covariate-residualized ("relative") leniency, in matrix
# form Gd with G = H - diag(H_ii/(M_ii - H_ii))(M - H), and tr(G) = 0 is the unbiasedness
# condition. 2SLS carries a bias that scales in K and points at OLS. JIVE1 carries a
# many-covariate bias that scales in L. UJIVE removes both. Trace algebra and the paper's
# empirical numbers are in references/details.md.
library(ManyIV)   # remotes::install_github("kolesarm/ManyIV"), the paper's own package
# API verified against the source at commit 0b82852 (2025-06-17) and run on the package's
# own fhl data on 2026-08-04:
#   ujive(formula, data, subset, na.action, tol = 1e-8, dropleverage = TRUE)
#   formula is y ~ d + controls | instruments, and d MUST come first on the right.
#   Returns class "IVResults". $estimate is a data frame with rows ols, tsls, ujive,
#   "old ujive", ijive1, jive1 and columns estimate, se_text, se_hte. se_hte is the
#   heteroskedasticity- and treatment-effect-heterogeneity-robust SE and is the one the
#   paper's tables report; it also absorbs the Bekker many-instrument term. se_text is the
#   textbook robust column and is too small in this design, so do not report it.
#   $IVData holds F (the homoskedastic first-stage F), k (instrument count AFTER collinear
#   drops), l (control count), n. $drop_obs holds the row indices dropped for leverage one
#   or singleton dummies. dropleverage = FALSE keeps them and returns NaN for UJIVE.
#   Factors go in raw: | examiner expands to the full dummy set, collinear columns dropped
#   with a message. There is no weights argument.
uj <- function(lhs, rhs = "d") stats::as.formula(   # one spec, reused by every step below
  paste0(lhs, " ~ ", rhs, " + cell | examiner"))

## 6a. Step 1: controls, estimator, and the SE decision, all before any regression.
# Controls are whatever institutional knowledge says makes assignment as good as random,
# and nothing more: in the patent setting, art unit by year, because the examiner pool
# within an art unit changes slowly. Both counts matter, K = examiners and L = controls.
# CLUSTERING RULE: cluster at the level at which ASSIGNMENT varies, not at the level at
# which residuals correlate. Under the random-instrument view (Abadie et al. 2020, 2023)
# what has to be uncorrelated is the product (relative leniency x error), so independent
# case-by-case assignment needs only robust SEs, and clustering "just in case" buys overly
# conservative inference. Cluster when a block is assigned together, e.g. one doctor covers
# a whole shift: then cluster on shift. This argument never justifies clustering on the
# examiner. Applied work sometimes does it anyway.
# CONSEQUENCE IF YOU DO CLUSTER: the ESTIMATOR changes as well as the SE, because
# leave-one-out leniency has to become leave-own-cluster-out. Otherwise within-
# cluster correlation between d_i and eps_j puts the mechanical bias back. ujive() has NO
# cluster argument (formals are formula, data, subset, na.action, tol, dropleverage), so
# ManyIV cannot do this. Hand-code the leave-own-cluster-out version (Frandsen, Leslie, and
# McIntyre 2025; Kolesár, Min, et al. 2026) and do not paste clustered SEs onto this fit.

## 6b. Step 2: balance, as the SAME UJIVE specification with the covariate as the outcome.
covs <- c("w1", "w2", "w3")               # predetermined covariates, one row each
bal <- t(sapply(covs, function(v)
  unlist(ujive(uj(v), data = df)$estimate["ujive", c("estimate", "se_hte")])))
cbind(bal, t = bal[, 1] / bal[, 2])
# The balance regression is the treatment specification with the covariate swapped in as
# the outcome, still instrumenting d with the examiner dummies. So an imbalance coefficient
# sits on the same scale as the treatment effect and reads directly as the bias it would
# cause. Do NOT run the reduced form of the covariate on the instrument in its place.
# Two more WRONG alternatives the paper rules out: (i) regressing observables on a
# constructed leniency measure, which manufactures a mechanical correlation, and which even
# in leave-out form suffers errors-in-variables bias from estimation noise in the measure;
# (ii) the joint F on the full examiner dummy set, whose default distribution is invalid
# with many examiners (Anatolyev and Sølvsten 2023).
# Read the magnitudes and do not stop at the stars. In the paper's reanalysis the balance
# coefficients run about 10x smaller than the treatment effects, and that gap is what makes
# the design credible.
# Sample trap: the dropped rows depend on the controls and instruments, so they are common
# across outcomes, but NAs in one covariate shrink that row's sample. Compare $drop_obs
# lengths across rows, or subset to complete cases once up front.

## 6c. Step 2b: exclusion check, same machinery on a POST-assignment variable.
ujive(uj("months_under_review"), data = df)$estimate["ujive", ]
# Their instance is months under review: an examiner moves outcomes through decision speed
# as well as through approval. A significant coefficient says the design does not recover
# the effect of the named treatment. The fix is a second treatment (or approval interacted
# with discretized review time), both instrumented by the same dummies in one UJIVE call.

## 6d. Step 3: estimate by UJIVE, and read the alternatives as diagnostics.
fit <- ujive(uj("y"), data = df)
fit                                       # prints all six rows plus F, n, K, L
fit$estimate["ujive", c("estimate", "se_hte")]         # the headline pair
# The tsls row (examiner dummies) lands between ols and ujive exactly when the
# many-instrument bias bites, and its SE is the tell: in the paper's reanalysis the
# many-dummy 2SLS SEs come out 3 to 4 times smaller than UJIVE's, which is the same
# overfitting that pulls the point estimate toward OLS. A large ujive-to-tsls SE ratio
# confirms the diagnosis and is never a cost of using UJIVE. jive1 next to ujive prices the
# many-covariate bias. ijive1 usually lands near ujive.
# Do NOT build a leniency measure by hand and plug it into a just-identified IV. The
# construction choices (leave-out or not, which cases enter) drive the bias, and the
# second-stage SEs ignore estimation error in the measure. For the same reason, do not read
# design strength off the variance of a constructed leniency measure: estimation noise in
# the measure inflates it. The UJIVE standard error is the power statistic.

## 6e. Strength: the first-stage F is the WRONG diagnostic here.
K <- fit$IVData$k                          # post-collinearity-drop instrument count
sqrt(K) * (fit$IVData$F - 1)               # the statistic to report, in place of F
# UJIVE stays approximately unbiased and consistent even when instruments are weak enough
# that E[F] converges to one, so long as sqrt(K) * (E[F] - 1) is large. That product is the
# signal-to-noise ratio of the estimator's denominator, which is what the delta-method
# normal approximation needs. An F of 1.2 with K = 750 examiners gives sqrt(750) * 0.2 =
# 5.5, so a first stage barely above one is no alarm in a design this wide.
# The paper states no cutoff for sqrt(K) * (E[F] - 1), so report the number and run 6f when
# it is small. Do not import the Keane-Neal ladder from section 3, which is about 2SLS.

## 6f. Weak-instrument fallback when sqrt(K) * (E[F] - 1) is small: Yap (2025).
# To test H0: beta = b0, compute eps_i0, the residual from projecting y - d * b0 on the
# covariates, then compute the UJIVE standard error exactly as usual but with eps_i0 in
# place of the UJIVE residual, and check whether UJIVE differs significantly from b0.
# Invert over a grid of b0 for the interval.
# NOT AVAILABLE in ManyIV: ujive() returns only the unrestricted se_hte and has no
# null-imposed option. Hand-code it from ManyIV:::ujive.fit, whose HTE numerator is
# sum((GY * MD + epD)^2): put eps_i0 where (YtW - DtW * beta) enters epD and where
# (Y - D * beta) enters GYujive, keeping the same denominator. $IVData$Y/$D/$Z/$W return
# the cleaned matrices to rebuild it on.
# Do NOT substitute the Mikusheva-Sun (2022) many-instrument AR or Matsushita-Otsu (2024):
# neither is robust to treatment-effect heterogeneity. Yap (2025) is.

## 6g. Step 4: average monotonicity (their test, built on Abadie 2002 and Kitagawa 2015).
# Keep the treatment, instruments, and controls, and replace the outcome with ytilde =
# v * d for any v determined BEFORE assignment. UJIVE then estimates a convex weighted
# average of v under exactly the weights of the main estimate. If v is BINARY that average
# must lie in [0, 1]. Landing outside [0, 1] rejects.
df$v <- as.numeric(df$y == 0)             # binary v: an indicator for one outcome value
ujive(uj("I(v * d)"), data = df)$estimate["ujive", c("estimate", "se_hte")]
# The condition at stake is average monotonicity (Frandsen, Lefgren, and Leslie 2023),
# which is weaker than Imbens-Angrist uniform monotonicity and is necessary and sufficient
# for the LATE weights to be nonnegative. Their Figure 1 sweeps v over indicators for every
# outcome value, so loop over the support and plot estimates with 95% intervals. This test
# catches gross violations only: pushing a weighted average outside [0, 1] takes
# on-average defiers who are both numerous and unlike the average complier.

## 6h. Step 5: characterize compliers for external validity, same trick with v not binary.
# v * d as the outcome gives TREATED compliers. Putting one minus the treatment in as the
# treatment gives UNTREATED compliers, which random assignment says should agree. Pool them
# efficiently (Angrist, Hull, and Walters 2023) with dt = 2 * d - 1, taking values in
# {-1, 1}: run UJIVE of v * dt on dt, keeping the controls and the examiner instruments.
df$dt <- 2 * df$d - 1
comp <- t(sapply(covs, function(v)
  unlist(ujive(uj(paste0("I(", v, " * dt)"), "dt"),
               data = df)$estimate["ujive", c("estimate", "se_hte")])))
cbind(comp, sample_mean = sapply(covs, function(v) mean(df[[v]], na.rm = TRUE)))
# The complier-vs-sample gap is the external-validity statement the LATE licenses. Small
# gaps let you say the LATE approximates the population effect. Complier means outside the
# logical range of v are a second reading of the monotonicity test.

## ---- 7. Shift-share, shift path (BHJ 2025) -----------------------------------
# Objects: S = N x K share matrix (rows = units, cols = shocks/sectors), gk = length-K
# shock vector, z_ss = as.vector(S %*% gk) the unit-level instrument.
# 7a. Effective number of shifts, the pre-test design diagnostic:
sk <- colMeans(S); sk <- sk / sum(sk)      # importance weights (weight rows if design is)
1 / sum(sk^2)                              # report next to N; small = no asymptotics protect you
# 7b. Incomplete shares: if rowSums(S) is not 1 for everyone, CONTROL the sum of shares
# (interacted with period FE in stacked designs); do not renormalize.
df$sum_shares <- rowSums(S)
# 7c. Exposure-robust inference (AKM / AKM0), Kolesar's ShiftShareSE:
library(ShiftShareSE)
ivreg_ss(y ~ x1 + sum_shares | d, X = z_ss, data = df, W = S,
         method = c("ehw", "akm", "akm0"))
# reg_ss(y ~ x1 + sum_shares, X = z_ss, data = df, W = S, method = c("akm", "akm0"))
# gives the reduced form; sector_cvar= clusters shocks. AKM0 inverts the null-imposed
# test and has better coverage with few effective shifts.
# 7d. Equivalent shift-level regression (BHJ): reproduces the unit-level coefficient
# exactly and delivers the honest exposure-robust first-stage F. R port of ssaggregate:
# remotes::install_github("kylebutts/ssaggregate")  (dev version; hand-code if in doubt)
# library(ssaggregate)
# ind <- ssaggregate(data = df_long, shares = shares_long, vars = ~ y + d,
#                    n = "sector", s = "share", l = "unit", controls = ~ x1)
# ind <- merge(ind, shocks, by = "sector")
# sl  <- feols(y ~ 1 | d ~ g, data = ind, weights = ~s_n, vcov = ~shock_cluster)
# fitstat(sl, ~ ivf1)                      # the exposure-robust F to report
# 7e. Balance: g_k on shock-level confounder proxies (shift-level regression), and
# predetermined unit covariates on z_ss with the akm SEs above.

## ---- 8. Shift-share, share path (GPSS 2020) ----------------------------------
# Rotemberg weights: which shares carry the design. Hand-coded from the GPSS
# just-identified decomposition (reference implementation: github.com/paulgp/bartik-weight,
# Stata and R); this block is OUR implementation, label it as such:
x_perp <- resid(feols(d ~ x1 + x2, data = df))       # endogenous var, residualized
z_perp <- resid(feols(z_var ~ x1 + x2, data = df))   # z_var = as.vector(S %*% gk)
alpha_k <- sapply(seq_len(ncol(S)), function(k) {
  gk[k] * sum(resid(feols(S[, k] ~ x1 + x2, data = df)) * x_perp)
}) / sum(z_perp * x_perp)
sort(alpha_k, decreasing = TRUE)[1:5]     # weights sum to 1, some may be negative
# Per-share audit for the top-weight shares: one-share-at-a-time IV estimates, and
# balance of each high-weight share against PRE-period outcome changes (did-style
# pre-trend scrutiny; Card's Philippines share is the canonical caught example).
# Many shares: TSLS is biased toward OLS; use JIVE (ManyIV), LIML/Fuller (ivmodel),
# or HFUL, and read dispersion across pooling schemes under the heterogeneity rule.

## ---- 9. Formula instruments: recenter or control (Borusyak-Hull 2023) --------
# Trigger: treatment/instrument = known formula f(shocks g; exposure w). Shock
# exogeneity is NOT enough; compute the expected instrument and recenter.
S_draws <- 1999
perm_z <- replicate(S_draws, {
  g_cf <- ave(gk, strata, FUN = sample)   # permute shocks WITHIN exchangeability strata
  compute_instrument(g_cf, w)             # your formula f(g; w), recomputed per draw
})                                        # N x S_draws matrix
mu   <- rowMeans(perm_z)                  # expected instrument: the sole confounder
df$z_re <- df$z_formula - mu
rec <- feols(y ~ x1 | d ~ z_re, data = df, vcov = ~cl)   # or control for mu instead:
# feols(y ~ x1 + mu | d ~ z_formula, ...); in natural experiments prefer controlling
# for SEVERAL candidate mu's from different guessed assignment processes (double robust).
# 9a. RI balance test: regress z_re on predetermined covariates; joint p from the
# sum-of-squared-fitted-values statistic across draws:
Tstat <- function(zv) { f <- fitted(feols(zv ~ x1 + x2, data = df)); sum(f^2) }
T_obs  <- Tstat(df$z_re)
T_null <- apply(perm_z - mu, 2, Tstat)
mean(T_null >= T_obs)                     # RI joint balance p-value
# 9b. RI confidence interval by Hodges-Lehmann inversion (NEVER the distribution of
# the estimator across re-randomized shocks: that instrument has a true first stage
# of zero). T(b) = mean(z_re * (y - b * d)):
ri_p <- function(b) {
  t_obs <- mean(df$z_re * (df$y - b * df$d))
  t_cf  <- apply(perm_z - mu, 2, function(zv) mean(zv * (df$y - b * df$d)))
  mean(abs(t_cf) >= abs(t_obs))
}
STEP <- 0.01
grid <- seq(-2, 2, by = STEP)             # widen until both endpoints are excluded
acc  <- grid[sapply(grid, ri_p) > 0.05]   # nulls not rejected at 5%
if (!length(acc)) stop("RI: no null survives at 5%. Report failed identification.")
if (acc[1] == grid[1] || acc[length(acc)] == grid[length(grid)])
  warning("RI: accepted set touches a grid endpoint. It is unbounded, widen the grid.")
runs <- split(acc, cumsum(c(1, diff(acc) > 1.5 * STEP)))   # contiguous pieces
lapply(runs, range)                       # the RI 95% set, a union printed as a union
# 9c. Placebo outcomes (lagged y as outcome) with the same RI machinery test shock
# exogeneity itself; the balance test only validates the counterfactual specification.

## ---- 10. OPTIONAL: beyond-LATE extrapolation bounds (MST 2018, ivmte) --------
# When the policy question is a rollout or an incentive change, the target is a PRTE, not the
# LATE: bound a generalized LATE extrapolated alpha beyond the complier interval, anchored by
# the IV-like estimands under stated MTR restrictions (Mogstad-Santos-Torgovitsky 2018,
# implemented by ivmte; see references/details.md for the package row).
# SOLVER TRAP: ivmte needs one of gurobi / cplexAPI / Rmosek / lpSolveAPI. The only fully
# free solver (lpSolveAPI) is roughly an order of magnitude slower and cannot run the
# regression-based direct criterion (a QCQP; Gurobi or MOSEK only), so this section always
# passes explicit ivlike moments, the route every solver can handle.
have_solver <- any(requireNamespace("gurobi",     quietly = TRUE),
                   requireNamespace("cplexAPI",   quietly = TRUE),
                   requireNamespace("Rmosek",     quietly = TRUE),
                   requireNamespace("lpSolveAPI", quietly = TRUE))
if (requireNamespace("ivmte", quietly = TRUE) && have_solver) {
  library(ivmte)
  p0 <- pi_a                      # p(0) = pr(d = 1 | z = 0), from the compliance table
  p1 <- 1 - pi_n                  # p(1) = pr(d = 1 | z = 1)
  alpha <- 0.10                   # stated extrapolation: participation up 10 points beyond
                                  # p(1); set it from the planned rollout or a choice model
  # Estimands: the saturated regression of y on d and z attains sharp bounds with discrete
  # d and z (MST Proposition 3); the plain z and d regressions add the IV and OLS slopes.
  # MTR space: spline knots sit at the propensity support points (degree 0 with these knots
  # is MST Proposition 4's exact nonparametric route); degree 2 is arbitrary smoothing, so
  # rerun at higher degrees as the sensitivity analysis for functional form. m0/m1 bounds
  # are set to the observed outcome range (also the default), which is the bounded-outcome
  # assumption; mte.dec = TRUE is monotone treatment selection (earlier takers gain more),
  # a behavioral claim to defend in the text. Shape constraints are enforced on the audit
  # grid (initgrid.nx/.nu, audit.nx/.nu); defaults are fine at this scale.
  # Do NOT set point = TRUE to force a number: it switches to GMM point estimation and
  # silently ignores every shape constraint.
  mst_bounds <- function(a) {
    ivmte(data = df,
          target = "genlate",
          genlate.lb = p0, genlate.ub = min(p1 + a, 1),
          m0 = ~ uSpline(degree = 2, knots = c(p0, p1)),
          m1 = ~ uSpline(degree = 2, knots = c(p0, p1)),
          m0.lb = min(df$y), m0.ub = max(df$y),
          m1.lb = min(df$y), m1.ub = max(df$y),
          ivlike = c(y ~ z, y ~ d, y ~ d * z),
          propensity = d ~ z,
          mte.dec = TRUE)
  }
  mst_bounds(alpha)               # the headline bounds at the stated alpha
  # Sensitivity: bounds as a function of alpha (MST Figure 8 is the template). They collapse
  # to the LATE as alpha -> 0 and widen as the policy reaches beyond the compliers; report
  # the widening as the stated price of the question. Grid spans plausible rollout sizes.
  for (a in c(0.05, 0.10, 0.15, 0.20)) {
    cat("alpha =", a, "\n")
    print(mst_bounds(a))
  }
}

## ---- Session ----------------------------------------------------------------
# Pin: fixest >= 0.14 (IV formula order), ivreg >= 0.6 (three-part formula),
# ivmodel 1.9.1 (KClass capitalization), ivDiag >= 1.0.6 (F_stat vector incl.
# F.effective), ShiftShareSE 1.1.0 (X-vs-W roles), bpbounds >= 0.1.8, ManyIV
# 0.0.2.9000 (GitHub only, se_hte column and no cluster argument, section 6);
# optional ivmte 1.4.0 plus an LP solver (section 10).
sessionInfo()
