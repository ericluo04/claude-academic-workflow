# IV canon

Current as of 2026-10-09. The user picked these sources. Goldsmith-Pinkham, Hull, and Kolesár
is a user-supplied addendum (2026-08-04) covering the leniency design, which the other five
sources reach only in passing. BibTeX keys point into
../../causal-design/references/causal.bib. Refresh: litreview on the method since the date
above, results proposed as flagged addenda.

## Imbens (2014)

Statistical Science 29(3): 323-358. Key: `imbens2014instrumental`.

- Role: the conceptual foundation; why economists reach for IV, what each assumption says, and
  the LATE estimand's honest defense.
- Settles: IV is for treatments that are chosen (selection on anticipated gains) or that are
  equilibrium objects (prices); the four assumptions are kept separate because unconfounded
  assignment of the instrument justifies the ITT only, never the IV ratio; exclusion is
  substantive in essentially every application and must be argued by compliance type;
  monotonicity is safe for one-directional incentives and suspect for examiner designs; the
  LATE is the only point-identified average and should travel with compliance shares and Manski
  bounds when the ATE was the target; overid-test rejections under heterogeneity may reflect
  instrument-specific complier populations; TSLS-LIML divergence flags weak or many
  instruments; the Balke-Pearl inequalities make the assumptions partially testable; the AR
  statistic inverts into weak-instrument-valid confidence sets.
- Binds when: any IV analysis; every exclusion argument; every choice among ITT, LATE, bounds,
  and structural estimands.
- Implement: estimator-level paper, names no software; R mappings (ivreg, fixest, ivmodel) are
  ours, in references/details.md.
- Quote: the second-best defense of LATE (the trial-that-enrolled-only-men analogy); exclusion
  "satisfied by design" only in double-blind placebo-controlled trials with noncompliance.

## Keane and Neal (2024)

Annual Review of Economics 16: 185-212. Key: `keane2024practical`.

- Role: the weak-instrument inference regime; the canon's rules for testing, intervals, and
  instrument-strength standards.
- Settles: abandon the 2SLS t-test at every instrument strength (power asymmetry: the 2SLS
  standard error is spuriously small when the estimate lands near OLS, rank correlation -0.92
  at population F 73.75, rho 0.8); AR always (CLR overidentified), intervals only by inversion; the F
  ladder (sample 10 certifies population 2.3; 50 certifies 29.4; 104.7 certifies 73.75 at 5
  percent size); target robust F about 50, scaled 50/K^(3/4); below 3.84 do not run IV;
  just-identified AR is the reduced-form robust t; overidentified use LIML/CUE + CLR, avoid
  2SLS and two-step GMM; never mix estimators and tests; one-sided t size distortions are
  severe at any realistic strength and t power against effects opposite the OLS bias is near
  zero, which manufactures publication-bias consensus; 24 percent of audited AER IV papers with
  F under 50 flip under AR/CLR.
- Binds when: every linear IV analysis, whatever the instrument's provenance; refereeing IV
  papers (the near-OLS significant-t pattern).
- Implement: Stata-first (weakiv, ivreg2 cue, weakivtest); R route is ivmodel + ivDiag, our
  mapping, in references/details.md.
- Quote: "If your first stage F is that small you should not be running 2SLS anyway!" (on
  F < 3.84).

## Borusyak, Hull, and Jaravel (2025)

Journal of Economic Perspectives 39(1): 181-204. Key: `borusyak2025practical`.

- Role: the shift-share practitioner guide; the two-path fork and both checklists.
- Settles: shift-share identification is a committed choice between exogenous shifts (shares
  arbitrarily endogenous; needs many effective shifts, shift-level controls as s-weighted
  aggregates, exposure-robust inference via AKM or the equivalent shift-level regression) and
  exogenous shares (each share a valid DiD-style instrument; must be tailored, not generic;
  Rotemberg weights name the shares that carry the design); the Table 2 disqualifiers (would
  you use the shifts, or a single share, directly?); control the sum of shares when incomplete;
  share timing at the start of the natural experiment; leave-out shifts when estimated
  in-sample; many-share designs need JIVE/LIML/HFUL/bias-corrected TSLS; failed share
  sensitivity conflates invalidity with heterogeneity (Mogstad-Torgovitsky-Walters).
