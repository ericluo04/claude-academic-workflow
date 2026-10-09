---
name: iv
description: Design, estimate, validate, and write up an instrumental-variables analysis: single-instrument LATE designs, weak-instrument-robust inference, shift-share instruments, formula instruments that need recentering, and leniency (judge and examiner) designs estimated by UJIVE. TRIGGER on "instrumental variable", "IV", "2SLS", "LATE", "complier", "exclusion restriction", "first stage", "weak instrument", "Anderson-Rubin", "shift-share", "Bartik", "judge design", "judge IV", "examiner design", "examiner leniency", "UJIVE", "JIVE", "jackknife IV", "LIML", "Rotemberg weights", "exposure-robust", "AKM", "price endogeneity", "cost shifter", "Hausman instrument", "simulated eligibility", "recentered instrument", or any setting where treatment is chosen by agents and an incentive or cost shifter moves it. Randomized encouragement designs are led end to end by field-experiment.
---

# Instrumental variables

An opinionated IV workflow grounded in a read canon (references/canon.md):
Imbens' Statistical Science perspective for the assumption structure and the LATE
estimand, Keane-Neal's Annual Review guide for the weak-instrument inference regime, the two
Borusyak-Hull(-Jaravel) papers for shift-share and formula instruments,
Mogstad-Santos-Torgovitsky's Econometrica framework for extrapolating beyond the compliers, and
Goldsmith-Pinkham-Hull-Kolesár's JEP operator's manual for leniency designs.
Deliverable: the recommendation with its citation, the R estimation and diagnostics code, and a
methods paragraph. The skill stops at the four stop points in
../causal-design/references/shared-rules.md (section "Stop points") and puts each choice to the user.

Current as of 2026-10-09; refresh per shared-rules (../causal-design/references/shared-rules.md,
section "Refresh path").
Nothing enters the canon without the user's approval.

## Six designs to recognize

Find your design here before reading about estimators. What each canonical case teaches is in
references/canon.md, section "Exemplar rows".

| Design | Canonical case | Marketing analogue | What kills it |
|---|---|---|---|
| Randomized encouragement with noncompliance (routes to field-experiment) | Oregon Medicaid lottery (Finkelstein et al. 2012) | ghost ads, PSA holdouts, invite-only betas | the offer itself moves the outcome, because the invitation signals |
| Leniency routing | Philadelphia bail magistrates (Stevenson 2018) | moderation queues, credit underwriting, support-ticket routing | units re-enter the queue after seeing their assignment; monotonicity across case types |
| Shift-share exposure | Bartik 1991; Autor-Dorn-Hanson 2013 | category demand growth from national demographic shifts weighted by sales shares | generic shares, which proxy exposure to any shock |
| Formula or network exposure | Borusyak-Hull 2023, China high-speed rail | fraction of friends treated in seeding and referral programs | no recentering; connected users are mechanically more exposed |
| Cost shifter for price | Wright 1928; Graddy's Fulton fish market | input costs, freight, Hausman other-market prices | the instrument-induced elasticity is not the one you face when you set price yourself |
| Access or distance | the McClellan-Newhouse differential-distance trick | store, warehouse, or delivery-coverage proximity | distance correlates with everything; condition on generic distance |

## When IV, and the five assumptions kept separate

IV is the tool when unconfoundedness fails because treatment is chosen: agents select on
anticipated gains (program participation, adoption, self-selected exposure), or the treatment is
an equilibrium object like a price, where OLS mixes supply and demand slopes (the Fulton fish
market numbers in references/details.md are the two-line demonstration). An instrument is an
incentive or cost shifter: it changes the attractiveness of taking treatment without entering the
potential outcomes. A price elasticity estimated this way is the elasticity of the compliers the
instrument moved (Angrist, Graddy, and Imbens 2000), and need not be the elasticity a firm faces
when it sets price itself. Cunningham (The Mixtape, online ch. 7 sec. 7.7) puts it as
*"But when the firm lowers its price, it won't do so using storms!"* Route
a pricing question to the PRTE ladder below, naming the policy that will move the price.

