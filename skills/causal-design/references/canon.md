# Router canon

Current as of 2026-07-28. These two sources are the only canon of the causal-design skill,
hand-picked, and nothing enters this file without explicit human approval. BibTeX keys
point into ./causal.bib, which is the one shared bib for the whole skill family. The
router also leans on `arkhangelsky2024causal` (the three-axis panel taxonomy), a
cross-reference owned by the did canon, and on `abadie2023clustering` (clustering as a
design property): the family-wide clustering statement is owned by this skill's own
SKILL.md, whose frontmatter claims the shared inference rules, while method skills carry
design-specific instances. Refresh: run litreview on the moving corner (panel estimators)
since the canon date. Any addendum needs explicit human approval.

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
  (Robins tradition).
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
  fuller feasibility gate; SKILL.md carries it); the data-shape fan-out within the panel
  branch: convex-hull failure -> augmented DiD (Li-Van den Bulte), outcome in range but
  too few pre-periods -> forward DiD (Li), controls far fewer than pre-periods -> HCW OLS
  (Hsiao-Ching-Wan), many treated units or short panels -> generalized synthetic control /
  matrix completion, unit and time reweighting both wanted -> SDID with inference
  procedure chosen by data shape; PSM "called into question," replaced by AIPW, double ML,
  causal forests; unconfoundedness often defensible in marketing because targeting rules
  are known and observable; the Li-Sonnier result that the gsynth parametric bootstrap
  yields biased CIs ("false precision or false imprecision... lead to incorrect business
  decisions"); the field vocabulary (design rigor vs statistical rigor, ATT-first, clean
  controls).
- Binds when: routing within the panel branch; arguing a method is accepted marketing
  practice; writing for marketing reviewers.
- Caveats: read via WebFetch extraction, so re-verify any quotation against the live page
  before it enters a paper; two of the three authors developed the augmented/forward DiD
  estimators, so the piece leans toward that family and the synth/did skills weigh those
  methods independently; silent on RDD and nearly silent on IV, so it never covers the
  confounded-observational branch beyond panel methods. Figure 1 ("Overview of Design
  Choices in Quasi-Experimental Settings") was read against the article text on
  2026-07-28. The figure is coarser than the article text (it lumps augmented DiD under
  too-few-pre-periods where the text gives it the convex-hull condition; HCW and matrix
  completion appear only in the text); where they differ, this skill follows the text.

## Primary papers cited through the canon

New to the bib with this skill: `hirano2003efficient` (estimated propensity score),
`li2018balancing` (overlap weights), `bang2005doubly` (doubly robust), `athey2021policy`
(policy learning), `aronow2017estimating` (exposure mappings), `bajari2023experimental` and
`johari2022experimental` (marketplace designs), `athey2026surrogate` (the surrogate index,
published REStud July 2026, no longer the NBER WP), the sensitivity ladder
(`manski1990nonparametric`, `rosenbaum1983assessing`, `imbens2003sensitivity`,
`oster2019unobservable`, `cinelli2020making`, `rosenbaum2002observational`), and the AMA
panel family (`hsiao2012panel`, `li2020inference`, `li2023augmented`, `li2024forward`,
`li2023statistical` for Li-Sonnier). Already in the bib from method skills and reused
here: `crump2009dealing`, `wager2018estimation`, `chernozhukov2018double`,
`xu2017generalized`, `athey2021matrix`, `crepon2013labor`, `hudgens2008toward`,
`athey2018exact`, the did/rdd/synth canons. New with the mediation decline:
`imai2010general` and `pieters2017meaningful`, decline pointers only, NOT canon (the
router declines mediation and points to them; no skill carries the route).
