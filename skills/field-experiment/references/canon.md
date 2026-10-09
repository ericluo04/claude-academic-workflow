# Field-experiment canon

Current as of 2026-07-28. Athey-Imbens and Freedman are hand-picked; Lin, Guo-Basse, and Lee
are human-approved addenda (2026-07-28) filling the covariate-adjustment and attrition gaps.
BibTeX keys point into ../../causal-design/references/causal.bib. Refresh: litreview on the
method since the date above, results proposed as flagged addenda.

## Athey and Imbens (2017)

Handbook of Economic Field Experiments, vol. 1, pp. 73-140, DOI 10.1016/bs.hefe.2016.10.003.
Key: `athey2017econometrics`. Read: arXiv 1607.00698
(the published chapter is paywalled; contents match).

- Role: the spine; randomization-based inference put ahead of the regression paradigm, and
  the design and analysis rules that follow.
- Settles: Fisher exact tests and Neyman conservative variance as the default pair; the
  Neyman variance drops an unidentifiable term, so CIs are conservative; HC2 equals the
  Neyman estimator for binary treatment, EHW is anti-conservative with rare arms
  (Behrens-Fisher dof fix); stratify ex ante (weakly dominates complete randomization even
  small-sample), strata to 2+2, do not pair (their position, contested by the later
  matched-pair theory in dispute 1 below, so do not carry it as settled),
  re-randomization needs a pre-specified
  acceptance rule; clustered designs have two estimands and cluster-level analysis is
  primary; ITT plus LATE and never as-treated or per-protocol; honest sample splitting for
  data-driven heterogeneity (coverage survives, MSE pays); QTEs are marginal-quantile
  differences and the bootstrap fails at mass points; interference handled by cluster
  randomization, saturation designs, or network-exact tests with focal/buffer units.
- Binds when: designing any experiment; every analysis choice; the noncompliance and
  interference blocks.
- Implement: names no software; the randomizr/estimatr/ri2/grf mapping is ours, in
  references/details.md.
- Quote: Freedman's "Experiments should be analyzed as experiments, not as observational
  studies," quoted in the chapter's introduction (attribute to Freedman 2006, not the
  chapter).

## Freedman (2008)

Statistical Science 23(2): 237-249. Key: `freedman2008logistic`.

- Role: the estimand discipline for binary outcomes; why covariate-adjusted logit
  coefficients are not treatment effects.
- Settles: under the randomization model the logit treatment coefficient is inconsistent for
  the marginal differential log odds, and the failure is noncollapsibility, not confounding
  (conditional odds multiplier strictly exceeds the pooled one whenever a prognostic
  covariate varies); robust SEs fix nothing about the estimand; the plug-in (standardization)
  estimator is consistent thanks to the canonical-link calibration property, and the
  ITT rate comparison is always available; probit plug-ins are not calibrated;
  "cross-tabulation before regression."
- Binds when: any binary-outcome experiment (the modal marketing experiment); comparing
  odds ratios across specifications, segments, or platforms (banned).
- Implement: glm + marginaleffects::avg_comparisons (our mapping); the four-line per-arm
  imputation pattern in scripts/experiment_template.R.
- Quote: "randomization does not justify the model, so the usual estimators can be
  inconsistent" (abstract). The "almost anything can happen" line belongs to the OLS
  companion paper (`freedman2008regression`), not this one; cite each Freedman to its own
  paper.

## Lin (2013)

Annals of Applied Statistics 7(1). Key: `lin2013agnostic`. Approved addendum.

- Role: closes Freedman's OLS critique; the covariate-adjustment default.
- Settles: under complete randomization, OLS with demeaned covariates and full treatment
  interactions cannot hurt asymptotic precision and is weakly more efficient than
  uninteracted adjustment; the sandwich variance is consistent or asymptotically
  conservative under the Neyman model;
  equal arms make the legacy specification benign, imbalanced arms are where interactions
  protect; adjustment bias is order 1/n with an estimable leading term; covariates chosen
  for prediction, the lagged outcome being the one that reliably matters; the zero-effect
  coverage simulation and leading-term bias estimate as pre-reporting checks; Fisher-Pitman
  CI inversion can undercover the ATE under heterogeneity (temper the RI-first stance to
  sharp nulls).
- Binds when: any OLS adjustment; every holdout design with unbalanced arms.
- Implement: estimatr::lm_lin (named for the paper), HC2 default; with a rare arm, HC2 with
  Imbens-Kolesar degrees of freedom through dfadjust::dfadjustSE on the lm refit.
