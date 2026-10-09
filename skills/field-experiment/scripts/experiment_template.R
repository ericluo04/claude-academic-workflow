# Field-experiment analysis template. Adapt the CONFIG block and run section by section.
# Package versions, pins, and API traps: the package index in references/details.md.
# Run end to end on 2026-10-09 (tier 2) on simulated data with seed 94305, once with
# stratified unit-level assignment (N = 600, 6 strata, no cluster column) and once with
# stratified cluster assignment (G = 12 clusters in 2 strata) (R 4.6.1; randomizr 2.0.1,
# estimatr 2.0.0, ri2 0.5.0, DeclareDesign 1.1.1, grf 2.6.1, marginaleffects 1.0.0,
# dfadjust 1.1.0, qte 2.0.0, sandwich 3.1-3, GenericML 0.2.3 with ranger).
# Not run: the commented RobinCar, wildrwolf, fwildclusterboot, and PowerUpR calls.

## ---- CONFIG ----------------------------------------------------------------
df <- your_data       # unit-level frame: y, z (0/1), stratum, x1, x2, pre_y, cluster
                      # (needed only when clustered = TRUE),
                      # s (observation gate, for the Lee block), y01 (binary 0/1 outcome,
                      # for the binary-outcome block), d (0/1 treatment actually received,
                      # for the noncompliance block)
clustered <- FALSE    # TRUE only when z was assigned by cluster, so z is constant within
                      # cluster. The declaration in section 2 assumes block_and_cluster_ra
                      # over stratum; after plain cluster_ra, drop blocks there and skip
                      # the stratified line. Sections 2, 5, 6, 7, and 8 read this
                      # flag (sections 3, 4, and 9 assume unit-level assignment)
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
# diagnose_design(design, sims = 2000)  # power is a default diagnosand; its Monte Carlo
#   SE near power 0.8 is sqrt(0.8 * 0.2 / sims): about 0.018 at 500 sims, 0.009 at 2000

## ---- 2. Primary analysis: Neyman + randomization inference ------------------
# Analyze as randomized: difference_in_means auto-detects blocked / clustered /
# matched-pair designs from the arguments and picks the design-appropriate variance.
# Under cluster assignment, clusters = passes the assignment unit (NULL otherwise).
difference_in_means(y ~ z, clusters = if (clustered) cluster else NULL,
                    data = df)                                         # complete
difference_in_means(y ~ z, blocks = stratum,
                    clusters = if (clustered) cluster else NULL, data = df)  # stratified
# Fisher exact p, same declaration that did the assignment (permute whole clusters under
# cluster assignment, or the p-value is wrong):
decl <- if (clustered) {
  declare_ra(N = nrow(df), clusters = df$cluster, blocks = df$stratum, prob = 0.5)
} else {
  declare_ra(N = nrow(df), blocks = df$stratum, prob = 0.5)
}
conduct_ri(y ~ z, declaration = decl, assignment = "z",
           sharp_hypothesis = 0, data = df,
           sims = 2000)   # Monte Carlo error negligible at this budget
# Rank statistic under heavy tails / many zeros (custom statistic route):
conduct_ri(test_function = function(d) with(d, mean(rank(y)[z==1]) - mean(rank(y)[z==0])),
           declaration = decl, assignment = "z", data = df, sims = 2000)
# Caveat: exact tests of SHARP nulls only; interval-estimate the ATE with Neyman/HC2,
# not by inverting permutation tests (undercoverage under heterogeneity).

