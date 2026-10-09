---
name: iv
description: Design, estimate, validate, and write up an instrumental-variables analysis: single-instrument LATE designs, weak-instrument-robust inference, shift-share instruments, formula instruments that need recentering, and leniency (judge and examiner) designs estimated by UJIVE. TRIGGER on "instrumental variable", "IV", "2SLS", "LATE", "complier", "exclusion restriction", "first stage", "weak instrument", "Anderson-Rubin", "shift-share", "Bartik", "judge design", "judge IV", "examiner design", "examiner leniency", "UJIVE", "JIVE", "jackknife IV", "LIML", "Rotemberg weights", "exposure-robust", "AKM", "price endogeneity", "cost shifter", "Hausman instrument", "simulated eligibility", "recentered instrument", or any setting where treatment is chosen by agents and an incentive or cost shifter moves it. Randomized encouragement designs are led end to end by field-experiment.
---

# Instrumental variables

An opinionated IV workflow grounded in a read canon (references/canon.md, current as of
2026-08-04): Imbens' Statistical Science perspective for the assumption structure and the LATE
estimand, Keane-Neal's Annual Review guide for the weak-instrument inference regime, the two
Borusyak-Hull(-Jaravel) papers for shift-share and formula instruments,
Mogstad-Santos-Torgovitsky's Econometrica framework for extrapolating beyond the compliers, and
Goldsmith-Pinkham-Hull-Kolesár's JEP operator's manual for leniency designs.
Deliverable: the recommendation with its citation, the R estimation and diagnostics code, and a
methods paragraph. The skill stops at the four stop points in
../causal-design/references/shared-rules.md (section "Stop points") and puts each choice to the user.

Refresh path: run litreview on the method since the canon date, then propose additions to
references/canon.md as flagged addenda.

## Six designs to recognize

Find your design here before reading about estimators. Fuller rows, with what each canonical
case teaches, are in references/details.md.

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
   and it is testable. The leniency section below carries the weakening and the test; do not
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
  back to t-intervals. Cunningham (The Mixtape, online ch. 7 sec. 7.4) reports AR intervals
  "for robustness"; this skill makes them the only interval, because the two disagree in the
  chapter's own fish example (sec. 7.7, Table 7.14, on Graddy's data): at an effective F of
  22.929 the 2SLS estimate is -1.119 with a robust standard error of 0.431, so the t-interval
  is about [-1.96, -0.27] against a printed AR interval of [-2.186, -0.394]. Both ends move,
  and the AR interval is asymmetric.
