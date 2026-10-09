# Conjoint lookup details

Heavy reference content the SKILL.md points into. Sources: reading notes in
the maintainer's reading notes, current as of 2026-07-31.

## The adjudicated dispute cell (AMCE interpretation)

AMCE interpretation (Abramson-Kocak-Magazinnik 2022 vs Bansak-Hainmueller-Hopkins-Yamamoto
2023): the mathematics is settled and shared; what stays live is which question the
estimand should answer. Both sides prove the same facts: the AMCE is a (probabilistic)
Borda aggregation mixing preference direction and intensity (AKM Prop 1; BHHY Prop 1
generalizes it to any independent-profiles randomization), a positive AMCE does not imply
a majority preference, and the AMCE identifies the effect on expected vote share in the
election defined by the design's attribute and voter distributions, for any preference
structure and any number of candidates (BHHY Prop 2, p. 510, checked in the published
article). The claims firewall is bilateral:
BHHY's own reporting rules ban reading an AMCE as a majority preference, a
proportion-preferring difference, or a probability-of-winning effect. Contested: BHHY show
vote share is the modal estimand of empirical election research (87% of 82 reviewed
articles) and that intensity-weighting is what makes the AMCE track real multi-attribute
contests (near-unanimous ceteris paribus preferences can carry near-zero electoral
consequence, their handedness case); AKM show the modal conjoint paper writes majority
sentences anyway (83% preference talk, 51% electoral framing). The audits sample different
literatures and both hold; the defect is in applied prose, and both papers say so.
Asymmetries carried honestly: AKM's bounds (their Prop 2) and sign condition (Prop 3) are
undisputed and are the only practical route to a proportion claim, because BHHY (p. 502)
call the fraction preferring infeasible to estimate from typically sized conjoint data,
where individual-level data are sparse ("biased toward 0.5" is unconfirmed: the main text
does not say it, and the Supplementary Material was not read); AKM's ceteris paribus
definition of attribute preference is the weak flank (with
three binary attributes only 1/7 of comparisons per attribute inform it; undefined under
non-separability, which AKM's own Prop 4 concedes). Design dependence is absorbed rather
than refuted: the AMCE is indexed by a stated target election, so cross-design AMCEs are
different estimands by construction, and an AMCE with no defensible target distribution
supports no substantive sentence. Routing: vote-share language with the target
distribution named is licensed by both sides; proportion talk gates through AKM's bounds;
electability talk routes to BHHY's probability-of-winning estimands, model-based and
validated by calibration, never to a reinterpreted AMCE.

The AKM side's sequel is a preprint: Abramson, Kocak, Magazinnik, and Strezhnev,
"Aggregation, Interpretation, and Estimation of Preferences in Conjoint Experiments"
(SocArXiv xjre9, v1 2023, v3 2026; not peer reviewed). It separates binary preference
relations (does a respondent prefer A to B) from estimands that score a feature against
the whole field of alternatives the design induces. The two can diverge under preference
cycles. It proposes the average feature choice probability (AFCP) for the binary
relation, writes common estimands as weighted averages of pairwise comparisons, and
gives diagnostics for divergence. Cite it as a preprint, from its abstract; the
skill has not read the full text.

## The AKM bounds (proportion-claim gate)

Given AMCE pi for level t1 vs t0, K possible profiles, and tau levels of the attribute
(assuming separable feature preferences), the fraction y strictly preferring t1 satisfies

    y_lo = max((pi*tau*K + tau) / (K*(tau-1) + tau), 0)
    y_hi = min((pi*tau*K + K*(tau-1)) / (K*(tau-1) + tau), 1)

Sharp; extremes reached when direction and intensity are maximally correlated. A majority
claim ships only if y_lo > 0.5 (or y_hi < 0.5 for the reverse). Large-K screens: a binary
attribute needs pi > 0.25; a tau-level attribute needs pi > (tau-1)/(2*tau). Worked check:
pi = 0, tau = 2, K = 4 gives [1/3, 2/3], so a zero AMCE tolerates a two-thirds majority
either way. Audit result: of the top-three-journal forced-choice conjoints 2016-2019Q1,
only one paper's largest effect (0.30, binary, small K) clears the majority bound.

    akm_bounds <- function(pi, K, tau) {
      den <- K * (tau - 1) + tau
      c(lo = max((pi * tau * K + tau) / den, 0),
        hi = min((pi * tau * K + K * (tau - 1)) / den, 1))
    }  # separability assumed; see Abramson et al. 2022 Prop 2 and their SI C

Sign-correspondence escape hatch (their Prop 3): if direction and intensity are
uncorrelated for the attribute, the AMCE's sign matches the majority and understates the
margin. Argued with evidence only (measured importance ratings; direction-stratified
intensity); the empirical default is correlation (17 of 22 ANES issues).

## The averaging-distribution machinery (uAMCE vs pAMCE)

The gap: uAMCE minus pAMCE = sum over profiles of interaction effects times
(Pr_target - Pr_uniform). Both factors must be nonzero to matter.

Design ladder (design-based, preferred when the target can enter before fielding):
- Joint population randomization: randomize whole profiles from the target joint
  distribution. No assumptions beyond HHY's. Estimate by weighted difference in means.
- Marginal population randomization: each factor independently from its target marginal.
  Needs only per-factor marginals. Assumption: no three-way or higher interactions. Under
  it the weights cancel and HHY's plain dummy regression is consistent for the pAMCE.
- Mixed randomization: main factors uniform, control factors from the target. Optimal for
  one main factor under no cross-profile interactions; doubles as preregistration of the
  focal factors. Partial joints relax the marginal design's assumption ((M+1)-way
  tolerated for M jointly drawn factors).