- Binds when: any instrument that is a weighted average of common shocks; OLS exposure designs
  with shift-share treatments; refereeing Bartik-style marketing IVs (generic category-mix
  shares fail the share path).
- Implement: ssaggregate (Stata/R), bartik_weight for Rotemberg weights, ShiftShareSE for AKM;
  details and traps in references/details.md.
- Quote: the two disqualifiers, near-verbatim from Table 2; the generic-versus-tailored shares
  distinction (generic industry shares proxy exposure to essentially any industry shock).

## Borusyak and Hull (2023)

Econometrica 91(6): 2155-2185. Key: `borusyak2023nonrandom`.

- Role: the formula-instrument framework; validity for constructed treatments and instruments.
- Settles: exogenous shocks feeding a known formula do not make the composite exogenous,
  because exposure is predetermined and endogenous; the expected instrument mu_i (average of
  the instrument over simulated counterfactual shock draws) is the sole confounder; recenter
  (z - mu) or control for mu; recenter-then-control in experiments, control for several
  candidate mu_i in natural experiments (double robustness); ordinary controls purge the bias
  only if they span mu_i (geography R2 of 0.82 was not enough); consistency needs many
  dispersed shocks; recentered IV is a convex-weighted complier average under monotonicity,
  rescaling by the counterfactual variance recovers unweighted estimands; the same draws give
  RI tests and intervals (Hodges-Lehmann inversion, not the naive re-randomized estimator
  distribution); China HSR employment elasticity 0.23 (0.075) collapses to 0.08 (0.097)
  recentered.
- Binds when: spillover counts, market access, simulated eligibility, media-coverage
  instruments, randomized rollouts propagating through nonrandom networks; any instrument
  built by formula from shocks plus exposure.
- Implement: hand-coded permutation loop (the template has it); ShiftShareSE for the linear
  special case; RI from the same draws.
- Quote: "randomizing transportation upgrades does not randomize the market access growth
  generated by them."

## Mogstad, Santos, and Torgovitsky (2018)

Econometrica 86(5): 1589-1619. Key: `mogstad2018using`.

- Role: the extrapolation framework; what the IV estimands say about parameters beyond the
  complier average (PRTEs, ATE/ATT/ATU, extrapolated LATEs), made computable.
- Settles: every treatment parameter and every IV-like estimand (IV slope, TSLS components,
  OLS slope, saturated cell means) is a weighted average of the same two marginal treatment
  response functions with identified weights, so bounds on the target come from a linear
  program over MTR pairs consistent with the estimands and the stated restrictions; saturated
  (d,z)-cell estimands attain sharpness (the feasible set is exactly the MTR pairs matching
  E[Y|D,Z], which exhausts the data); assumptions are priced continuously (their worked
  example: sharp nonparametric [-0.138, 0.407] shrinks to [0, 0.067] under decreasing MTRs
  plus a ninth-degree polynomial, truth 0.046) and bounds collapse to the LATE as the
  extrapolation distance alpha goes to zero; point identification has exactly two routes, both
  nested as special cases (a continuous instrument whose propensity-score support covers the
  target weights, or a parametric MTR space of dimension at most the number of independent
  estimands, the Brinch-Mogstad-Wiswall linear form for a binary instrument); an empty
  feasible set is a specification test (unrestricted MTRs reproduce the Balke-Pearl testable
  implications; restricting to zero average selection bias or zero selection on gains turns
  emptiness into a test of that behavioral hypothesis); under weak identification feed the LP
  the undivided covariance form of the IV estimand (their footnote 3).
