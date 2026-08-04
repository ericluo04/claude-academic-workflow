# Synthetic-control analysis template. Runnable end to end; every call signature verified
# against package documentation on 2026-07-28 (tidysynth 0.2.1, Synth 1.1-10, SCtools 0.3.3.1,
# scpi 4.0.1, pensynth 0.8.2, gsynth 1.4.0, fect 2.4.5, CausalImpact 1.4.1, all CRAN;
# synthdid 0.0.9, augsynth 0.2.0, scinference 0.0.0.9000 from GitHub, not on CRAN).
# Adapt the CONFIG block and run section by section.
#
# API traps older tutorials get wrong:
#   - tidysynth ipop tuning args are snake_case (margin_ipop/sigf_ipop/bound_ipop); the
#     package's OWN examples use Margin.ipop etc., which fall into ... and are SILENTLY
#     IGNORED (defaults run instead). Synth uses the dot-case names; opposite conventions.
#   - augsynth's current signature is augsynth(form, unit, time, data, t_int = NULL); the
#     repo README still shows the old positional order. Pass data= and t_int= by name.
#   - synthdid: with a single treated unit, vcov method = "placebo" is the only valid one.
#   - gsynth's estimator default is now "gsynth"; estimator = "ife" means IFE-with-EM.
#   - fect flags are camelCase (placeboTest) but their periods dot-case (placebo.period).
#   - scpi's w.constr is a list (list(name = "simplex")), solver default is CLARABEL.

## ---- CONFIG ----------------------------------------------------------------
df <- your_panel             # long panel: unit, year, y, covariates; balanced
TREATED <- "California"      # treated unit
T0      <- 1988              # last pre-treatment period (i_time = intervention year)
PRE     <- 1970:1988         # pre-period window
set.seed(94305)

## ---- 1. Feasibility gate, before any estimation ------------------------------
# Plot the treated unit against the raw donor mean over the full pre-period. If the
# donor mean tracks the treated unit, did may suffice; if it diverges pre-treatment,
# SC territory. Also check: co-movement, effect size vs outcome volatility, donor
# count (p floor is 1/(J+1)), anticipation (shift T0 to announcement if needed).
# Donor discipline: drop donors with their own interventions, big idiosyncratic
# shocks, or spillover exposure BEFORE fitting, and record why.

## ---- 2. Canonical SC (tidysynth) --------------------------------------------
library(tidysynth)
out <- df |>
  synthetic_control(outcome = y, unit = unit, time = year,
                    i_unit = TREATED, i_time = T0,
                    generate_placebos = TRUE) |>
  generate_predictor(time_window = PRE,
                     income  = mean(income,  na.rm = TRUE),
                     price   = mean(price,   na.rm = TRUE)) |>
  generate_predictor(time_window = 1975, y_1975 = y) |>   # lagged-outcome predictors
  # ipop values copied from the tidysynth worked example, not a recommendation;
  # the optimizer defaults are usually fine.
  generate_weights(optimization_window = PRE,
                   margin_ipop = .02, sigf_ipop = 7, bound_ipop = 6) |>  # snake_case!
  generate_control()
# The entry gate: pre-period fit table and trajectory plot. Visible gaps = stop
# (tighten pool, change predictors/transformation, bias-correct, or move to SDID).
out |> grab_balance_table()
out |> plot_trends(time_window = 1970:2000)
out |> grab_unit_weights()          # name the donors; sparsity is a feature
out |> grab_predictor_weights()     # V; show robustness to reasonable alternatives

## ---- 3. Permutation inference (in-space placebos) ----------------------------
out |> plot_placebos()              # prune = TRUE drops placebos with pre-RMSPE > 2x treated
out |> plot_placebos(prune = FALSE) # report the unpruned spaghetti too
out |> plot_mspe_ratio()
out |> grab_significance()          # post/pre MSPE ratio, rank, fishers_exact_pvalue
# The p floor is 1/(J+1): with fewer than 20 donors, p < .05 is unreachable; say so
# and lean on magnitude plus the placebo distribution. One-sided variants (positive
# or negative parts of the gaps) add power in small pools; compute from
# grab_synthetic_control(placebo = TRUE) if needed.

