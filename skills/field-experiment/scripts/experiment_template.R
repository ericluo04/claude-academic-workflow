# Field-experiment analysis template. Runnable end to end; every call signature verified
# against package documentation on 2026-07-28 (randomizr 1.0.1, estimatr 1.0.6, ri2 0.4.1,
# DeclareDesign 1.1.1, grf 2.6.1, marginaleffects 0.32.0, RobinCar 1.2.0, qte 2.0.0, all
# CRAN). Adapt the CONFIG block and run section by section.
#
# API traps older tutorials get wrong:
#   - estimatr::difference_in_means auto-detects the design (blocked, clustered,
#     matched-pair); its se_type is only "default"/"none". HC/CR strings belong to
#     lm_robust/lm_lin (HC2 default without clusters, CR2 with).
#   - lm_lin: formula is Y ~ Z with ONLY treatment on the RHS; covariates go in a separate
#     one-sided formula.
#   - marginaleffects: comparison = "oravg" DOES NOT EXIST; use "lnoravg" (+ transform =
#     exp for the odds-ratio scale).
#   - qte 2.0.0 (2026-07) deprecated ci.qte; the current call is unc_qte(yname, dname, ...).
#   - wildrwolf and PowerUpR are ARCHIVED from CRAN (2024-05 and 2026-03); install routes
#     and fallbacks below.
#   - Lee (2009) bounds have NO reliable R package (the Semenova GitHub repo is a
#     replication archive whose README example does not run); hand-rolled below.

## ---- CONFIG ----------------------------------------------------------------
df <- your_data       # unit-level frame: y, z (0/1), stratum, cluster, x1, x2, pre_y,
                      # s (observation gate, for the Lee block), y01 (binary 0/1 outcome,
                      # for the binary-outcome block), d (0/1 treatment actually received,
                      # for the noncompliance block)
set.seed(94305)
library(randomizr); library(estimatr); library(ri2)

## ---- 1. Design: assignment and power ----------------------------------------
# Stratified assignment (strata as fine as possible, >= 2 treated + 2 control each):
# Z <- block_ra(blocks = df$stratum, prob = 0.5)      # N inferred from blocks
# Clustered: cluster_ra(clusters = df$cluster, prob = 0.5)
# Both: block_and_cluster_ra(blocks = ..., clusters = ...)
# Power, individual randomization (matches the canon's closed form up to t-vs-normal):
power.t.test(delta = 1, sd = 6, sig.level = 0.05,  # .05/.80: the field-standard planning
             power = 0.80)                         # conventions. Returns n per arm
# Cluster designs: hand-code the design effect DEFF = 1 + (m - 1) * ICC and inflate N
# (PowerUpR::mdes.cra2 exists but the package was ARCHIVED from CRAN 2026-03; do not
# build a pipeline on it). Stratified/complex designs: simulate with DeclareDesign:
# library(DeclareDesign)
# design <- declare_model(N = 500, U = rnorm(N), potential_outcomes(Y ~ 0.2*Z + U)) +
#   declare_inquiry(ATE = mean(Y_Z_1 - Y_Z_0)) +
#   declare_assignment(Z = complete_ra(N, prob = 0.5)) +
#   declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
#   declare_estimator(Y ~ Z, .method = estimatr::lm_robust, inquiry = "ATE")  # .method!
# diagnose_design(design, sims = 500)   # power is a default diagnosand; Monte Carlo
#   error is negligible at 500 sims

## ---- 2. Primary analysis: Neyman + randomization inference ------------------
# Analyze as randomized: difference_in_means auto-detects blocked / clustered /
# matched-pair designs from the arguments and picks the design-appropriate variance.
difference_in_means(y ~ z, data = df)                       # complete randomization
difference_in_means(y ~ z, blocks = stratum, data = df)     # stratified
# Fisher exact p, same declaration that did the assignment:
decl <- declare_ra(N = nrow(df), blocks = df$stratum, prob = 0.5)
conduct_ri(y ~ z, declaration = decl, assignment = "z",
           sharp_hypothesis = 0, data = df,
           sims = 2000)   # Monte Carlo error negligible at this budget
# Rank statistic under heavy tails / many zeros (custom statistic route):
conduct_ri(test_function = function(d) with(d, mean(rank(y)[z==1]) - mean(rank(y)[z==0])),
           declaration = decl, assignment = "z", data = df, sims = 2000)
# Caveat: exact tests of SHARP nulls only; interval-estimate the ATE with Neyman/HC2,
# not by inverting permutation tests (undercoverage under heterogeneity).

