# Conjoint canon

Current as of 2026-10-09. The user picked fourteen sources and approved a fifteenth,
`egami2019causal`, on 2026-08-05; nothing enters this file without their approval. BibTeX keys
point into ../../causal-design/references/causal.bib, the family's shared bib. Refresh:
litreview on conjoint methodology since the canon date; addenda need user approval.

## The randomized-experiment track

### Hainmueller, Hopkins, and Yamamoto (2014)

Political Analysis 22(1): 1-30. Key: `hainmueller2014causal`.

- Role: the identification anchor. Puts conjoint on potential-outcomes footing; defines the
  AMCE and its averaging set; the assumption ladder (no carryover, no profile-order effects,
  randomization with positivity; conditionally vs completely independent randomization).
- Settles: one OLS on attribute dummies computes all AMCEs under full randomization;
  respondent-clustered SEs mandatory (within-task outcomes mechanically negatively
  correlated); the eq. 9 interaction-plus-weighting estimator under restricted
  randomization; the five-check diagnostic battery; the averaging distribution is
  analyst-chosen and must be disclosed; ACIEs and pretreatment-conditional AMCEs
  identified; the AMCE-in-any-factorial observation (collapsed multi-factor arms are
  implicit AMCEs).
- Binds when: any AMCE estimation; restricted designs; the diagnostics battery; inference.
- Caveats: implicitly assumes zero measurement error (revised by Clayton et al. 2026); its
  own subgroup comparison models the misuse Leeper et al. correct; uniform default matured
  into a testable claim by de la Cuesta et al.

### Hainmueller, Hangartner, and Yamamoto (2015)

PNAS 112(8): 2395-2400. Key: `hainmueller2015validating`.

- Role: the external-validity leg. Benchmarks five survey formats against Swiss secret-ballot
  naturalization referendums where the official leaflet was the voters' entire information
  set.
- Settles: paired conjoint tracked 21 behavioral attribute effects with mean absolute error
  2pp and reproduced the 15-19pp origin penalty; paired beats single throughout; the
  format-mimicking single vignette was worst; a student convenience sample failed with the
  forced-choice paired questionnaire (mean error 7pp against 4pp for that design on the
  main sample); absolute levels fail everywhere (21% predicted vs 37% actual);
  satisficing (accept-all share) tracks the attenuation.
- Binds when: any external-validity sentence; format and sample choices.
- Caveats: ONE domain (approve/reject decisions on people), one country; the benchmark is
  itself an estimate; no ratings arm, so it cannot adjudicate choice vs ratings; never cite
  as "conjoint is validated" without the scope limit.

### Bansak, Hainmueller, Hopkins, and Yamamoto (2021)

Chapter 2 of Advances in Experimental Political Science, CUP, 19-41. Key: `bansak2021conjoint`.

- Role: the consolidated practice review; the design-defaults section in near-final form.
- Settles: paired profiles default; a conservatively chosen task count well inside the
  30-task evidence (its own example ran 15); ~10 attributes with the masking-satisficing
  tradeoff named; uniform randomization with three
  sanctioned deviations (weighted draws with disclosed odds, restrictions for impossible
  combos, joint draws); row order randomized across respondents and frozen within; both
  outcomes collected, order randomized; tables over vignettes; preregister because of
  multiple comparisons; the applications census (124 articles).
- Binds when: setting design defaults.
- Caveats: read as the 2019 author preprint; SILENT on inference (HHY 2014 keeps that
  citation); superseded on the averaging distribution (de la Cuesta), subgroups (Leeper),
  interpretation (the dispute pair), and measurement error (Clayton); cite the satisficing
  anchors from their published versions, not this chapter's summaries.

### Bansak, Hainmueller, Hopkins, and Yamamoto (2018) + companion

Political Analysis 26(1): 112-119, key `bansak2018number`; companion PSRM 9(1): 53-71,
key `bansak2021beyond`.

- Role: the design-size evidence.
- Settles: degradation is front-loaded and bounded (AMCEs drop once from task 1 to 2, flat
  through 30; partial R2 likewise), so K is chosen by power and cost; the companion's
  two-stage filler design shows attenuation roughly uniform across attributes out to 15-35
  fillers, so relative magnitudes survive while small effects lose significance first; the
  masking formalization (the AMCE is conditional on the included attribute set).
