# Selection-on-observables template (the branch causal-design owns). Adapt and run
# section by section. Ran end to end on simulated data on 2026-10-08 under the versions
# listed in ../references/details.md (package index), which also carries the API traps
# for every package used here. Version pins live only in that index and in
# ../references/packages.md (grf, marginaleffects, and the other shared packages).

library(grf)
library(policytree)
library(sensemakr)
library(WeightIt)
library(marginaleffects)
library(cobalt)          # balance tables after weighting (section 4)

## df: one row per unit. y outcome; d treatment CODED NUMERIC 0/1; x1..xK PRETREATMENT
## covariates; cl cluster id at the level treatment was ASSIGNED (drop clusters= below if
## assignment was at the unit level; clustering is a design property, abadie2023clustering).
## The conditioning set contains only non-descendants of treatment and outcome, justified
## by temporal precedence. "Using variables causally affected by the treatment or outcome
## is the most common mistake" (Imbens 2024) -- audit the covariate list before running.

X <- as.matrix(df[, c("x1", "x2", "x3")])
set.seed(94305)

## ---- 1. Overlap FIRST (violations move the estimand, not just the estimator) ----------
cf <- causal_forest(X, df$y, df$d,
                    num.trees = 2000,          # grf default, pinned for reproducibility
                    clusters  = df$cl,         # cluster-robust SEs propagate from here
                    seed      = 42)
hist(cf$W.hat, xlim = c(0, 1))                 # grf's documented overlap check: nothing
                                               # near 0 or 1
mean(cf$W.hat < 0.10 | cf$W.hat > 0.90)        # share outside the Crump rule of thumb
# Poor overlap, two exits, both re-declare WHO the estimate is about:
#  (a) trim to W.hat in [0.10, 0.90] (crump2009dealing approximation of the
#      variance-minimizing rule), refit, and report the retained population.
#      Trimming breaks double robustness: the trimmed estimator is consistent only if
#      the outcome model is correct (Ma, Sant'Anna, Sasaki, and Ura, arXiv 2304.08974).
#      Prefer (b) when you do not trust the outcome model;
#  (b) target.sample = "overlap" below (Li-Morgan-Zaslavsky ATO): no division by
#      estimated propensities, weights concentrate on units that could get either arm.

## ---- 2. Doubly robust average effects (AIPW is the default method) --------------------
average_treatment_effect(cf, target.sample = "all")      # ATE;  returns c(estimate, std.err)
average_treatment_effect(cf, target.sample = "treated")  # ATT (marketing default framing)
average_treatment_effect(cf, target.sample = "overlap")  # ATO under poor overlap
# Nuisances are orthogonalized automatically (Y.hat, W.hat by internal regression
# forests); this is the doubly robust default of the skill (bang2005doubly; Imbens 2024).
# Wanting explicit nuisance-learner control instead: DoubleML (R, 1.0.2) on mlr3.

## ---- 3. Heterogeneity: describe CATEs vs decide who to treat (different goals) --------
tau <- predict(cf, estimate.variance = TRUE)   # $predictions = OOB CATEs;
                                               # sqrt($variance.estimates) = SEs
best_linear_projection(cf, A = X[, c("x1", "x2")])   # doubly robust CATE projection,
                                                     # HC3 SEs; the reportable summary
# Targeting evidence needs the split discipline (priorities independent of evaluation).
# Equal halves keep both the priority and evaluation forests adequately powered. Split
# by CLUSTER, not by unit: when treatment was assigned by cluster, a unit-level split puts
# members of one cluster in both halves, so the halves are not independent and the RATE
# standard errors are not cluster-robust. Both forests get clusters= for the same reason.
# Unit-level assignment: split units at random and drop clusters= from both fits.
cl_ids <- unique(df$cl)
tr <- which(df$cl %in% sample(cl_ids, length(cl_ids) / 2))
cf_tr <- causal_forest(X[tr, ],  df$y[tr],  df$d[tr],  clusters = df$cl[tr],  seed = 42)
cf_ev <- causal_forest(X[-tr, ], df$y[-tr], df$d[-tr], clusters = df$cl[-tr], seed = 42)
rank_average_treatment_effect(cf_ev,
                              priorities = predict(cf_tr, X[-tr, ])$predictions)
# Deciding WHO to treat is policy learning (athey2021policy), not a CATE map:
Gamma <- double_robust_scores(cf)              # N x 2: col 1 = control, col 2 = treated
pt <- policy_tree(X, Gamma, depth = 2)         # depth 2 default: trades interpretability
predict(pt, X)                                 # against fit; deepen only if the evaluated
                                               # policy value clearly improves (search is
                                               # exponential in depth). 1=control, 2=treat

## ---- 4. Overlap weights with weight-aware inference (the ATO route) -------------------
w <- weightit(d ~ x1 + x2 + x3, data = df, method = "glm", estimand = "ATO")
bal.tab(w, stats = c("m", "ks"), thresholds = c(m = .1))  # balance after weighting:
                                               # report standardized mean differences
fit <- lm_weightit(y ~ d * (x1 + x2 + x3), data = df, weightit = w,
                   cluster = ~ cl)             # drop cluster= if assignment was by unit
avg_comparisons(fit, variables = "d", wts = w$weights)
# vcov = "asympt" M-estimation SEs account for the weights being estimated (the docs'
# recommended pipeline); with cluster= they are also cluster-robust. Fixed-weight
# fallback, clustered:
#   f2 <- lm(y ~ d, data = df, weights = w$weights)
#   lmtest::coeftest(f2, vcov = sandwich::vcovCL(f2, cluster = ~ cl))

## ---- 5. Sensitivity analysis (MANDATORY: unconfoundedness is untestable) ---------------
# The robustness value below belongs to a linear OLS proxy with no clustering, not to the
# forest AIPW estimate in section 2. Say so in the methods paragraph ("the robustness
# value benchmarks a linear proxy of the AIPW specification"). The sensitivity analysis
# for the DR estimand itself is Chernozhukov, Cinelli, Newey, Sharma, and Syrgkanis
# ("Long Story Short", REStat 2026, chernozhukov2026long), implemented as sensitivity_analysis() in Python
# DoubleML; R DoubleML 1.0.2 has no equivalent, so use it as the upgrade path.
ols <- lm(y ~ d + x1 + x2 + x3, data = df)     # d numeric 0/1 (the sensemakr trap)
sens <- sensemakr(model = ols, treatment = "d",
                  benchmark_covariates = "x1",  # the strongest observed confounder,
                  kd = 1:3)                     # calibration in the Imbens (2003) spirit
summary(sens); plot(sens)
ovb_minimal_reporting(sens, format = "latex")  # the Cinelli-Hazlett reporting table
# Read the verdict on the DESIGN: an estimate that flips under a confounder 1-3x as
# strong as the best observed covariate indicts the identification, not the estimator.
# Ladder alternatives in ../references/details.md: Manski bounds (assumption-free) and
# Rosenbaum sensitivity bounds (rosenbaum2002observational, ch. 4) for matched designs.
# Oster's delta is dropped (details.md).

## ---- Session ---------------------------------------------------------------------------
# Versions and traps: ../references/details.md (package index). Record them here.
sessionInfo()