## ---- 4. In-time placebo (backdating) -----------------------------------------
# Re-run with the intervention moved back and post-T0 data EXCLUDED. Pass = no gap
# opens in the fake post-period AND the real gap still opens at T0. A pre-gap
# estimates the bias's size and direction. Caveat: assumes strict exogeneity;
# misleading under selection on recent shocks (Arkhangelsky-Hirshberg).
back <- df |> dplyr::filter(year <= T0) |>
  synthetic_control(outcome = y, unit = unit, time = year,
                    i_unit = TREATED, i_time = 1980, generate_placebos = FALSE) |>
  generate_predictor(time_window = 1970:1980,
                     income = mean(income, na.rm = TRUE)) |>
  generate_weights(optimization_window = 1970:1980) |>
  generate_control()
back |> plot_trends()

## ---- 5. Leave-one-out on positive-weight donors ------------------------------
w <- out |> grab_unit_weights()
# > 0.01 is a materiality floor, not a numerical-zero guard: it drops donors whose weight is
# genuinely positive but under 1%. Use > 0 when the donor pool is small or the weights are
# spread thin, since a 0.5% donor is then still worth leaving out.
for (dnr in w$unit[w$weight > 0.01]) {
  loo <- df |> dplyr::filter(unit != dnr) |>
    synthetic_control(outcome = y, unit = unit, time = year,
                      i_unit = TREATED, i_time = T0, generate_placebos = FALSE) |>
    generate_predictor(time_window = PRE, income = mean(income, na.rm = TRUE)) |>
    generate_weights(optimization_window = PRE) |>
    generate_control()
  # collect and overlay the counterfactuals; the conclusion must not hinge on one donor
}
# Same refit pattern for predictor-set, V, and tightened-donor-pool robustness.

## ---- 6. Classic route (Synth + SCtools), if a coauthor wants it --------------
# library(Synth); library(SCtools)
# dp  <- dataprep(foo = as.data.frame(df), predictors = c("income", "price"),
#                 special.predictors = list(list("y", 1975, "mean")),
#                 dependent = "y", unit.variable = "unit_num",       # must be numeric
#                 unit.names.variable = "unit", time.variable = "year",
#                 treatment.identifier = 3, controls.identifier = c(1:2, 4:39),
#                 time.predictors.prior = PRE, time.optimize.ssr = PRE,
#                 time.plot = 1970:2000)                             # extend past T0!
# fit <- synth(data.prep.obj = dp)          # dot-case Margin.ipop HERE (not tidysynth)
# synth.tab(synth.res = fit, dataprep.res = dp)
# tdf <- generate.placebos(dp, fit, strategy = "multisession")       # not "multiprocess"
# plot_placebos(tdf); mspe.test(tdf)$p.val

## ---- 7. Synthetic DiD (level gaps, stable-bias assumption) -------------------
# devtools::install_github("synth-inference/synthdid")   # not on CRAN
library(synthdid)
panel <- as.data.frame(df[, c("unit", "year", "y", "treated")])
setup <- panel.matrices(panel, unit = "unit", time = "year",
                        outcome = "y", treatment = "treated")   # names, not positions
tau_sdid <- synthdid_estimate(setup$Y, setup$N0, setup$T0)
sqrt(vcov(tau_sdid, method = "placebo"))    # single treated unit: placebo is the ONLY option
plot(tau_sdid); synthdid_units_plot(tau_sdid)
# The SC-DID-SDID trio on one panel is itself a diagnostic (divergence = the
# additive or convex restriction is doing work):
tau_sc  <- sc_estimate(setup$Y, setup$N0, setup$T0)
tau_did <- did_estimate(setup$Y, setup$N0, setup$T0)
# Requires block adoption on a balanced panel; staggered adoption -> multisynth/fect.

