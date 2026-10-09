# Conjoint template: the randomized-experiment pipeline plus the HB and WTP blocks.
# Ran on 2026-10-09 (R 4.6.1; projoint 1.1.4, estimatr 2.0.0, ashr 2.2.63, bayesm 3.1.7,
# posterior 1.7.0, bayesplot 1.16.0) on 300 simulated respondents with a flipped repeat
# task: the live code of sections 1-6, the make_projoint_data lines of section 2, and
# sections 8 and 9's bayesm lines uncommented (R 2000 per chain, plain and sign-constrained
# priors). Not run on 2026-10-09: cjoint (section 1), factorEx (7), FindIt (7b),
# CRTConjoint (6), and logitr (9). Package versions and pins live in one place:
# ../references/details.md, "Package index". Adapt CONFIG and run section by section.
#
# API traps verified against docs/source:
#   - projoint: EVERY argument is dot-prefixed (.data, .irr, .estimand). Subgroup trap:
#     .by_var is honored only with .structure = "profile_level" (ignored at choice
#     level); choice-level subgroup comparisons run projoint separately per group with
#     group-specific tau. The repeated task's outcome goes LAST in .outcomes, and
#     .flipped = TRUE means the repeat showed the profiles in reversed columns.
#   - cjoint::amce: cluster = TRUE alone does nothing useful; pass BOTH
#     cluster = TRUE and respondent.id = "<id column>".
#   - factorEx::model_pAMCE: target_type is "marginal" or "target_data" only
#     (partial_joint exists only in design_pAMCE); ord_fac has no default, pass it.
#   - ashr: input is estimates + SEs (any estimator); accessors get_pm/get_psd/get_lfsr.
#   - CRTConjoint: design = "Uniform" is capitalized; the default seed is RANDOM, set it.
#   - bayesm sign constraints: any nonzero SignRes silently switches every prior
#     default, and the shipped constrained V contradicts the man page AND vignette;
#     pass the FULL Prior explicitly (see section 8).
#   - logitr: WTP space is switched by scalePar = "price" (modelSpace/price/randPrice
#     are the deprecated pre-0.7.0 interface; do not use them).
#   - FindIt::CausalANOVA: vcov and CI.table come back ONLY when screen and collapse are
#     both FALSE; with either TRUE the intervals must come from test.CausalANOVA on a
#     held-out half. AME/AMIE2 are baselined at the GRAND MEAN, not a level. The FindIt
#     manual writes "select=FALSE and collapse=FALSE"; CausalANOVA has no `select`
#     argument, and the manual means `screen`.

library(estimatr)
library(projoint)
library(ashr)
# library(factorEx)     # section 7
# library(CRTConjoint)  # section 6
# library(bayesm)       # section 8
# library(posterior)    # section 8, convergence diagnostics
# library(bayesplot)    # section 8, rank plots
# library(logitr)       # section 9

## ---- CONFIG ----------------------------------------------------------------------------
## df: LONG, one row per respondent-task-profile (the display format), with:
##   id        respondent id (clustering unit)
##   task      task number 1..K (the repeated final task, if fielded, flagged in `rep`)
##   profile   1 or 2 (left/right)
##   y         1 if this profile was chosen in the task, else 0
##   A1..AL    the attributes, as factors with the reference level set first
## The hand-rolled sections (1, 5, 6) run on this profile-stacked HHY structure with
## respondent-clustered SEs (valid; it is the estimator HHY themselves use). The skill's
## default for choice modeling stays choice-level (one row per respondent-task), which
## projoint reshapes to internally. Qualtrics exports skip df entirely:
## read_Qualtrics() + reshape_projoint().

## ---- 1. AMCEs and MMs by hand (uniform independent randomization) ----------------------
# One regression, all AMCEs; respondent-clustered SEs are mandatory (within-task
# outcomes mechanically negatively correlated, within-respondent positively).
# The repeat duplicates task 1: estimation and the F-tests drop it (only IRR uses it).
df_est <- df[!df$rep, ]
amce_fit <- lm_robust(y ~ A1 + A2 + A3, data = df_est, clusters = id)  # se_type CR2 default
summary(amce_fit)
# Marginal means, the reporting primitive: per attribute, mean outcome at each level.
mm_A1 <- lm_robust(y ~ 0 + A1, data = df_est, clusters = id)  # MMs with clustered SEs
# RESTRICTED or WEIGHTED randomization: plain dummies silently change the estimand.
# Include the linked interactions and report the probability-weighted combination over
# admissible strata (HHY eq. 9; ../references/details.md). The packaged route:
# cjoint::amce(y ~ A1 + A2 + A3, data = df_wide, design = my_design,
#              cluster = TRUE, respondent.id = "id")   # design from makeDesign()

