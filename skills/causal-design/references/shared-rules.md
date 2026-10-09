# Rules shared across every design

The full argument behind the one-line rules in causal-design/SKILL.md. Every method skill in the
family points here rather than restating these.

## Estimand first, subpopulation named

IV and fuzzy RDD identify complier effects. DiD and SC identify the ATT of the treated units.
Overlap weighting identifies the overlap population. The methods template forces the clause.

## Clustering

Clustering is a design property, not a data property (Abadie, Athey, Imbens, and Wooldridge
2023): cluster standard errors at the level at which treatment was assigned or the sample was
drawn, and be able to say which. Do not cluster by habit at whatever level makes the panel.
The decision "depends on the nature of the sampling and the assignment processes only, and not
on the presence of within-cluster error components in the outcome variable," so within-cluster
outcome correlation is not a reason to cluster, and the size of the change in your standard
error is not evidence you needed it.

Both errors are live and they are not symmetric. Robust standard errors can be ANTI-conservative,
severely so when clusters explain much of the heterogeneity in treatment effects or potential
outcomes. Clustered standard errors are conservative and never anti-conservative asymptotically
in the number of clusters. The conservativeness scales with average sampled cluster size, so
clustering "just in case" is not free. With few clusters the asymptotics do not hold, and the
small-G rule below governs.

Under random sampling with unit-level random assignment, do not cluster at all. Under clustered
assignment, cluster at the assignment level. When the sampled clusters are a small fraction of
the population, clustered standard errors stop being conservative and remain correct under
clustered assignment, while robust standard errors still understate the variance. When few units
are sampled per cluster, robust and clustered standard errors coincide (AAIW, Sections 3.2 and
3.3).

One half of this decision is untestable and the skill states it rather than estimating it: the
sample "is not informative" about what fraction of clusters was sampled, so "information about
the need to adjust for clustered sampling must come from outside the sample," while the sample
IS informative about clustered assignment. The Mixtape's rationale for clustering by panel unit
(Cunningham, The Mixtape, online ch. 8 sec. 8.1), "to allow for correlation in the eps_it's
for the same person i over time," is the one reason
AAIW rule out, and the answer often coincides only because panel units in a survey are genuinely
the sampling clusters. Say which of the two you are invoking.

AAIW give the design-based rule a named counterexample worth quoting when a referee expects the
reflex: "in a judge-leniency design, where defendants are randomly assigned to judges, standard
errors should not be clustered at the level of the judge." Give that argument as a design
argument, not as a claim about what the residuals do. The sampling variance depends on the
sampling and assignment processes only, so within-examiner correlation in outcomes is irrelevant
by construction and not by cancellation.

Group fixed effects do not get you out of the question. Adding them "allows for group-specific
linear trends in the underlying potential outcomes series but does not change the answer to the
question whether one needs to adjust for clustering" (AAIW, on the common-timing case, which
reduces to a cross-sectional regression of the change in unit-level average outcomes). The same
passage answers "what is the superpopulation" when the sample is the population.

Two further facts to carry. Robust standard errors are conservative rather than exact when the
sample is a large share of the population and effects are heterogeneous (the Neyman finite-sample
correction; `abadie2020sampling` buys the precision back if unit attributes predict the treatment
effect). And for partially clustered assignment with large clusters, their CCV and TSCB estimators
sit between robust and clustered and can be considerably smaller than conventional cluster
standard errors. Neither applies under perfectly clustered assignment, and this family ships no
implementation of either.

Scope: linear estimators only (least squares and fixed effects). Once the level is chosen,
few-cluster inference is a separate problem with its own answer (MacKinnon, Nielsen, and Webb
2023). `rambachan2025design` is the DiD instance of `abadie2023clustering`.

The family's small-G rule. The few-clusters map in did/references/details.md gives the
thresholds and the full ladder. When the number of clusters is small, the first line is CV3, the
cluster jackknife, paired with the wild cluster restricted bootstrap. CR2 with Satterthwaite
degrees of freedom is the cross-check, reported beside it. The pairing follows MacKinnon,
Nielsen, and Webb (2023), who recommend CV3 and the restricted wild cluster bootstrap for
routine use when clusters are few or unbalanced. With few treated clusters, both CV3 and the
wild cluster bootstrap become unreliable. Verify them by randomization inference then (did's
few-clusters battery, step 5).

With one treated cluster, the cluster-level methods fail: CV1, CV3, and the wild cluster
bootstrap. Prefer synthetic-control, after aggregating the micro units to the treated unit, or
did's Fallback B, the cluster-level Fisher randomization test. When neither is feasible, use one
of the two rescues on did's map. Ferman-Pinto works under its restriction that
heteroskedasticity comes only from observables. The ordinary wild restricted bootstrap uses
observation-level weights.

## Multiplicity, staged by what a false positive costs

One correction applied at every stage is wrong in both directions at once, so match the procedure
to what the output is.

SCREENING, where the output is a candidate list something downstream will re-test: FDR at
q = .10 for every skill in the family. The level is the family's judgment. A false positive in a
screen costs one wasted follow-up test. A false negative drops a candidate that nothing
downstream will revisit, so the screen should accept twice the conventional .05 rate.
Benjamini-Hochberg is the default and holds under positive regression dependence. Anderson
(2008) made the Benjamini-Krieger-Yekutieli two-stage sharpened q-values the applied convention.
They recover power by estimating the null proportion instead of fixing it at 1. The price is an
independence-flavoured guarantee and less stability. So BKY suits a screen over
machine-generated candidates and BH suits estimates that share respondents. The choice is
design-dependent, and say which you took and why.
Adaptive shrinkage (Stephens 2017, the `ashr` package) is a third screening option. It shrinks
the estimates toward a unimodal prior fit to all of them and reports local false sign rates. It
suits a large family of estimates with standard errors, such as AMCEs (conjoint carries the
worked case).