- Quote: "In large samples, the essential problem is omission of treatment x covariate
  interactions, not the linear model."

## Guo and Basse (2023)

JASA 118(541): 524-536. Key: `guo2023generalized`. Approved addendum. Read: arXiv v1
(JASA text unverified in detail).

- Role: design-based covariate adjustment beyond OLS; the imputation reading that unifies
  Lin and Freedman's plug-in.
- Settles: Lin's estimator is the linear Oaxaca-Blinder imputation estimator, and centering
  is what makes one interacted regression equal two per-arm fits; prediction unbiasedness
  (canonical-link calibration) plus stability gives consistency with no correct-model
  assumption; the CI replaces Neyman arm variances with per-arm MSEs and shortens exactly
  in proportion to fit gains (Poisson imputation 45 percent shorter than Lin on counts);
  recalibration (second-stage OLS) makes any fit usable; NO universal noninferiority
  theorem (linear and isotonic have it, logistic unresolved; no-harm calibration restores
  it); estimand is the sample ATE, and they decline the g-formula superpopulation reading.
- Binds when: nonlinear outcomes (binary, counts, skewed revenue); platform default
  pipelines that must never lose to the difference in means.
- Implement: the paper's own four-line R snippet (in the template verbatim); RobinCar for
  covariate-adaptive designs.
- Quote: the noninferiority disclaimer, "the price of generality."

## Lee (2009)