## ---- 3. Covariate adjustment (Lin) -------------------------------------------
# Unadjusted first, always. Then the demeaned fully-interacted regression. Lin's
# never-hurts guarantee is for complete randomization. Under the stratified CONFIG design,
# stratum indicators enter the covariates, which gives the stratum-centered interacted
# estimator that keeps the guarantee under equal treatment fractions within strata (Liu
# and Yang 2020; without them the variance can rise, Cytrynbaum 2024). Under complete
# randomization, drop factor(stratum).
fit_lin <- lm_lin(y ~ z, covariates = ~ pre_y + x1 + factor(stratum), data = df)  # HC2
fit_lin
# Rare treatment arm: HC2 with Imbens-Kolesar degrees of freedom. dfadjustSE needs an lm
# fit, so refit the same specification (centered covariates and stratum dummies,
# interacted with z) with lm; the z row reports the adjusted df and interval:
Xc <- scale(model.matrix(~ pre_y + x1 + factor(stratum), df)[, -1], scale = FALSE)
fit_lm <- lm(df$y ~ df$z * Xc)
dfadjust::dfadjustSE(fit_lm)$coefficients["df$z", ]
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
# Revenue per user and other nonnegative outcomes with zeros: log(y) is undefined at 0,
# and log-like transforms do not identify a percentage effect there (Chen and Roth 2024).
# Impute per arm with Poisson quasi-likelihood (canonical link, so it calibrates):
if (min(df$y) >= 0) {
  m1 <- glm(y ~ pre_y + x1, family = quasipoisson, data = subset(df, z == 1))
  m0 <- glm(y ~ pre_y + x1, family = quasipoisson, data = subset(df, z == 0))
  y1_hat <- predict(m1, df, type = "response"); y0_hat <- predict(m0, df, type = "response")
  tau_pois <- mean(y1_hat - y0_hat)                       # ATE in levels
  print(tau_pois + t.test(residuals(m1, "response"), residuals(m0, "response"))$conf.int)
  print(tau_pois / mean(y0_hat))                          # as a share of the control mean
}
# Strictly positive skewed outcomes only (min(y) > 0): OLS on log(y), impute exp(Xb), then
# SECOND-STAGE OLS of y on the fitted values per arm (recalibration); never the log
# coefficient.
# Covariate-adaptive randomization (Pocock-Simon etc.): RobinCar:
# RobinCar::robincar_linear(df, treat_col = "z", response_col = "y",
#   car_strata_cols = "stratum", covariate_cols = c("pre_y", "x1"),
#   car_scheme = "permuted-block", adj_method = "ANHECOVA")  # arg is car_strata_cols

## ---- 5. Clustered designs: estimand first ------------------------------------
# Runs only under cluster assignment (CONFIG clustered = TRUE): z must be constant within
# cluster, e.g. df$z <- cluster_ra(clusters = df$cluster, prob = 0.5) at design time.
if (clustered) {
  stopifnot(all(tapply(df$z, df$cluster, function(v) length(unique(v))) == 1))
  # Cluster-average effect (primary): difference in means on cluster means.
  cl_means <- aggregate(cbind(y, z) ~ cluster, data = df, mean)
  print(difference_in_means(y ~ z, data = cl_means))
  # Unit-average effect: unit-level regression. With few clusters the family's small-G
  # rule (causal-design shared-rules, "Clustering") puts CV3 first, with the wild cluster
  # restricted bootstrap, and CR2 + Satterthwaite dof as the cross-check beside them.
  fit_u <- lm(y ~ z, data = df)
  se_cv3 <- sqrt(diag(sandwich::vcovBS(fit_u, cluster = ~cluster, type = "jackknife")))["z"]
  print(c(estimate = unname(coef(fit_u)["z"]), se_CV3 = unname(se_cv3)))   # CV3 first
  # Wild cluster restricted bootstrap: fwildclusterboot is archived from CRAN; install from
  # s3alfisc.r-universe.dev (did/references/details.md), then:
  # dqrng::dqset.seed(94305)   # boottest draws from dqrng, not base R
  # fwildclusterboot::boottest(fixest::feols(y ~ z, df, cluster = ~cluster), param = "z",
  #   B = 9999, clustid = "cluster", type = "webb", impose_null = TRUE)  # Webb: few G
  print(lm_robust(y ~ z, data = df, clusters = cluster, se_type = "CR2"))  # cross-check
  # Report BOTH when cluster sizes vary; the gap is evidence effects covary with size.
}