- Binds when: the stated question is a rollout, expansion, or incentive change, so the target
  is a PRTE; natural-experiment instruments (weather, stockouts, outages) whose compliers no
  policy would move; ATU-style "would it work on the non-adopters" questions; any
  point-identified extrapolation, whose functional-form price this framework audits.
- Scope limits: identification analysis only; the published version has no inference procedure
  (that is in the 2017 NBER working paper w23568), so bounds travel without confidence
  statements unless bootstrapped through software.
- Implement: the paper ships no code (AMPL plus Gurobi); the practical route is the ivmte R
  package (Shea-Torgovitsky 2023, `shea2023ivmte`), package row and solver traps in
  references/details.md, optional template block in scripts/iv_template.R.

## Goldsmith-Pinkham, Hull, and Kolesár (2026)

Journal of Economic Perspectives 40(3): 213-240. Key: `goldsmithpinkham2026leniency`. Open
version arXiv 2511.03572. User-supplied addendum, read 2026-08-04.

- Role: the leniency design (judge, examiner, caseworker, assessor) end to end. Which estimator,
  which standard errors, and the five checks that make the design credible. Every other canon
  paper here is about IV in general. This one is about a design.
- Settles: UJIVE (Kolesár 2013) is the estimator, because its bias trace is zero with many
  instruments and many controls at once; manual leniency IV is out; balance and exclusion are
  tested by running the same UJIVE specification with the covariate or a post-assignment
  variable as the outcome, and the joint F on the examiner dummies is invalid with many
  examiners; average monotonicity (Frandsen-Lefgren-Leslie 2023) is the operative condition,
  sufficient for nonnegative weights (FLL) and, as GHK state, also necessary; it is testable by
  checking whether the UJIVE interval for v_i times treatment overlaps [0, 1], and the same trick
  characterizes compliers; strength is read from sqrt(K) times (E[F] - 1), not the first-stage
  F; under independent assignment plain robust standard errors suffice, and clustering by
  examiner is not justified by the assignment process; clustered assignment requires
  leave-own-cluster-out UJIVE. The mechanics are in references/designs.md, section "Leniency
  designs: UJIVE and the five checks", and the trace algebra in references/details.md.
- Binds when: any design where cases are assigned to decision-makers who differ in strictness and
  the assignment is as good as random within a stratum. Judges, patent examiners, disability
  assessors, loan officers, child-protection investigators, radiologists, immigration officers,
  content moderators, and platform review queues that route by roster.
- Scope limits: Kolesár, Montiel Olea, and Roth (2025, arXiv 2512.24096, revised March 2026)
  give sharp bounds on counterfactual judge policies without IV monotonicity, so policy effects
  in a leniency design have a formal route. Parametric MST-style extrapolation has not been
  formalized for many decision-makers or controls, so do not carry that ladder into a leniency
  design without saying so.
- Implement: the authors' own R package ManyIV (github.com/kolesarm/ManyIV), row in
  references/details.md, template block in scripts/iv_template.R. Chyn-Frandsen-Leslie 2025
  (JEL 63(2): 401-439) is the companion practitioner's guide the paper positions itself against.
- Quote: "small first-stage F statistics need not worry a researcher using UJIVE"; on clustering,
  "this line of reasoning would never justify clustering on examiners (as is sometimes done in
  practice)"; on the many-dummy 2SLS standard errors in their reanalysis, "a difference that
  reflects statistical pathology rather than efficiency gains."

## Named disputes the skill carries

1. Just-identified t-test: Keane-Neal (abandon it; power asymmetry is the binding problem) vs
   Angrist-Kolesár 2024 (size is fine at realistic endogeneity), Lee et al. 2022 (tF critical
   values fix size), and Lee, McCrary, Moreira, Porter, and Yap 2023 (VtF intervals, NBER
   w31893). Default: AR/CLR and the F-50 standard; report both when pushed,
   cite the dispute. Presented as live, not settled. The t-test has near-zero power against
   effects opposite the OLS bias, which under publication bias manufactures spurious
   literature-wide consensus, and tF inherits the asymmetry. The AR test costs one
   regression, so there is no economy argument for the t-test.