Review of Economic Studies 76(3): 1071-1102. Key: `lee2009training`. Approved addendum.
Read: NBER WP 11721 (numbers quoted are the WP's).

- Role: attrition and gated outcomes; sharp bounds without exclusion restrictions.
- Settles: conditioning on a post-treatment gate breaks randomization for the gated outcome;
  under monotone selection the excess observation share p0 is point-identified and trimming
  the excess arm gives sharp bounds for the always-observed stratum; no exclusion
  restriction or bounded support needed (vs Heckman and Horowitz-Manski respectively);
  covariate cells tighten (predicted-outcome quintiles, 13 percent in Job Corps);
  Imbens-Manski interval as the default; p0 near zero plus selected-sample balance makes
  the untrimmed estimate valid and efficient; monotonicity is testable at p0 near zero and
  its failure compromises the bounds themselves; selection monotonicity mirrors compliance
  monotonicity (always-observed mirrors always-takers).
- Binds when: any gated outcome (spend given retention, NPS given response, order value
  given purchase); differential attrition of any kind.
- Implement: Stata leebounds (Tauchmann) is the standard; R is hand-rolled or the Semenova
  GitHub package (state verified in references/details.md); the template hand-rolls with a
  bootstrap.
- Quote: "Even a randomized experiment cannot guarantee that treatment and control
  individuals will be comparable conditional on being employed."

## Named disputes and caveats the skill carries

1. Pairing: the canon says never pair (prefer strata of four); later matched-pair theory
   disagrees. Bai (2022, AER) argues for pairing on optimality grounds. Bai, Romano, and
   Shaikh (2022, JASA) give the inference: both t-tests are conservative, and the
   pairs-of-pairs variance has exact asymptotic size. Bai, Jiang, Romano, Shaikh, and Zhang
   (2024) add covariate adjustment with pair fixed effects. Default: strata of at least 2+2
   when designing; analyze existing paired designs as paired; cite each paper for its own
   claim.
2. RI confidence intervals: exact tests of sharp nulls are exact, but Fisher-Pitman
   inversion can undercover the ATE under heterogeneity with unbalanced arms (Lin, citing
   Gail). The skill tests by permutation and interval-estimates by Neyman/HC2.
3. Nonlinear imputation has no universal never-worse guarantee; the earlier reading that
   Guo-Basse prove one is wrong (their explicit disclaimer). Linear or no-harm-calibrated
   imputation when a guarantee is required.

## Primary papers cited through the canon

Resolver-verified entries in causal.bib (field-experiment block): Neyman 1923/1990 and
Fisher 1935 (foundations); Imbens-Rubin 2015 (the long-form source); Freedman 2008
Adv. Appl. Math. (OLS critique, two arms); Imbens-Kolesar 2016 (small-sample robust SEs); Young 2019
(Channeling Fisher); Athey-Imbens 2016 and Wager-Athey 2018 (honest trees, causal forests);
List-Shaikh-Xu 2019 (multiple testing); Hudgens-Halloran 2008, Athey-Eckles-Imbens 2018,
Crepon et al. 2013 (interference); Imbens-Manski 2004 and Horowitz-Manski 2000 (bounds and
intervals); Rosenblum-van der Laan 2010 and Ye et al. 2023 (standardization robustness);
Cohen-Fogarty 2024 (no-harm calibration); Bai 2022 (matched pairs); Tauchmann 2014
(leebounds); Semenova 2025 ("Generalized Lee bounds", J. Econometrics 251); plus reused
iv-block entries imbens1994identification, angrist1996identification, balke1997bounds and
the shared abadie2023clustering.

Tier-2 additions (2026-10-09), each checked against Crossref and its abstract (full text
where noted in causal.bib). Each entry says what it settles for this skill. Entries that
change a rule also say where they bind and give their caveats.

- `freedman2008several` (Freedman, AoAS 2(1), 2008): with several arms, adjustment can lose
  precision even in a balanced design when effects are heterogeneous (Section 4, Example 4).
- `negi2021revisiting` (Econometric Reviews 2021) and `negi2025robust` (JBES 2025): separate
  per-arm adjustment is never less efficient asymptotically; the second paper covers more
  than two arms and the canonical-link nonlinear adjustments that stay consistent.
- `cytrynbaum2024covariate`, `liu2020regression`, `bai2024covariate`: adjustment under
  stratification and pairing (applied in tier 1).
- `bai2022inference` (JASA 2022): matched-pair inference; `bai2022optimality` stays for the
  design argument.
- `morgan2012rerandomization` (AoS 2012) and `li2018asymptotic` (PNAS 2018): rerandomization
  needs a rule fixed in advance; large-sample intervals for its non-normal limit.
- `su2021modelassisted` (JRSSB 2021): design-based estimators for the two cluster estimands.
  The unweighted regression on cluster means targets the cluster-average effect. The
  cluster-size-weighted one, or the regression on scaled cluster totals, targets the
  unit-average effect. Binds: any cluster-randomized design with unequal cluster sizes.
  Caveat: the adjusted cluster-total estimator loses robustness when sizes vary a lot.
- `deng2013improving` (WSDM 2013): CUPED, about 50 percent variance reduction at Bing.
- `deng2018applying` (KDD 2018): delta method for ratio metrics below the randomization unit.
- `johari2022always` (Operations Research 2022), `waudbysmith2024time` (AoS 2024),
  `ham2026design` (Management Science 2026): confidence sequences for continuous monitoring.
  The skill names them and does not implement them.
- `hadad2021confidence` (PNAS 2021): adaptive assignment biases sample means; adaptively
  weighted AIPW intervals. Cited for the caution; causal-design owns the route. Binds: any
  experiment whose assignment probabilities changed with the data (bandits, adaptive
  allocation). Caveat: the template assumes fixed assignment probabilities.
- `ghanem2026testing` (JHR 2026): attrition tests of internal validity; Stata attregtest.
  Binds: any gated or attrited outcome with a baseline measure of it. It replaces the
  comparison of attrition rates as the internal-validity check. Caveat: the descriptions of
  the respondent and population tests at the four-cell level come from behind the paywall
  and are unconfirmed; no R package implements them.
- `stoye2009more` (Econometrica 2009): the Imbens-Manski interval assumes superefficient
  estimation of the bound width. Binds: Lee bounds whose width is near zero relative to
  its standard error. Caveat: the template does not implement Stoye's interval.
- `chernozhukov2025fisher` (Econometrica 2025): BLP, GATES, and CLAN with repeated splitting;
  R package GenericML. Binds: RCT heterogeneity reported for an economics audience. Caveat:
  the paper recommends the nominal 1 - alpha level and GenericML reports 1 - 2 alpha, so
  pass significance_level = 0.025 for 95 percent intervals; the package has no cluster
  option.
- `yadlowsky2025evaluating` (JASA 2025): RATE, implemented in grf.
- `crump2008nonparametric` (REStat 2008): tests of zero and of constant conditional effects.
- `bertanha2020external` (JBES 2020): complier comparability tests, built for fuzzy RD; the
  LATE application is Athey and Imbens's.
- `johnson2017ghost` (JMR 2017): ghost ads as the control-side exposure log.
- `baird2018optimal` (REStat 2018): randomized saturation designs, power, optimal saturations.
- `aronow2017estimating` (AoAS 2017): exposure mappings for network interference.
- `leung2022causal` (Econometrica 2022) and `savje2021average` (AoS 2021): network
  asymptotics under decaying or bounded unknown interference.
- `bojinov2023design` (Management Science 2023): switchback designs and their inference.
- `roth2023efficient` (JPE Micro 2023): the estimator for randomized rollout timing.
