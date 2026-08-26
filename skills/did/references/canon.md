# DiD canon

Current as of 2026-08-26. These sources are hand-picked; nothing enters this file without
explicit human approval. BibTeX keys point into ../../causal-design/references/causal.bib.
Refresh: litreview on the method since the date above, results proposed as flagged addenda.

## Roth, Sant'Anna, Bilinski, and Poe (2023)

Journal of Econometrics 235(2): 2218-2244. Key: `roth2023whats`.

- Role: synthesis and default workflow; the triage checklist.
- Settles: TWFE failure modes under staggered adoption (negative weights, forbidden comparisons,
  event-study contamination); the CS-vs-imputation baseline tradeoff; pre-trend tests are
  underpowered with quantified stakes (Roth 2022 numbers); conditional PT wants RA/IPW/DR, never
  bare controls; cluster where treatment is independently assigned; the few-clusters map keyed
  to homogeneity assumptions.
- Binds when: any staggered design; any pre-trends discussion; any few-clusters problem.
- Implement: the package table (did/csdid, did2s, didimputation, DIDmultiplegt, fixest::sunab,
  HonestDiD, pretrends, bacondecomp, TwoWayFEWeights, staggered).
- Quote: "The lack of a significant pre-trend does not necessarily imply the validity of the
  parallel trends assumption."

## Baker, Callaway, Cunningham, Goodman-Bacon, and Sant'Anna (2026)

Journal of Economic Literature 64(2): 498-557. Key: `baker2026did`.

- Role: the build-order guide; forward engineering from estimand to estimator; worked Medicaid
  application with public R and Stata replication code (AEA materials 25430, 25431).
- Settles: weights define the estimand (unit vs person average, +0.1 vs -2.6); the three formal
  staggered PT variants (Nev, NYT, all) and the estimator-to-assumption crosswalk; TWFE with
  covariates fails even in the 2x2 (Caetano-Callaway); DR default with 0.995 propensity
  trimming; balanced-event-time aggregation; repeated-cross-section composition rules
  (Sant'Anna-Xu); the DDD warning (Ortiz-Villavicencio-Sant'Anna); worked HonestDiD arithmetic.
- Binds when: setting up any DiD analysis; choosing the PT variant; covariates enter; the panel
  is unbalanced or a repeated cross-section.
- Implement: did::att_gt + aggte as the core stack; est_method="dr"; etwfe/jwdid for Wooldridge;
  the estimator-to-assumption crosswalk is the paper's core practical content.
- Quote: TWFE has "well-understood, potentially serious, and easily remedied problems, and we do
  not recommend using it"; researchers must "clearly state the specific parallel trends
  assumption they are actually imposing."

## Arkhangelsky and Imbens (2024)

The Econometrics Journal 27(3): C1-C61. Key: `arkhangelsky2024causal`.

- Role: the unifying survey and the boundary document with synthetic-control; the taxonomy the
  causal-design router uses.
- Settles: three-axis classification (data type, frame shape, assignment mechanism); DiD, SC,
  unconfoundedness, and matrix completion as one optimization problem under different
  restrictions; under selection on lagged outcomes with autocorrelated errors DiD is
  inconsistent while SC is consistent (the routing result, due to Arkhangelsky-Hirshberg and
  relayed by this survey); the TWFE-vs-lagged-outcome bracketing; negative-weight concerns
  "have perhaps been exaggerated" (the named dissent from the clean/forbidden framing);
  backdated placebo tests can backfire under selection on past shocks.
- Binds when: choosing between did and synthetic-control; block vs staggered assignment; deciding
  whether the additive model itself is the weak point.
- Implement: names no software; the standard mapping (did, fixest::sunab, DIDmultiplegt,
  didimputation, synthdid, gsynth, fect, MCPanel) is ours, from package docs.
- Quote: "we recommend against the current routine use of the standard TWFE estimator or related
  estimators," paired with the block-assignment exception.

## Abadie, Angrist, Frandsen, and Pischke (2025)

NBER WP 34550; chapter of Metrics Remastered, Princeton UP 2026. Key: `abadie2025harvesting`.