## ---- 2. Measurement error: IRR and the tau correction (projoint) -----------------------
# Design route: the final task repeated task 1 with columns flipped. From Qualtrics:
#   raw <- read_Qualtrics("export.csv")
#   pj  <- reshape_projoint(raw, .outcomes = c(paste0("choice", 1:K), "choice_rep"),
#                           .repeated = TRUE, .flipped = TRUE)   # repeat outcome LAST
# Long non-Qualtrics data (the CONFIG df): projoint wants the repeated choice on the rows
# of task 1, as y_rep, in task 1's profile numbering. With flipped columns, the repeat's
# profile 2 showed task 1's profile 1, hence 3 - profile:
# df_pj <- df[!df$rep, ]; r <- df[df$rep, ]; t1 <- df_pj$task == 1
# df_pj$y_rep <- NA
# df_pj$y_rep[t1] <- r$y[match(paste(df_pj$id, 3 - df_pj$profile)[t1],
#                              paste(r$id, r$profile))]
# pj <- make_projoint_data(df_pj, .attribute_vars = c("A1", "A2", "A3"),
#                          .selected_var = "y", .selected_repeated_var = "y_rep")
# Choice level (the skill's default) estimates ONE contrast per call: build a set_qoi()
# object for each contrast the paper reports. projoint renames attributes and levels;
# read the ids from pj$labels and pass levels WITHOUT the "attN:" prefix ("level2").
q_mm <- set_qoi(.structure = "choice_level", .estimand = "mm",   # P(choose level2
                .att_choose = "att1", .lev_choose = "level2",    #   when paired with
                .att_notchoose = "att1", .lev_notchoose = "level1")  # level1)
q_amce <- set_qoi(.structure = "choice_level", .estimand = "amce",
                  .att_choose = "att1", .lev_choose = "level3",      # level3 over level1
                  .att_notchoose = "att1", .lev_notchoose = "level1",
                  .att_choose_b = "att1", .lev_choose_b = "level2",  # minus the baseline
                  .att_notchoose_b = "att1", .lev_notchoose_b = "level1")  # level2 over level1
out_mm   <- projoint(pj, q_mm)      # tau estimated from the repeated task
out_amce <- projoint(pj, q_amce)
summary(out_mm); plot(out_mm, .estimates = "corrected")
# The all-levels MM plot runs at PROFILE level, the only structure that sweeps every
# attribute without a .qoi. Say so in the figure note.
out_all <- projoint(pj, .structure = "profile_level", .estimand = "mm")
plot(out_all, .estimates = "both")
# Existing data with NO repeated task: extrapolate tau from task-pair agreement.
tau_hat <- predict_tau(pj)      # $irr row x = 0 is the extrapolated IRR; $figure the fit
out_mm2 <- projoint(pj, q_mm, .irr = tau_hat$irr$predicted[tau_hat$irr$x == 0])
# Report corrected AND uncorrected. Correction is for binary forced choice ONLY.
# Uncertainty in tau: .se_method = "analytical" (default) / "simulation" / "bootstrap".

## ---- 3. Multiple testing (never report an uncorrected forest of stars) -----------------
est <- amce_fit$coefficients[-1]                 # drop the intercept
se  <- amce_fit$std.error[-1]
a   <- ash(est, se, mixcompdist = "normal")      # adaptive shrinkage; preregister family
# mixcompdist "normal": symmetric unimodal shrinkage is the sensible default for AMCE
# effects, and Liu and Shiraito found results insensitive to this choice.
cbind(raw = est, shrunk = get_pm(a), psd = get_psd(a), lfsr = get_lfsr(a))
# Exploratory alternative: p.adjust(p, "BH") at FDR .05. Confirmatory: p.adjust(p, "holm")
# with the preregistered family m. Corrected + uncorrected side by side.
# NEVER "bonferroni": "holm" is a drop-in that rejects everything Bonferroni rejects and
# sometimes more, under the same assumptions. And "BH", not the adaptive BKY variant: AMCEs
# share respondents, which BH's PRDS condition covers and BKY's does not.
# Composing ash with tau-corrected estimates is mechanically fine but unstudied in the
# canon; label the combination as our own judgment.

