# causal-design canon

Current as of 2026-08-05. Four sources: three hand-picked and a fourth,
`abadie2023clustering`, approved on 2026-08-05, which was promoted from a cross-reference to
a full entry because five skills lean on it. Nothing enters this file without explicit human
approval. BibTeX keys point into ./causal.bib, which is the
one shared bib for the whole skill family. causal-design also leans on `arkhangelsky2024causal`
(the three-axis panel taxonomy), a cross-reference owned by the did canon. The family-wide
clustering statement is owned by this skill's own SKILL.md, whose frontmatter claims the shared
inference rules, while method skills carry design-specific instances. Refresh:
run litreview on the moving corners (panel estimators, text-causal) since the canon date;
any addendum needs explicit human approval.

## Imbens (2024)

Annual Review of Statistics and Its Application 11:123-152. Key: `imbens2024causal`.

- Role: the assumptions-first spine of the triage. Each design is introduced by the
  assumption that licenses it and the estimand it identifies; the review's structure is
  itself the decision tree, and this skill adopts it nearly verbatim.
- Settles: the assignment-based taxonomy (randomized / unconfounded-observational /
  confounded-observational / combined data); doubly robust estimators, which combine a
  propensity-score estimate with an outcome-model estimate, as "the most attractive" (sec.
  4.1.4; consistent if either nuisance is; the cross-fitting condition for ML nuisances,
  a product of error rates of o(n^-1/2), is from Chernozhukov et al. 2018,
  `chernozhukov2018double`, not this review); weighting by the ESTIMATED propensity
  score beats the true one (Hirano-Imbens-Ridder); fixed-match matching never fully
  efficient, and with two or more continuous covariates its bias does not vanish at the
  root-N rate; IV identifies the LATE for compliers only, the ATE
  needs substantially stronger assumptions; TWFE negative weights under staggered adoption
  (points to the did canon); local linear over global polynomials in RDD; ex post
  regression adjustment unbiased and precision-improving, design-stage covariate use
  preferred; naive sample means from adaptive/bandit experiments are biased; overlap
  violations move the estimand (Crump trimming, overlap weights); the graded sensitivity
  ladder (Manski bounds, calibrated Rosenbaum-Rubin, Rosenbaum sensitivity bounds);
  interference designs chosen by interference structure (clustered / network /
  marketplace); the surrogate index for long-run outcomes.
- Binds when: every triage; the selection-on-observables branch end to end; any
  sensitivity-analysis request.
- Scope limits: names no software at all; explicitly excludes dynamic treatment regimes
  (Robins tradition); no treatment of text or unstructured data.
- Quote (verbatim in SKILL.md): "In practice, using variables causally affected by the
  treatment or outcome is the most common mistake in choosing variables to condition on in
  estimating average treatment effects using unconfoundedness approaches."

## Li, Luo, and Pattabhiramaiah (2024)

AMA Marketing News, 2024-11-20; no journal companion, the web page is the citable object.
Key: `li2024quasiexperimental`.

- Role: the marketing-native data-shape axis, complementary to Imbens' assumption axis.
  Routes by number of treated units, pre-period length, covariate richness, treatment
  timing; anchors every method to named JM/JMR/Marketing Science applications (exemplar
  table in references/details.md).
- Settles: the summary heuristic that DiD/SC-family methods match on outcomes while
  propensity-family methods match on covariates, so the branch choice is which matching
  your data supports; the staggered rule (same-time: TWFE; staggered: Callaway-Sant'Anna,
  Sun-Abraham, or stacked regression, and justify the clean controls); the two MANDATORY
  SC-family best practices, stated as a gate ("only using the methods that satisfy both
  best practices"): pretreatment-fit plot and backdating (the family's adjudication adds a
  strict-exogeneity caveat to backdating and hands the final verdict to synthetic-control's
  fuller feasibility gate; SKILL.md carries it); the data-shape fan-out within
  the panel branch: convex-hull failure -> augmented DiD (Li-Van den Bulte), outcome in
  range but too few pre-periods -> forward DiD (Li), controls far fewer than pre-periods
  -> HCW OLS (Hsiao-Ching-Wan), many treated units or short panels -> generalized
  synthetic control / matrix completion, unit and time reweighting both wanted -> SDID
  with inference procedure chosen by data shape; PSM "called into question," replaced by
  AIPW, double ML, causal forests; unconfoundedness often defensible in marketing because
  targeting rules are known and observable; the Li-Sonnier result that the gsynth
  parametric bootstrap gives biased coverage when treated and control error variances
  differ ("false precision or false imprecision... lead to
  incorrect business decisions"); the field vocabulary (design rigor vs statistical rigor,
  ATT-first, clean controls).
