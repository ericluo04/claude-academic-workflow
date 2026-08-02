# DiD analysis template. Runnable end to end; every call signature verified against the
# package source/README on 2026-07-28 (versions noted per section). Adapt the column names
# in the CONFIG block and run section by section.
#
# Data expectations: long panel with one row per unit-period.
#   unit          unit id
#   period        integer time (consecutive)
#   first_treated integer cohort = first treated period, coded 0 for never-treated
#                 (the did/didimputation convention; sections recode where a package
#                 differs: staggered wants Inf, fixest::sunab wants any out-of-range value.
#                 Recycling one coding across packages silently misclassifies units.)
#   y             outcome
#   cluster       level at which treatment is independently assigned
#   treat         derived below (section 5): post-adoption indicator, 1 from first_treated
#                 on for treated units, 0 always for never-treated (first_treated == 0)

## ---- CONFIG ----------------------------------------------------------------
YNAME <- "y"; TNAME <- "period"; IDNAME <- "unit"; GNAME <- "first_treated"
CLUSTER <- "cluster"
XFORMLA <- NULL              # e.g. ~ x1 + x2 for conditional PT; NULL = unconditional
df <- your_data              # replace
set.seed(94305)

## ---- 0. Packages -----------------------------------------------------------
# CRAN: did (2.5.x), HonestDiD (0.2.8), didimputation (0.5.x), TwoWayFEWeights (2.1.x),
#       bacondecomp (0.1.1), fixest, staggered (1.2.x)
# GitHub only (not on CRAN): pretrends -> devtools::install_github("jonathandroth/pretrends")
library(did); library(HonestDiD); library(fixest)

## ---- 1. Group-time ATTs (Callaway-Sant'Anna) -------------------------------
# base_period = "universal" is REQUIRED for the honest_did sensitivity chain below
# (the helper hard-errors otherwise). control_group states the PT variant you impose:
# "notyettreated" = PT-NYT (default here), "nevertreated" = PT-Nev.
atts <- att_gt(
  yname = YNAME, tname = TNAME, idname = IDNAME, gname = GNAME,
  xformla = XFORMLA, data = df,
  control_group = "notyettreated",
  est_method = "dr",                 # "dr" | "ipw" | "reg"
  clustervars = CLUSTER,
  base_period = "universal"
)
summary(atts)

## ---- 2. Aggregations -------------------------------------------------------
# aggte's default type is "group"; event studies need type = "dynamic" explicitly.
# cband = TRUE gives simultaneous (uniform) bands via multiplier bootstrap.
# +/-15 is AAFP's window for a 41-period panel; set min_e/max_e from your own q and m.
es  <- aggte(atts, type = "dynamic", min_e = -15, max_e = 15, cband = TRUE)
att <- aggte(atts, type = "group")
ggdid(es)
# Composition check: balanced-in-event-time aggregation (units observed over the window)
# balance_e = 5 is a placeholder; set it to the horizon you report.
es_bal <- aggte(atts, type = "dynamic", balance_e = 5, cband = TRUE)

## ---- 3. Honest sensitivity (Rambachan-Roth) --------------------------------
# Run for every event study: this family's own hardening of the canon's best-practice
# endorsement (did/SKILL.md).
# helper source verbatim from the HonestDiD README (github.com/asheshrambachan/HonestDiD,
# "staggered timing" section, fetched 2026-07-28). Requires consecutive event times with
# -1 as the reference period.
honest_did <- function(...) UseMethod("honest_did")