## ---- 4. The bounds gate for any proportion claim ---------------------------------------
akm_bounds <- function(pi, K, tau) {             # Abramson et al. 2022 Prop 2; assumes
  den <- K * (tau - 1) + tau                     # separable feature preferences
  c(lo = max((pi * tau * K + tau) / den, 0),
    hi = min((pi * tau * K + K * (tau - 1)) / den, 1))
}
# "A majority prefers t1" ships only if lo > 0.5. Screens: binary attribute at large K
# needs AMCE > 0.25. Run on the tau-CORRECTED AMCE (correction first, then bounds).

## ---- 5. Subgroups: conditional MMs, omnibus F, subgroup-specific tau -------------------
# NEVER difference conditional AMCEs for preference claims (reference-category artifact).
mm_g <- lm_robust(y ~ 0 + A1:group, data = df_est, clusters = id)   # conditional MMs
# Omnibus "groups agree overall": cluster-robust Wald test that all group-by-level
# interactions are zero (restricted vs unrestricted fit).
f1 <- lm_robust(y ~ A1 + A2 + A3, data = df_est, clusters = id)
f2 <- lm_robust(y ~ (A1 + A2 + A3) * group, data = df_est, clusters = id)
# Compare via a Wald test on f2's interaction block (car::linearHypothesis on the
# interaction coefficient names, or refit with lm + lmtest::waldtest, vcovCL).
# Measurement error: tau varies by respondent characteristics, so estimate IRR and
# correct WITHIN each subgroup before differencing (separate projoint runs per group at
# choice level; .by_var works only at profile level). ~5% of subgroup differences
# flipped sign under correction in the replications.

## ---- 6. Diagnostics battery ------------------------------------------------------------
# Carryover: AMCEs by task number + F-test (expect a small task-1 drop, then flat).
ct <- lm_robust(y ~ A1 * factor(task), data = df_est, clusters = id)
# Profile order: y ~ A1 * factor(profile). Balance: respondent covariate ~ all attribute
# dummies, omnibus F. Row order (if randomized): row-specific AMCEs + F.
# Satisficing share: proportion of respondents choosing the same side / accepting all.
# Sharp modern carryover test (optional; hiernet is slow):
# CRT_carryovereffect(y ~ A1 + A2 + A3, data = df_wide, left = left_cols,
#                     right = right_cols, task = "task", design = "Uniform",
#                     B = 200, seed = 42)$p_val    # set seed: the default is random
# B = 200 keeps the CRT cheap but the p-value coarse; raise B when p lands near the
# threshold.

## ---- 7. pAMCE under a target profile distribution (factorEx) ---------------------------
# target_dist: named list of per-factor marginals (names = the data's levels). EVERY
# factor in the formula needs one (model_pAMCE stops otherwise); give a factor you do not
# retarget its design marginal.
# target_dist <- list(A1 = c(lev1 = .70, lev2 = .30), A2 = c(a = .1, b = .5, c = .4),
#                     A3 = c(x = .5, y = .5))
# fit_p <- model_pAMCE(y ~ A1 + A2 + A3, data = df_choice, ord_fac = rep(FALSE, 3),
#                      cluster_id = df_choice$id, target_dist = target_dist,
#                      target_type = "marginal", reg = TRUE, boot = 2000, seed = 42)
# summary(fit_p)
# decompose_pAMCE(fit_p, effect_name = c("A1", "lev2"))   # c(factor, level); required
# # Without target_diff it compares the target with the in-sample (uniform design)
# # distribution, which is where the uAMCE-pAMCE gap comes from.
# Design-based route (target enters the randomization): design_pAMCE(..., target_type =
# "partial_joint", partial_joint_name = list(c("A1","A2"), "A3")). Run the ESS check
# before fielding (../references/details.md).