## ---- 6. Noncompliance: ITT + LATE, never as-treated --------------------------
cl <- if (clustered) df$cluster else NULL  # cluster the variance under cluster assignment
difference_in_means(d ~ z, clusters = cl, data = df)  # first stage = compliance shares
difference_in_means(y ~ z, clusters = cl, data = df)  # ITT, the randomization-justified number
iv_robust(y ~ d | z, data = df, clusters = cl,
          se_type = if (clustered) "CR2" else "HC2")  # LATE; exclusion/monotonicity
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
# Otherwise Lee bounds. The function trims whichever arm has the higher observation rate,
# so the trim share p = |s1 - s0| / max(s1, s0) always lies in [0, 1). The bounds are
# continuous in s1 - s0 (both directions give the untrimmed contrast at s1 = s0). A
# bootstrap draw whose direction differs from the full sample's therefore trims the other
# arm, and the draw is kept; `flipped` counts those draws so the writeup can report them.
lee_bounds <- function(d) {
  s1 <- mean(d$s[d$z == 1]); s0 <- mean(d$s[d$z == 0])
  y1 <- d$y[d$z == 1 & d$s == 1]; y0 <- d$y[d$z == 0 & d$s == 1]
  if (s1 >= s0) {               # treatment raises observation: trim the treated arm
    p <- (s1 - s0) / s1
    c(lower = mean(y1[y1 <= quantile(y1, 1 - p)]) - mean(y0),
      upper = mean(y1[y1 >= quantile(y1, p)]) - mean(y0), trim = p, treated_trimmed = 1)
  } else {                      # treatment lowers observation: trim the control arm
    p <- (s0 - s1) / s0
    c(lower = mean(y1) - mean(y0[y0 >= quantile(y0, p)]),
      upper = mean(y1) - mean(y0[y0 <= quantile(y0, 1 - p)]), trim = p, treated_trimmed = 0)
  }
}
lb <- lee_bounds(df)
lb                                        # point bounds, trim share, trimmed arm
# Bootstrap the WHOLE pipeline (trimming share included; its estimation error was the
# largest variance component in Lee's application). Under cluster assignment, resample
# whole clusters within each arm, so that no draw loses an arm when G is small; otherwise
# resample units.
B <- 2000   # 2000 draws give stable trim-share quantiles
if (clustered) {
  cz <- unique(df[, c("cluster", "z")]); cl_arm <- split(cz$cluster, cz$z)
}
draw <- function() {
  if (!clustered) return(df[sample(nrow(df), replace = TRUE), ])
  ids <- unlist(lapply(cl_arm, function(g) g[sample.int(length(g), replace = TRUE)]))
  do.call(rbind, lapply(ids, function(g) df[df$cluster == g, ]))
}
boots <- t(replicate(B, lee_bounds(draw())))
flipped <- sum(boots[, "treated_trimmed"] != lb["treated_trimmed"])
c(B = B, flipped = flipped, share = flipped / B)  # report: draws that trimmed the other arm
# A near-zero gap s1 - s0 puts the trim share at the kink of |s1 - s0|, where the bootstrap
# is unreliable (the verification's near-equal run flipped 727 of 2000 draws). A large
# flipped share means the bounds and their interval are uninformative: say so, and go to
# the always-observed route above (balance test, selected-sample estimate). The 10 percent
# cutoff below is our judgment, not a published threshold.
if (flipped / B > 0.10) message("Flipped share above 10%: Lee interval uninformative; ",
                                "use the always-observed route")
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
pvec <- c(y   = difference_in_means(y ~ z, clusters = cl, data = df)$p.value,
          y01 = difference_in_means(y01 ~ z, clusters = cl, data = df)$p.value)
