---
name: conjoint
description: Design, analyze, and write up conjoint experiments in both traditions: as randomized experiments identifying average marginal component effects, and as preference-measurement instruments (hierarchical Bayes partworths, WTP, choice-share simulation), with measurement-error correction, multiple-testing correction, and a claims firewall on preference talk. TRIGGER on "conjoint", "AMCE", "marginal means", "AMIE", "choice-based conjoint", "CBC", "paired profiles", "attribute randomization", "partworth", "willingness to pay from choice data", "WTP space", "hierarchical Bayes conjoint", "pAMCE", "DCE", "mixed logit", "cjbart", "vignette experiment" (fully randomized factorial vignettes only), "IRR correction", "projoint", "cjoint", "factorEx", "bayesm", "choice share simulation". Text or image profiles whose treatment components are latent inside the stimulus are out of scope: the component needs a design of its own.
---

# Conjoint experiments

Design, estimate, validate, and write up conjoint experiments. The canon is fifteen
user-picked sources (see references/canon.md) spanning two
traditions that share one instrument: political science's design-based causal track
(Hainmueller, Hopkins, and Yamamoto 2014 and its correction wave) and marketing's
preference-measurement track (Netzer et al. 2008; Agarwal et al. 2015; Rossi, Allenby,
and Misra 2024; Sonnier, Ainslie, and Otter 2007). The deliverable is the design or
analysis recommendation with the assumption that licenses it, R code with calls verified
against package documentation, and a drafted methods paragraph. The skill stops at the
four stop points in ../causal-design/references/shared-rules.md (section "Stop points")
and puts each choice to the user. Bib keys live in
../causal-design/references/causal.bib, the family's shared bibliography.

Current as of 2026-10-09; refresh per shared-rules (../causal-design/references/shared-rules.md,
section "Refresh path").
Nothing enters the canon without the user's approval.

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
it breaks). If AMCEs are a deliverable, freeze the randomization. No AMCEs are computed from
an adaptive or utility-balanced design. Asked for them, the skill declines and says why: the
design broke the response-independent randomization the AMCE rests on, so the data goes to the
preference-measurement track. A frozen-randomization
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
- Interactions BETWEEN attributes get their own estimand, the AMIE (Egami and Imai 2019):
  the combination effect minus both AMEs. A regression interaction coefficient estimates
  the conventional interaction effect instead, and any conventional interaction involving a
  baseline level is identically zero, so an arbitrary coding decision blanks out a row and
  a column of the interaction table. All AMIEs are zero exactly when all conventional
  interactions are, so the global F-test can use either. Full statement:
  references/track-experiment.md, section "Interactions: the AMIE, full statement".
  Derivation: references/details.md, section "Causal interaction: the AMIE (Egami and Imai
  2019)".
- Conditional AMCEs are legitimate heterogeneous-effect estimates when the moderator is
  measured PRE-exposure. A difference in conditional AMCEs is never a causal effect of
  the moderator, and for preference description it is not even the right contrast (see
  the subgroup rule in references/track-experiment.md). The moderator's identity splits
  the two tools: respondent characteristics route to conditional marginal means, other
  randomized attributes route to the AMIE. Egami and Imai leave treatment-by-covariate
  interaction as future work, so the seam is theirs, not our patch.

## Design defaults

- Paired profiles (J = 2) side by side in a table, not a vignette. The evidence: paired
  conjoint tracked real referendum behavior with mean absolute error of 2 percentage
  points across 21 attribute effects; single vignettes, the format closest to the real
  documents, recovered no significant origin effect; vignettes attenuate toward zero, and
  engagement beats format mimicry (Hainmueller, Hangartner, and Yamamoto 2015).
- Tasks: choose K by power and cost, not satisficing fear. Degradation is front-loaded
  and bounded: AMCEs drop once from task 1 to 2, then stay flat through 30 (Bansak et
  al. 2018; scope: opt-in online panels, familiar domains). The 2021 handbook chapter's
  own example ran 15 tasks. Budget ONE extra task
  at the end repeating the first task with the profile columns switched: it estimates
  intra-respondent reliability at near-zero cost,
  and zero of 9,472 respondents noticed the repeat (Clayton et al. 2026).
