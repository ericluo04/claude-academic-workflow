# Synthetic-control lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-28.

## The factor model and the bias bound

Outcomes follow a linear factor model Y_jt = delta_t + theta_t Z_j + lambda_t mu_j + eps_jt.
DiD is the special case lambda_t = lambda (constant loadings); SC lets unobserved-factor
coefficients vary over time, which is why it survives visibly non-parallel pre-trends. Under
the factor model and perfect predictor fit (X1 = X0 W*), the bias of the SC effect estimate is
controlled by the ratio of the transitory-shock scale to T0, and it INCREASES with donor-pool
size J and with the number of unobserved factors. Consequences the skill states as rules: poor
fit is disqualifying (the bound assumes fit away), long T0 does not rescue bad fit, and short
T0 or noisy outcomes plus a big pool invite overfitting on transitory shocks. Excluded
covariates get absorbed into mu_j and raise the bound, which is why pre-outcomes-only predictor
sets are banned.

## The unified imputation view (routing logic)

SC is a "vertical regression" (treated unit's pre-period outcomes on control units' outcomes,
weights nonnegative summing to one); unconfoundedness-on-lagged-outcomes is the "horizontal
regression"; without constraints the two imputations coincide. DiD, SC, unconfoundedness, and
nuclear-norm matrix completion all minimize one fit-a-low-rank-plus-fixed-effects objective
under different restrictions (DiD: rank 0; SC: convex unit weights; MC-NNM: cross-validated
nuclear-norm penalty). Divergence among them is a specification diagnostic. The sharpest
routing result: under selection on lagged outcomes with autocorrelated errors, DiD is
inconsistent even as T0 grows while SC is consistent and asymptotically unbiased.

## V and predictor mechanics

- V default ladder: inverse-variance rescaling (simple), pre-period MSPE minimization
  (better), training/validation split of the pre-period with out-of-sample fit (best).
- Cross-validated V is not always unique (Klossner et al.); show stability across reasonable
  V choices.
- Fewer predictor rows give sparser weights. A single pre-period outcome average sufficed for
  reunification only because OECD GDP co-moves strongly; that is the exception.
- Sparsity fact: when X1 lies outside the convex hull of X0 with columns in general position,
  at most k donors get positive weight; the weights are nameable and should be named.
- Outcome transformations when levels cannot be matched: differences, growth rates,
  deviations from pre-intervention means (Ferman-Pinto). Each moves SC toward DiD logic and
  inflates the noise share of variance; matching changes alone is not credible when the level
  itself drives dynamics (growth convergence, life-cycle earnings, baseline-dependent sales).

## Inference details

- RMSPE ratio: r_j = post-period RMSPE / pre-period RMSPE per unit j; p = (1/(J+1)) sum
  I{r_j >= r_1}. Alternative: drop placebos with pre-RMSPE far above the treated unit's and
  compare post-RMSPEs directly. One-sided statistics (positive or negative parts of the gaps)
  add power in small pools.
- The p floor is 1/(J+1). With 12 donors the best attainable p is 0.077; say so instead of
  hunting significance.
- Design-based framing: the permutation distribution conditions on the sample and benchmarks
  extremeness against uniform assignment; it is exact randomization inference only if
  treatment were actually randomized. Firpo-Possebom: sensitivity analysis to non-uniform
  assignment and test-inversion confidence sets.
- Model-based complements: conformal inference (Chernozhukov-Wuthrich-Zhu; exchangeability of
  residuals under the null, a different maintained assumption than the factor model, per the
  Ferman-Pinto caveat that E[u_t Y_jt] = 0 generally fails), and scpi prediction intervals
  that decompose uncertainty into weight estimation and post-period shocks.
- SDID variance: placebo, jackknife, or bootstrap estimators; placebo is the few-treated
  default. The block bootstrap and jackknife estimators need many treated units. The placebo
  estimator (what the AMA Marketing News routing source (Li, Luo, and Pattabhiramaiah 2024;
  'AMA' hereafter) calls "permutation") works with one or few treated units but needs a
  moderate-to-large donor pool and roughly similar outcome variances across treated and
  control groups. Divergence across the applicable procedures signals the data shape does
  not support the chosen one.
