---
name: causal-design
description: Triage a causal question and hand off to the owning method skill. Owns the selection-on-observables branch (overlap, doubly robust estimation, causal forests, policy learning, sensitivity), plain panel fixed effects, and the shared inference rules (clustering, multiplicity, interference routing). TRIGGER on "identification strategy", "which causal method", "research design", "endogeneity", "quasi-experiment", "natural experiment", "selection on observables", "unconfoundedness", "propensity score", "matching", "IPW", "AIPW", "doubly robust", "double machine learning", "causal forest", "policy learning", "sensitivity analysis", "sensemakr", "Oster bounds", "Manski bounds", "overlap", "panel fixed effects", "strict exogeneity", "surrogate index", "mediation", "control function", "copula", "bandit", "adaptive experiment", "interrupted time series", "pre-post", or "how do I estimate the effect of X on Y" with no design chosen yet. Once a design is named, its method skill owns it.
---

# Causal design triage

The router of the family, grounded in a read canon of four sources
(references/canon.md): Imbens (2024) supplies the assumption axis
(what licenses identification), Li, Luo, and Pattabhiramaiah (2024, hereafter AMA; defined in
references/canon.md) the marketing data-shape axis (how many treated units, how many
pre-periods, how rich the covariates), Feder et al. (2022) the text-role axis (which role
unstructured data plays in the graph), and Abadie, Athey, Imbens, and Wooldridge (2023) the
clustering rules the family shares. The deliverable is a
design recommendation carrying four things: the assumption that licenses it, the estimand it
actually identifies WITH its subpopulation named, the handoff to the owning skill, and, for
the one branch no method skill owns (selection on observables), estimation code and a methods
paragraph. The skill stops at the four stop points in references/shared-rules.md (section
"Stop points") and puts each choice to the user. Marketing's framing throughout: randomization is
the gold standard, and quasi-experimental work substitutes statistical rigor for design rigor
(AMA); a design that fails its gate is a verdict, not an obstacle.

Current as of 2026-10-09; refresh per shared-rules (references/shared-rules.md,
section "Refresh path").
Nothing enters the canon without the user's approval.

## The triage: four questions in order

1. Was assignment randomized, or as good as (lottery, randomized rollout)? Yes:
   field-experiment. Two cautions at this gate. First, naive sample means from adaptive or
   bandit experiments are biased, because the arm that looked worse early is truncated. The
   analysis route is adaptive weighting (Hadad et al. 2021, `hadad2021confidence`;
   references/details.md). Second, suspected interference changes the DESIGN, not just the
   analysis (routing below). One sub-route: profile experiments randomizing multiple
   attributes within alternatives
   (conjoint, fully randomized factorial vignettes) go to conjoint, which owns the
   per-component estimand family and its correction layers.
2. If observational: is unconfoundedness defensible with PRETREATMENT covariates only? The
   conditioning set may contain only non-descendants of treatment and outcome, normally
   justified by temporal precedence. Verbatim, because it is the highest-frequency error
   (Imbens 2024): "In practice, using variables causally affected by the treatment or
   outcome is the most common mistake in choosing variables to condition on in estimating
   average treatment effects using unconfoundedness approaches." The marketing case where
   yes is credible: the targeting rule is known and observable (a campaign targeted on
   demographics or behavior selects on observables by construction; AMA). Tiebreak: a
   known DETERMINISTIC rule (treatment jumps at a cutoff on an observed score) is the rdd
   case, question 3, not this branch; the observables branch needs probabilistic
   assignment, since a deterministic rule makes every propensity 0 or 1 and leaves no
   overlap to estimate on. Yes: the selection-on-observables branch below, owned by this
   skill. A panel with pre-periods and an adoption date goes to did first, and the
   selection-on-observables estimate is the second column of the bracketing pair (did's
   Covariates section, the bracketing result). Stop here before any code runs. Confirm two
   things with the user: the covariate list, with each covariate's pretreatment status, and the
   targeting rule that assigned treatment.
