---
name: conjoint
description: Design, analyze, and write up conjoint experiments in both traditions, as randomized experiments identifying average marginal component effects (design-based, no behavioral model) and as preference-measurement instruments (hierarchical Bayes partworths, WTP, choice-share simulation), with measurement-error correction, multiple-testing correction, and a claims firewall on preference talk. Produces advice with citations, R estimation code, and a drafted methods paragraph. TRIGGER on "conjoint", "conjoint analysis", "conjoint experiment", "AMCE", "marginal component effect", "marginal means", "AMIE", "causal interaction", "attribute interactions", "choice-based conjoint", "CBC", "profile experiment", "paired profiles", "candidate experiment", "attribute randomization", "partworth", "part-worth", "willingness to pay from choice data", "WTP space", "hierarchical Bayes conjoint", "Sawtooth", "MaxDiff", "best-worst scaling", "forced choice profiles", "vignette experiment" (fully randomized factorial vignettes; single composite-treatment vignettes stay in field-experiment), "intra-respondent reliability", "IRR correction", "projoint", "cjoint", "factorEx", "FindIt", "bayesm", "market simulator", "choice share simulation". Randomization mechanics, power, and attrition belong to field-experiment; design triage across methods to causal-design.
---

# Conjoint experiments

Design, estimate, validate, and write up conjoint experiments. The canon is fourteen
hand-picked sources (see references/canon.md, current as of 2026-07-31) spanning two
traditions that share one instrument: political science's design-based causal track
(Hainmueller, Hopkins, and Yamamoto 2014 and its correction wave) and marketing's
preference-measurement track (Netzer et al. 2008; Agarwal et al. 2015; Rossi, Allenby,
and Misra 2024; Sonnier, Ainslie, and Otter 2007). The deliverable is the design or
analysis recommendation with the assumption that licenses it, R code with calls verified
against package documentation, and a drafted methods paragraph. Bib keys live in
../causal-design/references/causal.bib, the family's shared bibliography.

## The fork: what will the stakeholder do with the output?