honest_did.AGGTEobj <- function(es,
                                e          = 0,
                                type       = c("smoothness", "relative_magnitude"),
                                gridPoints = 100,
                                ...) {
  type <- match.arg(type)
  if (es$type != "dynamic") stop("need to pass in an event study")
  if (es$DIDparams$base_period != "universal") stop("Use a universal base period for honest_did")
  es_inf_func <- es$inf.function$dynamic.inf.func.e
  n <- nrow(es_inf_func)
  V <- t(es_inf_func) %*% es_inf_func / n / n
  referencePeriod <- -1
  consecutivePre  <- !all(diff(es$egt[es$egt <= referencePeriod]) == 1)
  consecutivePost <- !all(diff(es$egt[es$egt >= referencePeriod]) == 1)
  if (consecutivePre | consecutivePost) {
    stop("honest_did expects a time vector with consecutive time periods;\nplease re-code your event study and interpret the results accordingly.")
  }
  hasReference <- any(es$egt == referencePeriod)
  if (hasReference) {
    referencePeriodIndex <- which(es$egt == referencePeriod)
    V    <- V[-referencePeriodIndex, -referencePeriodIndex]
    beta <- es$att.egt[-referencePeriodIndex]
  } else {
    beta <- es$att.egt
  }
  nperiods <- nrow(V)
  npre     <- sum(1 * (es$egt < referencePeriod))
  npost    <- nperiods - npre
  if (!hasReference & (min(c(npost, npre)) <= 0)) {
    stop(paste0(if (npost <= 0) "not enough post-periods" else "not enough pre-periods",
                " (check your time vector; note honest_did takes -1 as the reference period)"))
  }
  baseVec1 <- basisVector(index = (e + 1), size = npost)
  orig_ci  <- constructOriginalCS(betahat = beta, sigma = V,
                                  numPrePeriods = npre, numPostPeriods = npost,
                                  l_vec = baseVec1)
  if (type == "relative_magnitude") {
    robust_ci <- createSensitivityResults_relativeMagnitudes(
      betahat = beta, sigma = V, numPrePeriods = npre, numPostPeriods = npost,
      l_vec = baseVec1, gridPoints = gridPoints, ...)
  } else if (type == "smoothness") {
    robust_ci <- createSensitivityResults(
      betahat = beta, sigma = V, numPrePeriods = npre, numPostPeriods = npost,
      l_vec = baseVec1, ...)
  }
  list(robust_ci = robust_ci, orig_ci = orig_ci, type = type)
}

# 3a. Relative magnitudes: post violations bounded by Mbar x the largest pre violation.
#     Report the breakdown Mbar at which the conclusion dies, and read it economically.
#     Widen Mbarvec until the breakdown Mbar sits inside the grid; a capped grid cannot
#     locate the breakdown this skill requires reporting.
hd_rm <- honest_did(es, e = 0, type = "relative_magnitude",
                    Mbarvec = seq(0.5, 3, by = 0.5))
createSensitivityPlot_relativeMagnitudes(hd_rm$robust_ci, hd_rm$orig_ci)

# 3b. Smoothness: violations bounded by M deviations from a linear extrapolation of the
#     pre-trend. Binds when the worry is a smoothly evolving confound (secular trend);
#     relative magnitudes binds when the worry is shocks like those seen pre-treatment.
hd_sm <- honest_did(es, e = 0, type = "smoothness",
                    Mvec = seq(0, 0.05, by = 0.01))   # scale M to your outcome units
createSensitivityPlot(hd_sm$robust_ci, hd_sm$orig_ci)

## ---- 4. Pre-test power (pretrends, GitHub) ---------------------------------
# Power of the pre-test against a violation you consider economically relevant.
# beta/sigma extracted from the event study the same way honest_did does.
library(pretrends)
inf  <- es$inf.function$dynamic.inf.func.e
Vall <- t(inf) %*% inf / nrow(inf) / nrow(inf)
keep <- es$egt != -1
sigma_es <- Vall[keep, keep]; beta_es <- es$att.egt[keep]; tVec <- es$egt[keep]
slope50 <- slope_for_power(sigma = sigma_es, targetPower = 0.5,
                           tVec = tVec, referencePeriod = -1)
pt <- pretrends(betahat = beta_es, sigma = sigma_es, tVec = tVec,
                referencePeriod = -1,
                deltatrue = slope50 * (tVec - (-1)))
pt$df_power       # power, Bayes factor, likelihood ratio
pt$event_plot_pretest