2. Overid rejections: invalidity vs heterogeneity (both canon papers, plus
   Mogstad-Torgovitsky-Walters 2021). Not a dispute between authors but a fork in
   interpretation the skill refuses to collapse.
3. Instrument-strength standard: Keane-Neal's robust-F-about-50 bar governs 2SLS bias in
   few-instrument designs, while Goldsmith-Pinkham-Hull-Kolesár 2026 hold that F is the wrong
   statistic for UJIVE in a many-examiner design, where the quantity that matters is sqrt(K)
   times (E[F] - 1) and UJIVE stays approximately unbiased as E[F] approaches one. The two
   papers do not cite each other, so this is a scope boundary the skill draws, not an argument
   either set of authors picked. Default: the F-50 bar everywhere outside a leniency design,
   the sqrt(K)(E[F] - 1) reading inside one, and name the estimator either way, since the bar
   is a statement about 2SLS and not about IV in general.
4. Weak-instrument fallback in leniency designs: the skill's general default is AR/CLR, but
   Goldsmith-Pinkham-Hull-Kolesár flag that the jackknife AR of Mikusheva-Sun 2022 and the
   jackknife LM test of Matsushita-Otsu 2024 are not robust to treatment-effect
   heterogeneity, which a leniency design has by construction. Inside a leniency design the
   fallback is Yap 2025 instead.

## Primary papers cited through the canon

Resolver-verified entries in causal.bib (see the IV block there for keys and PREPRINT flags):
Imbens-Angrist 1994 (LATE theorem); Angrist-Imbens-Rubin 1996 (IV in potential outcomes);
Staiger-Stock 1997 and Bound-Jaeger-Baker 1995 (weak-IV founding); Anderson-Rubin 1949 (the AR
test); Moreira 2003 (CLR), 2009 (UMPU optimality), Moreira-Moreira 2019 (heteroskedastic
optimality); Kleibergen 2005 (GMM identification-robust tests); Andrews-Stock-Sun 2019 (weak-IV
survey); Lee-McCrary-Moreira-Porter 2022 (tF); Angrist-Kolesár 2024 (just-ID defense);
Keane-Neal 2023 (power asymmetry mechanics); Montiel Olea-Pflueger 2013 (effective F); Dufour
1997 (unbounded-CI impossibility); Young 2022 (robust-F evidence); Balke-Pearl 1997 and
Imbens-Rubin 1997 (bounds and inequality tests); Bekker 1994 (many-instrument asymptotics);
Angrist-Imbens-Krueger 1999 (JIVE); Hausman et al. 2012 (HFUL); Kolesár et al. 2015
(bias-corrected TSLS); Borusyak-Hull-Jaravel 2022, Adão-Kolesár-Morales 2019,
Goldsmith-Pinkham-Sorkin-Swift 2020 (the three shift-share pillars); Mogstad-Torgovitsky-
Walters 2021 (heterogeneity and multiple instruments); Autor-Dorn-Hanson 2013, Card 2009,
Bartik 1991, Currie-Gruber 1996, Angrist-Krueger 1991 (worked designs);
Jaeger-Ruist-Stuhler 2018 (dynamic shift-share caveat).

