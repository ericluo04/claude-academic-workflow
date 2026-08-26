---
name: causal-design
description: Triage any causal question to the identification strategy the data can support, then hand off to the owning method skill; owns the selection-on-observables branch (overlap, doubly robust estimation, double ML, causal forests, policy learning, sensitivity analysis) and the inference rules shared across designs. Produces the design recommendation with the assumption that licenses it, the estimand and its subpopulation, R estimation code for the observables branch, and a drafted taxonomy paragraph. TRIGGER on "causal inference", "identification strategy", "which method", "research design", "endogeneity", "quasi-experiment", "natural experiment", "observational study", "selection on observables", "unconfoundedness", "conditional ignorability", "matching", "propensity score", "doubly robust", "AIPW", "double machine learning", "DML", "causal forest", "CATE", "policy learning", "targeting", "sensitivity analysis", "omitted variable bias", "Oster bounds", "coefficient stability", "overlap", "trimming", "panel fixed effects", "within estimator", "strict exogeneity", "marketplace experiment", "surrogate index", "mediation", "mediation analysis", "indirect effect", "conjoint", "AMCE", or any "how do I estimate the effect of X on Y" question with no design chosen yet. Once a design is chosen, the method skills own it: field-experiment, did, synthetic-control, rdd, iv, causal-unstructured, sae, sae-image, conjoint, steering.
---

# Causal design triage

The router of the family, grounded in a read canon of three user-picked reviews
(references/canon.md, current as of 2026-07-28): Imbens (2024) supplies the assumption axis
(what licenses identification), Li, Luo, and Pattabhiramaiah (2024, hereafter AMA) the
marketing data-shape axis (how many treated units, how many pre-periods, how rich the
covariates), and Feder et al. (2022) the text-role axis (which role unstructured data plays
in the graph). The deliverable is a design
recommendation carrying four things: the assumption that licenses it, the estimand it
actually identifies WITH its subpopulation named, the handoff to the owning skill, and, for
the one branch no method skill owns (selection on observables), estimation code and a methods
paragraph. Marketing's framing throughout: randomization is the gold standard, and
quasi-experimental work substitutes statistical rigor for design rigor (AMA); a design that
fails its gate is a verdict, not an obstacle.

Refresh path: the panel-methods corner moves fastest. To update, run the litreview skill on
quasi-experimental methods in marketing since the canon date and fold results into
references/canon.md as flagged addenda.

## The triage: four questions in order

1. Was assignment randomized, or as good as (lottery, randomized rollout)? Yes:
   field-experiment. Two cautions at this gate: naive sample means from adaptive/bandit
   experiments are biased (the arm that looked worse early is truncated; Imbens), and
   suspected interference changes the DESIGN, not just the analysis (routing below). One
   sub-route: profile experiments randomizing multiple attributes within alternatives
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
   skill.
3. If unconfoundedness is not plausible, look for structure in assignment:
   - An incentive or cost shifter moves treatment with no direct path to the outcome: iv.
     It identifies the LATE for compliers only; the ATE needs substantially stronger
     assumptions, and the complier population is the focus because it is the only one
     identifiable (Imbens).
   - Cases are routed to decision-makers who differ in strictness (judges, patent examiners,
     assessors, loan officers, reviewers) and the routing is as good as random within a
     stratum: iv, which owns the leniency design. The decision-maker identity is the
     instrument, 2SLS on it is biased, and the estimator is UJIVE.
   - Treatment switches at a threshold on a running variable: rdd (fuzzy RD is IV at the
     cutoff).
   - Treatment switches on over time for some units with untreated comparisons: the panel
     branch below, routed by data shape between did and synthetic-control.
   - Treatment switches on and off within unit, with no untreated comparisons and no
     adoption date: plain panel fixed effects, the section below.
   - No structure at all: bounds and sensitivity analysis (the ladder below), or advise
     against the causal claim. Estimate under the best defensible conditioning anyway and
     report how much calibrated confounding overturns it, or report Manski bounds alone;
     the sensitivity report, not the point estimate, is the deliverable.
   - Marketing's regression-based endogeneity corrections (control functions, Gaussian
     copulas; the third leaf of the AMA figure) sit outside this family's coverage: the iv
     skill's exclusion and relevance discipline is the nearest relative, and copula
     identification rests on distributional assumptions that need their own defense.
4. Does unstructured data (text, image, audio, video) appear anywhere in the graph, and in
   which role: confounder, outcome, treatment, or machine-coded measurement?
   causal-unstructured, with the role warnings below. Unknown-concept discovery and
   model-internals measurement: sae. Steering a model's internals (steered stimuli,
   steered model-respondents, dose-response manipulations) is instrument practice owned by
   steering; the design around it still routes through the questions above.