## ---- 5. TWFE alongside, and Sun-Abraham cross-check ------------------------
# Post-treatment indicator for the TWFE, bacon, and twowayfeweights calls. Never-treated
# units (GNAME == 0) must stay 0: without the != 0 guard, TNAME >= 0 would mark them
# treated everywhere, the same cohort-recoding trap flagged for sunab below.
df$treat <- as.integer(df[[GNAME]] != 0 & df[[TNAME]] >= df[[GNAME]])
twfe <- feols(as.formula(paste(YNAME, "~ treat |", IDNAME, "+", TNAME)),
              data = df, cluster = df[[CLUSTER]])
# sunab treats any cohort value outside the observed periods as never-treated;
# recode 0 -> 10000 (do NOT feed the did-style 0, it would read as an early cohort).
df$first_treated_sunab <- ifelse(df[[GNAME]] == 0, 10000, df[[GNAME]])
sa <- feols(as.formula(paste(YNAME, "~ sunab(first_treated_sunab,", TNAME, ") |",
                             IDNAME, "+", TNAME)),
            data = df, cluster = df[[CLUSTER]])

## ---- 6. Divergence diagnostics (run when TWFE and CS disagree) -------------
library(bacondecomp)
bd <- bacon(as.formula(paste(YNAME, "~ treat")), data = df,
            id_var = IDNAME, time_var = TNAME)   # weights on each 2x2, incl. forbidden
library(TwoWayFEWeights)
tw <- twowayfeweights(df, YNAME, IDNAME, TNAME, "treat", type = "feTR",
                      summary_measures = TRUE)   # negative weights, sign-reversal stats

## ---- 7. Imputation estimator (PT-all upgrade) ------------------------------
# Only when you will defend parallel pre-trends over the whole panel.
# didimputation codes never-treated as 0 or NA (same as did).
# pretrends = -5:-1 is a placeholder; match your panel.
# Without cluster_var the call clusters on idname, and the SEs stop being comparable to
# the other estimators in this file.
library(didimputation)
imp <- did_imputation(data = df, yname = YNAME, gname = GNAME,
                      tname = TNAME, idname = IDNAME, cluster_var = CLUSTER,
                      horizon = TRUE, pretrends = -5:-1)

## ---- 8. Quasi-random timing (efficient estimator) --------------------------
# staggered codes never-treated as g = Inf.
# eventTime = 0:10 is a placeholder; match your panel.
library(staggered)
df$g_inf <- ifelse(df[[GNAME]] == 0, Inf, df[[GNAME]])
st <- staggered(df = df, i = IDNAME, t = TNAME, g = "g_inf", y = YNAME,
                estimand = "eventstudy", eventTime = 0:10)

## ---- 9. Covariate balance: normalized differences --------------------------
norm_diff <- function(x, treated) {
  (mean(x[treated]) - mean(x[!treated])) /
    sqrt((var(x[treated]) + var(x[!treated])) / 2)
}
# Report for baseline levels and pre-period changes; flag |nd| > 0.25 (0.1 if the
# covariate is known to matter). A change-imbalance reads as a PT violation only if
# the covariate is strictly exogenous.

## ---- 10. Few clusters / few treated (MacKinnon-Nielsen-Webb) ----------------
# Signatures in this section verified 2026-07-29. summclust (0.7.0) and
# fwildclusterboot (0.14.3) are ARCHIVED from CRAN; install from r-universe:
#   install.packages(c("summclust", "fwildclusterboot"),
#                    repos = "https://s3alfisc.r-universe.dev")
# CRAN-resident fallbacks: clubSandwich (CR2 + Satterthwaite, 10c below) and sandwich's
# vcovBS(type = "jackknife"), the CV3-type estimator for linear models, without the
# leverage diagnostics.

# 10a. CV3 (cluster jackknife) with leverage diagnostics on the TWFE fit from section 5.
# Report G, the cluster-size distribution, leverage, partial leverage, and the effective
# number of clusters alongside N, always.
library(summclust)
sc <- summclust(twfe, cluster = CLUSTER, params = "treat", type = "CRV3")
summary(sc)   # CV3 vcov with t(G-1); leverage_g, partial_leverage, beta_jack
plot(sc)
# If some leave-one-cluster-out estimate in beta_jack cannot be computed (the only
# treated cluster was deleted), do not believe the original estimates.