- Before fielding: ESS = (sum w)^2 / (sum w^2) by Monte Carlo per candidate design and
  per factor; the SE multiplier between designs is sqrt(ESS ratio).

Model-based route (for already-fielded uniform data): LPM with all main effects, all
two-way between-factor interactions, and same-factor cross-profile interactions,
differenced across the pair; pAMCE = main coefficient + interaction coefficients weighted
by target marginals. Level collapsing by generalized lasso on adjacent-level differences
with two-fold cross-fitting; block bootstrap by respondent (2,000 reps) with cross-fitting
rerun inside each replicate. Diagnostic: F-test added three-way terms. Decomposition: the
uAMCE-pAMCE gap splits into per-factor contributions; plot each factor's conditional
AMCEs beside its uniform-vs-target distribution shift to locate real interactions vs
purely distributional contributions. No natural target: build counterfactual
distributions from the theory (e.g. low/high-information environments) and report the
pAMCE across them as sensitivity; attributes with no defensible distribution may stay
uniform inside an otherwise-target design, disclosed. Software: factorEx (CRAN 1.1.0,
2025-11-28, Egami/de la Cuesta/Imai, depends genlasso).

## Causal interaction: the AMIE (Egami and Imai 2019)

Estimands. ACE = E{Y(a_l, b_m) - Y(a_0, b_0)}, the combination effect. AME = the same
averaged over the distribution of the other factor. AMIE = ACE minus both AMEs,
pi(a_l, b_m; a_0, b_0) = tau - psi_A - psi_B. The conventional AIE, which is what a
dummy-coded regression interaction coefficient estimates, is instead
E{Y(a_l,b_m) - Y(a_0,b_m) - Y(a_l,b_0) + Y(a_0,b_0)}, the two effects taken at the other
factor's baseline. Both are identified by randomization alone and are linear functions of
one another, so all AMIEs are zero iff all AIEs are zero.

Why the AIE fails here. Interval invariance: differences between AMIEs do not move when the
baseline moves, and such a difference is itself an AMIE. The AIE has that property iff every
AIE is zero. The corollary that bites in practice: any AIE involving a baseline level is
identically zero (xi(a_0, b_m; a_0, b_0) = xi(a_l, b_0; a_0, b_0) = 0), so a whole row and
column of the interaction table are structurally blank, chosen by an arbitrary coding
decision. The AMIE can be nonzero there.

What it buys. Decomposition (their Eq. 10): the K-way ACE is the sum of AMIEs of every order
over every subset, main effects included, with no residual. Their worked case: an ACE of
-2.4 points splits into AMEs of +5.3 and -4.7 plus an AMIE of -3.0. Conditional effects
(Eq. 8): the effect of A at level b_0 of B is AME + AMIE, so adopting the AMIE loses nothing
if the conditional reading is what you want. At K > 2 the AIE degenerates into a conditional
effect of a conditional effect, which the AMIE avoids by construction.