Before you estimate, establish that the mechanism exists. An instrument is a treatment assignment
mechanism, and the design's credibility comes from that mechanism operating in the world, not
from the estimator. Interview whoever runs the assignment, the queue owner or the pricing
manager, and ask who ended up treated and why. Do not ask them to name an instrument, which is
not a question anyone outside this literature can answer. The best instruments come from
institutional knowledge of a program and rarely from a new dataset (Angrist and Krueger 2001).

Five assumptions, argued separately because they have different characters (Imbens 2014):

1. SUTVA, at the level of the instrument and not only the treatment: unit i's potential treatment
   and potential outcomes depend on i's own instrument alone. The violation to name is
   instrument-level spillover, a seeded user's friends changing behavior because of the seed
   itself. The LATE framework does not accommodate it, being built on unit-level potential
   treatment mappings, so the route is a partial-interference or network model (field-experiment).
2. Unconfounded assignment of the instrument. Can hold by design (randomized encouragement) or
   conditionally on covariates. On its own it justifies the reduced-form ITT effects ONLY, never
   the IV ratio.
3. Exclusion. Substantive in essentially every application; Imbens' line is that it holds by
   design only in double-blind placebo trials. Argue it separately by compliance type: the
   instrument can push always-takers and never-takers toward outcome-relevant side actions even
   though it cannot change their treatment (draft-lottery never-takers stayed in school; a
   retention-offer trigger that also flags the account for priority support).
4. Monotonicity (no defiers). Safe when the instrument is a one-directional incentive (letter,
   subsidy, default). Strong in examiner and judge designs: by Vytlacil's theorem it is
   equivalent to every examiner ranking the cases identically and differing only in where the
   cutoff falls, which fails whenever examiners weight criteria differently or differ in skill
   (Chan-Gentzkow-Yu find that skill accounts for 39 percent of the variation in radiologists'
   diagnosis rates, which is the leniency measure in this design). A leniency design needs less
   than this. The operative condition is average monotonicity, no unit a defier on average
   across pairwise comparisons. Frandsen, Lefgren, and Leslie (2023) show it is sufficient for
   nonnegative weights, Goldsmith-Pinkham, Hull, and Kolesár (2026) state it is also necessary,
   and it is testable. The leniency section below summarizes the weakening and the test; do not
   price a leniency design against the uniform condition. One-sided noncompliance (no
   always-takers) buys the uniform version for free, and the LATE then equals the average
   treatment effect on the treated (ATT).
5. Relevance, tested with the discipline in the next section, never with a full-sample afterthought.

The estimand under all five is the complier average effect (LATE). Compliers are the focus
because theirs is the only point-identified average, an honest second best. When the treatment
or the instrument is non-binary and the first stage varies across units, the LATE weights units
by their first-stage responsiveness. Compliers are then defined by responsiveness and not by
membership alone (Huntington-Klein 2020). With binary Z and D every complier moves by the same
one unit, so this weighting drops out. Report the compliance shares (always-takers,
never-takers, compliers, three lines of code) and, when the ATE was the
stated target, Manski bounds alongside the LATE. When the stated question is a rollout or an
incentive change (a bigger subsidy, wider eligibility, "what if we gave it to everyone"), name
the target as a PRTE and take the middle rung (Mogstad-Santos-Torgovitsky 2018): the LATE and
the policy parameter are weighted averages of the same marginal treatment response functions, so
the estimands already computed bound the policy parameter under stated MTR restrictions, with
the extrapolation distance alpha explicit. The ladder to report: ITT/LATE first; MST bounds
next, priced by the named restrictions and alpha; assumption-free Manski/Balke-Pearl bounds as
the floor. When the assignment itself is the policy lever (encouragement campaigns, defaults),
the ITT is the headline and rests on the fewest assumptions.

## The inference regime: abandon the 2SLS t-test

The binding constraint in modern IV practice is inference, and the canon's position (Keane-Neal
2024) is blunt:

- Test significance with the Anderson-Rubin test at EVERY instrument strength (CLR when
  overidentified; they coincide with one instrument). Just-identified, the AR test of a zero
  effect is the robust t-test on the instrument in the reduced form, so it costs one
  regression. The inverted interval repeats that test with y - b0 x as the outcome for each
  candidate b0.