## ---- 3. Covariate adjustment (Lin) -------------------------------------------
# Unadjusted first, always. Then the demeaned fully-interacted regression:
lm_lin(y ~ z, covariates = ~ pre_y + x1, data = df)         # HC2 default
# se_type = "HC3" with small arms or leverage points.
# Pre-reporting checks (minutes of compute):
# (a) zero-effect coverage simulation: re-randomize under no effect, check empirical
#     coverage of every planned estimator-variance pair (loop over declare_ra draws);
# (b) leading-term bias estimate: cov of outcomes with squared demeaned covariates / n,
#     worry only if a nontrivial fraction of the SE.

## ---- 4. Binary and nonlinear outcomes (Freedman / Guo-Basse) -----------------
# Primary: difference in proportions = difference_in_means on the binary y. For
# precision, standardize an interacted logistic working model to the MARGINAL effect;
# never report the logit coefficient (noncollapsible conditional estimand):
fit <- glm(y01 ~ z * (pre_y + x1), family = binomial, data = df)
marginaleffects::avg_comparisons(fit, variables = "z", vcov = "HC2")  # risk difference
# Marginal odds ratio, if a referee wants that scale ("oravg" does not exist):
marginaleffects::avg_comparisons(fit, variables = "z",
                                 comparison = "lnoravg", transform = exp)
# Guo-Basse per-arm imputation with the design-based MSE interval (their own snippet;
# swap family = poisson for counts -- 45% shorter intervals than linear on their data):
mu1 <- glm(y01 ~ pre_y + x1, family = binomial, data = subset(df, z == 1))
mu0 <- glm(y01 ~ pre_y + x1, family = binomial, data = subset(df, z == 0))
tau_gob <- mean(predict(mu1, df, "response") - predict(mu0, df, "response"))
tau_gob + t.test(residuals(mu1, "response"), residuals(mu0, "response"))$conf.int
# Pre-trust checks: no fitted values hugging 0/1 (separation); per-arm R2 not both
# near 1; model flexibility small vs arm sizes. No universal never-worse guarantee:
# platforms wanting one use linear imputation or no-harm calibration.
# Skewed revenue: fit OLS on log(y), impute exp(Xb), then SECOND-STAGE OLS of y on the
# fitted values per arm before imputing (recalibration); never the log coefficient.
# Covariate-adaptive randomization (Pocock-Simon etc.): RobinCar:
# RobinCar::robincar_linear(df, treat_col = "z", response_col = "y",
#   car_strata_cols = "stratum", covariate_cols = c("pre_y", "x1"),
#   car_scheme = "permuted-block", adj_method = "ANHECOVA")  # arg is car_strata_cols

## ---- 5. Clustered designs: estimand first ------------------------------------
# Cluster-average effect (primary): difference in means on cluster means.
cl_means <- aggregate(cbind(y, z) ~ cluster, data = df, mean)
difference_in_means(y ~ z, data = cl_means)
# Unit-average effect: unit-level regression, CR2 + Satterthwaite dof:
lm_robust(y ~ z, data = df, clusters = cluster, se_type = "CR2")
# Report BOTH when cluster sizes vary; the gap is evidence effects covary with size.

## ---- 6. Noncompliance: ITT + LATE, never as-treated --------------------------
difference_in_means(d ~ z, data = df)     # first stage = compliance-share table
difference_in_means(y ~ z, data = df)     # ITT, the randomization-justified number
iv_robust(y ~ d | z, data = df, se_type = "HC2")   # LATE; exclusion/monotonicity
# argued with the iv skill's discipline; weak first stage -> iv skill's AR machinery.
# Balke-Pearl bounds when exclusion is doubtful: bpbounds (see iv template, section 4).