## ---- 7b. Causal interaction: AMEs and AMIEs (FindIt) -----------------------------------
# The estimand behind section 7's gap. Do NOT read a dummy-coded interaction coefficient as
# the causal interaction: its relative magnitude depends on the baseline level, and any
# interaction involving a baseline level is mechanically zero.
# library(FindIt)
# Declare level order FIRST; it decides which merges the collapse step may make.
# df_choice$A1 <- factor(df_choice$A1, ordered = TRUE, levels = c("low","mid","high"))
# df_choice$A2 <- factor(df_choice$A2, ordered = FALSE, levels = c("x","y"))
#
# No regularization: full-sample AMEs and two-way AMIEs with ordinary intervals.
# fit_i <- CausalANOVA(y ~ A1 + A2 + A3, int2.formula = ~ A1:A2, data = df_choice,
#                      nway = 2, diff = TRUE, pair.id = df_choice$pair_id,
#                      cluster = df_choice$id, screen = FALSE, collapse = FALSE)
# summary(fit_i)                                   # vcov + CI.table only in this mode
# ConditionalEffect(fit_i, treat.fac = "A1", cond.fac = "A2")   # = AME + AMIE
#
# Regularized, when the design is large (>~6 factors to screen, >~6 levels to collapse).
# Post-collapsing inference is unsolved, so SPLIT: regularize on half, estimate on the rest.
# tr <- sample(unique(df_choice$id), length(unique(df_choice$id)) %/% 2)
# d_tr <- df_choice[df_choice$id %in% tr, ]; d_te <- df_choice[!df_choice$id %in% tr, ]
# fit_r <- CausalANOVA(y ~ A1 + A2 + A3, data = d_tr, nway = 2, diff = TRUE,
#                      pair.id = d_tr$pair_id, cluster = d_tr$id,
#                      screen = TRUE, collapse = TRUE)
# fit_t <- test.CausalANOVA(fit_r, newdata = d_te, diff = TRUE,
#                           pair.id = d_te$pair_id, cluster = d_te$id)
# summary(fit_t); plot(fit_t, type = "ConditionalEffect", fac.name = c("A1","A2"))
# Without a split, report selection probabilities instead of intervals and say FWER is not
# controlled: select.prob = TRUE, boot = 5000 (docs disagree on the default, pass it).
# Traps: AME/AMIE2 are reported against the GRAND MEAN, so they will not match section 1's
# dummy coefficients; nway = 3 requires every pair inside a three-way term to appear in
# int2.formula (strong hierarchy); screen = TRUE delegates to glinternet, which regularizes
# coefficients rather than their differences, so the baseline-invariance argument covers the
# collapse and estimation stages only.