3. If unconfoundedness is not plausible, look for structure in assignment:
   - An incentive or cost shifter moves treatment with no direct path to the outcome: iv.
     It identifies the LATE for compliers only; the ATE needs substantially stronger
     assumptions, and the complier population is the focus because it is the only one
     identifiable (Imbens).
   - Cases are routed to decision-makers who differ in strictness (judges, patent examiners,
     assessors, loan officers, reviewers) and the routing is as good as random within a
     stratum: iv, which owns the leniency design. The decision-maker identity is the
     instrument, and the estimator is UJIVE. 2SLS on the judge dummies is biased toward OLS
     when the dummies are many relative to the sample (Kolesar 2013; iv owns the detail).
   - Treatment switches at a threshold on a running variable: rdd (fuzzy RD is IV at the
     cutoff).
   - Treatment switches on over time for some units with untreated comparisons: the panel
     branch below, routed by data shape between did and synthetic-control.
   - A binary treatment switches on and off within unit (promotions, a price cut on or off).
     Plain FE (the section below) applies when all units switch together, so no period has
     both treated and untreated units. Otherwise: did, which owns the intertemporal dCDH
     estimator for non-absorbing treatments (section "Beyond the absorbing binary
     treatment"; de Chaisemartin and D'Haultfoeuille 2026, `dechaisemartin2026intertemporal`).
   - A continuous treatment intensity with no clean off state, no untreated comparisons, and
     no adoption date: plain panel fixed effects, the section below.
   - One series treated everywhere on one date, with no untreated units and no donors
     (interrupted time series, pre-post): no design in the family identifies the effect.
     The before-after change assumes nothing else moved on that date, and the data cannot
     test that. Report the change as descriptive and treat it as the no-structure case
     below. This routing is the family's judgment. did and synthetic-control need
     comparisons, and rdd sends RD in time back to them.
   - No structure at all: bounds and sensitivity analysis (the ladder below), or advise
     against the causal claim. Estimate under the best defensible conditioning anyway and
     report how much calibrated confounding overturns it, or report Manski bounds alone;
     the sensitivity report, not the point estimate, is the deliverable.
   - Marketing's regression-based endogeneity corrections (control functions, Gaussian
     copulas; the third leaf of the AMA figure) sit outside this family's coverage: the iv
     skill's exclusion and relevance discipline is the nearest relative, and copula
     identification rests on distributional assumptions that need their own defense. The
     decline carries four pointers for a coauthor who proposes a copula. Becker, Proksch,
     and Ringle (2022) find a bias in models with an intercept and low power in small
     samples. Liengaard et al. (2025) trace that bias to the CDF estimate and adjust the
     estimator. Eckert and Hohberger (2023) show that its performance deteriorates fast when
     its untestable assumptions fail. Papies, Ebbes, and van Heerde (2017) is the marketing
     chapter on endogeneity corrections.
4. Does unstructured data (text, image, audio, video) appear anywhere in the graph, and in
   which role: confounder, outcome, treatment, or machine-coded measurement? This question
   is a modifier on the leaf that questions 1 to 3 reached, and that leaf keeps the design.
   The role warnings below apply, and the measurement it rests on is settled before the
   estimate, not after. Discovering an unknown concept, or measuring one from a model's
   internals, is a measurement problem with its own validity argument. Intervening on a
   model's internals to build stimuli or model-respondents is instrument practice, and the
   design around it still routes through the questions above.

## The panel branch: routing by data shape

The AMA heuristic: DiD/SC-family methods match on outcomes (pretreatment paths),
propensity-family methods match on covariates; pick the branch by which matching the data
supports. Within outcomes-matching, crossed with the Arkhangelsky-Imbens (2024) three-axis
taxonomy (data type, frame shape, assignment mechanism; did skill):

- Many treated units, parallel trends plausible (only its pretreatment shadow is testable;
  did owns the statement of which variant is imposed): did. Same-time adoption: TWFE is
  fine for the static ATT without covariates; dynamic effects take the event-study form and
  covariates take did's adjusted estimators. Staggered: Callaway-Sant'Anna, Sun-Abraham, or
  stacked regression (whose implicit weights carry a caveat in did; Wing, Freedman, and
  Hollingsworth 2024, `wing2024stacked`), and justify the clean controls (AMA).
- One or few treated aggregate units, long pre-period: synthetic-control (few treated
  CLUSTERS of micro units with plausible parallel trends stay in did on its few-clusters
  map). The AMA gate, both parts: plot treated vs fitted counterfactual and verify
  pretreatment fit, AND run a backdating exercise; "only using the methods that satisfy
  both best practices." Both parts are necessary, never sufficient: backdating assumes
  strict exogeneity and backfires under selection on recent shocks, and
  synthetic-control's fuller feasibility gate (pre-fit quality, T0 length, overfitting
  screens) controls the final verdict.