- Confidence intervals only by inverting AR/CLR, never from the 2SLS standard error. Valid
  intervals cannot be symmetric in finite samples, and an unbounded AR interval is an honest
  statement that identification is not established, never something to suppress by switching
  back to t-intervals.
- Hold instruments to a robust first-stage F of about 50 (about 50/K^(3/4) with K instruments),
  not 10. A sample F of 10 bounds worst-case two-tailed t size at about 13.5 percent, not 5.
  Under a uniform prior on rho in [0, 0.45], 2SLS beats OLS in distance to the truth 47
  percent of the time at population F 10 and 65 percent at 29.44, the population F that a
  sample F of 50 certifies (Keane and Neal 2024, Table 5). The sample-F-to-certified-
  population-F ladder, and when a severe-endogeneity relaxation of this bar is credible, are
  in references/details.md. This bar prices 2SLS bias, so it moves with the estimator: it does
  not transfer to a jackknife estimator in a many-instrument design (see the leniency section).
- Below F = 3.84 do not run IV at all; the AR interval will be unbounded and rightly so.
- The reason the t-test dies even at strong F is power asymmetry, a mechanism worth knowing when
  refereeing: the 2SLS standard error is spuriously small exactly when the estimate lands near
  OLS. An IV estimate close to OLS with F between 10 and 50 and a significant t is the modal
  reversed result in their AER audit (12 of 49 papers, 24 percent).
- Estimator by identification status: just-identified, the 2SLS point estimate is fine (the
  estimate, not its t-test). Overidentified: LIML under homoskedasticity, CUE under
  heteroskedasticity or clustering, with CLR for inference; avoid 2SLS and two-step GMM. Never
  mix (no CLR p-values stapled to a 2SLS estimate; no screening on t before applying AR).
- Fewer instruments are better. Bias, size, and asymmetry all worsen with K. Legitimate extra
  instruments come from functions of one continuous instrument or interactions with exogenous
  covariates, which is exactly how Angrist-Krueger ended up many and weak.
- Compute the F heteroskedasticity- or cluster-robust, always; effective F (Montiel
  Olea-Pflueger) when overidentified and non-homoskedastic. Match clustering to the level of
  instrument assignment.

This regime is written for designs with one instrument or a handful. A leniency design has
hundreds, and three of these rules change there: the F bar stops applying, AR is the wrong
robust test because the many-instrument versions are not robust to treatment-effect
heterogeneity, and the clustering reflex has to be re-derived from the assignment mechanism.
Each replacement is in references/designs.md, section "Leniency designs: UJIVE and the five
checks". Where this skill departs from the Mixtape (AR intervals, F language, JIVE, balance),
the reasons and the chapter's numbers are in references/details.md, section "Mixtape notes".

## Overidentification and heterogeneity, one rule

Overid-test rejections conflate instrument invalidity with treatment-effect heterogeneity:
different instruments (or share combinations) move different complier populations, so divergent
estimates need not mean an invalid instrument, and with correlated instruments the pooled
estimate need not be any complier average at all (Imbens 2014; Mogstad-Torgovitsky-Walters 2021
via Borusyak-Hull-Jaravel 2025). A rejected J-test is a red flag for interpretability either
way; what it does not do is cleanly convict the instrument. Say which reading you take and why.

## Shift-share instruments

Recognize it by z_i = sum_k s_ik g_k, common shifts weighted by exposure shares (Bartik, ADH,
category demand growth weighted by sales shares). Rule: commit to the exogenous-shifts or the
exogenous-shares path (Borusyak-Hull-Jaravel 2025) and pass that path's Table 2 disqualifier.
Refusal: a design that fails both disqualifiers gets no shift-share IV estimate, and the
question goes back to causal-design. The paths, the three mechanical rules, timing, and
Rotemberg weights are in references/designs.md, section "Shift-share instruments: pick a path and
defend it".

## Formula instruments

Recognize it when the treatment or instrument is computed by a known formula from exogenous
shocks plus nonrandom exposure (treated-friend counts, market access, simulated eligibility).
Rule: shock exogeneity is not enough (Borusyak-Hull 2023), so recenter on the expected
instrument mu_i simulated from a specified assignment process, or control for it. Refusal: if
nobody can state that process, mu cannot be computed and the instrument yields no estimate. The
mechanics are in references/designs.md, section "Formula instruments: recenter or control".