CONFIRMATORY, where each hypothesis is named and defended: FWER by a resampling method. The
method bootstraps the actual dependence among the test statistics (Romano-Wolf stepdown,
Westfall-Young maxT). This is the family's default. It is at least as powerful as Holm, and the
gain grows with the dependence among the tests (Romano and Wolf 2005). Holm is the fallback
where resampling is impractical. Never plain Bonferroni: Holm step-down dominates it at zero
cost under no extra assumptions, so Bonferroni is never the right answer to a question Holm also
answers.

ACROSS STAGES of a staged design: fixed-sequence gatekeeping. Preregister the order, test each
stage's primary hypothesis at full alpha, stop at the first failure. It costs no alpha, and the
price accepted in advance is that nothing downstream of a failed gate is confirmatory.

Worked instantiations: field-experiment (subgroups and multiple outcomes), conjoint (AMCE
families), and any screen over a machine-generated candidate list.

## Ex-post power is not a diagnostic

Power computed after the fact from the observed effect is a monotone function of the p-value and
adds no information to it (Hoenig and Heisey 2001). No skill in the family reports it or reads a
null through it. Power belongs to the design stage, computed from an effect size fixed before
the outcomes are seen. After the fact, the confidence interval states which effects the data
rule out.

## Interference routing, by structure

This routing applies to prospective designs, where the researcher still controls assignment. In
an observational design no prospective fix is available, and did and synthetic-control carry the
observational fixes (buffer or drop adjacent controls, drop exposed donors, sign the bias).
Observational interference outside a panel design has no owner. Network spillovers in platform
data, where nobody assigned treatment, are unrouted in this family, and the router says so.

Designs, estimators, and diagnostics live in field-experiment. Clustered interference routes to
two-stage randomization (Hudgens and Halloran 2008, Crepon et al. 2013). Network interference
routes to exposure mappings (Aronow and Samii 2017) with exact tests (Athey, Eckles, and Imbens
2018). Marketplaces and two-sided platforms route to multiple randomization designs (Bajari et al.
2023, Johari et al. 2022).

## Combined experimental and observational data

The surrogate index gets long-run outcomes (retention, LTV) from short experiments. Athey,
Chetty, Imbens, and Kang (2026) identify it under three assumptions. Treatment is unconfounded
in the experimental sample. Surrogacy holds: all causal paths from treatment to the long-run
outcome pass through the surrogates. The experimental and observational samples are comparable,
so the surrogate-to-outcome relation carries over. The authors note that comparability *"is
rarely discussed explicitly"* (NBER w26463, Section 3). A paper that argues surrogacy alone
has not argued identification. The family ships no estimation template for the surrogate index.
Athey, Chetty, Imbens, and Kang's own empirical implementation is the recipe to follow, and the
router's deliverable stops at the validity argument.

## Text-role warnings at handoff (Feder)

As confounder, ignorability over text aspects is untestable, argue it from domain knowledge, and
audit positivity (a representation that nearly encodes the treatment leaves no counterfactual).
As outcome or discovered treatment, never train the measurement function on the estimation sample
(split-sample, via Egami). As treatment,
disentangle the named aspect from correlated aspects, and random assignment of texts leaves
reader-side confounding. Any machine-coded variable in any design gets a correction
before it enters a regression: PPI for a predicted outcome, DSL (Egami, Hinck, Stewart, Wei
2023) or Battaglia et al. 2025 for a predicted treatment or covariate.

One revision the family makes to Feder: his supervised text-as-confounder route (fine-tuned
causally sufficient embeddings, Veitch 2020) is superseded. The GPI results say never fit the
inference-time propensity on a representation learned with a treatment-prediction loss (on GPI's
own simulation evidence; the dispute and its replacement belong to the text-causal literature).

## Mediation has no route in this family

Process evidence (treatment affecting the outcome through a mediator, natural direct and indirect
effects) has NO route here: sequential ignorability is an assumption regime none of the family's
skills carries. Where to go: Imai, Keele, and Tingley (2010) for identification and sensitivity
analysis, Pieters (2017) for the marketing-native statement of what a mediation claim requires.
Fong-Grimmer treatment discovery is not mediation either, whatever it is called.

## Stop points

Every skill in the family stops at four points and puts the choice to the user with its tradeoff. The
four points are after triage, after the design gate, before estimation, and before the write-up.
A default named in a skill is the recommendation at that stop, never the decision. A sweep, a
pilot arm, or a search runs only when three conditions hold. The answer would change what we do,
literature and judgment cannot settle it, and the run is cheap relative to what it resolves. The
skill says which of the three conditions it leans on. Script runs go to a subagent, which
returns the numbers and the failures.

## Results sentence

Every effect in a write-up is reported with its magnitude and its direction. The benchmark is one
the reader knows (the control mean, the pre-period mean, or a known effect from the literature).
Translate it into managerial units where possible (dollars, customers, percentage points of
retention). Calibrate the language to the estimate with this vocabulary: "somewhat small but
meaningful in magnitude", "estimated imprecisely", "directionally consistent but not
significant". Template:

> Treatment [raised/lowered] [outcome] by [estimate] [units] ([95% CI]), which is [x] percent of
> the [control mean / benchmark] of [value], or about [managerial translation]. The effect is
> [calibration phrase].