Estimation. Difference in means straight from the definition, or equivalently ANOVA with
weighted zero-sum constraints (Scheffe), weights = the marginal assignment distribution;
differences in fitted coefficients are unbiased for the AME and AMIE. Neither estimator
assumes away higher-order interactions. Fully nonparametric estimation needs all interaction
terms up to J-way, so applications cap the order by sample size (theirs assumes no three-way
interactions at n = 544 respondents). Choice-based data go through a preference-differential
linear probability model with intercept 0.5 when within-pair position does not matter, IIA
assumed.

Regularization. GASH-ANOVA (`post2013factor`) penalizes DIFFERENCES in coefficients, which
are the AMEs and AMIEs themselves, so it collapses levels and selects factors jointly on
main and interaction effects. Two properties worth stating to a user: it can retain a factor
with small main effects and large interactions, and it collapses levels consistently across
the interactions they appear in. Group-lasso relatives including glinternet
(`lim2015learning`) penalize coefficients, not differences, so their output depends on the
coding. Ordered factors get penalties on adjacent-level differences only, unordered factors
on all pairwise differences, so the ordering declaration is a substantive choice about which
merges are admissible.

Inference after selection. Not established for level-collapsing methods. Their stand-in:
selection probability = 1 minus the share of bootstrap replicates (they use 5,000) in which
every coefficient for that factor or interaction is zero, cutoff 90%, with an explicit
statement that FWER is not controlled. The alternative, implemented in FindIt but not
reported in the paper, is sample splitting: regularize on train, estimate and build
intervals on test. Unregularized runs return ordinary variance-covariance output and need
neither.

