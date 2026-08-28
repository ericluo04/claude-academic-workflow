# Selection-on-observables template (the branch causal-design owns). Every call verified
# against package documentation and source on 2026-07-28 (grf 2.6.1, policytree 1.2.4,
# sensemakr 0.1.6, WeightIt 1.7.0, marginaleffects 0.32.0). Adapt and run section by
# section.
#
# API traps verified against docs/source:
#   - sensemakr looks the treatment up by COEFFICIENT NAME: a factor treatment fails with
#     "Variables not found in model" (undocumented; source check_covariates). Code the
#     treatment as numeric 0/1. kd defaults to 1; pass kd = 1:3 explicitly for the
#     standard 1x/2x/3x benchmark table.
#   - WeightIt: estimand = "ATO" is valid for method = "glm" (binary and multi-category)
#     but NOT for every method; re-check ?method_<name> if you swap methods. The
#     recommended downstream is now lm_weightit()/glm_weightit() (M-estimation SEs that
#     account for the weights being ESTIMATED) + marginaleffects::avg_comparisons();
#     plain lm + vcovCL treats weights as fixed.
#   - policytree double_robust_scores returns N x d with columns = actions IN ORDER:
#     column 1 = control, column 2 = treated; predict() returns that column index
#     (1 = assign control, 2 = assign treated), not a 0/1 treatment.
#   - grf: cluster-robust ATE standard errors come from passing clusters= AT FIT TIME
#     (DR scores are aggregated by cluster downstream); there is no cluster argument in
#     average_treatment_effect(). rank_average_treatment_effect() priorities must come
#     from a forest trained on a held-out split, or the RATE is spuriously inflated.

library(grf)             # 2.6.1
library(policytree)      # 1.2.4
library(sensemakr)       # 0.1.6
library(WeightIt)        # 1.7.0
library(marginaleffects) # 0.32.0
# Package index with versions, links, and traps in ../references/details.md.

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
#      variance-minimizing rule), refit, and report the retained population;
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
# Equal halves keep both the priority and evaluation forests adequately powered; any
# held-out split satisfies the grf requirement:
tr <- sample(nrow(X), nrow(X) / 2)
cf_tr <- causal_forest(X[tr, ],  df$y[tr],  df$d[tr],  seed = 42)
cf_ev <- causal_forest(X[-tr, ], df$y[-tr], df$d[-tr], seed = 42)
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
fit <- lm_weightit(y ~ d * (x1 + x2 + x3), data = df, weightit = w)
avg_comparisons(fit, variables = "d", wts = w$weights)
# vcov = "asympt" M-estimation SEs account for the weights being estimated (the docs'
# recommended pipeline). Fixed-weight fallback, clustered:
#   f2 <- lm(y ~ d, data = df, weights = w$weights)
#   lmtest::coeftest(f2, vcov = sandwich::vcovCL(f2, cluster = ~ cl))

## ---- 5. Sensitivity analysis (MANDATORY: unconfoundedness is untestable) ---------------
ols <- lm(y ~ d + x1 + x2 + x3, data = df)     # d numeric 0/1 (the sensemakr trap)
sens <- sensemakr(model = ols, treatment = "d",
                  benchmark_covariates = "x1",  # the strongest observed confounder,
                  kd = 1:3)                     # calibration in the Imbens (2003) spirit
summary(sens); plot(sens)
ovb_minimal_reporting(sens, format = "latex")  # the Cinelli-Hazlett reporting table
# Read the verdict on the DESIGN: an estimate that flips under a confounder 1-3x as
# strong as the best observed covariate indicts the identification, not the estimator.
# Ladder alternatives in ../references/details.md: Manski bounds (assumption-free),
# oster2019unobservable (state its proportional-selection and R2-target assumptions),
# rosenbaum2002observational design sensitivity for matched designs.

## ---- Session ---------------------------------------------------------------------------
# Pin: grf 2.6.1 (seed set; honesty on by default), policytree 1.2.4, sensemakr 0.1.6,
# WeightIt 1.7.0 (keep.mparts default TRUE is what makes lm_weightit's M-estimation SEs
# possible), marginaleffects 0.32.0 (WeightIt supported natively; grf is NOT, use grf's
# own estimators for forest effects).
sessionInfo()