- Binds when: routing within the panel branch; arguing a method is accepted marketing
  practice; writing for marketing reviewers.
- Caveats: read via WebFetch extraction, so re-verify any quotation against the live page
  before it enters a paper; two of the three authors developed the augmented/forward DiD
  estimators, so the piece leans toward that family and the synthetic-control and did skills
  weigh those methods independently; silent on RDD and nearly silent on IV, so it never covers the
  confounded-observational branch beyond panel methods. Figure 1 ("Overview of Design
  Choices in Quasi-Experimental Settings") was read against the article text on
  2026-07-28. The figure is coarser than the article text (it lumps augmented DiD
  under too-few-pre-periods where the text gives it the convex-hull condition; HCW and
  matrix completion appear only in the text); where they differ, this skill follows the
  text.

## Feder et al. (2022)

Transactions of the Association for Computational Linguistics 10:1138-1158. Key:
`feder2022causal`.

- Role: the text-role triage question. Any causal analysis where unstructured data appears
  gets asked: which role does it play (confounder, outcome, treatment)? Each role has its
  own assumption failures; causal-design states the question and the warnings, then hands
  the measurement problem to whoever owns it.
- Settles: ignorability over text aspects is untestable and must be argued from domain
  knowledge; positivity is generically fragile in high dimensions (a representation that
  nearly encodes the treatment leaves no conceivable counterfactual); consistency fails
  through the measurement model when it was trained on the estimation data, and the fix is
  split-sample measurement (via Egami et al.); invariance and sensitivity test batteries
  for any NLP measure feeding a causal pipeline; there are no real-world ground-truth
  causal text benchmarks, so semi-synthetic wins are never validation of a real estimate.
- Binds when: any unstructured data in the causal graph; causal-design's role question.
- REVISED WITHIN THE FAMILY: Feder's supervised text-as-confounder route (fine-tuned
  causally sufficient embeddings, Veitch et al. 2020) is superseded by the GPI results, on
  GPI's own simulation evidence, and the dispute and its replacement route belong to the
  text-causal literature. causal-design cites Feder for the role triage and the assumption
  failures, never for the Veitch route.
- Version note: read as the arXiv accepted version; cite with TACL pagination (1138-1158).

## Abadie, Athey, Imbens, and Wooldridge (2023)

QJE 138(1): 1-35. Key: `abadie2023clustering`. Provenance, corrected by the 2026-10-08 audit:
the quotations below come from the accepted version dated 2022-09-19 (MIT copy,
economics.mit.edu/sites/default/files/2022-09/cluster-6.pdf). arXiv v3 (May 2022) contains
none of them and does not cite Rambachan-Roth. The QJE PDF is Cloudflare-blocked, so the
version of record is unverified in detail. The judge-leniency sentence cites Chyn, Frandsen,
and Leslie (2022). Appendix regularity conditions and proofs not read. Promoted from a
header cross-reference on 2026-08-05 because five skills lean on it.

- Role: the family-wide clustering rule, and the reason it is a design question. Replaces "are
  my errors correlated within clusters" with "how were the data sampled and how was treatment
  assigned."