Scope. Positivity is required for ALL combinations, which rules out fractional factorial
designs and, read literally, hard attribute restrictions; the repairs are HHY footnote 18's
small nonzero probabilities or restricting to a subset of the data and estimands.
Treatment-by-pretreatment-covariate interaction is explicitly future work, so respondent
subgroups stay with Leeper's conditional marginal means. Whether the tau correction composes
with AMIE estimation is unstudied (our judgment, not either paper's claim).

## Restricted randomization: the eq. 9 estimator

Under conditionally independent randomization (restrictions), regress on the focal
attribute's dummies, the restricting attribute's dummies, and their interactions; the
AMCE is the main coefficient plus interaction coefficients weighted by the restricting
attribute's marginal probabilities, summing only over strata where the contrast is
defined (forbidden strata weight zero). HHY's worked example: with occupation 3 requiring
education 2, the education AMCE is beta_1 + 0.5*beta_4. Omitting the interactions under
restricted randomization is a specification error, not a simplification.

## Measurement error (IRR and the tau correction)

Model: reported binary choice flips with probability tau; IRR = 1 - 2*tau*(1-tau), so
tau_hat = (1 - sqrt(1 - 2*(1-IRR)))/2. IRR ~ 0.75 implies tau ~ 0.15.

Bias: E[MM_hat] = MM*(1-2tau) + tau (shrinkage toward 0.5); E[AMCE_hat] = AMCE*(1-2tau)
(pure attenuation, sign preserved, ~30% at tau = 0.15). Correction: MM_tilde =
(MM_hat - tau)/(1-2tau); AMCE_tilde = AMCE_hat/(1-2tau). Unbiased given tau, consistent
with estimated tau; always recommended regardless of expected magnitudes (their Monte
Carlo: lower RMSE almost everywhere; near-null truths with large tau get very uncertain,
the honest cost).

Four routes to tau, in order of preference:
1. Repeated task: one extra final task repeating task 1 with profile columns switched;
   IRR = agreement share. Undetected by all 9,472 respondents; no carryover found
   (largest p 0.18 by the CRT test). Insert fillers before the repeat in one-task designs.
2. Extrapolation (existing data): percent agreement between a respondent's task pairs as
   a function of the number of attributes differing; WLS; intercept at zero differences
   is IRR. Validated out of sample in all eight replicated studies.
3. Borrowing: from the replication archive's Figure 2 values (0.73-0.81) for a closely
   matched study; justify and sensitivity-test over a range.
4. Per-profile-pair nonparametric: drops the constancy assumption, rarely feasible.

Empirical regularities that license one tau per study: IRR does not vary with attribute
content (cross-sample correlation of pair-specific IRR 0.23, noise) but DOES vary with
respondent characteristics (0.85), hence subgroup-specific tau for subgroup comparisons.
Corrected-SE methods (three, speed/convenience/familiarity) are in the paper's
Supplementary Appendix C, all implemented in projoint; or condition on tau_hat plus
sensitivity. Scope: binary forced choice only; the authors warn against extending to
ratings/rankings/choose-one-of-many without new research.

## Multiple testing

FWER 1-(1-.05)^m: .401 at 10 tests, .642 at 20. Headline: >90% of 1,000 global-null
simulations of the HHY immigration design (41 tests) contain at least one significant
AMCE; fewer than 75 of 1,000 show none, and the Figure 1 histogram peaks at 2
significant AMCEs (about 210 data sets, read off the bars). Ten-true-effects scenario:
exact truth recovered 248/1,000 uncorrected vs 589-645 corrected (Table 2: BH 589,
Bonferroni 625, uniform-mixture Ash 620, normal-mixture Ash 645); Bonferroni misses at
least one true effect in ~30% of trials; BH is the method least likely to miss a true
AMCE (their Section 4.2) but is most lenient; Ash between, and it also shrinks point
estimates (smaller MSE, the only method improving magnitudes). Matched default: Ash when
prior knowledge is weak (preregister the mixture family; the uniform-mixture and
normal-mixture families performed similarly in their simulations); BH at the family's FDR
level (q = .10, ../../causal-design/references/shared-rules.md) for screening. Liu and
Shiraito's matched default for confirmatory work is BC with the preregistered family m
(count attribute-level comparisons minus constraint-excluded combinations, plus subgroup,
balance, and quality tests). This skill's confirmatory default is Romano-Wolf by
respondent block bootstrap, with Holm as the fallback at the same alpha and the same
family. Holm rejects everything BC rejects under the same assumptions, so every BC
simulation number above is a bound on Holm's (the ~30% miss rate is a ceiling, not an
estimate). Family discipline: realism-only attributes excluded from the family are excluded
from reported findings. Always report corrected and uncorrected side
by side and discuss status changes. Reanalysis anchor: Ash removed the
construction-worker bonus in Hainmueller-Hopkins-Yamamoto 2014, and BC and Ash removed
the Vietnam military-ally result in Spilker et al. 2016 (an attribute respondents
cannot meaningfully evaluate), so corrected pilots double as design diagnostics.
Interaction with
the tau correction: attenuation shifts the false-negative side, making BC's conservatism
costlier than the tau=0 simulations suggest; the composed procedure is unstudied (label
as our judgment).

## Diagnostics battery, worked numbers

From HHY 2014's application (each a regression plus F-test; pp. 22, 25, 26, checked
against the published article): carryover, per-task
interpreter penalties 0.13-0.19 around pooled 0.16, p ~ .52; profile order 0.15 vs 0.17,
p ~ .48; balance omnibus p ~ .69; row order 0.10-0.23, p ~ .14; atypical-profile strata
compared with the concession that typicality lists are somewhat arbitrary (census
frequencies the principled alternative; external validity only, internal validity
survives by design). Expected benign task-number pattern: task 1 AMCEs 0.186/0.263 drop
once to 0.152/0.238 at task 2, flat through task 30 (0.140/0.233); partial R2 0.104 to
0.079 to 0.075. Satisficing shares (accept-all): 56% paired conjoint, 63% paired
vignette, 70% single conjoint, 72% single vignette, with origin effects shrinking almost
in proportion. CRTConjoint implements the Ham-Imai-Janson randomization test for
carryover/profile order.

## The HB recipe (bayesm 3.1-7, verified at source level)