## ---- 7. Attrition / gated outcomes: Lee bounds (hand-rolled; no R package) ----
s1 <- mean(df$s[df$z == 1]); s0 <- mean(df$s[df$z == 0])
c(s1 = s1, s0 = s0, diff = s1 - s0)       # differential observation rate FIRST
# If |s1 - s0| ~ 0: monotonicity balance test within the selected sample, then report
# the selected-sample estimate labeled "always-observed stratum". The joint p needs a
# likelihood-ratio test against the null model (summary() gives per-coefficient Wald
# p-values only, never a joint one):
fit1 <- glm(z ~ pre_y + x1, family = binomial, data = subset(df, s == 1))
fit0 <- glm(z ~ 1, family = binomial, data = subset(df, s == 1))
anova(fit0, fit1, test = "LRT")           # monotonicity balance test, joint p
# Otherwise Lee bounds (here assuming treatment RAISES observation; flip arms if not):
lee_bounds <- function(d) {
  s1 <- mean(d$s[d$z == 1]); s0 <- mean(d$s[d$z == 0])
  p  <- (s1 - s0) / s1
  y1 <- d$y[d$z == 1 & d$s == 1]; y0 <- d$y[d$z == 0 & d$s == 1]
  c(lower = mean(y1[y1 <= quantile(y1, 1 - p)]) - mean(y0),
    upper = mean(y1[y1 >= quantile(y1, p)]) - mean(y0), trim = p)
}
lb <- lee_bounds(df)
# Bootstrap the WHOLE pipeline (trimming share included; its estimation error was the
# largest variance component in Lee's application):
B <- 2000   # 2000 draws give stable trim-share quantiles
boots <- t(replicate(B, lee_bounds(df[sample(nrow(df), replace = TRUE), ])))
se_l <- sd(boots[, "lower"]); se_u <- sd(boots[, "upper"])
# Imbens-Manski interval (covers the EFFECT, the right default):
cn <- uniroot(function(c) pnorm(c + (lb["upper"] - lb["lower"]) / max(se_l, se_u)) -
                pnorm(-c) - 0.95, c(1, 3))$root   # 0.95: the conventional coverage level
c(lb["lower"] - cn * se_l, lb["upper"] + cn * se_u)
# Tighten: cells from quintiles of OLS-predicted outcomes on baseline X, lee_bounds
# within each cell, average over the control-selected X distribution.
# REQUIRED sentence in the writeup: who the marginal observed units are, hence which
# end of the interval is credible.

## ---- 8. Heterogeneity ---------------------------------------------------------
# Pre-specified subgroups + Romano-Wolf. wildrwolf was ARCHIVED from CRAN 2024-05
# (needs archived fwildclusterboot; r-universe serves 0.7.0 and it accepts ONLY
# fixest models). Install if wanted:
# install.packages("wildrwolf", repos = c("https://s3alfisc.r-universe.dev",
#                                         "https://cloud.r-project.org"))
# ms <- list(fixest::feols(y1 ~ z, df), fixest::feols(y2 ~ z, df))
# wildrwolf::rwolf(ms, param = "z", B = 9999)   # B chosen so alpha*(B+1) is an integer
# Holm fallback (conservative, always available): collect the p-values of the outcome
# family into pvec; here the two outcomes the CONFIG frame carries, swap in yours:
pvec <- c(y   = difference_in_means(y ~ z, data = df)$p.value,
          y01 = difference_in_means(y01 ~ z, data = df)$p.value)
p.adjust(pvec, method = "holm")
# Data-driven: honest causal forest (grf; dot-separated arg names). Randomized
# experiment: pass the KNOWN W.hat instead of estimating propensities.
library(grf)
X <- as.matrix(df[, c("pre_y", "x1", "x2")])
cf <- causal_forest(X, df$y, df$z, W.hat = 0.5,
                    num.trees = 2000,          # grf default, pinned for reproducibility
                    clusters = df$cluster)
average_treatment_effect(cf, target.sample = "all")
best_linear_projection(cf, A = X[, c("pre_y", "x1")])
test_calibration(cf)
# Detectable heterogeneity (RATE): priorities MUST come from a forest fit on held-out
# data (train/evaluate split; the signature does not enforce it, the man page does):
half <- sample(nrow(df), nrow(df) / 2)
cf_tr <- causal_forest(X[half, ], df$y[half], df$z[half], W.hat = 0.5)
cf_ev <- causal_forest(X[-half, ], df$y[-half], df$z[-half], W.hat = 0.5)
rank_average_treatment_effect(cf_ev, priorities = predict(cf_tr, X[-half, ])$predictions)

## ---- 9. Quantile treatment effects --------------------------------------------
# qte 2.0.0 renamed the interface; ci.qte is deprecated. Randomized experiment:
library(qte)
q <- unc_qte(yname = "y", dname = "z", data = df, xformla = ~1,
             probs = seq(0.1, 0.9, 0.1),  # interior quantiles, where estimation is stable
             biters = 1000)               # Monte Carlo error small at 1000 draws
summary(q)
# OUR caveat, not the package's: bootstrap CIs are unreliable at quantiles sitting on
# mass points (many zeros); flag those quantiles and pair with an exact test using the
# QTE as the ri2 test statistic.

## ---- Session -------------------------------------------------------------------
# Pin: estimatr >= 1.0.6, ri2 0.4.1, marginaleffects >= 0.32 (lnoravg spelling),
# grf >= 2.6 (rank_average_treatment_effect), qte >= 2.0 (unc_qte API),
# RobinCar >= 1.2 (car_strata_cols). Archived: wildrwolf (r-universe), PowerUpR
# (CRAN Archive; prefer the hand-coded design effect).
sessionInfo()