## ---- 8. The HB block (preference-measurement track; bayesm) ----------------------------
# lgtdata: list of per-respondent lists; y in 1..p; X of (n_i * p) x nvar rows via
# createX; "none" option = all-zero row; price in ~unit scale (hundreds/thousands).
# data_hb  <- list(lgtdata = lgtdata, p = p)     # + Z = centered covariates, no intercept
# prior_hb <- list(ncomp = 1)
# ## Sign-constrained price (LAST column): pass the FULL prior, the shipped defaults
# ## contradict their own documentation (vignette values shown):
# # nvar <- ncol(lgtdata[[1]]$X)
# # prior_hb <- list(ncomp = 1, SignRes = c(rep(0, nvar - 1), -1),
# #                  mubar = c(rep(0, nvar - 1), 2), Amu = 0.1, nu = nvar + 15,
# #                  V = (nvar + 15) * diag(c(rep(4, nvar - 1), 0.1)))
# mcmc_hb <- list(R = 50000, keep = 10, nprint = 1000)  # man page: "Large R values may
#                                                        # be required (>20,000)"
# Convergence (Vehtari, Gelman, Simpson, Carpenter, and Buerkner 2021): four chains,
# split rank-normalized R-hat < 1.01 and bulk and tail ESS > 400 for EVERY parameter,
# rank plots in place of trace plots. bayesm runs one chain per call, so run four
# seeded calls and diagnose them jointly. bayesm's 10% burn-in is a convention. Discard
# the first half as warm-up and let R-hat and the rank plots judge it. bayesm starts every
# chain at the same values (each respondent's fractional-likelihood estimate), so the seeds
# differ only in the Metropolis path, and R-hat is weaker than from overdispersed starts.
# runs <- lapply(1:4, function(s) {
#   set.seed(s)
#   rhierMnlRwMixture(Data = data_hb, Prior = prior_hb, Mcmc = mcmc_hb)
# })
# ndraw <- dim(runs[[1]]$betadraw)[3]; keep_it <- (floor(ndraw / 2) + 1):ndraw
# nlgt <- dim(runs[[1]]$betadraw)[1]; nvar <- dim(runs[[1]]$betadraw)[2]
# # betadraw is nlgt x nvar x draws; stack into iterations x chains x variables.
# arr <- simplify2array(lapply(runs, function(r)
#   matrix(aperm(r$betadraw[, , keep_it, drop = FALSE], c(3, 1, 2)),
#          nrow = length(keep_it))))                        # iter x variables x chains
# arr <- aperm(arr, c(1, 3, 2))                             # iter x chains x variables
# dimnames(arr) <- list(NULL, NULL,
#   paste0("beta[", rep(seq_len(nlgt), nvar), ",", rep(seq_len(nvar), each = nlgt), "]"))
# stopifnot(dim(arr)[2] == 4)          # chains on dimension 2, or the diagnostics lie
# dr <- posterior::as_draws_array(arr)
# diag_hb <- posterior::summarise_draws(dr, "rhat", "ess_bulk", "ess_tail")
# ok <- with(diag_hb, rhat < 1.01 & ess_bulk > 400 & ess_tail > 400)
# bad <- diag_hb[is.na(ok) | !ok, ]    # an NA R-hat or ESS counts as a failure
# nrow(bad)    # must be 0; otherwise raise R and rerun all four chains
# bayesplot::mcmc_rank_overlay(dr, pars = head(diag_hb$variable[order(-diag_hb$rhat)], 6))
# Report the max R-hat and min bulk and tail ESS in the methods paragraph.
# partworths <- matrix(apply(arr, 3, mean), nlgt, nvar)   # pooled post-warm-up draws
# Report QUANTILES, not just posterior means and sds (the authors' explicit instruction).
# Mixture components are label-switched across draws, so diagnose the implied population
# moments, never the component draws. Use the same half warm-up as the betadraw:
# summary(runs[[1]]$nmix, burnin = floor(ndraw / 2))   # mixture-implied population moments

## ---- 9. WTP space (when WTP or prices are the deliverable) -----------------------------
# The Sonnier rule: put the heterogeneity prior on WTP directly; never feed a
# partworth-space posterior into a price optimizer; validate on holdout LPD, never
# in-sample LMD/DIC.
# HB route (Bayesian, stays on the section 8 posterior): WTP from preference space,
# computed draw by draw, never as a ratio of posterior means. A partworth over a price
# coefficient with density at zero (normal or a normal mixture) has no finite mean or
# variance (Daly, Hess, and Train 2012), so sign-constrain price (lognormal) and report
# posterior QUANTILES. With price in column nvar, constrained negative:
# wtp_draws <- -runs[[1]]$betadraw[, k, keep_it] / runs[[1]]$betadraw[, nvar, keep_it]
# wtp_q <- t(apply(wtp_draws, 1, quantile, c(.05, .5, .95)))   # per respondent
# (Pool all four chains the same way before reporting.)
# ML route: logitr is MAXIMUM LIKELIHOOD (simulated), not Bayesian. It fits the WTP-space
# mixed logit directly; randScale = "ln" makes the scale lognormal, which is Sonnier's
# surplus model, (x'beta_i - p) / mu_i with log mu_i normal.
# wtp_fit <- logitr(data = df_choice, outcome = "y", obsID = "obs", panelID = "id",
#                   pars = c("A1", "A2", "A3"), scalePar = "price",   # WTP space
#                   randPars = c(A1 = "n", A2 = "n", A3 = "n"),       # mixed logit
#                   randScale = "ln", numMultiStarts = 10)
# numMultiStarts = 10: mixed-logit likelihoods are multimodal; 10 starts balance
# local-optimum risk against runtime, raise for publication runs.
# scalePar = NULL gives preference space for the comparison. Holdout: one randomly
# selected middle task per respondent, never task 1 (it seeds the repeat) and never the
# final task (the design puts the flipped repeat of task 1 in the last slot, so it
# duplicates task 1's information); compare on holdout log predictive density.

## ---- Session ---------------------------------------------------------------------------
# Pins: ../references/details.md, "Package index". Record sessionInfo with every run
# (defaults changed across bayesm releases; the record makes the priors auditable).
sessionInfo()
