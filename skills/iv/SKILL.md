---
name: iv
description: Design, estimate, validate, and write up an instrumental-variables analysis, covering single-instrument LATE designs, weak-instrument-robust inference, shift-share instruments, and formula/composite instruments that need recentering. Produces advice with citations, R estimation and diagnostics code, and a drafted methods paragraph. TRIGGER on "instrumental variable", "IV", "2SLS", "two-stage least squares", "LATE", "complier", "exclusion restriction", "first stage", "weak instrument", "Anderson-Rubin", "shift-share", "Bartik", "judge design", "examiner leniency", "encouragement design" (field-experiment leads these end to end, including the ITT/LATE analysis; here for the exclusion-restriction discipline and weak-instrument inference when the encouragement serves as an instrument), "price endogeneity", "cost shifter", "Hausman instrument", "simulated eligibility", "recentered instrument", or any setting where treatment is chosen by agents and an incentive or cost shifter moves it. Design triage across methods belongs to causal-design.
---

# Instrumental variables

An opinionated IV workflow grounded in a read canon (references/canon.md, current as of
2026-07-29): Imbens' Statistical Science perspective for the assumption structure and the LATE
estimand, Keane-Neal's Annual Review guide for the weak-instrument inference regime, the two
Borusyak-Hull(-Jaravel) papers for shift-share and formula instruments, and
Mogstad-Santos-Torgovitsky's Econometrica framework for extrapolating beyond the compliers.
The deliverable is the identification argument with the citation that justifies each leg, the
estimation and diagnostics code in R (Stata mirrors noted where the canon is Stata-first), and
a methods paragraph with the limitation stated in first person at the point of the choice.

Refresh path: run the litreview skill on the method since the canon date and fold results into
references/canon.md as flagged addenda.

## When IV, and the four assumptions kept separate

IV is the tool when unconfoundedness fails because treatment is chosen: agents select on
anticipated gains (program participation, adoption, self-selected exposure), or the treatment is
an equilibrium object like a price, where OLS mixes supply and demand slopes (the Fulton fish
market numbers in references/details.md are the two-line demonstration). An instrument is an
incentive or cost shifter: it changes the attractiveness of taking treatment without entering the
potential outcomes.

Four assumptions, argued separately because they have different characters (Imbens 2014):

1. Unconfounded assignment of the instrument. Can hold by design (randomized encouragement) or
   conditionally on covariates. On its own it justifies the reduced-form ITT effects ONLY, never
   the IV ratio.
2. Exclusion. Substantive in essentially every application; Imbens' line is that it holds by
   design only in double-blind placebo trials. Argue it separately by compliance type: the
   instrument can push always-takers and never-takers toward outcome-relevant side actions even
   though it cannot change their treatment (draft-lottery never-takers stayed in school; a
   retention-offer trigger that also flags the account for priority support).
3. Monotonicity (no defiers). Safe when the instrument is a one-directional incentive (letter,
   subsidy, default). Suspect in examiner and judge designs, where it requires the strict
   examiner's approvals to nest the lenient examiner's, a strong behavioral claim. One-sided
   noncompliance buys it for free and turns the LATE into an effect on treated compliers.
4. Relevance, tested with the discipline in the next section, never with a full-sample afterthought.

The estimand under all four is the complier average effect (LATE). Compliers are the focus
because theirs is the only point-identified average, an honest second best. Report the compliance
shares (always-takers, never-takers, compliers, three lines of code) and, when the ATE was the
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
  overidentified; they coincide with one instrument). Just-identified, AR is simply the robust
  t-test on the instrument in the reduced form, so it costs one regression.
- Confidence intervals only by inverting AR/CLR, never from the 2SLS standard error. Valid
  intervals cannot be symmetric in finite samples, and an unbounded AR interval is an honest
  statement that identification is not established, never something to suppress by switching
  back to t-intervals.
- Hold instruments to a robust first-stage F of about 50 (about 50/K^(3/4) with K instruments),
  not 10. F of 10 only controls two-tailed t size; below roughly 50, 2SLS is quite likely
  farther from the truth than OLS unless endogeneity is severe. The sample-F-to-certified-
  population-F ladder, and when a severe-endogeneity relaxation of this bar is credible, are
  in references/details.md.
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
wrong candidate cannot introduce bias where none existed). The same draws give randomization
inference and the balance test of the recentered instrument. The China HSR numbers (0.23
significant collapsing to 0.08 insignificant after recentering) are the calibration for how much
pure exposure bias can look like an effect. Ordinary controls do not substitute: geography
absorbing 82 percent of the instrument's variation still left a significant biased estimate.