- Settles: the decision "depends on the nature of the sampling and the assignment processes
  only, and not on the presence of within-cluster error components in the outcome variable";
  two knobs run the whole taxonomy (sampling, clusters drawn with probability q then units with
  probability p; assignment, cluster-specific treatment probabilities with variance sigma^2,
  where sigma^2 = 0 is random assignment and sigma^2 = mu(1-mu) is perfectly clustered
  assignment); random sampling plus unit-level random assignment means do NOT cluster, and
  "clustering is not appropriate even if there is within-cluster correlation in outcomes
  (however those clusters are defined), and thus even if clustering makes a substantial
  difference in the magnitude of the standard errors"; robust standard errors can be
  ANTI-conservative, since the gap can take either sign and "the robust variance formula can
  severely underestimate the variance" when clusters explain much of the heterogeneity;
  clustered standard errors are always conservative and never anti-conservative, with the
  conservativeness equal to (p n / m) q times the cluster-size-weighted variance of cluster
  ATEs, so it scales with average sampled cluster size and can be extreme; when p is small all
  three coincide; under random sampling and random assignment the correction to the robust term
  is the familiar Neyman finite-sample correction, which vanishes with homogeneous effects or a
  small sampling fraction, so robust standard errors are conservative rather than exact when
  the sample is a large share of the population; the judge-leniency case by name, "standard
  errors should not be clustered at the level of the judge"; and for common-timing DiD, "adding
  group-level fixed effects ... does not change the answer to the question whether one needs to
  adjust for clustering."
- The untestability result, which is the most useful thing in the paper and the easiest to
  miss: the sample "is not informative about the value of q," so "information about the need to
  adjust for clustered sampling must come from outside the sample," while "the sample is
  potentially informative about the need to account for clustered assignment." One half of the
  clustering decision is an assertion about data collection, the other half is estimable.
- Binds when: any standard-error decision in any design in this family.
- Implement: names no software. It proposes CCV and TSCB for partially clustered assignment
  with large clusters, which can be considerably smaller than conventional cluster standard
  errors and are inapplicable (TSCB) or useless (CCV) under perfectly clustered assignment. No
  implementation anywhere in this family, and no package check has been done.
- Scope limits, from their own conclusion: LINEAR estimators only, least squares and fixed
  effects, with Xu (2019) named for the nonlinear extension (Ruonan Xu, working paper on
  M-estimators under cluster sampling and cluster assignment); and the particular sampling and
  assignment processes modelled here, with `rambachan2025design` named as the extension to
  other designs. The framework is asymptotic in the number of clusters and treats growing
  cluster sizes explicitly, so it is a many-clusters result.
- Pairs with `mackinnon2023cluster` (read in full, noted under did/), which answers HOW to do
  cluster-robust inference once you have decided to cluster. Cite the two together: this paper
  settles whether and at what level, MacKinnon-Nielsen-Webb settles few-cluster inference.

## Primary papers cited through the canon