## Leniency designs

Recognize it when cases are routed to decision-makers who differ in strictness, as good as
random within a stratum (judges, examiners, review queues). The decision-maker is the instrument.
Rule: estimate by UJIVE on the decision-maker dummies (Kolesár 2013; Goldsmith-Pinkham, Hull,
and Kolesár 2026), never manual leniency IV, and let assignment pick controls and clustering.
Refusal: if re-routing after assignment is common and only the final assignment is recorded,
report no leniency estimate. The five checks, inference, the sqrt(K)(E[F] - 1) strength
statistic, and the Yap 2025 fallback are in references/designs.md, section "Leniency designs:
UJIVE and the five checks".

Monotonicity and compliers. Price a leniency design against average monotonicity, sufficient
(Frandsen-Lefgren-Leslie 2023) and necessary (Goldsmith-Pinkham-Hull-Kolesár) for nonnegative
weights. Test it by running UJIVE with a binary v times treatment as the outcome, and reject
only when the whole 95% interval sits outside [0, 1]. The null is joint, and the test catches
only gross violations. Non-binary v gives complier means for the external-validity table. Bound
counterfactual decision-maker policies with Kolesár, Montiel Olea, and Roth (2025), and flag
any use of the MST ladder there. Full text: references/details.md, section "Leniency designs:
monotonicity and compliers".

## Diagnostics battery

1. Robust first-stage F, computed at the level the design lives at: in-bandwidth for fuzzy RD
   (that skill), shift-level for shift-share, cluster-robust at the assignment level otherwise.
   Read it against the ladder in references/details.md, not against 10. Leniency designs are
   the exception: report sqrt(K) times (E[F] - 1) and skip the threshold entirely.
2. Compliance-share table (binary instrument): pi_a, pi_n, pi_c. A thin complier slice means
   wide intervals and honest extrapolation language.
3. Balke-Pearl inequality checks (binary Y, X, Z): four testable inequalities implied by the
   assumptions; a violation means the design is internally inconsistent, and passing proves
   nothing. Worked flu-data numbers in references/details.md.
4. OLS next to IV, always, and the OLS-proximity audit: t-significant IV near OLS with moderate
   F is the configuration to distrust. When IV lands above OLS, name which explanation you are
   claiming, measurement error in the endogenous regressor or higher complier returns, and why.
5. Overid J (with CUE) where applicable, interpreted under the heterogeneity rule above.
6. Balance of the instrument on predetermined covariates, with the design's controls and the
   design's standard errors (exposure-robust on the shift path; RI for recentered instruments).
   On the share path this is a pre-trends exercise and did-style scrutiny applies.
7. TSLS-LIML divergence in overidentified designs as a cheap weak/many-instrument alarm. Also
   re-estimate with random draws in place of the instruments: the second stage typically still
   looks reasonable while the first-stage F sits near one (Bound, Jaeger, and Baker 1995).
8. Placebo outcomes: lagged outcomes as the dependent variable, RI-based for recentered
   designs (sharp null sidesteps the RI-with-heterogeneity complication).
9. Placebo first stage, bounded by the mechanism: name the margin the mechanism can reach and
   show the instrument does not move treatment past it. Quarter of birth moves high-school
   completion and not college completion, because compulsory schooling binds only through high
   school (Angrist-Krueger 1991). A cost shifter should move price and not assortment, a
   delivery-radius instrument purchase and not browsing.
10. Leniency designs run the battery in references/designs.md instead: UJIVE balance
   regressions on the covariates and on a post-assignment variable, the [0, 1] monotonicity
   test, and the complier table (the last two in references/details.md). Item 7 is replaced
   there by reporting UJIVE next to OLS, 2SLS, and JIVE, where 2SLS sitting between OLS and
   UJIVE is the many-instrument alarm.
