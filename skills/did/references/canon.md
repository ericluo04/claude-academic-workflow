# DiD canon

Current as of 2026-10-09. The user picked these sources; nothing enters this file without their
approval. BibTeX keys point into ../../causal-design/references/causal.bib. Refresh: litreview
on the method since the date above, results proposed as flagged addenda.

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
  even when G = 200 or more"); CV3 with t(G-1) as the first line, run beside CV1 and a WCR
  bootstrap; few treated clusters is a distinct failure ("the CV1 standard error of this
  coefficient can easily be too small by a factor of five or more" at G1 = 1) while WCR
  under-rejects, with the ordinary WR bootstrap as the rescue; the five concern zones and the
  reporting of G, cluster sizes, and leverage. The rest is in details.md, sections "Few-clusters
  map" and "Few-clusters battery".
- Binds when: any clustered inference on a CRVE; choosing the clustering level; any of the five
  concern zones fires; before reaching for the few-clusters map.
- Implement: Stata boottest, summclust, edfreg, randcmd (the paper's own stack); in R,
  fwildclusterboot 0.14.3 and summclust 0.7.0 (both archived from CRAN, r-universe builds),
  clubSandwich CR2/Satterthwaite, sandwich vcovBS jackknife (details.md package index and
  did_template.R section 10); no R package implements RI-t, hand-roll it.
- Scope limits: on IV, Section 5 says only that IV coefficients are biased in finite samples
  and recommends the equal-tail bootstrap P value; the guide does not develop clustered-IV
  inference further (an earlier "explicitly out of scope" reading was not found in the text);
  two-way clustering theory still developing; model-based inference only, with the design-based AAIW branch set
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
  for population-total % under heavy tails; implicit weighting as a separate estimand choice
  (Solon-Haider-Wooldridge); the Var(log Y) shift and the Ciani-Fisher diagnostic; levels TWFE
  sign-unstable under proportional growth with baseline gaps, matching as a special case, and
  the SDID caveat; PT stated on a named scale. The mechanics are in details.md, section
  "Estimand and estimator under heavy tails".
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
- Settles: PT on the index G^{-1}(E[Y_t(∞) | D, X_t]), which holds in levels only under no
  selection or a stationarity restriction, while CS, BJS, and DNWZ state PT in levels; one
  pooled QMLE with the canonical link, cohort dummies in place of unit FEs, and covariates
  centered within cohort-period cells; pooled QMLE equals imputation under canonical links; the
  PT-diagnostic event study on the index scale, with lags-only and leads-and-lags both reported;
  collapse thin cohort cells; cluster at the assignment level (AAIW). The recipe is in
  details.md, section "Nonlinear DiD with repeated cross sections".
- Binds when: the outcome is binary, fractional, or a count; units are seen once (surveys,
  trackers, transactions); staggered adoption in a repeated cross section; a linear
  probability DiD is on the table (he compares logit against a DNWZ-style LPM).
- Implement: Stata APE facilities (the only software named; the Secure Communities application
  with 682 PUMAs is available from the author with Stata code). etwfe 0.6.2 (ivar = NULL,
  family = "poisson"/"logit", emfx) and jwdid 2.0 (no ivar, method(poisson|logit)) are ours,
  from package docs and source, verified 2026-08-26.
- Quote: "Assumption CPT imposes the parallel trends assumption on G^{-1}(E[Y_t(∞) | D, X_t]).
  In general, CPT does not hold for E[Y_t(∞) | D, X_t]" (p. 76).

## Ghanem, Sant'Anna, and Wüthrich

"Selection and Parallel Trends". Key: `ghanem2022selection` (still a preprint, SSRN 4215029 and
arXiv 2203.09001; the circulating version is v15, revised 2026-07-24. The Mixtape cites it as
2024 in the online ch. 9 and 10 reference lists). Companion: "When Should Pre-trends Be
Parallel?", AEA Papers and Proceedings 116: 64-69 (2026), key `ghanem2026when`.

- Role: the assignment-mechanism half of parallel trends, and the source for SKILL.md's "Why
  these units were treated". Read alongside Marx, Tamer, and Tang (2024) on forward-looking
  choice.
- Settles: which selection mechanisms are compatible with PT (common constant trend, selection
  on baseline Y(0) under the martingale condition of Corollary 3.3, selection on fixed effects,
  selection on observables, imperfect foresight) and which is not (selection on realized gains,
  Heckman-Urzua-Vytlacil essential heterogeneity, after Roy 1951). Selection on baseline Y(0)
  breaks pre-trends mechanically, because the baseline is both the selection point and the
  omitted category. It leaves PT intact only under the martingale condition (a unit-root
  restriction on the shocks). When Y(0) mean-reverts, PT fails (the Ashenfelter dip).
- Binds when: reading a pre-trend picture; deciding whether a baseline dip is a problem; setting
  the HonestDiD relative-magnitudes anchor.
- Implement: names no software. The mechanism table and the HonestDiD interaction are in
  details.md, the latter labeled as the skill's own judgment.

## Roth (2026), event-study interpretation

The Japanese Economic Review 77(2): 275-288, "Interpreting event-studies from recent
difference-in-differences methods". Key: `roth2026interpreting`. The Mixtape cites the 2024
working paper (online ch. 10 reference list); this is the published version.

- Role: what an event-study coefficient means once the estimator is not OLS.
- Settles: short gaps versus long differences (a rolling baseline estimates a different quantity
  from a universal one, and OLS can only produce the latter); the BJS kink at t = -1, which
  comes from fitting the counterfactual on the whole pre-period, so imputation pre-period
  coefficients are a valid pre-trend test only if PT holds in every period and are not
  comparable to CS or TWFE coefficients.
- Binds when: choosing `base_period`; reading someone else's CS or dCDH event study; deciding
  whether to overlay estimators on one plot.
- Implement: `base_period = "universal"` in R's did. Stata's csdid 2.0.0 defaults to the
  universal base period; on csdid 1.8x pass `long2`. The csdid2 default is unverified.

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
  384pp): dropped from canon by user decision 2026-07-28. Their coverage here rests on their
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
`roth2022pretest` (pretest power); `ghanem2022selection` (selection mechanisms; preprint;
promoted to its own entry above 2026-08-26);
`caetano2024covariates` (covariate TWFE; preprint; the four-author time-varying-covariates paper
is separate); `harmon2022efficient` (pre-period averaging precision; unpublished WP, R&R
ReStat); `chen2025efficient` (Chen, Sant'Anna, and Xie, efficient combination; preprint);
`roth2023functional`
(functional form); `chen2024logs` (zeros and logs); `abadie2023clustering` (clustering);
`gardner2022twostage` (two-stage; preprint, revised co-authored version circulates).

Added 2026-08-26 from the Mixtape gap analysis (chapters 8, 9, 10), each Crossref-verified on
that date: `marx2024parallel` (forward-looking choice and PT, JPE: Micro 2(1)); `olden2022triple`
(the triple-difference parallel-bias assumption, Econometrics Journal 25(3));
`santanna2026compositional` (compositional changes; published Journal of Econometrics 253,
article 106147, superseding the 2023 working paper the Mixtape cites); `kahnlang2019promise`
(explain the level difference before differencing it away; JBES 38(3), online 2019, print issue
2020); `callaway2024continuous` (continuous treatment, NBER WP 32117; preprint, R package
contdid; the 2026-10-08 Mixtape check found no citation of it on the online site, so it did not
come from the Mixtape); `hong2013napster` (compositional change in repeated cross-sections, the Napster
exemplar; JAE 28(2)). All six are cited in prose in SKILL.md or details.md and previously had
no key.

Added 2026-08-26 through the two new canon entries, resolver-verified against Crossref on that
date: `wooldridge2023simple` (nonlinear DiD with panel data, Econometrics Journal 26(3));
`deb2024flexible` (DNWZ, the FLEX linear estimator for repeated cross sections; NBER WP 33026,
revised April 2026, preprint, cited by Wooldridge as Deb et al. 2025); `santossilva2006log`
(PPML consistency, the log of gravity); `solon2015weighting` (what are we weighting for);
`correia2020ppmlhdfe` (ppmlhdfe); `ciani2019multiplicative` (multiplicative DiD and the
variance-shift diagnostic, J. Econometric Methods 8(1)). Wooldridge 1997, the QMLE consistency
source the companion cites, did not resolve on Crossref; SKILL.md now cites the primary result,
Gourieroux, Monfort, and Trognon 1984 (`gourieroux1984pseudo`).

Added 2026-10-09 (tier 2 of the 2026-10-08 audit), each checked against Crossref, arXiv, or the
NBER abstract page on that date:

- `ghanem2026when` (AEA P&P 116: 64-69): necessary and sufficient conditions for pre-trends and
  trends to be parallel; pretests can be uninformative about PT except under restrictions on
  selection. Cited in SKILL.md "Pre-trends and honest sensitivity".
- `deb2025aggregating` (NBER WP 34331, October 2025; preprint): the standard Callaway-Sant'Anna
  software's aggregation weights include reference pre-period observations. Cited in "Estimand
  before estimator".
- `liu2025cohort` (arXiv 2509.01829; preprint): cohort-anchored HonestDiD; the aggregated event
  study can mislead when pre-trends differ across cohorts. Cited in the HonestDiD scope note.
- `caetano2026bad` (arXiv 2608.03881; preprint; R package badcontrols): DiD when PT needs a
  covariate that treatment moves; dropping it is often ill-advised. Cited in "Covariates".
- `roth2023efficient` (JPE Micro 1(4): 669-709): efficient estimation under staggered random
  timing, the R package staggered.
- `ding2019bracketing` (Political Analysis 27(4): 605-615): the nonparametric bracketing result
  between DiD and lagged-outcome adjustment.
- `daw2018matching` (Health Services Research 53(6): 4138-4156): matching on pre-period
  outcomes can induce regression-to-the-mean bias in DiD.
- `borusyak2024revisiting`, already keyed: now also cited for the underidentified linear
  component without never-treated units.
- `pustejovsky2018small` (JBES 36(4): 672-683): small-sample cluster-robust Wald tests; cited
  with AAFP for avoiding a clustered joint F over many leads.
- `gourieroux1984pseudo` (Econometrica 52(3): 681-700): pseudo maximum likelihood consistency
  under a correct conditional mean, the PPML default.
- `wing2024stacked` (NBER WP 32054) and `ortizvillavicencio2025better` (arXiv 2505.09942), keyed
  by the tier-1 bib pass: stacked-regression weights and DDD with covariates or staggering.
- `bellego2025chained` (Journal of Econometrics 248, 105783; R package cdid): chained DiD for
  unbalanced panels.
- `dube2025local` (JAE 40(7): 741-758): LP-DiD and its two equivalences.
- `mackinnon2020randomization` (Journal of Econometrics 218(2): 435-450): RI-beta and RI-t with
  few treated clusters.
- `rubin2008objective` (Annals of Applied Statistics 2(3)): design before outcome data, cited in
  place of the Mixtape for the design stage.
- `liu2024practical`, already keyed: FEct imputation, the "LWX" of the PT-menu table.

## Exemplar rows

The recognition table's canonical cases and what each one teaches. New keys were
Crossref-verified and merged into causal.bib 2026-08-26. Baker et al. (2026) and Winkler et al.
(2026) have their own canon sections above.

- Miller, Johnson, and Wherry (2021) `miller2021medicaid`, ACA Medicaid expansion and
  near-elderly mortality. The Mixtape's model of a complete DiD paper (Cunningham, The Mixtape,
  online ch. 9 sec. 9.7): bite shown three ways (eligibility, enrollment, and the share
  uninsured, the last of which shows some enrollment came from people with no coverage at all),
  event studies, a same-outcome-alternative-group falsification on the 65-and-over population,
  main results (0.13pp, 9.3% of the sample mean; these two numbers are not on the Mixtape site
  and are unconfirmed against the paper), and a mechanism. Never-treated comparison states.
- Braghieri, Levy, and Makarin (2022) `braghieri2022social`, the staggered rollout of
  TheFacebook across colleges and student mental health. The staggered exemplar: treatment dates
  built from the Wayback Machine (the platform announced each new school on its front page) and
  linked to an existing repeated-cross-section student survey, with the outcome z-scored so
  effects read in standard deviations. Also the Mixtape's instance of the multi-estimator plot
  it argues against (Cunningham, The Mixtape, online ch. 10 sec. 10.13, Figure 10.13).
- Hong (2013) `hong2013napster`, Napster and music spending in the Consumer Expenditure Survey.
  Compositional change in a repeated cross-section: internet users got older, poorer, and less
  likely to hold a college degree between 1997 and 2000, and those covariates predict Y(0), so
  who is sampled breaks parallel trends without anyone being mistreated.
- Gruber (1994) `gruber1994incidence`, state-mandated maternity benefits. The origin of triple
  differences, with the ineligible group (single men aged 20-40 and older workers) inside the
  same states.
- Card and Krueger (1994) `card1994minimum`, NJ versus PA fast food. The exemplar of the DiD
  idea, the bite figure (mass at the new minimum), and primary data the authors collected twice
  themselves. Not an inference template: at the assignment level it is G = 2 with one treated
  cluster.