Added with the leniency addendum (2026-08-04): Kolesár 2013 (UJIVE's origin);
Frandsen-Lefgren-Leslie 2023 (average monotonicity, and their own test of the stronger
condition); Sigstad 2026, AER 116(1): 189-208 (monotonicity is often violated in judicial
panels, yet the violations cause little bias); Chyn-Frandsen-Leslie
2025 (the companion examiner-design practitioner's guide in JEL); Blandhol et al. 2026, Review
of Economic Studies, advance online publication 2026-05-14, formerly NBER w29709 (linearity of
E[z|w] in the covariates as a necessary condition); Yap 2025 (many-weak-instrument inference
that survives treatment-effect heterogeneity); Frandsen-Leslie-McIntyre 2025 (cluster jackknife
IV, the leave-own-cluster-out route under clustered assignment).

Added with the Mixtape chapter 7 pass (2026-08-26): Angrist-Graddy-Imbens 2000, REStud 67(3):
499-527 (an IV demand elasticity is the compliers' elasticity, specific to the instrument that
moved price, and not the elasticity a firm faces when it sets price itself); Angrist-Krueger
2001, JEP 15(4): 69-85 (the best instruments come from institutional knowledge of a program and
rarely from a new dataset, which is what the "before you estimate" paragraph in SKILL.md rests
on). Both verified against Crossref 2026-08-26; BibTeX drafted as `angrist2000interpretation` and
`angrist2001instrumental`, merged into causal.bib.

## Flagged addenda (tier-2 audit pass, 2026-10-09)

The user approved these with the tier-2 pass. Each entry was written from the abstract page fetched
on 2026-10-09, and from the text where the entry says so. Keys are new in causal.bib and await
the bibcheck pass.

- Wang and Zhang 2024 (`wang2024wild`), Journal of Econometrics 241: 105727 (arXiv
  2108.13707). Role: inference with few clusters. Settles: with a small fixed number of large
  clusters, their wild bootstrap AR test controls size even when identification is weak in
  every cluster. The wild bootstrap Wald test needs strong identification in at least one
  cluster. Binds when: assignment is clustered and the clusters are few (a handful of markets or
  states). Caveat: we have not checked for an R implementation.
- Coulibaly, Hsu, Mourifié, and Wan 2024 (`coulibaly2024sharp`), NBER w32456 (arXiv 2405.06156,
  v2 November 2025). Role: the sharp joint test for a leniency design. Settles: sharp testable
  implications of random assignment, exclusion, and monotonicity, for few or many cases per
  judge and for discrete or continuous instruments. Under rejection, a variant of the MTE is
  identified under weaker assumptions. They apply it to Stevenson's Philadelphia data. Binds
  when: a referee wants more than the GHK [0, 1] test. Caveat: preprint, not run by us.
- Słoczyński, Sun, and Uysal 2026 (`sloczynski2026practical`), arXiv 2605.15115 (v2 July 2026).
  Role: a practitioner's guide to IV with heterogeneous effects. Settles: different covariate
  specifications identify different weighted averages of covariate-specific LATEs, and
  misspecification can break the causal reading, so flexible specifications are a robustness
  check. It reviews tests of the LATE assumptions and methods robust to monotonicity failure, and
  it carries a software table. Read in the text: it names FEJIV (Chao, Swanson, and Woutersen
  2023, `chao2023jackknife`, Journal of Econometrics 235(2): 1747-1769, not read by us) beside
  UJIVE as the jackknife estimators for many instruments with covariates. In their Stevenson
  reanalysis (Appendix Table A2), incarceration length rises 666 days (233) by linear IV, 51
  (91) by FEJIV, and 56 (99) by UJIVE. Binds when: covariates are needed for identification or
  instrument-covariate interactions create many instruments.
- Mogstad and Torgovitsky 2024 (`mogstad2024instrumental`), NBER w32927, a Handbook chapter.
  Role: the current survey behind the MST ladder. Settles (abstract): two strategies under
  unobserved heterogeneity, reading linear IV as a LATE after the fact and building MTE
  estimators that allow for it, with links to control-function and bounding methods. Binds when:
  refreshing the extrapolation ladder, or receiving a control-function question from
  causal-design. Caveat: abstract only.
- Słoczyński 2026 (`sloczynski2026when`), arXiv 2011.06695 (v8 April 2026). Role: negative
  weights under weak monotonicity with covariates. Settles: when covariates are needed and the
  first stage and reduced form impose a homogeneous instrument effect, some conditional LATEs get
  negative weights under weak monotonicity. The interacted specification of Angrist and Imbens
  (1995) removes them. Binds when: beside the Blandhol et al. rich-covariates condition in check
  1. Caveat: listed as REStud forthcoming in Słoczyński, Sun, and Uysal 2026; unconfirmed in
  Crossref, which has no DOI for it yet.
- Ferman 2026 (`ferman2026design`), arXiv 2603.11381. Settles (abstract): in shift-share designs,
  simulations that fix outcomes and resample shocks can confound true effects with error
  dependence, so they can overstate inference distortions from spatial correlation. He proposes
  alternative simulation designs. Binds when: a paper or referee uses resampled-shock simulations
  to judge shift-share inference. Caveat: abstract only.
- Hahn, Liao, Liu, and Shi 2024 (`hahn2024econometric`), "Econometric Inference Using Hausman
  Instruments", University of California Riverside working paper dated 2024-10-01. Unconfirmed:
  no index carries it, and the series number rests on the file name (202405). Settles (text):
  an IV estimator built on a Hausman instrument correlates observations, which can invalidate
  textbook standard errors, and clustering is a pragmatic compromise. In section 5 they suspect
  that a leave-one-out judge instrument shares the problem when each judge sees few cases. Binds
  when: Hausman other-market prices instrument a marketing demand model. Caveat: the judge claim
  sits against GHK's no-clustering rule. The skill keeps GHK's rule, and the conflict is open.

## Exemplar rows

The recognition table's canonical cases. New keys were Crossref-verified and merged into
causal.bib 2026-08-26. One line each, with the design the case is the precedent for.

- Finkelstein et al. 2012 (`finkelstein2012oregon`), randomized encouragement with noncompliance,
  the Oregon Medicaid lottery with the ITT and the LATE reported side by side. It teaches
  lottery IV under voluntary take-up, across financial, utilization, and health outcomes;
  winning the lottery raised Medicaid enrollment by about 26 points.
- Baicker et al. 2013 (`baicker2013oregon`), the clinical-outcome companion to the same lottery,
  and the paper the chapter points at for the lottery-as-instrument design.
- Stevenson 2018 (`stevenson2018distortion`), leniency routing, Philadelphia bail magistrates,
  where OLS finds nothing and IV carries the paper. It teaches the design end to end. In
  Cunningham's replication of the data (The Mixtape, online ch. 7 sec. 7.7, Table 7.12), 331,971
  cases and eight judges, OLS -0.001 with time controls (0.029 with defendant controls) and IV 15
  to 21 percent on guilty pleas. Stevenson's own headline is a 13 percent rise in conviction.
- Bartik 1991 (`bartik1991who`) and Autor, Dorn, and Hanson 2013 (`autor2013china`), shift-share
  exposure, the shares claim and the shifts claim as two separate identification arguments, each
  with its own estimator, balance test, and disqualifier. Both keys already resolve in causal.bib.
- Borusyak and Hull 2023 (`borusyak2023nonrandom`), formula or network exposure, and the
  recentering that a nonrandom exposure map requires. A formula-built instrument inherits
  endogeneity from its nonrandom exposure weights: 0.23 collapses to 0.08 after recentering. Key
  already resolves in causal.bib, and the paper has its own canon section above.
- Wright 1928 (`wright1928tariff`), the cost shifter for price, and the origin of the
  simultaneity problem the design solves: observed price-quantity pairs are equilibria, a supply
  shifter identifies demand, and the elasticity recovered belongs to the instrument's compliers.
- Graddy 2006 (`graddy2006fulton`), the Fulton fish market data behind the worked price-elasticity
  example, read alongside `angrist2000interpretation` for what the recovered elasticity is.
- McClellan, McNeil, and Newhouse 1994 (`mcclellan1994intensive`), the access or distance design,
  and the differential-distance trick of conditioning on generic distance and instrumenting with
  the specific version, because raw distance proxies everything. The SKILL.md row names no year;
  this is the paper it points at.