## The panel branch: routing by data shape

The AMA heuristic: DiD/SC-family methods match on outcomes (pretreatment paths),
propensity-family methods match on covariates; pick the branch by which matching the data
supports. Within outcomes-matching, crossed with the Arkhangelsky-Imbens (2024) three-axis
taxonomy (data type, frame shape, assignment mechanism; did skill):

- Many treated units, parallel trends plausible (only its pretreatment shadow is testable;
  did owns the statement of which variant is imposed): did. Same-time adoption: TWFE is
  fine; staggered: Callaway-Sant'Anna, Sun-Abraham, or stacked regression (whose implicit
  weights carry a caveat in did), and justify the clean controls (AMA).
- One or few treated aggregate units, long pre-period: synthetic-control (few treated
  CLUSTERS of micro units with plausible parallel trends stay in did on its few-clusters
  map). The AMA gate, both parts: plot treated vs fitted counterfactual and verify
  pretreatment fit, AND run a backdating exercise; "only using the methods that satisfy
  both best practices." Both parts are necessary, never sufficient: backdating assumes
  strict exogeneity and backfires under selection on recent shocks, and
  synthetic-control's fuller feasibility gate (pre-fit quality, T0 length, overfitting
  screens) controls the final verdict.
- The routing result between them: under selection on lagged outcomes with autocorrelated
  errors, DiD is inconsistent while SC is consistent (Arkhangelsky-Hirshberg, via the
  panel survey, Arkhangelsky and Imbens 2024). The DiD-to-SC-to-SDID decision path lives
  in did and synthetic-control.
- Data-shape fan-out when neither default fits (estimator details in synthetic-control's
  extensions map): treated outcome outside the donor convex hull: augmented DiD (Li and
  Van den Bulte 2023); outcome in range but too few pre-periods for SC: forward DiD (Li
  2024); control units far fewer than pre-periods: HCW OLS (Hsiao, Ching, and Wan 2012);
  many treated units or short panels: generalized synthetic control / factor models (Xu
  2017) or matrix completion (Athey et al. 2021), with the warning that the gsynth
  parametric bootstrap yields biased CIs, subsampling or the Li-Sonnier corrections
  instead (Li and Sonnier 2023, via AMA); unit AND time reweighting wanted: synthetic DiD;
  the inference-procedure-by-data-shape rules live in synthetic-control.

## Plain panel fixed effects: no comparison group, no adoption date

The within estimator on Y_it = delta D_it + u_i + eps_it is licensed by strict exogeneity
conditional on the unit effect, E[eps_it | D_i1, ..., D_iT, u_i] = 0 for every t (Wooldridge
2010 for the unobserved-effects model and the assumption). It buys every time-invariant
confounder, observed or not, and lets D_it be arbitrarily correlated with u_i. It buys
nothing against a time-varying unobservable, feedback from past outcomes to current
treatment, or simultaneity. Feedback is what fires in marketing panels: last period's sales
set this period's promotion, last quarter's churn sets this quarter's retention spend. The
Mixtape's own 5% price premium on unprotected sex holds "under the assumption of strict
exogeneity", and the condom decision is settled inside the session alongside the price, so a
session-level shock moving both is the violation it rests on being absent. Reverse causality
and simultaneity defeat the estimator outright: Cornwell and Trumbull (1994) put crime on
police in North Carolina counties and the within estimate is 0.413 (0.027), the wrong sign
against Becker's (1968) prediction, because Y -> D was there all along. Exits: iv under
feedback or simultaneity, did when an adoption date and clean untreated or not-yet-treated
comparisons exist. The design needs within-unit variation in D and identifies no
time-invariant covariate's effect (the Mixtape's Table 8.3 shows the column of exact zeros
with (.) standard errors).

The Mixtape (Cunningham, Causal Inference: The Remix, panel-data chapter) presents columns 3
and 4 of its Table 8.2, from Cornwell and Rupert (1997), which add job tenure and then
quadratics in years married and walk the marriage premium from the column 1 FGLS 0.083 to
0.033, as evidence about time-varying unobserved heterogeneity; under this skill's rule
those columns are inadmissible, because years married and job tenure are plausibly
consequences of marriage, so they condition on descendants of the treatment, which is
verbatim the error Imbens (2024) calls the most common one. The chapter assumes constant
effects and declares that scope. A non-absorbing time-varying treatment with heterogeneous
effects has left it, the implicit weighting is live, and the dCDH weight diagnostic in did
applies. Random effects, Mundlak-Chamberlain devices, and dynamic panel estimators stay out,
and Wooldridge (2010) is the shelf for them.