Ask this first (it is the marketing canon's own first question). Two answers, two tracks:

- A causal claim about attributes at the population level ("does adding the badge move
  choice, and by how much"): the RANDOMIZED-EXPERIMENT track. Estimand family: AMCEs and
  marginal means. No behavioral model, no individual-level parameters. Identification
  rides on frozen randomization.
- Individual-level partworths, choice-share simulation, WTP, pricing, targeting, or
  segmentation: the PREFERENCE-MEASUREMENT track. Hierarchical Bayes choice modeling.
  Judged by holdout prediction and the decision it supports, not by identification.

The hard rule at the fork: adaptive questioning, utility-balanced or efficiency-optimized
designs, and informative priors on the design side all break the response-independent
randomization that gives the AMCE its design-based causal reading (Netzer et al. 2008 is
the authority for the adaptive family; Hainmueller, Hopkins, and Yamamoto 2014 for what
it breaks). If AMCEs are a deliverable, freeze the randomization. A frozen-randomization
design can feed BOTH tracks from the same data; an adaptive design feeds only the second.
Never mix the interpretations silently.

## Estimands (randomized-experiment track)

- The AMCE: the effect of switching one attribute between two levels on the probability
  the profile is chosen, averaged over the joint distribution of the profile's other
  attributes and the opposing profiles' attributes, restricted to the support where both
  counterfactuals exist (Hainmueller, Hopkins, and Yamamoto 2014). The contrast is a
  profile with the level against an INDEPENDENTLY DRAWN opponent, compared to a profile
  with the baseline against a similarly drawn opponent; it is not "female beats male
  head to head" (Bansak et al. 2023).
- Every AMCE names its averaging distribution. The uniform AMCE (uAMCE) and the
  population AMCE (pAMCE) over a substantively chosen target distribution are different
  members of one estimand family, and the gap between them equals interaction effects
  times the target's distance from uniform, so uniform is externally valid exactly when
  attributes do not interact, which is when a conjoint was unnecessary (de la Cuesta,
  Egami, and Imai 2022). Uniform is not a safe harbor: it is a claim carrying a testable
  burden. Accept it when the analyst shows no meaningful interactions (the model-based
  check in references/details.md, or the global F-test below) or argues a theoretically
  uniform target; otherwise route to the pAMCE machinery.
- Marginal means are the primitive: in forced choice the MM of a level is the choice
  probability of profiles carrying it, and the AMCE is the difference between the MM at
  a level and the MM at the reference category (Leeper, Hobolt, and Tilley 2020). MMs
  contain all the information AMCEs do and more; always pair an AMCE plot with an MM
  plot.
- Analyze at the CHOICE level: one row per respondent-task, outcome coded 1 if the left
  profile was chosen. The profile-stacked structure with clustering patches is a
  marketing-ratings inheritance that creates the correlation problem it then corrects
  (Clayton et al. 2026). Three attribute types (independent, dependent across the pair,
  pair-level) organize what can be asked; profile-level analysis handles only the first.
- Interactions BETWEEN attributes get their own estimand, the AMIE (Egami and Imai 2019).
  A regression interaction coefficient estimates the conventional interaction effect,
  whose relative magnitude depends on which level was named the baseline, and conjoint
  attributes (gender, religion, occupation) rarely have a natural one. The mechanical
  consequence is sharper than the interpretive one: any conventional interaction involving
  a baseline level is identically zero, so an arbitrary coding decision blanks out a row
  and a column of the interaction table. The AMIE subtracts the two AMEs instead of
  conditioning at baseline, which makes relative magnitudes baseline-invariant, decomposes
  any treatment-combination effect into main effects plus interactions of every order with
  no residual, and returns the conditional effect of one attribute at a level of another as
  AME plus AMIE. It marginalizes, so it carries the same averaging-distribution discipline
  as the AMCE. This is the quantity inside the uAMCE-pAMCE gap above: when that gap is what
  routes you to the pAMCE, the AMIE is what says which interactions and how large. Testing
  whether ANY interaction exists is baseline-free either way, since all AMIEs are zero
  exactly when all conventional interactions are, so the global F-test can use either.
- Conditional AMCEs are legitimate heterogeneous-effect estimates when the moderator is
  measured PRE-exposure. A difference in conditional AMCEs is never a causal effect of
  the moderator, and for preference description it is not even the right contrast (see
  the subgroup rule below). The moderator's identity splits the two tools: respondent
  characteristics route to conditional marginal means, other randomized attributes route
  to the AMIE. Egami and Imai leave treatment-by-covariate interaction as future work, so
  the seam is theirs, not our patch.

## Design defaults

- Paired profiles (J = 2) side by side in a table, not a vignette. The evidence: paired
  conjoint tracked real referendum behavior with mean absolute error of 2 percentage
  points across 21 attribute effects; single vignettes, the format closest to the real
  documents, recovered no origin effect at all; vignettes attenuate toward zero, and
  engagement beats format mimicry (Hainmueller, Hangartner, and Yamamoto 2015).
- Tasks: choose K by power and cost, not satisficing fear. Degradation is front-loaded
  and bounded: AMCEs drop once from task 1 to 2, then stay flat through 30 (Bansak et
  al. 2018; scope: opt-in online panels, familiar domains). K is typically 5 to 6 in
  applications (the 2021 handbook chapter's own example ran 15). Budget ONE extra task
  at the end repeating the first task with the profile columns switched: it estimates
  intra-respondent reliability at near-zero cost,
  and zero of 9,472 respondents noticed the repeat (Clayton et al. 2026).
- Attributes: around 10 is standard practice. The list is an ESTIMAND decision first:
  the AMCE is conditional on the included set, respondents infer omitted attributes from
  included ones (masking), and adding or dropping attributes can flip signs with the
  same respondents (Abramson, Kocak, and Magazinnik 2022). Burden binds late: adding 15
  to 35 FILLER attributes on top of the base set produced modest, roughly uniform
  attenuation with relative magnitudes preserved (the ocean-view AMCE roughly halved by
  18 fillers), with small effects losing significance first (Bansak et al. 2021 PSRM).
  The practical ceiling is a judgment about respondent burden, with no hard 20 in the
  evidence. Equalize the number of levels across attributes (the
  number-of-levels effect inflates derived importance; Agarwal et al. 2015).
- Randomization: uniform independent randomization is the parsimony default, with three
  sanctioned deviations (Bansak et al. 2021): weighted draws with disclosed odds to
  match real-world marginals, restrictions for genuinely impossible combinations only
  (excluded combinations have undefined counterfactuals, and the restricted AMCE is
  defined only on the remaining support), and joint draws for correlated attributes.
  When a target distribution is defensible, prefer design-based pAMCE randomization: the
  three-design ladder (joint, marginal, mixed) keyed to what population data exist, with
  the effective-sample-size check run before fielding (de la Cuesta, Egami, and Imai
  2022; ladder details and the ESS formula in references/details.md).
- Attribute row order: randomized across respondents, frozen within a respondent across
  tasks.
- Outcomes: collect BOTH the forced choice and a rating, with the order of the two
  outcome items randomized at the respondent level. Match the choice-set structure to
  the target behavior where one exists: when the real-world counterpart is an
  unconstrained approve/reject, the unconstrained paired design tracked behavior best
  and forced choice produced the largest single distortion (Hainmueller, Hangartner,
  and Yamamoto 2015).
- Sample: matched to the target population, screened to likely decision-makers,
  reweighted to known margins. The identical questionnaire that tracked behavior on a
  matched probability sample failed badly on a student convenience sample (mean error 7
  points, maximum 28, wrong attributes loading).
- Preregister. A conjoint is a multiple-testing machine, which makes preregistration
  especially valuable (Bansak et al. 2021; Liu and Shiraito 2023). Pin ex ante: the
  attribute list with the masking rationale, the averaging distribution and its source,
  K with its power basis, J, the clustering level, the correction method and its family,
  the IRR estimation method, the diagnostics to be run, and the target population with
  the sample-matching procedure. The preregister skill drafts the document.

## Estimation and inference

- One OLS of the choice indicator on all attribute dummies (reference level omitted per
  attribute) gives every AMCE at once; nonparametric despite the OLS routine. Standard
  errors cluster by respondent, always: within-task outcomes are mechanically negatively
  correlated and within-respondent outcomes positively correlated, so default or merely
  heteroskedasticity-robust SEs are badly biased (Hainmueller, Hopkins, and Yamamoto
  2014). Block bootstrap by respondent is the small-sample alternative. The template's
  hand-rolled sections run this regression on the profile-stacked HHY structure with
  clustered SEs, valid because it is the estimator HHY themselves use; choice-level
  analysis remains the skill's default for choice modeling.
- Under restricted or weighted (dependent) randomization, plain dummies silently change
  the estimand: include the linked-attribute interactions and report the probability-
  weighted coefficient combination over admissible strata (the eq. 9 machinery; worked
  form in references/details.md).
- Measurement error: never assume it away. Shown the identical task twice, respondents
  agree with themselves only about 75% of the time in every study examined (IRR 73 to
  81% across eight from-scratch replications), which attenuates every AMCE by roughly
  30% (the factor 1 - 2*tau at tau near 0.15) and can flip subgroup differences
  (Clayton et al. 2026). Estimate IRR (repeated task; for existing data, extrapolate
  from task-pair agreement; or borrow with sensitivity), correct via projoint, and
  report both raw and corrected estimates. The correction is for binary forced choice
  ONLY; refuse to extend it to ratings, rankings, or choose-one-of-many, citing the
  authors' own warning. A write-up reporting no IRR is assuming tau = 0, which was
  false everywhere it has been checked.
- Multiple testing: never report an uncorrected forest of AMCE stars. Under a global
  null at a realistic design size (41 tests), the standard pipeline yields at least one
  significant AMCE in over 90% of experiments (Liu and Shiraito 2023). Default:
  adaptive shrinkage (ashr) on the estimates and clustered SEs when priors about which
  effects exist are weak; Benjamini-Hochberg at FDR .05 for exploratory work; Holm with a
  preregistered family for confirmatory work. Corrected and uncorrected shown
  side by side, every status change discussed. Never plain Bonferroni: Holm step-down rejects
  everything Bonferroni rejects and sometimes more, under the same assumptions and at no extra
  cost, so it is a drop-in with strictly more power (the family-wide statement is in
  causal-design's shared rules). Plain BH and not the adaptive BKY variant, deliberately: BKY's
  extra power comes with an independence-flavoured guarantee, and AMCEs estimated on the same
  respondents are dependent in a way BH's positive-regression-dependence condition covers and
  BKY's does not. A screen over machine-generated candidates, where the candidates are not
  respondent-linked, is the case that flips it. Composing the tau correction with the
  multiple-testing correction is mechanically fine (ash consumes any estimate-SE pairs)
  but unstudied; label the combination as our own judgment.
- Interaction search is a worse multiplicity problem than the AMCE forest (every level pair
  across every factor pair), and it takes a different instrument. Regularize the estimates
  and report bootstrap selection probabilities instead of corrected p-values (Egami and Imai
  2019, who decline family-wise error control explicitly and use a 90% selection cutoff).
  Valid inference after level collapsing is unsolved, so a confirmatory interaction claim
  needs a held-out half: collapse and select on one, estimate and build intervals on the
  other. Screening this way is exploratory by construction, and the write-up says so.
- Subgroups, the danger zone twice over. For preference description: differences in
  conditional AMCEs conflate preferences with feelings about the arbitrary reference
  category, so their sign, size, and significance are artifacts (Leeper, Hobolt, and
  Tilley 2020). Estimate conditional marginal means, difference those, and test
  "groups agree overall" with the nested-model F over group-by-level interactions. For
  measurement error: IRR varies by respondent characteristics, so correct each
  subgroup with its own tau before differencing; roughly 5% of subgroup differences
  flipped sign under correction (Clayton et al. 2026).

## The claims firewall

What a conjoint estimate licenses you to say, and what it never does. The mathematics
behind this is settled and shared by both sides of the interpretation dispute (the
adjudicated cell is in Live disputes below).

- Licensed sentence templates (Bansak et al. 2023): "changing [attribute] from [t0] to
  [t1] increases the probability the profile is chosen by [x] points" or ", increases
  the candidate's expected vote share by [x] points", always naming the averaging
  distribution and, for electoral claims, the target election (attribute distribution,
  voter population, number of candidates).
- Banned as direct readings of an AMCE or an MM: "a majority prefers", "most
  respondents favor", proportion differences, electability, "X would win". The AMCE is
  a Borda-type aggregation mixing preference direction and intensity; even with
  rational respondents it can carry the opposite sign of the majority preference
  (Abramson, Kocak, and Magazinnik 2022). MM > 0.5 fails the same way.
- Proportion claims gate through the AKM sharp bounds, which need only the AMCE, the
  number of possible profiles, and the attribute's level count (formula and R helper in
  references/details.md; quick screens: a binary attribute in a large design needs an
  AMCE above 0.25). Direct estimation of the fraction preferring an attribute from
  standard conjoint data is severely biased toward 0.5 and covariate pooling needs
  exact within-stratum preference homogeneity, so the bounds are the only practical
  route (Bansak et al. 2023 concede this from the other side).
- The uncorrelated-intensity escape hatch (sign correspondence when direction and
  intensity are uncorrelated) must be argued with evidence, never assumed: supporters
  and opponents attach different importance on 17 of 22 ANES issues.
- Electability routes to model-based probability-of-winning estimands: conditional
  logistic ridge with two-way interactions, thresholded and averaged, validated by
  CALIBRATION on cross-validated predictions, never by raw accuracy (a perfect model of
  a 55-45 contest scores 0.55).
- The intensity screen for user questions: "do most people prefer X" needs a head count
  (bounds or a redesign); "what happens to choices if we add X" is the AMCE's question,
  and its intensity-weighting is then a feature (near-unanimous mild preferences carry
  near-zero choice consequence, the handedness case). In marketing, expected choice
  share IS usually the managerial estimand, so the vote-share reading needs no import
  license; majority talk within segments still gates through the bounds.

## External validity

- The honest statement: conjoint attribute effects can track real behavior closely
  under the right design and sample; this has been shown once, for approve/reject
  decisions on people in Swiss naturalization referendums, where the paired conjoint
  reproduced 21 behavioral effects with mean absolute error of 2 points and the
  dominant 15-19 point origin penalty almost exactly (Hainmueller, Hangartner, and
  Yamamoto 2015). Generalization beyond that domain is extrapolation, and this skill
  never cites the paper without the scope limit.
- Levels never validate: the best design predicted a 21% rejection rate against the
  actual 37%. Effects, orderings, and relative importance are what survived. No
  absolute-level or uptake claims from stated-preference data.
- Report the satisficing diagnostic (share of respondents accepting or rejecting
  everything); origin effects shrank almost in proportion to it across designs.
- Profile realism is the second external-validity axis alongside respondent
  representativeness: uniform randomization weights configurations no market or ballot
  offers equally with realistic ones (de la Cuesta, Egami, and Imai 2022).
- The marketing tradition's two answers to hypothetical bias, presented together:
  incentive alignment (roughly doubled holdout hit rates, 26% to 48%, and raised price
  sensitivity toward realism) and behavioral benchmarking (the one-domain validation
  above). Alignment improves prediction; benchmarking showed unincentivized EFFECTS can
  match real effects while levels fail.

## The preference-measurement track (marketing)

When the deliverable is partworths, shares, WTP, pricing, or targeting:

- The stack is choice-based conjoint estimated by hierarchical Bayes, the field's
  accepted default ("comparable or even superior to the traditional methods both in
  part-worth estimation and predictive validity", Agarwal et al. 2015). The reference
  implementation is bayesm's rhierMnlRwMixture (Rossi, Allenby, and Misra 2024; bayesm
  3.1-7): hierarchical MNL with a mixture-of-normals heterogeneity distribution. The
  six-step recipe, the prior-defaults table, and the verified input formats are in
  references/details.md; the template implements them.
- The sign-constraint hard rule: any run constraining a coefficient's sign (price
  negative) passes the FULL Prior explicitly, because the shipped constrained defaults
  contradict the package's own documentation in two places (verified at source level;
  the discrepancy table is in references/details.md). Report the priors used.
- Scale before priors: bayesm defaults assume roughly unit-scale data; rescale price
  (hundreds or thousands), leaving the prior alone.
- WTP: when WTP, reservation prices, or optimal prices are the deliverable,
  parameterize in WTP space (the surplus model) and put the normal heterogeneity prior
  on WTP directly. Normal partworths over a lognormal price coefficient put prior mass
  near a zero price coefficient, so the implied WTP prior is fat-tailed and, with 14-15
  tasks per respondent, posterior WTP, demand curves, and optimized prices inherit the
  tails: the partworth model priced a Taurus at $33,200 and a $499-max camera above
  $1,500 in the paper's own data (Sonnier, Ainslie, and Otter 2007). Validate on
  holdout log predictive density, never in-sample LMD or DIC (both preferred the badly
  wrong model on simulated data with known truth). If stuck in partworth space, report
  posterior medians of WTP and keep the posterior out of price optimizers. Caveat
  carried: WTP space assumes everyone has finite WTP, an assumption when
  noncompensatory price screening is plausible. Write the rule as "prior on the
  quantity you report", not "WTP space always fits better" (the founding papers
  disagree on the fit ranking).