## ---- 8. Augmented SC (imperfect fit that must stay in) -----------------------
# devtools::install_github("ebenmichael/augsynth")       # not on CRAN
library(augsynth)
asyn <- augsynth(y ~ treated, unit = unit, time = year, data = df,
                 progfunc = "ridge", scm = TRUE)   # t_int inferred; pass by name if set
summary(asyn)                                      # conformal inference by default
plot(asyn)
# Report raw SC and augmented side by side; a large augmentation term means the
# convex weights alone could not match, which is information, not decoration.
# Staggered many-treated: multisynth(y ~ treated, unit = unit, time = year,
#                                    data = df, n_leads = 10); plot(msyn, levels = "Average")
# Disaggregated units / penalized SC: pensynth::cv_pensynth(X1, X0, Z1, Z0)
# (units in COLUMNS, Synth orientation; Z1/Z0 hold-out outcomes required).

## ---- 9. Factor-model / matrix-completion robustness (fect) -------------------
library(fect)
# nboots = 200 in both calls is a quick-run value; raise to 2000 or more for publication.
# r = c(0, 5) is the CV search range for the number of latent factors, min then max. 5 is
# fect's own default ceiling, so this is not a reduced quick-run setting. Read fout$r.cv
# afterwards: if the selected count comes back at 5 the ceiling bound the search, so raise
# the max and refit.
fout <- fect(y ~ treated + income, data = df, index = c("unit", "year"),
             method = "ife", CV = TRUE, r = c(0, 5),
             se = TRUE, vartype = "bootstrap", nboots = 200)
plot(fout, type = "gap")
fect(y ~ treated + income, data = df, index = c("unit", "year"),
     method = "mc", CV = TRUE, se = TRUE, nboots = 200)   # nuclear-norm route
# Built-in falsification: placeboTest = TRUE, placebo.period = c(-2, 0);
# carryoverTest = TRUE, carryover.period = c(1, 2). (camelCase flag, dot-case period)
# fect method = "gsynth" reproduces gsynth (Xu 2017) inside fect; standalone gsynth
# 1.4.0 remains fine, but note its force default is "unit" vs fect's "two-way".

## ---- 10. Prediction intervals (scpi) -----------------------------------------
library(scpi)
sd_ <- scdata(df = as.data.frame(df), id.var = "unit", time.var = "year",
              outcome.var = "y", period.pre = PRE, period.post = 1989:2000,
              unit.tr = TREATED, unit.co = setdiff(unique(df$unit), TREATED))
est <- scest(sd_, w.constr = list(name = "simplex"))     # list, not a string
# sims = 200 is a quick-run value; raise to 2000 or more for publication.
pin <- scpi(sd_, w.constr = list(name = "simplex"), sims = 200,
            e.method = "gaussian", u.missp = TRUE)
scplot(pin)
# Conformal alternative (Chernozhukov-Wuthrich-Zhu):
# devtools::install_github("kwuthrich/scinference")  # research code, pin the commit
# scinference(Y1, Y0, T1 = 12, T0 = length(PRE),
#             inference_method = "conformal", estimation_method = "sc")  # underscores;
# default alpha is 0.10, and CIs need an explicit ci_grid.

## ---- 11. CausalImpact, as comparison point only ------------------------------
# BSTS counterfactual from the treated unit's own series plus covariates; no donor
# weights, so this skill's donor discipline does not apply, and covariates must be
# unaffected by the intervention. Response must be the FIRST column.
# library(CausalImpact); library(zoo)
# ci <- CausalImpact(zoo(cbind(y_treated, x1, x2), years),
#                    pre.period = c(1970, 1988), post.period = c(1989, 2000))
# plot(ci); summary(ci, "report")

## ---- Session ----------------------------------------------------------------
# Pin: tidysynth 0.2.1 (snake_case ipop args), synthdid 0.0.9 @ 70c1ce3, augsynth
# 0.2.0 @ 7a90ea4 (t_int after data), scinference @ 567c688, fect >= 2.4.5 (no
# bspline; camelCase test flags), gsynth >= 1.4.0 (estimator default "gsynth"),
# scpi >= 4.0.1 (CLARABEL, list-valued w.constr).
sessionInfo()
