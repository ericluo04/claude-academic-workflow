# IV analysis template. Runnable end to end; every call signature verified against package
# documentation on 2026-07-28 (fixest 0.14.2, ivreg 0.6-8, ivmodel 1.9.1, ivDiag 1.0.6,
# ShiftShareSE 1.1.0, bpbounds 0.1.8, all CRAN; ssaggregate and ManyIV from GitHub; ivmte
# 1.4.0, CRAN, verified 2026-07-29). Adapt the CONFIG block and run section by section.
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

## ---- CONFIG ----------------------------------------------------------------
df <- your_data              # replace
# y  = outcome; d = endogenous treatment; z = instrument(s); x1, x2 = exogenous controls;
# cl = cluster id at the level of INSTRUMENT assignment (Imbens 2014's flu example:
# physicians were randomized, so cluster on physician, not patient).
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
# Many instruments: JIVE/UJIVE and many-instrument-valid SEs (Kolesár 2018 minimum
# distance, JoE 204(1):86-100; a different paper from Kolesár-Rothe 2018 on discrete
# running variables, which belongs to rdd) live in
# remotes::install_github("kolesarm/ManyIV"): IVreg(y ~ d + x1 | z1 + z2, data = df,
# inference = "standard"), then IVoverid() -- dev-version API, check before relying on it.

## ---- 6. Shift-share, shift path (BHJ 2025) -----------------------------------
# Objects: S = N x K share matrix (rows = units, cols = shocks/sectors), gk = length-K
# shock vector, z_ss = as.vector(S %*% gk) the unit-level instrument.
# 6a. Effective number of shifts, the pre-test design diagnostic:
sk <- colMeans(S); sk <- sk / sum(sk)      # importance weights (weight rows if design is)
1 / sum(sk^2)                              # report next to N; small = no asymptotics protect you
# 6b. Incomplete shares: if rowSums(S) is not 1 for everyone, CONTROL the sum of shares
# (interacted with period FE in stacked designs); do not renormalize.
df$sum_shares <- rowSums(S)
# 6c. Exposure-robust inference (AKM / AKM0), Kolesar's ShiftShareSE:
library(ShiftShareSE)
ivreg_ss(y ~ x1 + sum_shares | d, X = z_ss, data = df, W = S,
         method = c("ehw", "akm", "akm0"))
# reg_ss(y ~ x1 + sum_shares, X = z_ss, data = df, W = S, method = c("akm", "akm0"))
# gives the reduced form; sector_cvar= clusters shocks. AKM0 inverts the null-imposed
# test and has better coverage with few effective shifts.
# 6d. Equivalent shift-level regression (BHJ): reproduces the unit-level coefficient
# exactly and delivers the honest exposure-robust first-stage F. R port of ssaggregate:
# remotes::install_github("kylebutts/ssaggregate")  (dev version; hand-code if in doubt)
# library(ssaggregate)
# ind <- ssaggregate(data = df_long, shares = shares_long, vars = ~ y + d,
#                    n = "sector", s = "share", l = "unit", controls = ~ x1)
# ind <- merge(ind, shocks, by = "sector")
# sl  <- feols(y ~ 1 | d ~ g, data = ind, weights = ~s_n, vcov = ~shock_cluster)
# fitstat(sl, ~ ivf1)                      # the exposure-robust F to report
# 6e. Balance: g_k on shock-level confounder proxies (shift-level regression), and
# predetermined unit covariates on z_ss with the akm SEs above.

## ---- 7. Shift-share, share path (GPSS 2020) ----------------------------------
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

## ---- 8. Formula instruments: recenter or control (Borusyak-Hull 2023) --------
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
# 8a. RI balance test: regress z_re on predetermined covariates; joint p from the
# sum-of-squared-fitted-values statistic across draws:
Tstat <- function(zv) { f <- fitted(feols(zv ~ x1 + x2, data = df)); sum(f^2) }
T_obs  <- Tstat(df$z_re)
T_null <- apply(perm_z - mu, 2, Tstat)
mean(T_null >= T_obs)                     # RI joint balance p-value
# 8b. RI confidence interval by Hodges-Lehmann inversion (NEVER the distribution of
# the estimator across re-randomized shocks: that instrument has a true first stage
# of zero). T(b) = mean(z_re * (y - b * d)):
ri_p <- function(b) {
  t_obs <- mean(df$z_re * (df$y - b * df$d))
  t_cf  <- apply(perm_z - mu, 2, function(zv) mean(zv * (df$y - b * df$d)))
  mean(abs(t_cf) >= abs(t_obs))
}
grid <- seq(-2, 2, by = 0.01)             # widen until both endpoints are excluded
range(grid[sapply(grid, ri_p) > 0.05])    # the RI 95% interval
# 8c. Placebo outcomes (lagged y as outcome) with the same RI machinery test shock
# exogeneity itself; the balance test only validates the counterfactual specification.

## ---- 9. OPTIONAL: beyond-LATE extrapolation bounds (MST 2018, ivmte) ---------
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
# F.effective), ShiftShareSE 1.1.0 (X-vs-W roles), bpbounds >= 0.1.8; optional
# ivmte 1.4.0 plus an LP solver (section 9).
sessionInfo()
