# RDD analysis template. Runnable end to end; every call signature verified against the
# rdpackages suite on 2026-07-28 (rdrobust 4.0.0, rddensity 3.0, rdlocrand 2.0, rdpower 3.0,
# rdmulti 2.0.0, all CRAN). Suite home: rdpackages.github.io. Adapt the CONFIG block and run
# section by section. Do NOT trust rdrr.io for these packages (stale 2023 builds).
#
# rdrobust 4.0.0 API changes older tutorials get wrong:
#   - `all=` was REMOVED from rdrobust(); it now lives in summary(fit, all = TRUE)
#   - `data=` is new (bare column names allowed); covs= accepts a one-sided formula
#   - cluster= requires vce = "cr1"/"cr2"/"cr3" (other vce values auto-map with a warning)

## ---- CONFIG ----------------------------------------------------------------
df <- your_data              # replace
y  <- df$y                   # outcome
x  <- df$score               # running variable
d  <- df$takeup              # observed treatment (fuzzy designs only)
Z  <- as.matrix(df[, c("cov1", "cov2")])   # predetermined covariates
CUT <- 350                   # the cutoff
set.seed(94305)

library(rdrobust); library(rddensity); library(rdlocrand); library(rdpower)

## ---- 1. Anatomy first ------------------------------------------------------
# Global p=4 fit is for VISUALIZATION ONLY, never estimation.
rdplot(y, x, c = CUT)
# Fuzzy pre-check: take-up against the score. Jumps AWAY from the official cutoff
# are the first disqualifying red flag (soft rule).
rdplot(d, x, c = CUT)
# Discrete scores (roughly <= 30 distinct values): no binning, plot mass-point means,
# and lead with the local-randomization branch (section 5).
length(unique(x))

## ---- 2. Sharp estimation (continuity framework) ----------------------------
# Consensus recipe: local linear (p=1 default), triangular kernel (default),
# MSE-optimal bandwidth (bwselect="mserd" default), robust bias-corrected CIs.
fit <- rdrobust(y, x, c = CUT)
summary(fit, all = TRUE)          # Conventional + Bias-Corrected + Robust rows

# With covariates (precision only; the point estimate should barely move):
fit_cov <- rdrobust(y, x, c = CUT, covs = Z)
# With clustering (note the vce requirement in 4.0.0):
# fit_cl <- rdrobust(y, x, c = CUT, cluster = df$cluster, vce = "cr2")
# Robustness variants: p = 2, uniform kernel, CE-optimal bandwidth:
fit_p2 <- rdrobust(y, x, c = CUT, p = 2)
fit_ce <- rdrobust(y, x, c = CUT, bwselect = "cerrd")

## ---- 3. Fuzzy estimation and diagnostics -----------------------------------
fzy <- rdrobust(y, x, c = CUT, fuzzy = d)
summary(fzy, all = TRUE)          # prints a first-stage block before the ratio
# First stage as its own sharp RD at the SAME bandwidths (CKT 2023 pattern):
h <- fzy$bws[1]; b <- fzy$bws[2]
fs <- rdrobust(d, x, c = CUT, h = h, b = b)
summary(fs)
# Weak-instrument check INSIDE the bandwidth, never full-sample. The package
# reports no F; the native strength measure is the first-stage z (fs output),
# z^2 ~ F for one instrument. The manual kernel-weighted F below is OUR addition,
# not from the guides:
inb <- abs(x - CUT) <= h
wgt <- pmax(0, 1 - abs(x - CUT) / h)               # triangular weights
fs_lm <- lm(d ~ I(x >= CUT) * I(x - CUT), weights = wgt, subset = inb)
# ITT effects on take-up and outcome are reported ALONGSIDE the fuzzy ratio, always.

## ---- 4. Manipulation testing -----------------------------------------------
# Density test (jackknife vce per the applied guide) + built-in binomial table
# (bino = TRUE default in rddensity 3.0; binoP = 0.5 null, 10 nested windows).
mtest <- rddensity(X = x, c = CUT, vce = "jackknife")
summary(mtest)
rdplotdensity(mtest, X = x)
# Manual binomial route on the chosen local-randomization window (guide's pattern):
# binom.test(sum(x >= CUT & inwin), sum(inwin), 1/2)
# Keep windows narrow: a trending density fails the constant-probability null
# mechanically, which is not evidence of sorting.

## ---- 5. Local randomization branch -----------------------------------------
# Window by nested covariate balance: loose threshold level = 0.15 (default),
# minimum ~10 obs per side, no multiplicity correction (over-rejection only
# shrinks the window). R = running variable, X = covariate matrix.
w <- rdwinselect(R = x, X = Z, cutoff = CUT, reps = 1000, seed = 50)
# Fisherian inference in the selected window (exact under the sharp null):
ri <- rdrandinf(Y = y, R = x, cutoff = CUT, wl = w$w_left, wr = w$w_right,
                reps = 1000, seed = 50)
# Fuzzy local randomization:
# rdrandinf(Y = y, R = x, cutoff = CUT, wl = w$w_left, wr = w$w_right,
#           fuzzy = c(d, "tsls"))
# Window sensitivity: rdsensitivity(Y = y, R = x, cutoff = CUT, wlist = ..., tlist = ...)

## ---- 6. Falsification battery ----------------------------------------------
# 6a. Covariate / placebo-outcome balance: full RD machinery per covariate,
#     FRESH MSE-optimal bandwidth each time (do not reuse the outcome bandwidth).
for (j in seq_len(ncol(Z))) {
  cat("--", colnames(Z)[j], "--\n")
  print(summary(rdrobust(Z[, j], x, c = CUT)))
}
# 6b. Placebo cutoffs: one side of the true cutoff at a time, so real treatment
#     effects cannot contaminate the placebo. The +/-50 offset is scaled to the
#     CUT = 350 example; adapt it to your score's scale.
summary(rdrobust(y[x >= CUT], x[x >= CUT], c = CUT + 50))
summary(rdrobust(y[x < CUT],  x[x < CUT],  c = CUT - 50))
# 6c. Donut hole: drop cutoff-adjacent observations, KEEP the original bandwidths.
donut <- abs(x - CUT) > 1     # tune the radius to the score's granularity
summary(rdrobust(y[donut], x[donut], c = CUT, h = fit$bws[1], b = fit$bws[2]))
# 6d. Bandwidth sensitivity: instability at or below the MSE-optimal h is the
#     warning sign; degradation far above it is expected by construction.
for (hh in c(0.75, 1, 1.25, 1.5) * fit$bws[1]) {
  print(summary(rdrobust(y, x, c = CUT, h = hh)))
}

## ---- 7. Power and MDE (report with any null result) ------------------------
# R functions are rdpower()/rdsampsi()/rdmde(); rdpow is the Stata name.
# data = two columns, outcome then running variable.
pow <- rdpower(data = cbind(y, x), cutoff = CUT, tau = 5)   # tau in outcome units
# Ex-ante design: rdsampsi(data = cbind(y, x), cutoff = CUT, tau = 5)

## ---- 8. Multiple cutoffs (tiered programs) ----------------------------------
# library(rdmulti)
# cvec <- df$tier_cutoff                       # observation-level cutoff values
# rdmc(Y = y, X = x, C = cvec)                 # per-cutoff + pooled estimands

## ---- Session ----------------------------------------------------------------
# Pin: rdrobust >= 4.0.0 (the `all`/summary and cluster/vce changes above),
# rddensity >= 3.0 (built-in binomial table), rdlocrand 2.0, rdpower 3.0.
sessionInfo()