11. MST feasibility tests, two cheap re-solves of the extrapolation LP
   (Mogstad-Santos-Torgovitsky 2018): restrict the MTR pairs to zero average selection bias
   and re-solve, then to zero selection on gains. Infeasibility rejects that behavioral
   hypothesis and turns the OLS-IV gap of item 4 into a formal test; with unrestricted MTRs,
   infeasibility is item 3's Balke-Pearl falsification in general form.

## Exhibits: three figures and one table

Three figures carry an IV paper: the instrument's own variation, the first stage, and the reduced
form (Angrist-Krueger 1991 for the pair, Cunningham-Finlay 2013 for the three-figure structure).
Never plot the outcome against fitted treatment, a processed quantity that reads as opaque. Where
a placebo series exists (an untreated market, an unaffected product category), plot it on the
same axes so the reader can see the shock hit one thing. The table carries OLS beside IV, the
first-stage coefficient on the instrument, the strength statistic (effective F, or sqrt(K) times
(E[F] - 1) in a leniency design), N, and the AR interval in brackets under the point estimate,
which puts the valid interval where a reader looks for it.

## The live disputes, carried honestly

Four disputes live in references/canon.md, section "Named disputes the skill carries": whether
the just-identified 2SLS t-test is rescuable (default AR/CLR and the F-50 bar; when a referee
cites Angrist-Kolesár, report both), how to read an overid rejection, which strength standard
holds inside a leniency design, and the weak-instrument fallback there (Yap 2025).

## R implementation

The complete runnable pipeline is scripts/iv_template.R (estimation, the full weak-IV inference
menu, compliance shares and Balke-Pearl checks, both shift-share paths with exposure-robust
inference, recentering with RI, and an optional ivmte block for MST extrapolation bounds), with
every call verified against package documentation. The core:

```r
library(fixest); library(ivmodel); library(ivDiag)
est <- feols(y ~ w1 + w2 | x ~ z, data = df, vcov = ~cl)   # 2SLS point estimate
m   <- ivmodel(Y = df$y, D = df$x, Z = df$z, X = df[, c("w1","w2")])
AR.test(m); CLR(m)                       # identification-robust tests + inverted CIs
LIML(m); Fuller(m)                       # overidentified / many-weak point estimates
ivDiag(data = df, Y = "y", D = "x", Z = "z",
       controls = c("w1","w2"), cl = "cl")   # bootstrapped F, effective F, AR, tF in one call
```

Shift-share: ShiftShareSE (reg_ss / ivreg_ss, AKM and AKM0) and the shift-level equivalent
regression via ssaggregate. Recentering is a hand-coded permutation loop (no package needed;
the template has it). Leniency: ManyIV, the authors' own package, which returns OLS, 2SLS,
UJIVE, IJIVE, and JIVE from one call with heterogeneity-robust standard errors, and which the
paper's own tables were produced with. Package index with versions, links, and traps in
references/details.md.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

> Treatment here is chosen, not assigned: [selection story]. We instrument with [instrument],
> which shifts the incentive to take treatment through [channel]. Assignment of the instrument
> is [randomized / plausibly unconfounded conditional on X], which justifies the reduced-form
> intention-to-treat estimates; the IV estimate additionally requires exclusion, which we assess
> separately for always-takers and never-takers ([arguments]), and monotonicity, which [holds
> because the instrument is a one-directional incentive]. [If this is an examiner-style design,
> use the leniency template below in place of this paragraph.] The estimand is the complier
> average effect (Imbens 2014); compliers are [share] of the sample. Our instrument's robust
> first-stage F is [value], certifying a population F of at least [ladder value] at 95 percent
> confidence; following Keane and Neal (2024) we report Anderson-Rubin [CLR] tests and inverted
> confidence intervals in place of 2SLS t-statistics. [Shift-share designs add: identification
> follows the exogenous-[shifts/shares] path of Borusyak, Hull, and Jaravel (2025), with
> (exposure-robust inference and the effective number of shifts reported / Rotemberg weights and
> per-share balance tests reported).] A limitation of this design is that it identifies effects
> for compliers only. [If the question stops at the compliers, say so and stop. Otherwise:]
> Because our policy question concerns [the rollout / the incentive change], the target is the
> policy-relevant treatment effect for [policy population]. Following Mogstad, Santos, and
> Torgovitsky (2018) we report bounds on it consistent with our IV and OLS estimands under
> [the MTR restrictions imposed: bounded outcomes / decreasing MTE / spline of stated degree],
> for a policy that raises participation by [alpha]. The bounds [range] widen as the
> extrapolation grows, which is the price of asking about individuals the instrument did not
> move.