- Binds when: task and attribute counts; the per-task diagnostic.
- Caveats: scope is opt-in online panels in familiar domains; stability across tasks must
  NEVER be cited as evidence of per-task reliability (that is Clayton's 75%).

### Leeper, Hobolt, and Tilley (2020)

Political Analysis 28(2): 207-221. Key: `leeper2020measuring`.

- Role: the subgroup-reporting discipline.
- Settles: MMs are the primitive, AMCEs derived contrasts; differences in conditional
  AMCEs across subgroups have arbitrary sign, size, and significance as preference
  statements (they equal the preference difference only when groups feel identically about
  the reference category); the fix is conditional MMs, their differences, and the
  nested-model omnibus F; the reference-sensitivity diagnostic; the bounds caveat on
  comparing AMCE magnitudes across attributes with different level counts; a 23-paper
  audit of the misuse in top venues.
- Binds when: any subgroup or cross-sample comparison; descriptive preference reporting.
- Caveats: cregg, its software, is archived off CRAN (hand-roll or projoint); MMs inherit
  the AKM intensity critique wholesale (the firewall applies to them too).

### Egami and Imai (2019)

JASA 114(526): 529-540. Key: `egami2019causal`. Added 2026-08-05, promoted from the
flagged-unread list below.

- Role: the interaction estimand. HHY gave the design a main effect; this gives it an
  interaction effect that survives the absence of a natural baseline.
- Settles: the AMIE as the interaction estimand that survives an arbitrary baseline,
  with the mechanical-zero corollary for the conventional AIE (Theorems 1 to 3). The
  derivation, the estimators, the regularization, and inference after selection are in
  details.md, section "Causal interaction: the AMIE (Egami and Imai 2019)".
- Binds when: any attribute-by-attribute interaction claim; any high-dimensional interaction
  search; whenever the pAMCE machinery says interactions are what drives the uAMCE gap and the
  user asks which ones.
- Caveats: positivity is required for ALL combinations, so restricted randomization needs
  HHY's footnote-18 repair or a restricted estimand; treatment-by-pretreatment-covariate
  interaction is explicitly future work, so respondent subgroups stay with Leeper's marginal
  means; the application is small (544 respondents) and assumes away three-way interactions;
  composition with the tau correction is unstudied (the skill's own judgment). FindIt's
  `screen` option delegates to glinternet, so the invariance claim covers the collapse and
  estimation stages, not the screening stage (our reading, not the paper's claim).

### de la Cuesta, Egami, and Imai (2022)

Political Analysis 30(1): 19-45. Key: `delacuesta2022improving`.

- Role: the averaging-distribution machinery; profile realism as the second
  external-validity axis.
- Settles: uAMCE vs pAMCE vocabulary; the gap equals interactions times distance from
  uniform; 88% of practice used uniform, under 4% justified it; restrictions do not close
  the gap; the three-design ladder (joint / marginal / mixed population randomization)
  keyed to data availability, with marginal randomization making plain dummies consistent
  for the pAMCE under no three-way interactions; the ESS pre-fielding check; the
  model-based reanalysis recipe for fielded uniform data (two-way interaction LPM,
  marginal-weighted sums, generalized-lasso collapsing with cross-fitting, block
  bootstrap); the three-way F diagnostic; published nulls move (Ono-Burden's -0.09pp
  becomes -1.98/+5.69 by party).
- Binds when: choosing or defending the averaging distribution; any pAMCE estimation;
  counterfactual-distribution sensitivity when no natural target exists.
- Caveats: the resolution adopted by this skill (uniform demoted from safe harbor to a
  testable claim) is the family's synthesis of this paper with HHY's disclosure rule.

### Abramson, Kocak, and Magazinnik (2022)

AJPS 66(4): 1008-1020. Key: `abramson2022what`.

- Role: the interpretation critique; the claims firewall's foundation.
- Settles: the AMCE is proportional to a Borda-count difference, mixing direction and
  intensity; it can carry the opposite sign of the majority preference with rational
  respondents; design dependence (adding an attribute flipped -1/20 to +1/16, the Borda
  IIA violation); the three valid readings (vote-share change, Borda difference, mean
  ideal point under quadratic RUM); the sharp bounds on the fraction preferring given the
  AMCE, K, and levels; the sign-correspondence condition (direction-intensity
  uncorrelated, empirically the exception: 17 of 22 ANES issues correlated); the audit
  (only one published effect size clears the majority bound).
- Binds when: any preference-talk sentence; any proportion claim; ratings get no
  exemption.
- Caveats: the ceteris paribus preference definition is the weak flank (its own Prop 4
  concedes non-separability breaks it); read WITH the rejoinder below, adjudicated cell in
  details.md.

### Bansak, Hainmueller, Hopkins, and Yamamoto (2023)

Political Analysis 31(4): 500-518. Key: `bansak2023using`.

- Role: the rejoinder; the estimand's defense and the constructive alternatives.
- Settles: accepts AKM's mathematics wholesale and generalizes the Borda result (expected
  Borda scores under any independent-profiles randomization); the AMCE identifies the
  expected-vote-share effect in the target election (A, V) for any preference structure
  and any J; vote share is the field's modal estimand (87% of 82 voting articles); the
  bilateral firewall (their own reporting rules ban the majority reading);
  probability-of-winning as a separate, model-based estimand (calibration-validated; the
  "conditional logistic ridge" is unconfirmed, since the main text sends the estimator to
  a Supplementary Material not yet read); the fraction-preferring estimand is infeasible
  from typically sized data because individual-level data are sparse (p. 502; "biased
  toward 0.5" is unconfirmed); the clarified contrast (vs independently drawn opponents).
  The vote-share identification result is Proposition 2 (p. 510).
- Binds when: electoral/vote-share language; electability requests; adjudicating the
  dispute.
- Caveats: the intensity defense answers the vote-share question, not the head-count
  question; the dispute cell in details.md carries the asymmetries.

### Clayton, Horiuchi, Kaufman, King, and Komisarchik (2026)

AJPS, early view (backfill pages when assigned). Key: `clayton2026correcting`.

- Role: the measurement-error layer; the analysis-side anchor.
- Settles: IRR ~75% (73-81 across eight from-scratch replications, 9,472 respondents);
  attention checks do not explain it; swapping error attenuates AMCEs by (1-2tau) (~30%
  at tau=0.15) and shrinks MMs toward 0.5; subgroup differences can attenuate, exaggerate,
  or flip (82%/12%/5%); IRR invariant to attribute content but varying with respondent
  characteristics, so one tau per study and subgroup-specific tau for subgroups; the
  closed-form correction with tau from a repeated final task (columns flipped, undetected
  by all 9,472) or extrapolation from task-pair agreement; choice-level data structure;
  the replication side-finding (all eight studies replicate, median correlation 0.9).
- Binds when: every new conjoint design (the repeated task); every analysis (correct or
  justify tau=0); all subgroup work.
- Caveats: binary forced choice only, the correction does not transfer to ratings or
  rankings; early view, pages pending.

### Liu and Shiraito (2023)

Political Analysis 31(3): 380-395. Key: `liu2023multiple`.

- Role: the multiple-testing discipline.
- Settles: over 90% of null experiments at realistic design size (41 tests) produce at
  least one significant AMCE under the standard pipeline; all three corrections dominate
  none; the matched default (adaptive shrinkage when priors weak, BH exploratory,
  Bonferroni confirmatory with a preregistered family); Ash also improves point estimates
  (smaller MSE); report corrected and uncorrected side by side; the family-definition
  discipline (realism-only attributes excluded from the family are excluded from reported
  findings).
- Binds when: any conjoint inference with many levels; preregistration of the correction.
- Caveats: corrections inherit input biases; composition with the tau correction is
  unstudied (the skill labels it our own judgment).

## The preference-measurement track

### Netzer et al. (2008)

Marketing Letters 19(3-4): 337-354. Key: `netzer2008beyond`.

- Role: the marketing-side agenda and taxonomy; conjoint as "only a special case" of
  preference measurement; the fork's first question (whose problem, what will they do
  with the output).
- Settles: HB as the standard estimator; the adaptive-design family (and that it exists to
  serve prediction, not causal identification); incentive alignment over hypothetical
  tasks (26% to 48% holdout hit rates); the Sonnier prior trap flagged; auxiliary-data
  fusion; the isomorphic/paramorphic rule (quoted in details.md, section "Marketing
  translation and instrument threats"); the action stage (posterior expected loss,
  product-line optimization).
- Binds when: the fork; adaptive designs; the marketing track's scope.
- Caveats: an agenda paper, no estimands, no estimators, no software; never cite for
  identification, inference, or diagnostics.

### Agarwal, DeSarbo, Malhotra, and Rao (2015)

Customer Needs and Solutions 2(1): 19-40. Key: `agarwal2015interdisciplinary` (the bib key;
a reader once proposed agarwal2015conjoint, the bib's key wins).

- Role: the marketing consensus map circa 2014 (five categories, three stakeholders).
- Settles: CBC as the dominant format; HB "comparable or even superior" for partworths and
  prediction, robust to distributional violations; latent class for segmentation
  deliverables with poor individual predictions; incentive alignment changes estimates
  (higher price sensitivity) with mechanism-choice rules (WTP mechanism vs Rank Order);
  the efficient-design ladder and the S-vs-R-efficiency tradeoff; the respondent-behavior
  threat list (no-choice effects, number-of-levels effect, attribute nonattendance,
  noncompensatory screening, context effects); MaxDiff properties; MVAI and the
  managerial-translation layer.
- Binds when: marketing-track defaults; instrument-threat checks; MaxDiff and menu
  formats.
- Caveats: heavy self-citation by the author group; dated 2014 (nothing on software or the
  poli-sci wave); Perspectives genre.

### Rossi, Allenby, and Misra (2024) + bayesm

Bayesian Statistics and Marketing, 2nd ed., Wiley. Keys: `rossi2024bayesian` (book),
`rossi2025bayesm` (package, 3.1-7).

- Role: the HB estimation anchor with the reference implementation.
- Settles (at package-doc and source level, verified): the hierarchical MNL with
  mixture-of-normals heterogeneity; exact rhierMnlRwMixture signature and lgtdata/createX
  input formats; every prior default with the unit-scale assumption explicit; sign-
  constraint mechanics (beta = SignRes*exp(beta*), hierarchy on beta*); the two
  doc-vs-code discrepancies (Metropolis scale 2.38/sqrt(nvar) in code vs 2.93 in the man
  page; the sign-constrained V overwritten late in code, contradicting man page AND
  vignette), hence the pass-the-full-Prior rule; MCMC practice (the man page: "Large R
  values may be required (>20,000)"; quantiles not just means; the book's one-chain
  ESS/trace/ACF and 10% burn-in are superseded by Vehtari et al. 2021, below);
  rhierMnlDP, rhierLinearMixture (ratings), camera data.
- Binds when: any HB estimation; prior reporting; the marketing-track template.
- Caveats: 2e author list is Rossi-Allenby-MISRA (the package DESCRIPTION's Description
  field still names McCulloch; `citation("bayesm")` names no book); Chapters 5, 10, 11
  unread (paywalled), so WTP-chapter content ("WTP Properly Defined") is NOT asserted, only
  named; version-pin bayesm, defaults have
  changed across releases.

### Sonnier, Ainslie, and Otter (2007)

QME 5(3): 313-331. Key: `sonnier2007heterogeneity`.

- Role: the WTP-space anchor.
- Settles: utility and surplus parameterizations have equivalent likelihoods, but normal
  partworths over a lognormal price coefficient imply a fat-tailed WTP prior that sparse
  per-respondent data never overwhelm; the surplus reparameterization (normal prior on
  WTP directly) recovers true WTP better in all four simulation DGPs including the two
  generated by the utility model; empirical magnitudes (means 2-3x, sds 5-6x inflated;
  optimal prices outside the experimental range: $33,200 Taurus, over $1,500 camera); validate
  on holdout LPD, never in-sample LMD/DIC (both preferred the wrong model on known
  truth); the median dodge for legacy partworth analyses and why it fails for
  decision-theoretic uses.
- Binds when: any WTP, reservation-price, or price-optimization deliverable.
- Caveats: read as the SSRN WP; the numbers in details.md were checked against the
  published article on 2026-10-09 (pp. 318-329);
  homogeneous models exempt; the fit-ranking is contested with Train-Weeks (write the
  rule as prior-on-the-quantity-you-report); finite-WTP-for-everyone is an assumption.

## Primary papers cited through the canon

Already in the shared bib and key here: `hainmueller2014causal`,
`hainmueller2015validating`, `bansak2021conjoint`, `bansak2018number`, `bansak2021beyond`,
`leeper2020measuring`, `egami2019causal`, `delacuesta2022improving`, `abramson2022what`,
`bansak2023using`, `clayton2026correcting`, `liu2023multiple`, `netzer2008beyond`,
`agarwal2015interdisciplinary`, `rossi2024bayesian`, `rossi2025bayesm`,
`sonnier2007heterogeneity`.

New to the bib with the Egami-Imai addendum, cited through it and NOT read: `post2013factor`
(GASH-ANOVA, the level-collapsing regularizer) and `lim2015learning` (glinternet, behind
FindIt's screening option and named in the paper as a method that lacks the invariance).

Flagged-unread neighbors (NOT canon; addendum candidates needing user approval before any
key citation): Ganter 2023 (direct-preference estimand); Ham-Imai-Janson 2024, Political
Analysis 32(3): 329-344 (the CRT carryover test's own paper); Dafoe-Zhang-Caughey 2018
(information equivalence / masking formalized); Horiuchi-Markovich-Yamamoto (social
desirability); Goplerud-Imai-Pashley 2025, Annals of Applied Statistics 19(2): 866-888
(heterogeneity); Train-Weeks 2005 (econ-side WTP space; user declined 2026-07-29, cite only
via Sonnier reception); the 2e book chapters 10-11
(read before asserting their content); Rao 2026 Applied Conjoint Analysis 2e.
The Rao entry and the Train-Weeks declination come from the
build-session discussion; no reading note covers them.

## Tier-2 additions (2026-10-09, approved with the audit's tier 2)

Written from abstracts and, where marked, the section that carries the claim. None is a
canon anchor; each supports one rule in SKILL.md or details.md.

- Vehtari, Gelman, Simpson, Carpenter, and Bürkner (2021), Bayesian Analysis 16(2):
  667-718, `vehtari2021rank`. Role: the HB convergence standard. Settles: four chains,
  split rank-normalized R-hat below 1.01, bulk and tail ESS above 400, rank plots (Section
  2). Binds: every HB run. Caveat: bayesm runs one chain per call and starts all chains at
  the same values, so the template's R-hat is weaker than from overdispersed starts.
- Daly, Hess, and Train (2012), Transportation 39(1): 19-31, `daly2012assuring`. Role:
  why WTP means explode. Settles: a WTP ratio whose price coefficient has density at zero
  has no finite moments. Binds: any WTP from partworth space. Caveat: the attribution
  rests on the title and the literature; the text was not read.
- Stan User's Guide 2.40 (2026), Regression Models, "Multivariate priors for hierarchical
  models", `standevelopmentteam2026stan`; with Lewandowski, Kurowicka, and Joe (2009),
  Journal of Multivariate Analysis 100(9): 1989-2001, `lewandowski2009generating`. Role:
  the price of the inverse-Wishart and the LKJ alternative. Binds: the HB prior paragraph.
  Caveat: bayesm offers only the inverse-Wishart.
- Orme (2024), Sawtooth Software research paper, `orme2024comparison`, summarizing van
  Horn (2024, not public). Role: the one head-to-head of MH, HMC, and VB on CBC data, and
  the draws-over-point-estimates rule for share simulation (p. 4). Caveat: a practitioner
  summary of an unpublished white paper.
- Robinson and Duch (2024), Journal of Politics 86(2): 412-427, `robinson2024how`; Zhirkov
  (2022), Political Analysis 30(2): 236-249, `zhirkov2022estimating`. Role: individual
  marginal component effects (IMCEs), by BART with post-estimation partitioning (cjbart)
  and by a respondent-level procedure with design changes. Binds: subgroup discovery when
  the moderators are not known in advance. Caveat: exploratory; confirm with conditional
  MMs.
- Bansak and Jenke (2025), Political Analysis 33(4): 315-338, `bansak2025odd`. Role:
  eye-tracking evidence that odd attribute-level combinations barely move attention,
  search, or choice. Binds: the restrictions-for-impossible-combinations-only default.
- Abramson, Kocak, Magazinnik, and Strezhnev, SocArXiv xjre9 (v1 2023, v3 2026),
  `abramson2023aggregation`. Role: the AKM side's sequel, the average feature choice
  probability for binary preference relations. Caveat: preprint, read from the abstract.