- Attributes: around 10 is standard practice. The list is an ESTIMAND decision first:
  the AMCE is conditional on the included set, respondents infer omitted attributes from
  included ones (masking), and adding or dropping attributes can flip signs with the
  same respondents (Abramson, Kocak, and Magazinnik 2022). Burden binds late: adding 15
  to 35 FILLER attributes on top of the base set produced modest, roughly uniform
  attenuation with relative magnitudes preserved (the ocean-view AMCE fell from 0.175
  with no fillers to 0.082 with 18, keeping nearly half its size, p. 67), with small
  effects losing significance first (Bansak et al. 2021 PSRM).
  The practical ceiling is a judgment about respondent burden, with no hard 20 in the
  evidence. Equalize the number of levels across attributes (the
  number-of-levels effect inflates derived importance; Agarwal et al. 2015).
- Randomization: uniform independent randomization is the parsimony default, with three
  sanctioned deviations (Bansak et al. 2021): weighted draws with disclosed odds to
  match real-world marginals, restrictions for genuinely impossible combinations only
  (excluded combinations have undefined counterfactuals, and the restricted AMCE is
  defined only on the remaining support), and joint draws for correlated attributes.
  Odd but possible combinations stay in: in an eye-tracking study, odd attribute-level
  combinations did not change attention, information search, or choice substantially or
  consistently (Bansak and Jenke 2025).
  When a target distribution is defensible, see references/track-experiment.md, section
  "Design-based pAMCE randomization".
- Attribute row order: randomized across respondents, frozen within a respondent across
  tasks.
- Outcomes: collect BOTH the forced choice and a rating, with the order of the two
  outcome items randomized at the respondent level. Match the choice-set structure to
  the target behavior where one exists: when the real-world counterpart is an
  unconstrained approve/reject, the unconstrained paired design tracked behavior best
  and forced choice produced the largest single distortion (Hainmueller, Hangartner,
  and Yamamoto 2015).
- Sample: matched to the target population, screened to likely decision-makers,
  reweighted to known margins. The forced-choice paired questionnaire had a mean error of
  4 points on the matched probability sample. The same questionnaire failed badly on a
  student convenience sample (mean error 7 points, maximum 28, wrong attributes loading).
- Preregister. A conjoint is a multiple-testing machine, which makes preregistration
  especially valuable (Bansak et al. 2021; Liu and Shiraito 2023). Pin ex ante: the
  attribute list with the masking rationale, the averaging distribution and its source,
  K with its power basis, J, the clustering level, the correction method and its family,
  the IRR estimation method, the diagnostics to be run, and the target population with
  the sample-matching procedure. The user writes the preregistration from this list.

## Estimation: the randomized-experiment track

Defaults, each with the condition that moves off it. The full rules, evidence, and worked
numbers are in references/track-experiment.md, section "Estimation and inference". The
code is scripts/conjoint_template.R, sections 1 to 7b.

- Estimator: one OLS of the choice indicator on all attribute dummies, with standard
  errors clustered by respondent (CR2). With few respondents or very unbalanced task
  counts, use CV3 with the wild cluster restricted bootstrap (shared-rules.md, section
  "Clustering"). Under restricted or weighted randomization, add the linked interactions
  with the eq. 9 weights.
- Measurement error: estimate IRR, correct via projoint, and report raw and corrected
  estimates. The correction is for binary forced choice only. The skill refuses to extend
  it to ratings, rankings, or choose-one-of-many.
- Multiple testing: for screening, adaptive shrinkage or BH at q = .10. For confirmatory
  work, Romano-Wolf with the respondent block bootstrap, and Holm where the bootstrap is
  impractical. Never an uncorrected forest of stars, never plain Bonferroni.
- Interactions: AMIEs with bootstrap selection probabilities. A confirmatory interaction
  claim needs a held-out half.
- Subgroups: conditional marginal means with the nested-model F, each subgroup corrected
  with its own tau. Never difference conditional AMCEs.
- Individual-level heterogeneity: IMCEs (Zhirkov 2022; cjbart) are exploratory
  description, confirmed on fresh data or a held-out half.

## Estimation: the preference-measurement track

Defaults, each with the condition that moves off it. The full rules and evidence are in
references/track-hb.md. The recipe, prior defaults, and input formats are in
references/details.md, section "The HB recipe (bayesm 3.1-7, verified at source level)".
The code is scripts/conjoint_template.R, sections 8 and 9.

- Estimator: choice-based conjoint by hierarchical Bayes, bayesm's rhierMnlRwMixture with
  a mixture-of-normals heterogeneity distribution. Convergence: four chains, split
  rank-normalized R-hat below 1.01, bulk and tail ESS above 400 for every parameter, and
  rank plots. Move to HMC (cmdstanr) at about 100 parameters (untested; track-hb.md) or
  when a referee asks for HMC diagnostics.
- Any run with a sign constraint passes the full Prior explicitly. Rescale price to about
  unit scale and leave the prior alone.