- Incentive alignment is the default for WTP-relevant tasks, with the mechanism chosen
  by product availability (the BDM-based WTP mechanism with one real product, Rank
  Order with several; Agarwal et al. 2015). Include the no-choice option when it is
  feasible and salient for consumers, knowing its mere presence shifts processing.
  Always field holdout tasks, holding out one randomly selected middle task per
  respondent, never task 1 and never the final repeat (both carry task 1's
  information); out-of-sample hit rate and LPD are this track's currency.
- Managerial translation (MVAI and its cost threshold, reservation-price pricing,
  product-line optimization) is mapped in references/details.md. Decisions ride on the
  posterior, not point estimates.
- Open question, flagged honestly: whether a measurement-error correction analogous to
  the IRR correction exists for HB partworths is unstudied; the canon does not answer
  it.

## Diagnostics battery

Run and report; each is a regression plus F-test with worked numbers in
references/details.md.

1. Carryover: AMCEs by task number, F-test the attribute-by-task interactions. Expected
   benign pattern: a small task-1 drop, flat thereafter. Failure fallback: first-task
   data only. The CRTConjoint randomization test is the modern sharp version.
2. Profile-order effects: AMCEs by profile position, F-test.
3. Randomization balance: regress respondent characteristics on attribute dummies,
   omnibus F.