- The routing result between them: in a two-way model where assignment depends on both the
  permanent and the time-varying parts of past outcomes, DiD is inconsistent while SC is
  consistent and asymptotically normal once the pre-period is long (Arkhangelsky and
  Hirshberg 2023, arXiv 2311.13575, Section 1). The DiD-to-SC-to-SDID decision path lives
  in did and synthetic-control.
- Data-shape fan-out when neither default fits (estimator details in synthetic-control's
  extensions map): treated outcome outside the donor convex hull: augmented DiD (Li and
  Van den Bulte 2023); outcome in range but too few pre-periods for SC: forward DiD (Li
  2024); control units far fewer than pre-periods: HCW OLS (Hsiao, Ching, and Wan 2012);
  many treated units or short panels: generalized synthetic control / factor models (Xu
  2017) or matrix completion (Athey et al. 2021). The gsynth parametric bootstrap gives
  biased coverage when treated and control error variances differ (Li and Sonnier 2023).
  Use fect's nonparametric bootstrap or jackknife `vartype`, or hand-code the Li-Sonnier
  correction (synthetic-control's details.md); unit AND time reweighting wanted: synthetic DiD;
  the inference-procedure-by-data-shape rules live in synthetic-control's details, absorbed
  there from the AMA piece with "permutation" mapped to the placebo estimator.

## Plain panel fixed effects: no comparison group, no adoption date

The within estimator on Y_it = delta D_it + u_i + eps_it is licensed by strict exogeneity
conditional on the unit effect, E[eps_it | D_i1, ..., D_iT, u_i] = 0 for every t (Wooldridge
2010 for the unobserved-effects model and the assumption). It buys every time-invariant
confounder, observed or not, and lets D_it be arbitrarily correlated with u_i. It buys
nothing against a time-varying unobservable, feedback from past outcomes to current
treatment, or simultaneity. Feedback is what fires in marketing panels: last period's sales
set this period's promotion, last quarter's churn sets this quarter's retention spend.
Reverse causality and simultaneity defeat the estimator outright. The two Mixtape worked
cases (the condom premium and Cornwell and Trumbull 1994) are in references/details.md
(section "Plain panel fixed effects: the Mixtape's worked cases"). Exits: iv under
feedback or simultaneity, did when an adoption date and clean untreated or not-yet-treated
comparisons exist. The design needs within-unit variation in D and identifies no
time-invariant covariate's effect.

Do not add controls that are consequences of the treatment. That rule makes the tenure and
years-married columns of Cornwell and Rupert (1997) inadmissible here (columns 3 and 4 of
Table 8.2 in Cunningham, The Mixtape, online ch. 8; references/details.md for the argument, the
constant-effects scope it assumes, and the estimators that stay out).

```r
library(fixest)                     # panel: one row per unit-period, unit = the panel id
## Within-variation check first: units with no variation in d contribute nothing to the
## within estimate of delta. fixest keeps them in the sample, the FE count, and the R2
## without a message, so count them here (singletons return NA).
nv <- tapply(panel$d, panel$unit, function(z) var(z, na.rm = TRUE))
c(no_within_variation = sum(is.na(nv) | nv == 0), units = length(nv))
## cluster = ~unit only when the design justifies it: panel units are the sampled clusters
## or treatment was assigned by unit (abadie2023clustering). Within-unit correlation of the
## errors alone is not a reason; drop the argument otherwise.
pols   <- feols(y ~ d, data = panel, cluster = ~unit)   # u_i left in the composite error
within <- feols(y ~ d | unit, data = panel, cluster = ~unit)
etable(pols, within)                # side by side: the gap is the unit effects at work, and
                                    # no time-invariant covariate enters the within column.
## Stata FE standard errors instead (argument-name trap in references/details.md):
# estimatr::lm_robust(y ~ d, data = panel, fixed_effects = ~unit, clusters = unit,
#                     se_type = "stata")
```

## Selection on observables (the branch this skill owns)

- Overlap before estimation, always: estimate the propensity score and look at its
  distribution by arm. Violations move the ESTIMAND, not just the estimator: trim with the
  variance-minimizing rule of Crump et al. (2009) (the 0.1/0.9 rule of thumb is its common
  approximation) and report the retained population. Trimming breaks double robustness: the
  trimmed estimator is consistent only if the outcome model is correct (Ma, Sant'Anna, Sasaki,
  and Ura, arXiv 2304.08974). When you do not trust the outcome model, switch to overlap weights
  e(x)(1-e(x)) (Li, Morgan, and Zaslavsky 2018), which target the population that could
  plausibly receive either treatment. Under poor overlap the doubly robust estimator
  amplifies extreme weights and often does worse than IPW or outcome modeling alone. Yang,
  Thomas, and Li (2026, arXiv 2602.01648) recommend the same exit: change the target
  population.
- Refusal rule for this branch. Decline the ATE when the trimming rule would drop most of
  the sample, or when the targeting rule turns out to be deterministic. Report the overlap
  population's effect instead, or reroute: rdd for a known cutoff, Manski bounds otherwise.
  "Most of the sample" is the family's judgment: past that point the retained population is
  no longer the one the question was about.
- Estimator default: doubly robust (AIPW, from Robins, Rotnitzky, and Zhao 1994; Bang and
  Robins 2005 named the double-robustness property). Imbens (2024, sec. 4.1.4) calls the
  estimators that combine a propensity-score estimate with an outcome-model estimate "the
  most attractive". AIPW is consistent if either the outcome model or the propensity model
  is consistent. ML nuisance estimates are allowed with cross-fitting, when the product of
  the two nuisance error rates is o(n^-1/2). Rates of n^-1/4 each suffice (Chernozhukov et
  al. 2018). grf's AIPW cross-fits internally through out-of-bag predictions; a hand-rolled
  AIPW needs explicit sample splitting. In practice: grf's causal forest with its built-in
  AIPW average effect, or double ML (Chernozhukov et al. 2018) when you want explicit
  nuisance control. Plain regression or matching are acceptable in low dimensions, with two
  caveats. Fixed-number-of-matches matching is never fully efficient. With two or more
  continuous covariates, its bias does not vanish at the root-N rate, so it is not
  negligible against the standard error (Abadie and Imbens 2006). Marketing has moved off
  propensity score matching for its sensitivity to parametric assumptions (AMA).
- Weight by the ESTIMATED propensity score even when the true one is known; the true score
  is inefficient (Hirano, Imbens, and Ridder 2003).
- Heterogeneity has two different goals: describing CATEs (causal forest, Wager and Athey
  2018, honest inference without prespecified subgroups) and deciding WHO to treat, which
  is policy learning (Athey and Wager 2021; policytree), where the complexity of the
  policy class is the key choice. Do not answer a targeting question with a CATE
  map.
- Sensitivity analysis is mandatory, because unconfoundedness is untestable. The graded
  ladder (details in references/details.md): Manski bounds (assumption-free, honest,
  usually uninformative); calibrated confounder models (Rosenbaum and Rubin 1983, Imbens
  2003, with Cinelli-Hazlett 2020 as the modern reporting standard; sensemakr implements it
  on a linear model); Rosenbaum sensitivity bounds (Rosenbaum 2002, ch. 4). The
  doubly robust estimate itself takes the omitted-variable bounds of Chernozhukov et al.
  (2026, "Long Story Short"), implemented as sensitivity_analysis() in Python DoubleML. The
  family drops Oster's delta. Masten and Poirier (2026) show that whenever the delta is
  large, a much smaller value already reverses the coefficient's sign. Oster's delta assumes
  the omitted variables are uncorrelated with the included controls. Diegert, Masten, and
  Poirier (2022) give an analysis that drops that assumption. An estimate that flips under mild
  confounding indicts the design, not the
  estimator.
- Run a placebo test before the sensitivity analysis. A pretreatment outcome, or an outcome
  the treatment cannot move, should show no effect (Imbens and Xu 2025,
  `imbens2025comparing`). Goodness-of-fit checks alone do not validate the design.

## Rules shared across every design

- Estimand first, with the subpopulation named: complier, ATT, or overlap population.
- Cluster where treatment was assigned or the sample was drawn, and say which of the two.
- Multiplicity staged by cost: FDR to screen, resampling FWER to confirm, gatekeeping by stage.
- Interference in prospective designs routes to field-experiment by structure: clustered,
  network, or marketplace. Observational fixes live in did and synthetic-control. Observational
  interference outside a panel design (network spillovers in platform data, where nobody
  assigned treatment) is unrouted: no skill in the family owns it.
- Surrogate index for long-run outcomes, valid only under three assumptions: unconfoundedness
  in the experiment, surrogacy (every causal path runs through the surrogates), and
  comparability of the experimental and observational samples.
- Text-role warnings at handoff (Feder). A machine-coded variable gets its correction first:
  PPI for a predicted outcome, DSL or Battaglia et al. 2025 for a predicted treatment or
  covariate.
- Mediation has no route here. Sequential ignorability is a regime no skill carries.

Full argument: references/shared-rules.md.

## Implementation

scripts/unconfoundedness_template.R is the runnable path for the branch this skill owns
(overlap diagnostics and trimming, grf AIPW, CATE and policy learning, sensemakr
sensitivity reporting), verified against package documentation. Package index with
versions, links, and traps in references/details.md, and references/packages.md for
shared packages. Every other branch's code lives in
the owning skill's template.

## Methods paragraph template

> Following the taxonomy in Imbens (2024), our setting is [randomized / observational with
> a defensible unconfoundedness argument / observational with assignment structure X /
> combined]. The assignment structure that identifies the effect is [structure], which
> points to [estimator], identifying [estimand] for [subpopulation]. [Observables branch:]
> We condition on [pretreatment covariates], none causally affected by treatment or
> outcome; overlap is [assessed how, trimmed how, moving the estimand to whom]; estimation
> is doubly robust [implementation]; and we report [Cinelli-Hazlett robustness values,
> computed on a linear proxy of the doubly robust specification / omitted-variable bounds on
> the doubly robust estimate (Chernozhukov et al. 2026)] against a confounder as strong as
> [benchmark covariate]. [Plain FE branch:] We rely on strict exogeneity conditional on the
> unit effect. The price is that feedback from past outcomes to current treatment would bias
> the estimate, and we argue it is absent because [institutional reason]. [Panel branch:]
> Given [T treated units, K pre-periods], we use [method] per the data-shape criteria in
> Li, Luo, and Pattabhiramaiah (2024). A limitation we accept: [the identifying assumption
> this design rests on], stated where the choice is made, with its price named.

The template is written in "we". Match the paper's voice: switch to "I" for a
sole-authored paper.

Report each effect with the results sentence in references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

Every claim traces to references/canon.md; keys live in references/causal.bib.

## When a method skill declines

A method skill that refuses a design sends it back here with the failed gate named. The gate is
a pre-trend did fails, a donor pool synthetic-control cannot fit, a density test rdd fails, or
a first stage iv rejects. The router does not rerun triage from scratch. It moves to the next
leaf the assignment structure still supports. When no leaf remains, it takes the no-structure exit:
bounds and sensitivity analysis, or advice against the causal claim. The failed gate goes into
the write-up as a finding. A decline is a stop point, so the next route goes to the user before any
code runs.

## Handoffs

- field-experiment: anything randomized, prospective experimental design, interference
  analysis, power.
- conjoint: profile experiments with multiple randomized attributes (AMCEs, marginal
  means, measurement-error and multiple-testing corrections, HB partworths and WTP).
- did: many treated units with timing variation; parallel-trends machinery; it sends
  plain-FE cases with no comparison group back to the plain panel fixed effects section.
- synthetic-control: few treated units, long pre-periods; SDID; factor models and matrix
  completion; the augmented/forward DiD and HCW conditions stated above.
- rdd: thresholds on running variables; the design gate and falsification battery.
- iv: instruments, shift-share, formula instruments, leniency and examiner designs;
  weak-instrument inference.
- Any text, image, audio, or video role in the graph carries a measurement design of its own:
  a prediction-powered correction for a machine-coded outcome, DSL or Battaglia et al. 2025 for
  a machine-coded treatment or covariate, an internal-state adjustment where the confounder is
  latent, and the split-sample rule throughout.
- Unknown-concept discovery and model-internals measurement are instruments, and their
  validity is argued before they enter a design.
- Activation steering for stimuli and model-respondents (instrument choice, strength
  calibration, damage audits) is instrument practice; the surrounding design stays with the
  owning method skill.
- Preregistration: the user writes it themselves once the design is chosen; the owning method
  skill supplies the field list (outcomes, hypotheses, sample size, analysis plan).