- When WTP, reservation prices, or optimal prices are the deliverable, parameterize in WTP
  space with the prior on WTP. In partworth space, compute WTP draw by draw and report
  posterior quantiles. Validate on holdout log predictive density, never in-sample LMD or
  DIC.
- Use incentive alignment for WTP-relevant tasks. Hold out one randomly selected middle task
  per respondent.
- Shares: share of preference on the posterior draws. Run first choice on draws as the
  check when the scenario adds products similar to existing ones.
- Heterogeneity defaults to mixtures. Flag latent class for segmentation deliverables.
- Whether an IRR-style correction exists for HB partworths is unstudied. Flag it as open.

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
6. Satisficing share (External validity) and IRR (the experiment track). IRR is the one
   diagnostic whose absence is itself a finding.

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
  AMCE above 0.25). Bansak et al. (2023, p. 502) call the fraction preferring an
  attribute infeasible to estimate from typically sized conjoint data, because
  individual-level data are sparse (the "biased toward 0.5" wording is unconfirmed:
  their main text does not say it). Covariate pooling needs exact within-stratum
  preference homogeneity, so the bounds are the only practical route.
- The uncorrelated-intensity escape hatch (sign correspondence when direction and
  intensity are uncorrelated) must be argued with evidence, never assumed: supporters
  and opponents attach different importance on 17 of 22 ANES issues.
- Electability routes to model-based probability-of-winning estimands: conditional
  logistic ridge with two-way interactions (unconfirmed: the main text sends the
  estimator to a Supplementary Material not yet read), thresholded and averaged, validated by
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

## Live disputes, carried honestly

The AMCE-interpretation dispute is adjudicated in references/details.md, section "The
adjudicated dispute cell (AMCE interpretation)". The two HB-track disputes (WTP-space fit
ranking, continuous vs discrete heterogeneity) are in references/track-hb.md, section
"Live disputes on this track".

## Implementation

Which package does which job, with pinned versions, verified traps, and the hand-rolled
fallbacks: references/details.md. Read it before writing any package call. The template
(scripts/conjoint_template.R) runs the full randomized-experiment pipeline and the HB block,
every call verified against package documentation.

## Methods paragraph template

Report each effect with the results sentence in ../causal-design/references/shared-rules.md
(section "Results sentence"): magnitude, direction, a benchmark, and the calibration vocabulary.

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
simultaneous tests, we report [adaptive-shrinkage / BH (screening) / Romano-Wolf
(confirmatory) / Holm (fallback)]-corrected estimates alongside uncorrected ones (Liu and
Shiraito 2023). Subgroup preferences are
described by conditional marginal means with nested-model F-tests (Leeper, Hobolt, and
Tilley 2020). [Interactions: We estimate average marginal interaction effects (Egami and
Imai 2019), which are invariant to the choice of baseline level, by ANOVA under weighted
zero-sum constraints[, collapsing levels within factors and reporting selection
probabilities from [b] bootstrap replicates / with regularization on a held-out half and
intervals estimated on the remainder].] [HB track: We estimate individual partworths by
hierarchical Bayes multinomial logit with a mixture-of-normals heterogeneity distribution
(Rossi, Allenby,
and Misra 2024; bayesm 3.1-7, priors reported in the appendix)[, parameterized in WTP
space with the heterogeneity prior on WTP directly (Sonnier, Ainslie, and Otter 2007)],
validated on [h] holdout tasks. We ran [c] chains of [R] iterations each and discarded
the first half as warm-up. Split rank-normalized R-hat was below 1.01 (maximum [r]),
and bulk and tail ESS exceeded 400 (minimum [e]) for every parameter (Vehtari et al.
2021)[; [k] divergent transitions (HMC runs only)]. [Shares: simulated by [share of
preference / first choice] on the posterior draws.]]"

The template is written in "we". Match the paper's voice: switch to "I" for a
sole-authored paper.

## Handoffs

- causal-design: design triage when no method is chosen yet; this skill assumes the
  conjoint is the design.
- field-experiment: randomization mechanics, power analysis, attrition, and
  noncompliance for experiments generally. The seam runs the other way too: when a
  multi-factor experiment collapses arms on one dimension, the collapsed effect is an
  implicit AMCE averaged over the other factors' assignment distribution, and the full
  machinery lives here.
- Preregistration: the user writes it themselves; this skill supplies the conjoint field list
  (see Design defaults).
- Text or image profiles whose treatment components are latent inside the stimulus are out of
  scope for this skill: randomizing the object does not randomize the component, and the
  component needs a design of its own.