4. Attribute row-order effects: row-specific AMCEs, F-test.
5. Atypical profiles: AMCEs by realized-profile typicality strata (external validity,
   not internal).
6. Satisficing share and IRR, as above. IRR is the one diagnostic whose absence is
   itself a finding.

## Live disputes, carried honestly

- AMCE interpretation (Abramson-Kocak-Magazinnik 2022 vs Bansak-Hainmueller-Hopkins-
  Yamamoto 2023): the mathematics is settled and shared; what stays live is which
  question the estimand should answer. Both sides prove the AMCE is a probabilistic
  Borda aggregation mixing direction and intensity, that a positive AMCE does not imply
  a majority preference, and that it identifies the expected-vote-share effect in the
  stated target election. The claims firewall is bilateral (the defenders ban the
  majority reading too). Contested: whether vote share (the field's modal estimand, 87%
  of 82 reviewed voting articles) or the head count (what 83% of applied conjoint
  papers write sentences about) is the right target; both audits hold, the defect is in
  applied prose. Full adjudicated cell with the asymmetries in references/details.md.
- Preference-space vs WTP-space fit ranking: contested between the founding papers;
  the durable claim is about the implied prior, and the rule is stated accordingly
  (above).
- Continuous vs discrete heterogeneity in HB: unresolved in the marketing literature
  (Agarwal et al. 2015); the skill defaults to mixtures and flags latent class for
  segmentation deliverables.