# 10b. Restricted wild cluster bootstrap (WCR: impose_null = TRUE). boottest's fixest
# method takes feols objects only and disallows weights combined with fixed effects.
# Use type = "webb" (6-point weights) when G is small: only 2^G Rademacher draws exist
# (G = 12 gives 4,096), and boottest enumerates them all when B > 2^G. Pick B so
# alpha * (B + 1) is an integer (9999 or 99999).
library(fwildclusterboot)
# boottest has no seed argument. With the default engine = "R" and Rademacher, Webb, or
# Normal weights, reproducibility comes from dqrng's generator, not base R's, so the
# set.seed in CONFIG does not cover these two calls. (Use set.seed instead only for
# engine = "R-lean", Mammen weights, or engine = "WildBootTests.jl".)
dqrng::dqset.seed(94305)
wcr <- boottest(twfe, param = "treat", B = 9999, clustid = CLUSTER,
                type = "rademacher", impose_null = TRUE, bootstrap_type = "fnw11")
wcr           # p-value and CI to set beside the CV1 and CV3 answers
# Plot the bootstrap t-statistic distribution: bimodality is the few-treated failure
# signature (WCR then under-rejects while every CRVE over-rejects).
# Cross-check with the "33" variant (CV3 statistic, jackknife-transformed bootstrap
# scores); it over-rejects less as regressors multiply and cluster sizes diverge.
wcr33 <- boottest(twfe, param = "treat", B = 9999, clustid = CLUSTER,
                  type = "rademacher", impose_null = TRUE, bootstrap_type = "33")
# The same calls run on the Sun-Abraham fit (sa, section 5) with the sunab coefficient
# name as param, for event-study leads and lags.

# 10c. CRAN cross-check: CR2 with Satterthwaite dof (clubSandwich 0.7.0). The dof can
# fall far below G-1; the Imbens-Kolesar variant is inapplicable once cluster FEs are
# absorbed.
# clubSandwich has no fixest method, so this block refits the same TWFE spec as a plain
# lm with factor() fixed effects.
library(clubSandwich)
fml_lm  <- paste0(YNAME, " ~ treat + factor(", IDNAME, ") + factor(", TNAME, ")")
twfe_lm <- lm(as.formula(fml_lm), data = df)
vc2 <- vcovCR(twfe_lm, cluster = df[[CLUSTER]], type = "CR2")
coef_test(twfe_lm, vcov = vc2, test = "Satterthwaite")

# 10d. Few treated (or control) clusters: CV1/CV2 standard errors can be too small by a
# factor of five or more at G1 = 1; CV3 over-rejects less but still fails when G1 is
# very small; WCR fails the other way (under-rejection, essentially zero at G1 = 1).
# Rescues, in order: the ordinary wild restricted (WR, observation-level weights)
# bootstrap; randomization inference; the synthetic-control handoff for one or very few
# treated. No R package implements MacKinnon-Webb RI-t; hand-roll it (about 20 lines):
#   1. enumerate the C(G, G1) assignments of which clusters are treated, or draw
#      B = 99999 re-randomizations without replacement when enumeration is infeasible
#      (B picked so alpha * (B + 1) is an integer, the same rule as in 10b);
#   2. re-estimate and compute the cluster-robust t statistic under each assignment;
#   3. the p-value counts the actual assignment among those at least as extreme (the
#      P*_2 convention).
# RI needs timing as good as random and treated clusters not systematically different.
# Under cluster-size heterogeneity RI-t degrades less than RI-beta, so RI-t is the
# default.

## ---- Session ---------------------------------------------------------------
# Pin versions in the replication package: did >= 2.5, HonestDiD 0.2.8. did 2.5
# defaults faster_mode = TRUE and aggte's default type is "group", both changed
# from the 2.1.x tutorials. summclust 0.7.0 and fwildclusterboot 0.14.3 come from
# r-universe, not CRAN; record the repo in the replication package.
sessionInfo()