- Role: the counterweight; specification mechanics the guides skip; the pro-pretesting position.
- Settles: lead/lag arithmetic (q = T - min c(s), m = max c(s) - 1); the second-normalization
  requirement without never-treated units and the path-rotation demonstration; leverage failure
  of clustered SEs at long horizons, fixed by binning and sup-t bands; the pretesting
  cost-benefit rule (screening pays when |delta_s|/(2-theta) < delta at calibrated power);
  exposure-design estimands (average marginal effect, not E[tau_s]); "DD identification
  strategies are inherently transformation-dependent"; BJS-vs-TWFE agreement in the divorce data
  as the empirical bottom line.
- Binds when: writing any event-study specification; no never-treated units; long panels; deciding
  whether to pretest; exposure designs; the logs-vs-levels choice.
- Implement: Stata boottest (the only package it names); the sup-t four-step recipe is
  implementable from the covariance matrix directly (details.md).
- Quote: heterogeneity concerns "are unlikely to derail DD or event-study designs in practice";
  "Better to choose these reference points deliberately than to let regression software make
  hidden—and potentially misleading—choices for you." (the em dashes are the paper's own,
  verified against NBER WP 34550 p. 2; verbatim quotes keep source punctuation)

## MacKinnon, Nielsen, and Webb (2023)

Journal of Econometrics 232(2): 272-299. Key: `mackinnon2023cluster`.

- Role: execution companion to the Roth et al. few-clusters map; the routine cluster-inference
  battery, its diagnostics, and the failure signatures.
