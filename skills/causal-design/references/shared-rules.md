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
outcomes. Clustered standard errors are always conservative and never anti-conservative, but the
conservativeness scales with average sampled cluster size, so clustering "just in case" is not
free.

Under random sampling with unit-level random assignment, do not cluster at all. Under clustered
assignment, cluster at the assignment level. When the sampled clusters are a small fraction of
the population, or few units are sampled per cluster, the choice stops mattering.

One half of this decision is untestable and the skill states it rather than estimating it: the
sample "is not informative" about what fraction of clusters was sampled, so "information about
the need to adjust for clustered sampling must come from outside the sample," while the sample
IS informative about clustered assignment. The Mixtape's rationale for clustering by panel unit,
"to allow for correlation in the eps_it's for the same person i over time," is the one reason
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
2023; the map is in did). `rambachan2025design` is the DiD instance of `abadie2023clustering`.

## Multiplicity, staged by what a false positive costs

One correction applied at every stage is wrong in both directions at once, so match the procedure
to what the output is.

SCREENING, where the output is a candidate list something downstream will re-test: FDR, at
q = .10 and not .05, since a false positive costs one wasted follow-up. Benjamini-Hochberg is the
default and holds under positive regression dependence. The Benjamini-Krieger-Yekutieli two-stage
sharpened q-values that Anderson (2008) made the applied convention recover power by estimating
the null proportion instead of fixing it at 1, at the price of an independence-flavoured guarantee
and less stability. So BKY suits a screen over machine-generated candidates and BH suits estimates
that share respondents. The choice is design-dependent, and say which you took and why.

CONFIRMATORY, where each hypothesis is named and defended: FWER by a resampling method that
bootstraps the actual dependence among the test statistics (Romano-Wolf stepdown, Westfall-Young
maxT), uniformly at least as powerful as Holm and equal to it only under independence. Where
resampling is impractical, Holm. Never plain Bonferroni: Holm step-down dominates it at zero cost
under no extra assumptions, so Bonferroni is never the right answer to a question Holm also
answers.

ACROSS STAGES of a staged design: fixed-sequence gatekeeping. Preregister the order, test each
stage's primary hypothesis at full alpha, stop at the first failure. It costs no alpha, and the
price accepted in advance is that nothing downstream of a failed gate is confirmatory.

Worked instantiations: field-experiment (subgroups and multiple outcomes), conjoint (AMCE
families), and any screen over a machine-generated candidate list.

## Interference routing, by structure

Designs, estimators, and diagnostics live in field-experiment. Clustered interference routes to
two-stage randomization (Hudgens and Halloran 2008, Crepon et al. 2013). Network interference
routes to exposure mappings (Aronow and Samii 2017) with exact tests (Athey, Eckles, and Imbens
2018). Marketplaces and two-sided platforms route to multiple randomization designs (Bajari et al.
2023, Johari et al. 2022).

## Combined experimental and observational data

The surrogate index gets long-run outcomes (retention, LTV) from short experiments, valid only
when all causal paths from treatment to the long-run outcome pass through the surrogates (Athey,
Chetty, Imbens, and Kang 2026). The family ships no estimation template for the surrogate index.
Athey, Chetty, Imbens, and Kang's own empirical implementation is the recipe to follow, and
causal-design's deliverable stops at the validity argument.

## Text-role warnings at handoff (Feder)

As confounder, ignorability over text aspects is untestable, argue it from domain knowledge, and
audit positivity (a representation that nearly encodes the treatment leaves no counterfactual).
As outcome or discovered treatment, never train the measurement function on the estimation sample
(split-sample, via Egami). As treatment,
disentangle the named aspect from correlated aspects, and random assignment of texts leaves
reader-side confounding. Any machine-coded variable in any design gets the PPI rectifier logic
before it enters a regression.

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
