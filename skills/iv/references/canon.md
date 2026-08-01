# IV canon

Current as of 2026-07-29. These sources are hand-picked; nothing enters this file without
explicit human approval. BibTeX keys point into ../../causal-design/references/causal.bib.
Refresh: litreview on the method since the date above, results proposed as flagged addenda.

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
  at population F 29.4); AR always (CLR overidentified), intervals only by inversion; the F
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

## Named disputes the skill carries

1. Just-identified t-test: Keane-Neal (abandon it; power asymmetry is the binding problem) vs
   Angrist-Kolesár 2024 (size is fine at realistic endogeneity) and Lee et al. 2022 (tF/VtF
   critical values fix size). Default: AR/CLR and the F-50 standard; report both when pushed,
   cite the dispute. Presented as live, not settled.
2. Overid rejections: invalidity vs heterogeneity (both canon papers, plus
   Mogstad-Torgovitsky-Walters 2021). Not a dispute between authors but a fork in
   interpretation the skill refuses to collapse.

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