## Implementation

Package index with versions, verified traps, and the hand-rolled fallbacks lives in
references/details.md. Headlines: projoint (CRAN, maintained) is the code path for
choice-level MMs/AMCEs with the IRR correction; factorEx for pAMCE estimation; FindIt
(1.3.0, CRAN 2025-09-23, verified 2026-08-05) for AMEs and AMIEs, with the choice-based
mode, level collapsing, and the held-out-sample inference path;
cjoint is the AMCE reference implementation; cregg is ARCHIVED off CRAN (cite it as the
method reference, do not depend on it; MMs hand-roll in three lines on estimatr with
respondent clustering); ashr for adaptive shrinkage; CRTConjoint (0.1.0, verified
2026-07-31) for the carryover test; bayesm 3.1-7 for the HB track; logitr (1.2.0,
verified 2026-07-31) for the preference-space/WTP-space pair (re-verify at use). The
template (scripts/conjoint_template.R) runs the full
randomized-experiment pipeline and the HB block, every call verified against package
documentation.

## Methods paragraph template

"We estimate average marginal component effects (Hainmueller, Hopkins, and Yamamoto
2014) by regressing [choice / rating] on attribute indicators with standard errors
clustered by respondent[, including linked interactions with probability-weighted
combinations for attributes under restricted randomization]. AMCEs average over [the
uniform / a stated target] distribution of the remaining attributes [justified by ...;
for target distributions: estimated by weighted difference in means / the model-based
pAMCE estimator (de la Cuesta, Egami, and Imai 2022)]. Because reported choices contain
swapping error that attenuates estimates and can reverse subgroup comparisons (Clayton
et al. 2026), we [included a repeated task / extrapolated task-pair agreement],
estimated IRR = [x] (tau = [y]), and report corrected estimates via projoint
[, with subgroup-specific tau for subgroup comparisons]. Because the design implies [m]
simultaneous tests, we report [adaptive-shrinkage / BH / Holm]-corrected
estimates alongside uncorrected ones (Liu and Shiraito 2023). Subgroup preferences are
described by conditional marginal means with nested-model F-tests (Leeper, Hobolt, and
Tilley 2020). [Interactions: We estimate average marginal interaction effects (Egami and
Imai 2019), which are invariant to the choice of baseline level, by ANOVA under weighted
zero-sum constraints[, collapsing levels within factors and reporting selection
probabilities from [b] bootstrap replicates / with regularization on a held-out half and
intervals estimated on the remainder].] [HB track: We estimate individual partworths by hierarchical Bayes
multinomial logit with a mixture-of-normals heterogeneity distribution (Rossi, Allenby,
and Misra 2024; bayesm 3.1-7, priors reported in the appendix)[, parameterized in WTP
space with the heterogeneity prior on WTP directly (Sonnier, Ainslie, and Otter 2007)],
validated on [h] holdout tasks.]"

## Handoffs

- causal-design: design triage when no method is chosen yet; this skill assumes the
  conjoint is the design.
- field-experiment: randomization mechanics, power analysis, attrition, and
  noncompliance for experiments generally. The seam runs the other way too: when a
  multi-factor experiment collapses arms on one dimension, the collapsed effect is an
  implicit AMCE averaged over the other factors' assignment distribution, and the full
  machinery lives here.
- preregister: drafts the preregistration; this skill supplies the conjoint field list
  (see Design defaults).
- Text or image profiles whose treatment components are latent inside the stimulus are out of
  scope for this skill: randomizing the object does not randomize the component, and the
  component needs a design of its own.