- Settles: there is no safe G ("In very favorable cases, inference based on CV1 and the t(G-1)
  distribution can be fairly reliable when G = 20, but in unfavorable ones it can be unreliable
  even when G = 200 or more"; score heterogeneity, cluster-size variation, and leverage decide);
  CV3, the cluster jackknife, is the most reliable CRVE and runs with t(G-1) as first line,
  cheap even for huge samples; cluster at the assignment level or coarser, largest-SE rule of
  thumb, and picking the level by test is pre-testing; cluster FEs do not remove intra-cluster
  dependence outside pure random effects; few treated clusters is a distinct failure ("the CV1
  standard error of this coefficient can easily be too small by a factor of five or more" at
  G1 = 1, and CV3 helps but still fails when G1 is very small) while WCR fails the other way
  (under-rejection, bimodal bootstrap distribution as the tell, ordinary WR bootstrap as the
  rescue); RI-t over RI-beta under cluster-size heterogeneity; the five concern zones (G <= 12;
  G1 <= 6 or G - G1 <= 6; seriously unbalanced sizes; atypical treated clusters; leverage
  concentration); reporting G, cluster sizes, leverage, partial leverage, and effective
  clusters is part of the method.
- Binds when: any clustered inference on a CRVE; choosing the clustering level; any of the five
  concern zones fires; before reaching for the few-clusters map.
- Implement: Stata boottest, summclust, edfreg, randcmd (the paper's own stack); in R,
  fwildclusterboot 0.14.3 and summclust 0.7.0 (both archived from CRAN, r-universe builds),
  clubSandwich CR2/Satterthwaite, sandwich vcovBS jackknife (details.md package index and
  did_template.R section 10); no R package implements RI-t, hand-roll it.
- Scope limits: IV with clustered data explicitly out of scope (theory and simulations
  insufficient; the iv skill must not cite it for clustered-IV fixes); two-way clustering
  theory still developing; model-based inference only, with the design-based AAIW branch set
  aside; Donald-Lang is the one map row the guide does not discuss.
- Quote: "it is therefore absolutely essential to report the number of clusters, G, whenever
  inference is based on a CRVE. This is even more important than reporting N."

## Winkler, Hotz-Behofsits, Wlömert, Papies, and Liaukonytė (2026)

Quantitative Marketing and Economics 24: article 10. Key: `winkler2026tiktok`.

- Role: the functional-form and estimand companion, marketing-native. An applied paper (UMG's
  TikTok withdrawal, 53,753 matched song pairs, Spotify streams) whose Section 6 practitioner's
  companion (pp. 25-27) is the guide. Fenced scope: two-group single-timing designs. It says
  nothing about staggered adoption, HonestDiD, few clusters, anticipation, or repeated cross
  sections, and must not be cited for them.
- Settles: three estimands (typical-unit % = ΔΔE[log Y], population-total % = ΔΔ log E[Y],
  level = ΔΔE[Y]) that differ in sign on the same clean design (log OLS +0.0063, PPML -0.0310,
  weighted log OLS -0.0286); estimand from the question, then estimator; PPML as the default
  for population-total % under heavy tails, consistent for any nonnegative Y with
  equidispersion an efficiency condition only; implicit weighting as a separate estimand
  choice (Solon-Haider-Wooldridge); the second log-OLS failure (treatment-induced Var(log Y)
  shift, the cumulant expansion in fn. 18, the Ciani-Fisher squared-residual diagnostic, a
  calibrated simulation with a spurious positive under a true null); levels TWFE sign-unstable
  under proportional growth with baseline gaps; matching on baseline as a special case, not a
  general fix; the SDID caveat; concentration diagnostics (Lorenz, Gini, top-decile share)
  before anything; PT stated on a named scale; interference can belong to the estimand under
  share-based payouts.
- Binds when: the outcome is revenue, streams, sales, views, engagement, or anything
  heavy-tailed; a log outcome is proposed; levels and logs disagree; a referee asks for
  "functional-form robustness".
- Implement: ppmlhdfe (the only package it names) and the authors' DiDestimands.app; in R
  fixest::fepois and etwfe(family = "poisson") are ours, from package docs.
- Quote: "these choices are not interchangeable robustness checks: they target different
  estimands and impose different counterfactual trend restrictions" (p. 11); "PT in levels and
  PT in logs are different assumptions — the data cannot tell you which holds" (p. 27; the em
  dash is the paper's own).

## Wooldridge (2026)

AEA Papers and Proceedings 116: 75-80. Key: `wooldridge2026nonlinear`.

- Role: the nonlinear recipe for repeated cross sections, extending Wooldridge (2023,
  `wooldridge2023simple`) from panels; the repeated-cross-section case of the estimator etwfe
  and jwdid implement (both predate the paper and coincide with it once unit FEs are dropped).
- Settles: PT on the index G^{-1}(E[Y_t(∞) | D, X_t]) (log odds under logit, log mean under
  the exponential mean) with the explicit statement that CS, BJS, and DNWZ state PT in levels,
  and that index PT holds in levels only under no selection (β_g = η_g = 0) or a stationarity
  restriction; one pooled QMLE in the LEF with the canonical link on all observations, cohort
  dummies in place of unit FEs, covariates centered within cohort-period cells and interacted
  with cohort, time, and treatment; robustness to distributional misspecification (only the
  conditional mean must be right); pooled QMLE equals imputation under canonical links and
  avoids the two-step SE problem; ATT(g,t) as APEs of the binary treatment dummy, aggregated
  by exposure time with N_gt weights; the PT-diagnostic event study on the index scale, not
  the mean; lags-only and leads-and-lags both reported, unrankable on bias or efficiency;
  cohort-specific trends as a contamination-free pretest when covariates enter flexibly, at a
  precision cost; collapse thin cohort cells to exposure-time or constant effects so the
  inference can be trusted; cluster at the assignment level (AAIW) even under independent
  sampling, and at the sampling cluster under cluster sampling; a never-treated group is
  assumed, relaxable per Wooldridge (2023).
- Binds when: the outcome is binary, fractional, or a count; units are seen once (surveys,
  trackers, transactions); staggered adoption in a repeated cross section; a linear
  probability DiD is on the table (he compares logit against a DNWZ-style LPM).
- Implement: Stata APE facilities (the only software named; the Secure Communities application
  with 682 PUMAs is available from the author with Stata code). etwfe 0.6.2 (ivar = NULL,
  family = "poisson"/"logit", emfx) and jwdid 2.0 (no ivar, method(poisson|logit)) are ours,
  from package docs and source, verified 2026-08-26.
- Quote: "Assumption CPT imposes the parallel trends assumption on G^{-1}(E[Y_t(∞) | D, X_t]).
  In general, CPT does not hold for E[Y_t(∞) | D, X_t]" (p. 76).

## Named disagreements the skill carries

- TWFE in practice: Baker et al. and Arkhangelsky-Imbens against routine use; AAFP find it
  adequate with a BJS check. Default: robust headline, TWFE alongside.
- Pretesting: Roth (2022) caution vs AAFP pro-pretest cost-benefit. Default: sup-t pretest plus
  power report, never a substitute for HonestDiD.
- What follows from robust-estimator agreement: AAFP keep TWFE as workhorse; A-I move to
  factor/SC/SDID because the additive model is the weak point. Presented as live.
- Which question the headline estimator answers: Baker et al. and Roth et al. fix the
  staggered-timing bias; Winkler et al. show four estimators disagree in sign in a single-date
  two-group design where staggered timing does not arise, because functional form and weights
  pick the estimand, and Callaway-Sant'Anna appears only as a matching-robustness row.
  Resolution here: orthogonal questions, both
  answered. Name the estimand and scale first (Winkler et al.), then the PT variant and the
  heterogeneity-robust estimator on that scale (Baker et al.); etwfe with a nonlinear family,
  or PPML with cohort-by-period treatment dummies, does both at once. Wooldridge (2026) adds
  that index PT in general fails in levels (two exceptions: no selection, or stationarity), so
  the linear-versus-nonlinear comparison he recommends running is a comparison of assumptions.

## Excluded

- de Chaisemartin and D'Haultfoeuille, "Credible Answers to Hard Questions" (SSRN 4487202,
  384pp): dropped from canon by human decision 2026-07-28. Their coverage here rests on their
  published papers as relayed by the surveys, plus the public companion ecosystem:
  github.com/Credible-Answers (did_multiplegt_dyn and relatives), SSC cc_xd_didtextbook,
  anzonyquispe.github.io/did_book solutions in Stata, R, and Python.

## Primary papers cited through the surveys

Cite the survey for the synthesis; cite the primary paper for a specific theorem. All entries
below are resolver-verified in causal.bib (2026-07-28); the ones marked preprint there get
re-checked with bibcheck at manuscript time. Keys: `goodmanbacon2021timing` (decomposition);
`callaway2021multiple` (ATT(g,t)); `sun2021dynamic` (contamination, interaction-weighted);
`dechaisemartin2020twoway` (negative weights); `dechaisemartin2026intertemporal` (intertemporal;
published ReStat 108(4) on 2026-07-17, superseding NBER w29873); `borusyak2024revisiting`
(imputation, efficiency); `wooldridge2025mundlak` (ETWFE, supersedes the 2021 SSRN WP);
`santanna2020doubly` (doubly robust); `rambachan2023credible` (honest inference);
`roth2022pretest` (pretest power); `ghanem2022selection` (selection mechanisms; preprint);
`caetano2024covariates` (covariate TWFE; preprint; the four-author time-varying-covariates paper
is separate); `harmon2022efficient` (pre-period averaging precision; unpublished WP, R&R
ReStat); `chen2025efficient` (efficient combination; preprint); `roth2023functional`
(functional form); `chen2024logs` (zeros and logs); `abadie2023clustering` (clustering);
`gardner2022twostage` (two-stage; preprint, revised co-authored version circulates).

Added 2026-08-26 through the two new canon entries, resolver-verified against Crossref on that
date: `wooldridge2023simple` (nonlinear DiD with panel data, Econometrics Journal 26(3));
`deb2024flexible` (DNWZ, the FLEX linear estimator for repeated cross sections; NBER WP 33026,
revised April 2026, preprint, cited by Wooldridge as Deb et al. 2025); `santossilva2006log`
(PPML consistency, the log of gravity); `solon2015weighting` (what are we weighting for);
`correia2020ppmlhdfe` (ppmlhdfe); `ciani2019multiplicative` (multiplicative DiD and the
variance-shift diagnostic, J. Econometric Methods 8(1)). Wooldridge 1997 (the QMLE consistency
result the companion cites) is cited in prose only; it has no entry yet.