New to the bib with this skill: `hirano2003efficient` (estimated propensity score),
`li2018balancing` (overlap weights), `bang2005doubly` (doubly robust), `athey2021policy`
(policy learning), `aronow2017estimating` (exposure mappings), `bajari2023experimental` and
`johari2022experimental` (marketplace designs), `athey2026surrogate` (the surrogate index,
REStud 93(4):2284-2312, online 2025-09-30, no longer the NBER WP), the sensitivity ladder
(`manski1990nonparametric`, `rosenbaum1983assessing`, `imbens2003sensitivity`,
`cinelli2020making`, `rosenbaum2002observational`; `oster2019unobservable` stays in the bib
but the family dropped Oster's delta on 2026-10-09, see details.md), and the AMA
panel family (`hsiao2012panel`, `li2020inference`, `li2023augmented`, `li2024forward`,
`li2023statistical` for Li-Sonnier). Already in the bib from
method skills and reused here: `crump2009dealing`, `wager2018estimation`,
`chernozhukov2018double`, `xu2017generalized`, `athey2021matrix`, `crepon2013labor`,
`hudgens2008toward`, `athey2018exact`, `egami2022make`, the did/rdd/synthetic-control canons.
New with the mediation decline: `imai2010general` and `pieters2017meaningful`, decline pointers
only, NOT canon (causal-design declines mediation and points to them; no skill carries the
route).

Reference shelf, not canon: `wooldridge2010econometric` (Econometric Analysis of Cross
Section and Panel Data, 2nd ed., MIT Press), the citation for the unobserved-effects model
and strict exogeneity in SKILL.md's plain-panel-fixed-effects section, and the pointer for
the panel methods that section leaves out, random effects among them. Added 2026-08-26 from
the reference list of the panel-data chapter of Cunningham, The Mixtape, online ch. 8,
whose footnote 1 names it for the same purpose. A textbook, so it carries no reading notes and
does not sit alongside the four read sources above.

## Shelf additions from the 2026-10-08 audit (tier 2, added 2026-10-09)

Shelf, not canon. Each entry was written from the abstract on Crossref or arXiv, read
2026-10-09; none has full reading notes. The user approved tier 2 as a whole.

- `goldfarb2022conducting`, Goldfarb, Tucker, and Wang (2022), Journal of Marketing
  86(3):1-20. Role: the Journal of Marketing reference for quasi-experiments, cited beside the
  AMA piece. Settles: how to find a setting, structure the empirical strategy, and state the
  identifying assumptions, across DiD, RD, IV, PSM, synthetic control, and selection
  correction. Binds when: writing for marketing reviewers. Caveat: a 2014 SSRN draft
  predates the panel-estimator literature the family uses.
- `imbens2025comparing`, Imbens and Xu (2025), Journal of Economic Perspectives
  39(4):173-201. Role: the current source for the order the observables branch follows.
  Settles: on the LaLonde data, modern methods give robust estimates of the adjusted
  differences once overlap is adequate. Those estimates need not be causally interpretable
  (the abstract's caveat). Credibility then rests on placebo-style validation, and
  goodness-of-fit tests alone are inadequate. Binds
  when: defending the branch's order (unconfoundedness, overlap, doubly robust, heterogeneity,
  validation). Caveat: the audit gave the issue as 39(2); Crossref says 39(4).
- `hadad2021confidence`, Hadad, Hirshberg, Zhan, Wager, and Athey (2021), PNAS 118(15).
  Role: the analysis route for bandit-collected data. Settles: an adaptively weighted
  estimator whose test statistic is asymptotically unbiased and normal under weak
  conditions on the adaptive design. Binds when: data come from a bandit or adaptive test.
  Implementation: CRAN banditsCI 1.0.0. Caveat: field-experiment owns the design decision.
- `yang2026demystify`, Yang, Thomas, and Li (2026), arXiv 2602.01648, "Demystify
  Doubly-Robust Estimation: The Role of Overlap". Role: the citation for the overlap-weight
  exit. Settles, by simulation: the outcome model dominates the doubly robust estimate as
  overlap falls, and under poor overlap the estimator amplifies extreme weights and often
  loses to IPW and outcome modeling. Recommends shifting the target population by trimming
  or overlap weighting. Caveat: a preprint with simulation evidence only.
- Sensitivity analysis, replacing Oster's delta in the reporting standard.
  `masten2026effect` (AER 116(7):2685-2710) shows that omitted variables can flip a sign far
  more easily than they can drive it to zero, so a large Oster's delta coexists with a much
  smaller sign-reversing value. `diegert2022assessing` (arXiv 2206.02303, v6 2026) gives a
  sensitivity analysis that allows omitted variables correlated with the included controls.
  Both ship the Stata module regsensitivity. `chernozhukov2026long` (REStat 2026, "Long Story
  Short") bounds omitted-variable bias for ATEs and other linear functionals in machine-learned
  models; Python DoubleML implements it as sensitivity_analysis(). Binds when: the
  sensitivity rung of the observables branch.
- Primary sources added for SKILL.md statements: `robins1994estimation` (the AIPW estimator,
  JASA 89:846-866), `abadie2006large` (matching is not root-N consistent in general,
  Econometrica 74:235-267), `rosenbaum2004design` (design sensitivity, Biometrika
  91:153-164, the object the sensitivity-bounds rung is distinguished from).
- Decline pointers for Gaussian copula corrections, NOT canon (the family declines the method):
  `becker2022revisiting` (JAMS 50(1):46-66: bias in models with an intercept, low power in
  small samples), `liengaard2025dealing` (JAMS 53(1):279-299: an adjusted estimator that traces
  the bias to CDF estimation), `eckert2023addressing` (Journal of Management 49(4):1460-1495:
  performance deteriorates fast when untestable assumptions fail), and `papies2017addressing`
  (the marketing chapter on endogeneity, in Advanced Methods for Modeling Markets, Springer,
  581-627; the audit named the Handbook of Marketing Decision Models, Crossref says otherwise).