## Diagnostics battery

1. Robust first-stage F, computed at the level the design lives at: in-bandwidth for fuzzy RD
   (that skill), shift-level for shift-share, cluster-robust at the assignment level otherwise.
   Read it against the ladder in references/details.md, not against 10.
2. Compliance-share table (binary instrument): pi_a, pi_n, pi_c. A thin complier slice means
   wide intervals and honest extrapolation language.
3. Balke-Pearl inequality checks (binary Y, X, Z): four testable inequalities implied by the
   assumptions; a violation means the design is internally inconsistent, and passing proves
   nothing. Worked flu-data numbers in references/details.md.
4. OLS next to IV, always, and the OLS-proximity audit: t-significant IV near OLS with moderate
   F is the configuration to distrust.
5. Overid J (with CUE) where applicable, interpreted under the heterogeneity rule above.
6. Balance of the instrument on predetermined covariates, with the design's controls and the
   design's standard errors (exposure-robust on the shift path; RI for recentered instruments).
   On the share path this is a pre-trends exercise and did-style scrutiny applies.
7. TSLS-LIML divergence in overidentified designs as a cheap weak/many-instrument alarm.
8. Placebo outcomes: lagged outcomes as the dependent variable, RI-based for recentered
   designs (sharp null sidesteps the RI-with-heterogeneity complication).
9. MST feasibility tests, two cheap re-solves of the extrapolation LP
   (Mogstad-Santos-Torgovitsky 2018): restrict the MTR pairs to zero average selection bias
   and re-solve, then to zero selection on gains. Infeasibility rejects that behavioral
   hypothesis and turns the OLS-IV gap of item 4 into a formal test; with unrestricted MTRs,
   infeasibility is item 3's Balke-Pearl falsification in general form.

## The live dispute, carried honestly

Whether the just-identified 2SLS t-test is rescuable. Angrist-Kolesár 2024 defend it (size is
approximately fine at realistic endogeneity); Lee et al. 2022 patch it with tF/VtF critical
values. The canon's position (Keane-Neal) is that both miss the binding problem: power, not
size. The t-test has near-zero power against effects opposite the OLS bias, which under
publication bias manufactures spurious literature-wide consensus, and tF inherits the asymmetry.
Default here: AR/CLR and the F-50 standard. When a referee pushes back with Angrist-Kolesár,
report both and cite the dispute; the AR test costs one regression, so there is no economy
argument for the t-test.

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
the template has it). Package index with versions, links, and traps in references/details.md.

## Methods paragraph template

> Treatment here is chosen, not assigned: [selection story]. We instrument with [instrument],
> which shifts the incentive to take treatment through [channel]. Assignment of the instrument
> is [randomized / plausibly unconfounded conditional on X], which justifies the reduced-form
> intention-to-treat estimates; the IV estimate additionally requires exclusion, which we assess
> separately for always-takers and never-takers ([arguments]), and monotonicity, which [holds
> because the instrument is a one-directional incentive / is threatened because this is an
> examiner-style design, and we report the corresponding bounds]. The estimand is the complier
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

Every claim traces to references/canon.md; keys live in causal-design/references/causal.bib.

## Handoffs

- causal-design: whether IV is the right tool at all; clustering and inference questions shared
  across designs.
- rdd: fuzzy RD is IV at a cutoff; its first-stage and exclusion discipline lives there, the
  weak-IV inference regime here.
- did: the share-exogeneity path is a stack of DiD-style exposure designs, so parallel-trends
  scrutiny and pre-trend tools from did apply to share balance.
- field-experiment: randomized encouragement designs end to end (including the ITT/LATE
  analysis) and randomization inference on a simple physically randomized instrument;
  recentered and formula instruments keep their RI machinery here.
- preregister: pre-specifying the instrument, specification, and weak-IV fallback before
  outcomes are seen (experiment-first skill; adapt its structure for quasi-experimental PAPs).