Six steps: (1) format lgtdata as a list of per-respondent lists (y coded 1..p; X of
n_i*p rows via createX or by hand; "none" = all-zero row; matrices not dataframes; named
elements); (2) scale check: defaults assume roughly unit-scale data, so rescale price
(hundreds/thousands) rather than the prior; (3) model choice: start ncomp = 1, inspect
posterior-mean partworths, move to mixtures or rhierMnlDP if skewed/multimodal;
sign-constrain price only with the full explicit Prior; (4) run rhierMnlRwMixture with
a large R (the man page: "Large R values may be required (>20,000)"; 50,000 keep 10 is
a sane opening), Z centered with no
intercept; (5) judge convergence by the Vehtari, Gelman, Simpson, Carpenter, and Bürkner
(2021, Bayesian Analysis 16(2): 667-718) standard: four chains, split rank-normalized
R-hat below 1.01 and bulk and tail ESS above 400 for every parameter, and rank plots in
place of trace plots. bayesm runs one chain per call, so run four calls with different
seeds, stack each `betadraw` (respondents x variables x draws) into an iterations x
chains x variables array, and pass it to `posterior::summarise_draws()` with `rhat`,
`ess_bulk`, and `ess_tail` (template section 8). One chain cannot produce an R-hat. The
`summary()` default of a 10% burn-in is a convention. The template
discards the first half of each chain and lets R-hat and the rank plots judge it. If any
parameter fails, raise R and rerun all four chains;
(6) report mixture-implied population moments (nmix), individual partworths post-burn-in,
and QUANTILES, never just posterior means and sds (the authors' explicit instruction).

Unconstrained prior defaults (man page, vignette, and source agree): a = rep(5, ncomp);
deltabar = 0; Ad = 0.01*I; mubar = 0; Amu = 0.01 (authors flag as too small for many
applications); nu = nvar+3; V = nu*I; s = 2.38/sqrt(nvar) IN CODE (man page's 2.93 is
stale); w = 0.1.

The covariance prior and its price. bayesm offers only an inverse-Wishart (nu, V) on each
component's covariance. The Stan User's Guide (2.40, Regression Models, "Multivariate
priors for hierarchical models") says the scaled inverse-Wishart (Gelman and Hill's
choice) was motivated mainly by conjugacy, which simplifies Gibbs sampling. It recommends
splitting the covariance into scales and a correlation matrix: "*Our final recommendation
is to give the correlation matrix Ω an LKJ prior with shape η ≥ 1*" (LKJ: Lewandowski,
Kurowicka, and Joe 2009). The skill's
reading of the cost: one degrees-of-freedom value sets the tightness of every variance and
every correlation together, so the analyst cannot loosen one without the other. In the
methods text, name the inverse-Wishart, its nu and V, and the reason (bayesm's conjugate
sampler). A referee who asks for LKJ gets the cmdstanr route in SKILL.md.

Sign-constrained defaults, THE TRAP: any nonzero SignRes flips the whole prior (mubar = 2
on constrained entries, Amu = 0.1, nu = nvar+15), and for V the three sources disagree:
man page diag 4/0.01, vignette 4/0.1, shipped code OVERWRITES to 1/0.2. Hard rule: pass
Prior$V, mubar, Amu, nu explicitly in any constrained run and report them. Also: betadraw
is on the constrained scale but nmix is the mixture over unconstrained beta*; the
transform beta = SignRes*exp(beta*) shrinks WTP-relevant tails.

Relatives: rhierMnlDP (Dirichlet-process heterogeneity; check posteriors of a, nu, v not
piled at support ends); rhierLinearMixture (ratings analog); rhierBinLogit deprecated.
Camera data: 332 respondents x 16 tasks, 4 brands + none, price in hundreds so defaults
work. Citation hygiene: the DESCRIPTION file's Description field says "Rossi, Allenby
and McCulloch (second edition 2024)"; the 2e's third author is Misra. `citation("bayesm")`
returns only the package itself (Rossi 2025, version 3.1-7) and names no book.
Version-pin bayesm and
record sessionInfo; defaults changed across 2.0-2, 3.0, 3.1-0, 3.1-2, 3.1-3.

## WTP space (the Sonnier numbers)