- Hold instruments to a robust first-stage F of about 50 (about 50/K^(3/4) with K instruments),
  not 10. A sample F of 10 bounds worst-case two-tailed t size at about 13.5 percent, not 5.
  Under a uniform prior on rho in [0, 0.45], 2SLS beats OLS in distance to the truth 47
  percent of the time at population F 10 and 65 percent at 29.44, the population F that a
  sample F of 50 certifies (Keane and Neal 2024, Table 5). The sample-F-to-certified-
  population-F ladder, and when a severe-endogeneity relaxation of this bar is credible, are
  in references/details.md. This bar prices 2SLS bias, so it moves with the estimator: it does
  not transfer to a jackknife estimator in a many-instrument design (see the leniency section).
  The Mixtape calls an F of 17.6 "strong enough for identification" (online ch. 7 sec. 7.8, on
  Cunningham and Finlay's data) and the fish instrument "strong (F > 22)" (sec. 7.7), both
  inside the band this ladder distrusts (a sample F of 23.1 certifies a population F of 10), so
  a reader who copies that language into a current submission will draw the objection.
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
The leniency section below states each replacement.

## Overidentification and heterogeneity, one rule

Overid-test rejections conflate instrument invalidity with treatment-effect heterogeneity:
different instruments (or share combinations) move different complier populations, so divergent
estimates need not mean an invalid instrument, and with correlated instruments the pooled
estimate need not be any complier average at all (Imbens 2014; Mogstad-Torgovitsky-Walters 2021
via Borusyak-Hull-Jaravel 2025). A rejected J-test is a red flag for interpretability either
way; what it does not do is cleanly convict the instrument. Say which reading you take and why.

## Shift-share instruments: pick a path and defend it

A shift-share instrument z_i = sum_k s_ik g_k (common shifts g_k weighted by exposure shares
s_ik) does not get identification from "cov(z, eps) = 0". Commit to one of two paths
(Borusyak-Hull-Jaravel 2025), each with its own estimator, standard errors, balance tests, and
disqualifier:

- Exogenous shifts: the shifts are a shock-level natural experiment (possibly conditional on
  shift-level controls); the shares may be arbitrarily endogenous. Disqualifier, near-verbatim
  from their Table 2: do not take this path if you would not use the shifts directly as an
  instrument in a shift-level regression, for example because they are too few or endogenous.
- Exogenous shares: every individual share satisfies a parallel-trends-style exogeneity
  condition; shifts only pool the K share instruments and matter for power. Disqualifier: do not
  take this path if you would not use a single share as an instrument on its own, for example
  because the shares are generic. Generic shares (industry mix) proxy exposure to any industry
  shock; tailored shares (origin-country migrant networks for migration treatments) can qualify.

Refusal. A design that fails both disqualifiers has no identification path, and no estimator or
standard error repairs that. Report no shift-share IV estimate. The write-up says the shifts are
too few or too endogenous to instrument on their own and the shares are generic, and the
question goes back to causal-design. This exit is our judgment, built on the Table 2
disqualifiers.

Three mechanical rules that are silently violated in practice:

1. Control for the sum of shares whenever shares are incomplete (do not renormalize), interacted
   with period indicators in stacked designs.
2. On the shift path, use exposure-robust inference: the AKM variance estimator or the
   equivalent shift-level regression (ssaggregate), which also delivers the honest first-stage F.
   Conventional clustering misses the mechanical correlation between units with similar shares.
3. Report the effective number of shifts, 1/sum_k s_k^2 on the importance weights. A small value
   means a few shocks drive everything and no asymptotics protect you, whatever N is.

Timing: measure shares at the beginning of the natural experiment generating the shifts, so
shifts cannot feed back into shares, and lag only with a stated mechanism (it always costs
power). On the share path, compute Rotemberg weights, name the shares that carry the design, and
balance-test those shares against pre-period outcomes (Card's Philippines share fails this in
every period, the canonical caught example). With many shares, TSLS is biased toward OLS: use
JIVE, LIML, HFUL, or bias-corrected TSLS. In-sample estimated shifts (classic Bartik, Card) need
the leave-out construction.

## Formula instruments: recenter or control

Trigger rule (Borusyak-Hull 2023): if the treatment or instrument is computed from exogenous
shocks plus nonrandom exposure by a known formula, shock exogeneity is not enough. Their
one-sentence version: randomizing transportation upgrades does not randomize the market access
growth generated by them. Recognition is the hard part; the standing examples are network
spillover counts (number of treated friends), market-access measures, and simulated eligibility
instruments, and the structure also covers media-coverage instruments and randomized rollouts
propagating through nonrandom networks.

The fix is one-dimensional: simulate counterfactual shock vectors from a specified assignment
process (a permutation class in natural experiments), recompute the instrument under each,
average to get the expected instrument mu_i, then instrument with z_i - mu_i or control for
mu_i. Recenter first in a true experiment; in a natural experiment prefer controlling for
several candidate mu_i from different guessed assignment processes, which is doubly robust (a
wrong candidate cannot introduce bias where none existed). The protection has a price. Each
extra candidate is one more control, which absorbs instrument variation and widens the
interval. Our judgment: add a candidate only for an assignment process you can defend. The
same draws give randomization inference and the balance test of the recentered instrument. The
China HSR numbers (0.23 significant collapsing to 0.08 insignificant after recentering) are the
calibration for how much pure exposure bias can look like an effect. Ordinary controls do not
substitute: geography absorbing 82 percent of the instrument's variation still left a
significant biased estimate.

Refusal. Recentering needs an assignment process to simulate from. If nobody can state one (no
protocol, and no stratum of similar shocks within which permutation is credible), mu cannot be
computed, and the formula instrument is not valid. Report no estimate from it. The write-up says
which shocks are exogenous, why their assignment process cannot be specified, and that the
design is set aside for that reason. This exit is our judgment, built on Borusyak and Hull's
requirement that the process be specified.

## Leniency designs: UJIVE and the five checks

Recognition: cases are routed to decision-makers who differ in strictness, and the routing is as
good as random within a stratum. Judges, patent examiners, disability assessors, loan officers,
child-protection investigators, radiologists, immigration officers, and any platform review
queue that assigns by roster. The instrument is the decision-maker identity itself, and keeping
it that way instead of collapsing it to a constructed leniency number drives everything below
(Goldsmith-Pinkham-Hull-Kolesár 2026).

Two practices to drop first. Do not build an external leniency measure and plug it into a
just-identified IV ("manual leniency IV"), because the construction details drive the bias and
the second-stage standard errors are wrong. Do not read design strength off the variance of a
constructed leniency measure, because estimation noise inflates it. Pass the examiner dummies in
directly and let the estimator do the leave-out.

The estimator is UJIVE (Kolesár 2013), which instruments treatment with leave-one-out fitted
relative leniency: residualize the examiner dummies on the controls first, then fit the first
stage without observation i. The reason it is the default here is arithmetic. Bias is
proportional to the trace of the estimator's weighting matrix, and a leniency design is the
setting that carries many instruments and many controls at once: 2SLS has trace K, so its bias
scales in the number of examiners; JIVE has trace -L, so its bias scales in the number of
controls and points the opposite way; UJIVE has trace zero. Bias-corrected 2SLS also has trace
zero, but only under homoskedasticity. IJIVE does not fully clear the bias, though in practice
it lands close. The trace algebra is in references/details.md. The other jackknife built for
many covariates is FEJIV, the fixed-effect jackknife IV of Chao, Swanson, and Woutersen (2023).
Słoczyński, Sun, and Uysal (2026) report it beside UJIVE, and the fejiv package (MATLAB, R,
Stata) implements it. Their guide is the place to look for covariate specifications, weak
monotonicity, and software.

The Mixtape (online ch. 7 sec. 7.7) demonstrates JIVE in its bail exercise, calling that
treatment "somewhat backwards looking", and flags UJIVE itself as the more robust version. This
skill runs UJIVE: by the trace argument above, many examiners and many controls at once leave
JIVE's many-covariate bias live and pointing opposite to 2SLS's. Report JIVE beside UJIVE as a
diagnostic.

The five checks, in their order:

1. Name the controls that buy as-good-as-random assignment, and let the assignment mechanism
   pick both the estimator and the standard errors. The institutional story is what names the
   controls, so with no institutional story there is no principled control set. Keep necessary
   controls (in every specification) separate from precision controls (optional, and in their
   application these widened the intervals, because the first-stage noise the extra controls
   introduce outweighed the gain in the outcome equation). E[z|w] has to be linear in the
   covariates, which is automatic when w is fixed effects and otherwise needs interactions or
   higher-order terms (sufficient in Kolesár 2013, necessary in Blandhol et al. 2026). Assignment
   can be random and the design still broken if units act on the realization: Gaudet, Harris, and
   St. John (1933), as quoted in Cunningham (The Mixtape, online ch. 7 sec. 7.7), recorded
   defendants changing their plea to draw a different judge. Where the data record it,
   instrument with the initial assignment instead of the final one, and ask the administrators
   how often re-routing happens, since check 2 misses sorting on unobservables. The platform
   analogue is the appealed moderation decision or the re-submitted ticket. Refusal: if
   re-routing after assignment is common and the data hold only the final assignment, the
   instrument carries the units' own choices. Report no leniency estimate. The write-up says how
   often re-routing happens, that the initial assignment is not recorded, and that the design is
   set aside for that reason (our judgment).
2. Balance, run as the same UJIVE specification with the covariate as the outcome. This is the
   step that gets done wrong. Do not regress observables on a constructed leniency measure,
   which manufactures mechanical correlation and carries errors-in-variables bias even when the
   measure is leave-out, and do not report the joint F on the examiner dummies, which is invalid
   with many examiners (Anatolyev-Sølvsten 2023). Running balance as UJIVE puts any imbalance in
   the same units as the treatment effect, so the two are directly comparable: in their patent
   reanalysis the balance coefficients came in about ten times smaller than the effects. The
   same machinery on a post-assignment variable tests exclusion (their instance is months under
   review). The Mixtape (online ch. 7 sec. 7.7) calls balance "an absolute must" and says
   nothing about how, and the two implementations a reader reaches for first are the two ruled
   out here.
3. Estimate by UJIVE and report the alternatives beside it. 2SLS on the examiner dummies landing
   between OLS and UJIVE is the signature of many-instrument bias pulling toward OLS, and 2SLS
   standard errors 3 to 4 times tighter than UJIVE's are that same pathology showing up in the
   variance.
4. Test monotonicity (below).
5. Characterize compliers (below).

Inference. Clustering follows assignment, so with independent assignment to examiners plain
robust standard errors are valid, and clustering on the examiner is not justified by the
assignment process. Say so explicitly when a referee expects examiner clusters. Clustered
assignment (one doctor covers a whole shift) also changes the estimator, calling for
leave-own-cluster-out UJIVE (Frandsen-Leslie-McIntyre 2025), so the clustering decision comes
before the estimation. The clusterIV package (CRAN) implements that cluster-jackknife estimator
and a cluster-jackknife AR test. Confirm that it carries UJIVE's many-control correction before
reporting it as the headline (row in references/details.md).
Full argument: ../causal-design/references/shared-rules.md.

Strength and the weak-instrument fallback. Do not read the first-stage F against a threshold
here. UJIVE stays approximately unbiased and consistent even as E[F] approaches one, provided
sqrt(K) times (E[F] - 1) is large, so that product is the statistic to report. F is also
mechanically small in these designs because the formula divides by K, so a modest F is
uninformative about whether leniency moves treatment. The heterogeneity-robust plug-in variance
absorbs the Bekker many-instrument term, so one standard error covers both. When
sqrt(K) times (E[F] - 1) is small, the fallback is Yap 2025, which substitutes the null-imposed
residual into the UJIVE standard error. The jackknife AR of Mikusheva-Sun 2022 and the
jackknife LM test of Matsushita-Otsu 2024 do not apply here, since neither survives
treatment-effect heterogeneity, which a leniency design has by construction.

Monotonicity, weakened and tested. Price the design against average monotonicity
(Frandsen-Lefgren-Leslie 2023), meaning no unit is a defier on average across pairwise
comparisons. FLL show that the condition is sufficient for nonnegative weights on the
individual effects, and Goldsmith-Pinkham, Hull, and Kolesár (2026) state that it is also
necessary. Nonnegative weights are what uniform monotonicity was protecting in the first place,
and the condition is strictly weaker. It is not invariant to first-stage misspecification: when
examiners work across several strata with stratum-specific leniency, an additive first stage can
break average monotonicity where the true relative leniency satisfies it. Check robustness to
interacting examiner assignment with the stratum fixed effects, and expect that flexibility to
cost precision.

The test: pick a binary v, replace the outcome with v times treatment, hold the treatment,
instruments, and controls fixed, and run UJIVE. The estimand is a convex weighted average of v
under the same weights as the headline estimate, so it lies in [0, 1]. The point estimate is
noisy, so compare the 95% interval with [0, 1] and reject only when the whole interval sits
outside. A rejection means something in the LATE theorem has failed. Two forms of v test
different things. An indicator for an outcome value (the template's default) checks the outcome
distribution of treated compliers, the Kitagawa-type form. An indicator built from a covariate
determined before assignment checks the complier covariate distribution. Two limits to
state when reporting it: the null is joint across assignment, exclusion, and monotonicity, so a
rejection does not localize; and it catches only gross violations, since on-average defiers have
to be both common and unlike the compliers to push a weighted average out of [0, 1]. A sharper
joint test of random assignment, exclusion, and monotonicity is Coulibaly, Hsu, Mourifié, and
Wan (2024), built from the sharp testable implications. It handles few or many cases per judge
and discrete or continuous instruments, and they apply it to Stevenson's Philadelphia data.
What the [0, 1] test buys over testing the stronger condition is that its rejections bear
directly on sign reversals, and it needs neither bounded outcomes nor a small number of
decision-makers. Sigstad 2026 is the calibration for how much to worry: monotonicity is often
violated in judicial panels, yet the violations bias leniency IV estimates little.

Compliers and external validity. The same trick with non-binary v identifies complier means of
any pre-assignment characteristic under the headline weights. Put the complier mean beside the
sample mean covariate by covariate and let the gaps carry the external-validity claim. Untreated
compliers come from using one minus the treatment. To pool the two, run UJIVE of v times (2x - 1)
on (2x - 1). This doubles as a monotonicity check, since a complier mean outside logical bounds
rejects. For effects of counterfactual decision-maker policies, use Kolesár, Montiel Olea, and
Roth (2025, "Evaluating Counterfactual Policies Using Instruments", arXiv 2512.24096), which gives
sharp bounds in judge designs without IV monotonicity. Do not carry the parametric MST
extrapolation ladder into a leniency design without flagging it: that route has not been
formalized for many decision-makers or controls.

Chyn-Frandsen-Leslie 2025 (JEL 63(2)) is the companion practitioner's guide. Read both when the
design is the whole paper.

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
8b. Placebo first stage, bounded by the mechanism: name the margin the mechanism can reach and
   show the instrument does not move treatment past it. Quarter of birth moves high-school
   completion and not college completion, because compulsory schooling binds only through high
   school (Angrist-Krueger 1991). A cost shifter should move price and not assortment, a
   delivery-radius instrument purchase and not browsing.
9b. Leniency designs run the battery in their own section instead: UJIVE balance regressions on
   the covariates and on a post-assignment variable, the [0, 1] monotonicity test, and the
   complier table. Item 7 is replaced there by reporting UJIVE next to OLS, 2SLS, and JIVE,
   where 2SLS sitting between OLS and UJIVE is the many-instrument alarm.
9. MST feasibility tests, two cheap re-solves of the extrapolation LP
   (Mogstad-Santos-Torgovitsky 2018): restrict the MTR pairs to zero average selection bias
   and re-solve, then to zero selection on gains. Infeasibility rejects that behavioral
   hypothesis and turns the OLS-IV gap of item 4 into a formal test; with unrestricted MTRs,
   infeasibility is item 3's Balke-Pearl falsification in general form.

## Exhibits: three figures and one table

Three figures carry an IV paper: the instrument's own variation, the first stage, and the reduced
form (Angrist-Krueger 1991 for the pair, Cunningham-Finlay 2012 for the three-figure structure).
Never plot the outcome against fitted treatment, a processed quantity that reads as opaque. Where
a placebo series exists (an untreated market, an unaffected product category), plot it on the
same axes so the reader can see the shock hit one thing. The table carries OLS beside IV, the
first-stage coefficient on the instrument, the strength statistic (effective F, or sqrt(K) times
(E[F] - 1) in a leniency design), N, and the AR interval in brackets under the point estimate,
which puts the valid interval where a reader looks for it.

## The live disputes, carried honestly

Whether the just-identified 2SLS t-test is rescuable. Angrist-Kolesár 2024 defend it (size is
approximately fine at realistic endogeneity); Lee et al. 2022 patch it with tF critical values,
and Lee, McCrary, Moreira, Porter, and Yap 2023 (NBER w31893) with VtF intervals. The canon's
position (Keane-Neal) is that both miss the binding problem: power, not size. The t-test has
near-zero power against effects opposite the OLS bias, which under publication bias
manufactures spurious literature-wide consensus, and tF inherits the asymmetry.
Default in a few-instrument design: AR/CLR and the F-50 standard. When a referee pushes back
with Angrist-Kolesár, report both and cite the dispute. The AR test costs one regression, so
there is no economy argument for the t-test.

Two further disputes are scope boundaries this skill draws, not positions either set of authors
picked. The F-50 bar and the AR default both come out of the few-instrument literature, and
neither transfers to a leniency design, where strength is read off sqrt(K) times (E[F] - 1) and
the weak fallback is Yap 2025. Keane-Neal and Goldsmith-Pinkham-Hull-Kolesár do not cite each
other, so say which regime you are in before quoting either bar. All four disputes are in
references/canon.md.

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