p.adjust(pvec, method = "holm")
# Romano-Wolf stepdown by resampling, coded by hand so no archived package is needed.
# Resample assignment units (whole clusters under cluster assignment) within stratum-by-arm
# cells, recompute each outcome's HC2 (CR2 under clusters) t-statistic centered at the
# full-sample estimate, and step down on the max |t|. With few clusters (G = 12 in the
# test run), the wild cluster bootstrap route above is the better choice.
# hdm::p_adjust(method = "RW") does not qualify: it draws Gaussian vectors from the
# homoskedastic vcov of one lm fit, with no resampling and no HC2.
outs <- c("y", "y01")                    # the outcome family; swap in yours
tstat <- function(d) sapply(outs, function(v) {
  f <- if (clustered) difference_in_means(reformulate("z", v), clusters = .u, data = d) else
    difference_in_means(reformulate("z", v), data = d)
  c(est = unname(f$coefficients), se = unname(f$std.error))
})
d0 <- df; d0$.u <- if (clustered) df$cluster else seq_len(nrow(df))
s0 <- tstat(d0)
ud <- unique(d0[, c(".u", "z", "stratum")])
cells <- split(ud$.u, interaction(ud$z, ud$stratum, drop = TRUE))
rows_by_unit <- split(seq_len(nrow(d0)), d0$.u)
draw_rw <- function() {
  picked <- unlist(lapply(cells, function(u) u[sample.int(length(u), replace = TRUE)]))
  idx <- rows_by_unit[as.character(picked)]
  bd <- d0[unlist(idx), ]
  bd$.u <- rep(seq_along(idx), lengths(idx))   # a unit drawn twice counts as two units
  s <- tstat(bd)
  abs(s["est", ] - s0["est", ]) / s["se", ]
}
B_rw <- 999   # B chosen so that alpha * (B + 1) is an integer at alpha = .05
tb <- t(replicate(B_rw, draw_rw()))
t0 <- abs(s0["est", ] / s0["se", ])
ord <- order(t0, decreasing = TRUE)
p_rw <- setNames(numeric(length(outs)), outs)
for (j in seq_along(ord)) {
  maxb <- apply(tb[, ord[j:length(ord)], drop = FALSE], 1, max)
  p_rw[ord[j]] <- (1 + sum(maxb >= t0[ord[j]])) / (B_rw + 1)
}
p_rw[ord] <- cummax(p_rw[ord])           # stepdown p-values are monotone in t
p_rw
# Data-driven: honest causal forest (grf; dot-separated arg names). Randomized
# experiment: pass the KNOWN W.hat instead of estimating propensities.
library(grf)
X <- as.matrix(df[, c("pre_y", "x1", "x2")])
cf <- causal_forest(X, df$y, df$z, W.hat = 0.5,
                    num.trees = 2000,          # grf default, pinned for reproducibility
                    # cluster only under cluster assignment, never under unit-level
                    # assignment (causal-design shared rules):
                    clusters = if (clustered) df$cluster else NULL)
average_treatment_effect(cf, target.sample = "all")
best_linear_projection(cf, A = X[, c("pre_y", "x1")])
test_calibration(cf)
# Detectable heterogeneity (RATE): priorities MUST come from a forest fit on held-out
# data (train/evaluate split; the signature does not enforce it, the man page does):
half <- sample(nrow(df), nrow(df) / 2)
cf_tr <- causal_forest(X[half, ], df$y[half], df$z[half], W.hat = 0.5)
cf_ev <- causal_forest(X[-half, ], df$y[-half], df$z[-half], W.hat = 0.5)
rank_average_treatment_effect(cf_ev, priorities = predict(cf_tr, X[-half, ])$predictions)
# Generic ML inference (Chernozhukov, Demirer, Duflo, Fernandez-Val 2025): BLP, GATES, and
# CLAN over repeated sample splits. The propensity is known (constant) in an experiment.
# Learners in mlr3 syntax; the ranger learner needs the ranger package. 100 splits is the
# package default; 20 here keeps the run to seconds, so raise it for reported numbers.
# The package has no cluster option, so this block runs under unit-level assignment only;
# under cluster assignment, aggregate to clusters first. Intervals print at level
# 1 - 2 * significance_level (95 percent here, the paper's recommended nominal level).
if (!clustered) {
  library(GenericML)
  gm <- GenericML(Z = X, D = df$z, Y = df$y,
                  learners_GenericML = c("mlr3::lrn('ranger', num.trees = 200)", "lasso"),
                  learner_propensity_score = "constant", num_splits = 20,
                  quantile_cutoffs = c(0.25, 0.5, 0.75), significance_level = 0.025,
                  monotonize = TRUE,  # the 0.2.3 default, passed explicitly
                  parallel = FALSE, seed = 94305)
  print(get_BLP(gm, plot = FALSE))    # beta.2 significantly > 0: the proxy tracks real
                                      # heterogeneity
  print(get_GATES(gm, plot = FALSE))  # effects by proxy quartile, top-minus-bottom gap
  print(get_CLAN(gm, variable = "pre_y", plot = FALSE))  # covariate means by group
}

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
# Pins and archived packages: the package index in references/details.md.
sessionInfo()