Trap: normal partworths over a lognormal price coefficient put prior mass near a zero
price coefficient, so the implied WTP prior is fat-tailed and with 14-15 tasks the
posterior never escapes it. Remedy: surplus parameterization, index
(x'beta_i - p)/mu_i, theta_i = (beta_i', log mu_i)' ~ N; same sampler. Evidence (page
numbers from the published article): the surplus model has the lower average WTP RMSE
in all four simulated data sets (Table 3, p. 320). In D1 and D2, generated by the
utility model, the RMSEs are 49.23 vs 51.63 and 1.32 vs 1.74 (surplus vs utility). In
D3 and D4, generated by the surplus model, they are 1.52 vs 18.73 and 0.92 vs 1.24. In
D3 the in-sample LMD preferred the utility model although it recovered WTP badly
(p. 321). LMD also preferred the utility model in D1 and D2, where it is the true
model. Sedans: utility-model WTP means 2-3x, sds 5-6x the surplus model's (p. 323;
Camry mean $16,230 vs $7,000, sd $47,870 vs $9,730, Table 7, p. 324); a quarter of respondents
implied to need a free Passat plus a subsidy; optimal prices $33,200 vs $25,800 (Taurus,
largest price difference shown in the experiment $9,000) and >$1,500 vs ~$522 (camera,
max shown $499; p. 329); holdout LPD favors surplus in both data sets (p. 324).
Medians are much less prior-sensitive than
means/sds (the Sawtooth practitioner dodge), but the median fix fails for
decision-theoretic uses since actions depend on the whole distribution. The cause of the
exploding means: in partworth space, WTP is the ratio of a partworth to the price
coefficient, and when the heterogeneity distribution of the price coefficient has
density at zero (a normal, or any mixture of normals), the ratio has no finite mean or
variance (Daly, Hess, and Train 2012, Transportation 39(1): 19-31). Posterior means and
sds of WTP then estimate nothing. WTP moments exist when the price coefficient is
lognormal (bayesm's sign constraint, beta = -exp(beta*)) or otherwise bounded away from
zero. Compute WTP draw by draw, as -beta_ik^(r) / beta_i,price^(r) for each respondent
i and draw r, never as a ratio of posterior means, and report posterior quantiles
(template section 9). Guardrails: the
fit ranking is contested (Train-Weeks found the reverse ordering; Scarpa-Thiene-Train
2008 records both), so the rule is "prior on the quantity you report"; finite WTP for
everyone is an assumption when price screening is plausible; reservation prices need a
fielded no-buy option, equalization prices do not.

## Marketing translation and instrument threats

- Incentive alignment: Ding-Grewal-Liechty doubled holdout hit rates (26% to 48%) and
  raised price sensitivity toward realism; mechanism choice: BDM-based WTP mechanism with
  one real product, Rank Order with several; contingent valuation carries exaggeration
  bias; auctions overbid under perceived competition.
- MVAI (market value of an attribute improvement): share change from the improvement over
  share loss from a price change; improve when MVAI exceeds cost; profitability falls
  once competitive reaction is modeled.
- Threat checklist at design time: no-choice option changes processing (include when
  feasible and salient); number-of-levels effect (equalize levels across attributes);
  attribute nonattendance; noncompensatory screening (consider-then-choose models when
  suspected); context/compromise effects; do not elicit unacceptable levels directly.
- The isomorphic/paramorphic rule (verbatim anchor): "Claiming that a model is isomorphic
  to the true underlying decision process ... seems to require exogenous manipulations
  and/or a set of process measures. Otherwise, a model may only be shown to be
  paramorphic to the true underlying decision process." Fit and prediction never license
  a process claim.

## Package index

Versions verified 2026-07-29/31. projoint, factorEx, FindIt, cjoint, estimatr, ashr,
CRTConjoint, bayesm, logitr, posterior, and bayesplot were re-run in the template on
2026-10-08 under R 4.6.1. Signature-level details are in the conjoint_template.R comments.

| Tool | Version | Role | Traps |
|---|---|---|---|
| projoint | 1.1.4 (CRAN 2026-08-28) | choice-level MMs/AMCEs, IRR estimation (repeated-task + extrapolation), tau correction, corrected SEs, plots | the maintained code path for the correction; methodology = clayton2026correcting; binary forced choice only; choice level takes one contrast per call through a `set_qoi()` object (it errors without one), profile level sweeps all attributes; 1.1.4 tracks estimatr 2.0.0 |
| factorEx | 1.1.0 (CRAN 2025-11-28) | design-based and model-based pAMCE | depends genlasso; target distributions supplied as per-factor marginals or joints |
| FindIt | 1.3.0 (CRAN 2025-09-23, verified 2026-08-05) | CausalANOVA for AMEs and AMIEs; test.CausalANOVA, ConditionalEffect, cv.CausalANOVA | maintained by Egami, well past the paper's 1.1.x; screen=TRUE delegates to glinternet, so the invariance claim covers collapse and estimation, not screening (our reading); vcov and CI.table are returned ONLY when screen and collapse are both FALSE (the manual writes `select`, which is not an argument; it means `screen`); AME/AMIE2 are reported against the GRAND MEAN, so they do not match dummy-regression coefficients; docs disagree on boot (Usage and the code say 100, the argument text says 50), pass it explicitly |
| cjoint | 2.1.3 (CRAN 2026-05-19) | AMCE reference implementation (HHY lineage) | AMCE-centered, not MM-centered |
| cregg | 0.4.0 (last CRAN release 2020-06-28; ARCHIVED off CRAN 2024-09-05; GitHub dormant since 2020) | mm, mm_diffs, cj_anova, amce_by_reference API as the method reference | cite, do not depend; hand-roll MMs instead |
| posterior | 1.7.0 (CRAN) | summarise_draws() with rhat, ess_bulk, ess_tail on the four stacked bayesm chains | expects an iterations x chains x variables array; variable names go in the third dimension |
| bayesplot | 1.16.0 (CRAN) | mcmc_rank_overlay() rank plots for the HB chains | takes the posterior draws_array directly |
| ashr | 2.2-63 (CRAN 2023-08-21) | adaptive shrinkage: ash(betahat, sebetahat) on estimates + clustered SEs | composes with any estimator's output; BH/BC need only p.adjust |
| CRTConjoint | 0.1.0 (verified 2026-07-31) | Ham-Imai-Janson carryover/profile-order randomization test | named in Clayton's appendix; signature verified in the template; re-verify at use |
| bayesm | 3.1-7 (CRAN 2025-11-11) | rhierMnlRwMixture, rhierMnlDP, rhierLinearMixture, createX | the defaults/discrepancy traps above; unit-scale assumption; pass full Prior when sign-constrained |
| logitr | 1.2.0 (verified 2026-07-31) | preference-space AND WTP-space MNL/mixed logit | the Sonnier rule's code path; the space switch is scalePar = "price"; re-verify at use |

Shared with other causal skills: estimatr, whose lm_robust with clusters= gives AMCEs and MMs by
hand. Version and family-wide traps are in ../../causal-design/references/packages.md.

Hand-rolled MM in three lines (the cregg-independent route): per feature,
estimatr::lm_robust(Y ~ 0 + factor(level), clusters = id) gives level MMs with
respondent-clustered SEs; difference two levels for the AMCE; subgroup MMs by
interacting with the group; the omnibus "groups agree" test is the cluster-robust Wald
test that all group-by-level interactions are zero.

## Quote bank (verbatim, note-verified)

- "respondents select the same profile only about 75% of the time, which is about halfway
  between flipping coins (50% agreement) and perfect reliability (100%)" (Clayton et al.).
- "Even with individually rational experimental subjects, the AMCE can indicate the
  opposite of the true preference of the majority." (Abramson et al., abstract.)
- "Marginal means contain all of the information provided by AMCEs and more." (Leeper et
  al.)
- "The lack of a significant pre-trend..." does not belong here; conjoint's analog:
  stability across tasks must never be cited as evidence of reliability (family
  formulation from the Bansak-Clayton compatibility analysis).
- "The standard estimation method for conjoint analysis has become hierarchical Bayes."
  (Netzer et al., p. 348; the paper follows it with citations to Lenk et al. 1996 and
  Rossi and Allenby.)
- "conjoint analysis is only a special case of the broader field of preference
  measurement" (Netzer et al., p. 338).
- "researchers first created a statistical problem for no reason and then had to turn
  around and correct the problem they originally created" (Clayton et al., on profile
  stacking).