A leniency design shares almost none of that structure, so it gets its own template:

> Cases here are assigned to [decision-makers] who differ in strictness, and assignment is
> [randomized / as good as random conditional on the [stratum] fixed effects that
> [institution]'s routing rule makes necessary]. We instrument [treatment] with the full set of
> [decision-maker] indicators and estimate by UJIVE (Kolesár 2013), which instruments with a
> leave-one-out estimate of covariate-residualized leniency and stays approximately unbiased
> with many decision-makers and many controls at once, where 2SLS and JIVE do not
> (Goldsmith-Pinkham, Hull, and Kolesár 2026). We report OLS, 2SLS on the indicators, and JIVE
> alongside. [If assignment is independent across units:] Because assignment is independent across
> [units], we report heteroskedasticity-robust standard errors and do not cluster on
> [decision-makers], following Goldsmith-Pinkham, Hull, and Kolesár (2026). [If assignment is
> clustered:] Because a single [decision-maker] covers an entire [shift], we cluster at the
> [shift] level and use the corresponding leave-own-cluster-out estimator. Instrument strength
> is sqrt(K)(E[F] - 1) = [value] across K = [number] [decision-makers]. We do not report the
> first-stage F against a threshold, because it divides by K and is small here even when
> leniency moves treatment substantially. We assess assignment by running the same UJIVE
> specification with each pre-assignment covariate as the outcome, which puts any imbalance in
> treatment-effect units: the coefficients are [magnitude] times smaller than the estimated
> effects. We assess exclusion the same way, using [post-assignment variable] as the outcome.
> The estimand is a convex weighted average of individual treatment effects under average
> monotonicity, which is weaker than the usual no-defiers condition. The condition is sufficient
> for the weights to be nonnegative (Frandsen, Lefgren, and Leslie 2023) and also necessary
> (Goldsmith-Pinkham, Hull, and Kolesár 2026). We test it by re-running the specification with
> [binary pre-assignment variable] times treatment as the outcome, whose estimand must lie in
> [0, 1]: the estimate is [value], and its 95 percent interval [interval] [overlaps / lies
> wholly outside] [0, 1]. A limitation of this test
> is that it detects only gross violations, since on-average defiers have to be both common and
> unlike the compliers to move a weighted average outside those bounds, and its null is joint
> across assignment, exclusion, and monotonicity, so a rejection would not tell us which failed.
> Compliers resemble the full sample on [characteristics], which is the basis for reading the
> estimate as informative beyond the marginal cases. [If a counterfactual policy is the target:]
> We bound the effect of [policy] using the framework of Kolesár, Montiel Olea, and Roth (2025),
> which does not require monotonicity. [Otherwise:] We do not extrapolate beyond the compliers.

Every claim traces to references/canon.md. Keys for the canon papers live in
../causal-design/references/causal.bib; works cited only in passing may have no entry there yet.

## Handoffs

- causal-design: whether IV is the right tool at all; clustering and inference questions shared
  across designs. This skill does not take control functions or Gaussian copulas. The decline
  paragraph at causal-design's triage question 3 carries the pointers for them.
- rdd: fuzzy RD is IV at a cutoff; its first-stage and exclusion discipline lives there, the
  weak-IV inference regime here.
- did: the share-exogeneity path is a stack of DiD-style exposure designs, so parallel-trends
  scrutiny and pre-trend tools from did apply to share balance.
- field-experiment: randomized encouragement designs end to end (including the ITT/LATE
  analysis) and randomization inference on a simple physically randomized instrument;
  recentered and formula instruments keep their RI machinery here.
- Perceived-treatment designs, where an actual feature instruments the perceived feature, arrive
  here: the exclusion and weak-instrument discipline apply to them unchanged.
- Preregistration: the user writes it themselves; this skill supplies the instrument, specification,
  and weak-IV fallback to pre-specify before outcomes are seen.