- Backdating doubles as a bias estimate: if biases are stable in time, subtract the
  pre-period "effect" (the DiD-flavored corrections of Arkhangelsky et al. and
  Chernozhukov-Wuthrich-Zhu).

## Multiple treated units and imperfect fit

- Many treated units: one SC per treated unit, aggregate with population or size weights.
  Inside-the-hull treated units make weights non-unique; the penalized estimator (Abadie-
  L'Hour) adds lambda times the weighted sum of pairwise predictor discrepancies, is unique
  and sparse for lambda > 0, and spans pure SC (lambda to 0) to one-to-one matching (lambda
  to infinity), lambda by cross-validation.
- Poorly fitted units that must stay in an aggregate: bias-correct with a regression
  adjustment on the discrepancies (equivalently SC on regression residuals; Abadie-L'Hour,
  Ben-Michael-Feller-Rothstein). augsynth's ridge augmentation is the standard
  implementation; report both raw and augmented.
- Staggered timing across treated units: multisynth (staggered augsynth) or hand the design
  to did.
- Volatile outcomes: filter unit-specific noise before fitting (singular value thresholding,
  robust SC); common-factor volatility is what the SC itself absorbs.

## Extensions map (method to source to package)

| Situation | Method | Source | Package |
|---|---|---|---|
| Canonical, one treated aggregate unit | ADH SC | abadie2010synthetic | Synth / tidysynth (+ SCtools placebos) |
| Imperfect pre-fit | augmented (ridge) SC | benmichael2021augmented | augsynth |
| Disaggregated / many treated | penalized SC | abadie2021penalized | pensynth |
| Level gaps, stable-bias plausible | synthetic DiD | arkhangelsky2021synthetic | synthdid |
| N and T both modest-plus | IFE / generalized SC | xu2017generalized | gsynth, fect |
| Same, nuclear-norm route | matrix completion | athey2021matrix | fect (mc), MCPanel |
| Prediction intervals | scpi | cattaneo2021prediction | scpi |
| Conformal / t-test inference | conformal SC | chernozhukov2021exact | scinference |
| Single-market BSTS counterfactual | CausalImpact (the AMA figure's 'Bayesian SC') | brodersen2015inferring | CausalImpact |
| Elastic-net weights | Doudchenko-Imbens | doudchenko2016balancing | augsynth ridge or glmnet by hand |
| Noisy outcomes | robust SC (denoise first) | amjad2018robust | (SVD thresholding by hand) |
| Treated outcome outside the donor convex hull | augmented DiD (Li and Van den Bulte), scales the control average | li2023augmented | author replication code, no CRAN package |
| Outcome in donor range but too few pre-periods for SC | forward DiD (Li), forward-selects a control subset then applies DiD | li2024forward | author replication code, no CRAN package |
| Control units far fewer than pre-treatment periods | HCW OLS (Hsiao, Ching, and Wan), regression on a small control set | hsiao2012panel | plain OLS, no package needed |

The AMA routing source's 'augmented DiD' (Li and Van den Bulte 2023, convex-hull repair) is a
different estimator from the augmented (ridge) SC row above (Ben-Michael et al.); do not conflate
the two.

## Marketing translations

- Geo rollouts: a pricing, assortment, or feature change in one DMA/country with untouched
  markets as donors; the CausalImpact use case, upgraded with this skill's donor discipline
  and permutation inference.
- Regulation: state-level advertising or privacy rules hitting one state (the Prop 99
  template, literally a marketing-regulation outcome).
- Platform shocks: a policy change hitting one category, region, or creator tier; channel- or
  streamer-level panels where channels co-move (Twitch-YouTube style data).
- Anticipation: forward-buying before announced price changes; shift T0 to the
  announcement, not the enactment.
- Interference: national campaigns contaminate donor markets; drop exposed donors or sign
  the bias and report a bound.
- Volatility screen: sales and attention series are noisy, so the effect-vs-volatility gate
  and pre-filtering matter more here than in the macro applications.
- Aggregation note: SC needs aggregate units that co-move; customer-level rollouts belong to
  field-experiment or did, not here.

## Package index (verified against package docs 2026-07-28)

| Package | Version | Role | Traps |
|---|---|---|---|
| tidysynth | 0.2.1 (CRAN) | modern ADH pipeline: synthetic_control, generate_predictor/weights/control, grab_significance (RMSPE-ratio table), plot_placebos | ipop tuning args are snake_case (margin_ipop/sigf_ipop/bound_ipop); the package's OWN examples use dot-case names that fall into ... and are silently ignored; needs >= 20 donors for p < .05 |
| Synth | 1.1-10 (CRAN, 2026-04, still maintained) | original dataprep/synth/synth.tab/path.plot/gaps.plot | unit and time variables must be numeric; time.plot defaults to the pre-period, extend it explicitly; dot-case Margin.ipop here (opposite of tidysynth); no placebo machinery of its own |
| SCtools | 0.3.3.1 (CRAN) | in-space placebos for Synth objects: generate.placebos, mspe.test, plot_placebos | strategy = "multiprocess" deprecated (use "multisession"); prunes at 20x MSPE by default vs tidysynth's 2x |
| synthdid | 0.0.9 (GitHub synth-inference, not on CRAN) | SDID: panel.matrices, synthdid_estimate, sc_estimate/did_estimate trio, vcov(placebo/jackknife/bootstrap) | single treated unit: placebo is the ONLY valid vcov method; panel.matrices matches columns by position unless named; balanced panel, block adoption only |
| augsynth | 0.2.0 (GitHub ebenmichael, not on CRAN) | augmented SC (progfunc = "ridge"), conformal summary; multisynth for staggered many-treated | current signature has t_int AFTER data (the repo README shows the old order); fixedeff default differs (FALSE single, TRUE multisynth) |
| pensynth | 0.8.2 (CRAN) | penalized SC with cross-validated lambda (cv_pensynth) | Synth orientation, units in COLUMNS; Z1/Z0 hold-out outcome matrices are required for CV |
| scpi | 4.0.1 (CRAN) | scdata/scest/scpi prediction intervals, scplot; multi-treated variants scdataMulti/scplotMulti | w.constr is a list (list(name = "simplex")), not a string; default solver is CLARABEL (ECOS tutorials stale); scpi() is simulation-heavy |
| gsynth | 1.4.0 (CRAN) | generalized SC / IFE (Xu 2017) | estimator default is now "gsynth"; "ife" means IFE-with-EM; force default "unit" (fect's is "two-way"); GitHub README stale at 1.3.1; parametric bootstrap CIs biased in both directions (Li and Sonnier 2023, li2023statistical); prefer subsampling or the corrected inference |
| fect | 2.4.5 (CRAN; dev at xuyiqing/fect) | counterfactual estimators suite (fe/ife/mc/gsynth/cfe), placebo and carryover tests, effective successor to gsynth | no "bspline" in 2.x; flags camelCase (placeboTest) but periods dot-case (placebo.period); CV default NULL (auto); parametric bootstrap CIs biased in both directions (Li and Sonnier 2023, li2023statistical); prefer subsampling or the corrected inference |
| CausalImpact | 1.4.1 (CRAN) | BSTS single-series counterfactual for geo tests | response must be the first column; covariates must be unaffected by the intervention; no donor weights, so donor discipline does not transfer |
| scinference | 0.0.0.9000 (GitHub kwuthrich, commit 567c688, 2021) | conformal and cross-fit t-test inference (Chernozhukov-Wuthrich-Zhu) | underscore argument names; default alpha 0.10; CIs need an explicit ci_grid; research code, pin the commit |
| MCPanel | GitHub susanathey/MCPanel | original matrix-completion code | fect method = "mc" is the maintained route |

Stata and Python mirrors exist (Stata sdid and synth/synth_runner; Python pysyncon, and scpi
ships its own Python interface) but were NOT API-verified in this pass; check signatures
against their docs before citing them in a methods section.
