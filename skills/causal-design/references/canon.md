# Router canon

Current as of 2026-08-05. Four sources: three hand-picked and a fourth,
`abadie2023clustering`, approved on 2026-08-05, which was promoted from a cross-reference to
a full entry because five skills lean on it. Nothing enters this file without explicit human
approval. BibTeX keys point into ./causal.bib, which is the
one shared bib for the whole skill family. The router also leans on `arkhangelsky2024causal`
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
  confounded-observational / combined data); doubly robust estimators as "the most
  attractive" under unconfoundedness with many covariates (consistent if either nuisance
  is, tolerate ML-rate convergence); weighting by the ESTIMATED propensity score beats the
  true one (Hirano-Imbens-Ridder); fixed-match matching never fully efficient, bias
  non-vanishing in high dimensions; IV identifies the LATE for compliers only, the ATE
  needs substantially stronger assumptions; TWFE negative weights under staggered adoption
  (points to the did canon); local linear over global polynomials in RDD; ex post
  regression adjustment unbiased and precision-improving, design-stage covariate use
  preferred; naive sample means from adaptive/bandit experiments are biased; overlap
  violations move the estimand (Crump trimming, overlap weights); the graded sensitivity
  ladder (Manski bounds, calibrated Rosenbaum-Rubin, Rosenbaum design sensitivity);
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
  parametric bootstrap yields biased CIs ("false precision or false imprecision... lead to
  incorrect business decisions"); the field vocabulary (design rigor vs statistical rigor,
  ATT-first, clean controls).
- Binds when: routing within the panel branch; arguing a method is accepted marketing
  practice; writing for marketing reviewers.
- Caveats: read via WebFetch extraction, so re-verify any quotation against the live page
  before it enters a paper; two of the three authors developed the augmented/forward DiD
  estimators, so the piece leans toward that family and the synth/did skills weigh those
  methods independently; silent on RDD and nearly silent on IV, so it never covers the
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
  own assumption failures; the router states the question and the warnings, then hands off
  to causal-unstructured.
- Settles: ignorability over text aspects is untestable and must be argued from domain
  knowledge; positivity is generically fragile in high dimensions (a representation that
  nearly encodes the treatment leaves no conceivable counterfactual); consistency fails
  through the measurement model when it was trained on the estimation data, and the fix is
  split-sample measurement (via Egami et al.); invariance and sensitivity test batteries
  for any NLP measure feeding a causal pipeline; there are no real-world ground-truth
  causal text benchmarks, so semi-synthetic wins are never validation of a real estimate.
- Binds when: any unstructured data in the causal graph; the router's role question.
- REVISED WITHIN THE FAMILY: Feder's supervised text-as-confounder route (fine-tuned
  causally sufficient embeddings, Veitch et al. 2020) is superseded by the GPI results, on
  GPI's own simulation evidence; causal-unstructured carries the dispute and the
  replacement route. The router cites Feder for the role triage and the assumption
  failures, never for the Veitch route.
- Version note: read as the arXiv accepted version; cite with TACL pagination (1138-1158).

## Abadie, Athey, Imbens, and Wooldridge (2023)

QJE 138(1): 1-35. Key: `abadie2023clustering`. Read: the latest arXiv e-print (1710.02926),
which cites Rambachan-Roth 2022 and so postdates the 2017 posting; the QJE PDF is
Cloudflare-blocked and the NBER copy is the 2017 vintage, so the version of record is
unverified in detail. Appendix regularity conditions and proofs not read. Promoted from a
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
  effects, with Xu (2019) named for the nonlinear extension; and the particular sampling and
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
published REStud July 2026, no longer the NBER WP), the sensitivity ladder
(`manski1990nonparametric`, `rosenbaum1983assessing`, `imbens2003sensitivity`,
`oster2019unobservable`, `cinelli2020making`, `rosenbaum2002observational`), and the AMA
panel family (`hsiao2012panel`, `li2020inference`, `li2023augmented`, `li2024forward`,
`li2023statistical` for Li-Sonnier). Already in the bib from
method skills and reused here: `crump2009dealing`, `wager2018estimation`,
`chernozhukov2018double`, `xu2017generalized`, `athey2021matrix`, `crepon2013labor`,
`hudgens2008toward`, `athey2018exact`, `egami2022make`, the did/rdd/synth canons. New with
the mediation decline: `imai2010general` and `pieters2017meaningful`, decline pointers
only, NOT canon (the router declines mediation and points to them; no skill carries the
route).

Reference shelf, not canon: `wooldridge2010econometric` (Econometric Analysis of Cross
Section and Panel Data, 2nd ed., MIT Press), the citation for the unobserved-effects model
and strict exogeneity in SKILL.md's plain-panel-fixed-effects section, and the pointer for
the panel methods that section leaves out, random effects among them. Added 2026-08-26 from
the reference list of Cunningham's "Causal Inference: The Remix" panel-data chapter, whose
footnote 1 names it for the same purpose. A textbook, so it carries no reading notes and
does not sit alongside the four read sources above.