```r
library(fixest)                     # panel: one row per unit-period, unit = the panel id
## Within-variation check first: units with no variation in d contribute nothing to the
## within estimate and every FE routine drops them silently (singletons return NA here).
nv <- tapply(panel$d, panel$unit, function(z) var(z, na.rm = TRUE))
c(no_within_variation = sum(is.na(nv) | nv == 0), units = length(nv))
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
  approximation) and report the retained population, or switch to overlap weights
  e(x)(1-e(x)) (Li, Morgan, and Zaslavsky 2018), which target the population that could
  plausibly receive either treatment.
- Estimator default: doubly robust (AIPW; Bang and Robins 2005), "the most attractive" under
  unconfoundedness with many covariates (Imbens): consistent if either the outcome model
  or the propensity model is consistent, tolerates ML-rate nuisance estimation. In
  practice: grf's causal forest with its built-in AIPW average effect, or double ML
  (Chernozhukov et al. 2018) when you want explicit nuisance control. Plain regression or
  matching are acceptable in low dimensions, with two caveats: fixed-number-of-matches
  matching is never fully efficient and its bias does not vanish with many covariates
  (Imbens), and marketing has moved off propensity score matching for its sensitivity to
  parametric assumptions (AMA).
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
  2003, with Oster 2019 and Cinelli-Hazlett 2020 as the modern reporting standards;
  sensemakr implements Cinelli-Hazlett); Rosenbaum design sensitivity (Rosenbaum 2002). An
  estimate that flips under mild confounding indicts the design, not the estimator.

## Rules shared across every design

- Estimand first, subpopulation named: IV and fuzzy RDD identify complier effects; DiD and
  SC identify the ATT of the treated units; overlap weighting identifies the overlap
  population. The methods template forces the clause.
- Clustering is a design property, not a data property (Abadie, Athey, Imbens, and Wooldridge
  2023): cluster standard errors at the level at which treatment was assigned or the sample was
  drawn, and be able to say which; do not cluster by habit at whatever level makes the panel.
  The decision "depends on the nature of the sampling and the assignment processes only, and
  not on the presence of within-cluster error components in the outcome variable," so
  within-cluster outcome correlation is not a reason to cluster and the size of the change in
  your standard error is not evidence you needed it. Both errors are live and they are not
  symmetric. Robust standard errors can be ANTI-conservative, severely so when clusters explain
  much of the heterogeneity in treatment effects or potential outcomes. Clustered standard
  errors are always conservative and never anti-conservative, but the conservativeness scales
  with average sampled cluster size, so clustering "just in case" is not free. Under random
  sampling with unit-level random assignment, do not cluster at all; under clustered
  assignment, cluster at the assignment level; when the sampled clusters are a small fraction
  of the population, or few units are sampled per cluster, the choice stops mattering.
  One half of this decision is untestable and the skill states it rather than estimating it:
  the sample "is not informative" about what fraction of clusters was sampled, so "information
  about the need to adjust for clustered sampling must come from outside the sample," while the
  sample IS informative about clustered assignment. The Mixtape's rationale for clustering
  by panel unit, "to allow for correlation in the eps_it's for the same person i over time,"
  is the one reason AAIW rule out, and the answer often coincides only because panel units
  in a survey are genuinely the sampling clusters. Say which of the two you are invoking.
  Two further facts to carry. Robust standard errors are conservative rather than exact when
  the sample is a large share of the population and effects are heterogeneous (the Neyman
  finite-sample correction; `abadie2020sampling` buys the precision back if unit attributes
  predict the treatment effect). And for partially clustered assignment with large clusters,
  their CCV and TSCB estimators sit between robust and clustered and can be considerably
  smaller than conventional cluster standard errors; neither applies under perfectly clustered
  assignment, and this family ships no implementation of either. Scope: linear estimators only
  (least squares and fixed effects). Once the level is chosen, few-cluster inference is a
  separate problem with its own answer (MacKinnon, Nielsen, and Webb 2023; the map is in did).
- Multiplicity, staged by what a false positive costs. One correction applied at every stage is
  wrong in both directions at once, so match the procedure to what the output is. SCREENING,
  where the output is a candidate list something downstream will re-test: FDR, at q = .10 and
  not .05, since a false positive costs one wasted follow-up. Benjamini-Hochberg is the
  default and holds under positive regression dependence; the Benjamini-Krieger-Yekutieli
  two-stage sharpened q-values that Anderson (2008) made the applied convention recover power
  by estimating the null proportion instead of fixing it at 1, at the price of an
  independence-flavoured guarantee and less stability. So BKY suits a screen over
  machine-generated candidates and BH suits estimates that share respondents; the choice is
  design-dependent, and say which you took and why. CONFIRMATORY, where each hypothesis is
  named and defended: FWER by a resampling method that bootstraps the actual dependence among
  the test statistics (Romano-Wolf stepdown, Westfall-Young maxT), uniformly at least as
  powerful as Holm and equal to it only under independence. Where resampling is impractical,
  Holm. Never plain Bonferroni: Holm step-down dominates it at zero cost under no extra
  assumptions, so Bonferroni is never the right answer to a question Holm also answers. ACROSS
  STAGES of a staged design: fixed-sequence gatekeeping. Preregister the order, test each
  stage's primary hypothesis at full alpha, stop at the first failure. It costs no alpha, and
  the price accepted in advance is that nothing downstream of a failed gate is confirmatory.
  Worked instantiations: sae (screens over a latent dictionary), field-experiment (subgroups
  and multiple outcomes), conjoint (AMCE families).
- Interference routing, by structure (designs, estimators, and diagnostics live in
  field-experiment): clustered interference routes to two-stage randomization (Hudgens
  and Halloran 2008, Crepon et al. 2013); network interference to exposure mappings
  (Aronow and Samii 2017) with exact tests (Athey, Eckles, and Imbens 2018); marketplaces
  and two-sided platforms to multiple randomization designs (Bajari et al. 2023, Johari
  et al. 2022).
- Combined experimental and observational data: the surrogate index for long-run outcomes
  (retention, LTV) from short experiments, valid only when all causal paths from treatment
  to the long-run outcome pass through the surrogates (Athey, Chetty, Imbens, and Kang
  2026). The family ships no estimation template for the surrogate index; Athey, Chetty,
  Imbens, and Kang's own empirical implementation is the recipe to follow, and the
  router's deliverable stops at the validity argument.
- Text-role warnings at handoff (Feder): as confounder, ignorability over text aspects is
  untestable, argue it from domain knowledge, and audit positivity (a representation that
  nearly encodes the treatment leaves no counterfactual); as outcome or discovered
  treatment, never train the measurement function on the estimation sample (split-sample,
  via Egami; the authoritative rule lives in causal-unstructured); as treatment,
  disentangle the named aspect from correlated aspects, and random assignment of texts
  leaves reader-side confounding. Any machine-coded variable in any design gets the PPI
  rectifier logic before it enters a regression (causal-unstructured). One revision the
  family makes to Feder: his supervised text-as-confounder route (fine-tuned causally
  sufficient embeddings, Veitch 2020) is superseded; the GPI results say never fit the
  inference-time propensity on a representation learned with a treatment-prediction loss
  (on GPI's own simulation evidence; causal-unstructured carries the dispute and owns the
  replacement).
- Mediation (process evidence, treatment affecting the outcome through a mediator, natural
  direct and indirect effects) has NO route in this family: sequential ignorability is an
  assumption regime none of the family's skills carries. Where to go: Imai, Keele, and
  Tingley (2010) for identification and sensitivity analysis, Pieters (2017) for the
  marketing-native statement of what a mediation claim requires. causal-unstructured's
  note that Fong-Grimmer treatment discovery is not mediation remains authoritative there.

## Implementation

scripts/unconfoundedness_template.R is the runnable path for the branch this skill owns
(overlap diagnostics and trimming, grf AIPW, CATE and policy learning, sensemakr
sensitivity reporting), verified against package documentation. Package index with
versions, links, and traps in references/details.md. Every other branch's code lives in
the owning skill's template.

## Methods paragraph template

> Following the taxonomy in Imbens (2024), our setting is [randomized / observational with
> a defensible unconfoundedness argument / observational with assignment structure X /
> combined]. The assignment structure that identifies the effect is [structure], which
> points to [estimator], identifying [estimand] for [subpopulation]. [Observables branch:]
> We condition on [pretreatment covariates], none causally affected by treatment or
> outcome; overlap is [assessed how, trimmed how, moving the estimand to whom]; estimation
> is doubly robust [implementation]; and we report [Cinelli-Hazlett robustness values /
> Oster's delta] against a confounder as strong as [benchmark covariate]. [Panel branch:]
> Given [T treated units, K pre-periods], we use [method] per the data-shape criteria in
> Li, Luo, and Pattabhiramaiah (2024). A limitation I accept: [the identifying assumption
> this design rests on], stated where the choice is made, with its price named.

Every claim traces to references/canon.md; keys live in references/causal.bib.

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
- causal-unstructured: any text/image/audio/video role in the graph; PPI for machine-coded
  variables; GPI for internal-state adjustment; the split-sample rule.
- sae: unknown-concept discovery in text; model-internals measurement instruments.
- steering: activation-steering practice for steered stimuli and model-respondents
  (instrument choice, strength calibration, damage audits); the surrounding design stays
  with the owning method skill.
- preregister: pre-analysis plans once the design is chosen (experiment-first skill;
  quasi-experimental and measurement PAPs adapt its structure).
