# RDD lookup details

Heavy reference content the SKILL.md points into. Current as of 2026-07-28.

## Package index (every row re-verified against CRAN 2026-08-26; suite home rdpackages.github.io)

| Package | CRAN version | Role | Traps |
|---|---|---|---|
| rdrobust | 4.0.0 (2026-05-16) | rdrobust, rdbwselect, rdplot | `all=` removed from rdrobust(), now summary(fit, all=TRUE); cluster= needs vce="cr1/2/3" (use cr2, our default across these skills, following the small-G cluster-robust literature); masspoints="adjust" default |
| rddensity | 3.0 (2026-05-21) | density + built-in binomial table, rdplotdensity | argument is camelCase `massPoints`; binomial via bino/binoW/binoNW; imports lpdensity (>= 2.2), so R needs no separate install where Stata does |
| rdlocrand | 2.0 (2026-05-14) | rdwinselect, rdrandinf, rdsensitivity, rdrbounds | rdwinselect needs covariates; level=0.15 default is the loose balance threshold by design |
| rdpower | 3.0 (2026-05-17) | rdpower, rdsampsi, rdmde | `rdpow` is the Stata name only; data = cbind(Y, X) |
| rdmulti | 2.0.0 (2026-05-17) | rdmc, rdms, rdmcplot | C is an observation-level cutoff vector |
| binsreg | 2.2 (2026-08-21) | binsreg, binsregselect, binstest: the general binscatter tool (Cattaneo, Crump, Farrell, Feng 2024) | no cutoff argument, so fit each side with subset= or by=; bins are quantile-spaced by default (binspos="qs"); rdplot with its IMSE-optimal bins stays the default RD figure |
| RDHonest | 1.0.1 (2024-12-16) | honest-school intervals | manual smoothness constant M; the canon's critique applies; the only package here without a 2026 release, so pin it and re-check before relying on it |

The chapter's footnote 8 sends R users to cran.r-project.org/web/packages/rdd, which is the old
orphaned `rdd` package and not rddensity. Do not use `rdd` or any other pre-rdpackages
implementation. The chapter's other R loads (fixest for the hand-bandwidth OLS, haven for .dta)
are not RD tools and stay out of this index; lpdensity stays out too, since R users get it as an
rddensity dependency and never call it directly.

Replication repos: github.com/rdpackages-replication/{CKT_2023_SIM, CIT_2024_CUP, CIT_2020_CUP}.
rdrr.io serves stale 2023 builds of these packages; never verify signatures there. The fuzzy
output reports no F statistic; first-stage strength comes from its own sharp RD at fixed
bandwidths (z squared ~ F for one instrument), or a manual kernel-weighted regression, which is
our addition and should be labeled as such.

## Falsification checklist with per-check conventions

| Check | Convention | Failure means |
|---|---|---|
| Qualitative manipulation account | written before estimation | design suspect regardless of tests |
| Density test (rddensity, RBC) | own bandwidth; show the plot | sorting (strategic or administrative); explain or walk away |
| Binomial count test | small windows; constant assignment probability must be sensible, so keep the window narrow (a trending density fails it mechanically) | same as density; works for discrete scores |
| Raw histogram for heaping | finest granularity of the score, before any formal test | excess mass at round values from rounding or coarse measurement; the density test can pass anyway, so run the donut regardless |
| Covariate / placebo-outcome balance | fresh MSE-optimal bandwidth PER covariate; RBC p-values; equivalence-test variant to claim balance affirmatively | invalid if the covariate plausibly drives the outcome |
| Placebo cutoffs | one side of the true cutoff at a time | unexplained jump undermines continuity |
| Donut hole | drop cutoff-adjacent observations, KEEP the original bandwidth | effect rides on the most manipulable observations; the surviving estimate is a different parameter, local to a wider neighborhood |
| Bandwidth sensitivity | instability at or below chosen h is the warning; failure far above is expected | curvature or manipulation, not a license to cherry-pick |
| Take-up plot (fuzzy) | before estimation | off-cutoff jumps = soft rule = likely fatal |

## Window selection mechanics (local randomization)

Nested Fisherian balance tests on predetermined covariates: start from the smallest window with
about 10 observations per side, enlarge stepwise, stop before balance rejects. Threshold
deliberately loose (p < 0.15 or 0.10) with no multiplicity correction, because over-rejection
only shrinks the window (conservative in the right direction). Use the omnibus or minimum
p-value across covariates. Expect the window to be much narrower than the continuity bandwidth;
a local-randomization null next to a significant continuity estimate can be power, not
contradiction (ART: 121 vs 2,593 observations).

## Fuzzy diagnostics

- First stage inside the bandwidth/window only. Anchors: F about 698 (valid ART design) vs
  F = 1.51 (failed chemotherapy design, first-stage effect 0.15 with Fisherian p = 0.32).
- Fuzzy-ratio balance tests: instrument strength amplifies covariate bias.
- One MSE-optimal bandwidth for the ratio, not separate numerator/denominator bandwidths.
- Exclusion argued concretely: crossing the cutoff must move the outcome only through
  treatment. Marketing example that fails it: a churn-score threshold that triggers both the
  retention offer under study and a separate priority-support flag.

## Discrete scores

Roughly 30 or fewer distinct values: treat as discrete. Local randomization applies as-is; RD
plots need no binning (plot mass-point means); continuity methods extrapolate from the nearest
mass points and their effective N is the number of mass points (Kolesar-Rothe for honest
inference in that case). Marketing norm, not exception: weeks of tenure, order counts, months
since signup, integer spend tiers.

## Estimation defaults and their citations

- Local linear (p=1), triangular kernel, MSE-optimal bandwidth, RBC intervals: the consensus
  recipe. p=2 and uniform kernel as robustness. Data-driven polynomial-order choice exists
  (Pei-Lee-Card-Weber).
- CE-optimal bandwidth when the interval is the object; separate left/right bandwidths when
  curvature differs (Arai-Ichimura); clustered variants exist.
- The 95-to-80 percent coverage fact is the one-line justification for RBC.
- Simple RBC implementation detail: inference at polynomial order p+1 with the MSE-optimal
  bandwidth for order p.

## Extrapolation menu (claims away from the cutoff need one of these)

Multi-cutoff variation; pre-period outcomes; conditional ignorability on covariates
(Angrist-Rokkanen); derivative-based local extrapolation (Dong-Lewbel). Absent one, the
methods paragraph says the estimate is local to the cutoff, full stop.

## Power and MDE

Ex-post power from observed effects is unreliable. For nulls that matter, report minimum
detectable effects (rdpower: rdpow, rdsampsi). For ex-ante design (choosing which threshold
experiment to run), rdsampsi gives the required N near the cutoff.

## Canonical cases and what each teaches

The long form of the recognition table in SKILL.md. All six are worked in Cunningham, Causal
Inference: The Remix, ch. 6.

- Card, Dobkin, and Maestas 2008 (AER 98(5)), Medicare at 65. The compound-treatment discipline.
  Retirement also happens at 65, so the authors brought in a third dataset on the same running
  variable (March CPS 1996-2004) and showed employment does not jump there. That is the move
  when the confounder you need to rule out is absent from your own data.
- Hansen 2015 (AER 105(4)), the 0.08 BAC threshold for a DUI charge in Washington State. The
  end-to-end workflow: histogram, density test, covariate balance as both table and figure,
  linear and quadratic outcome plots, then rdrobust. The score is measured by the arresting
  agency with a breathalyzer, which is what makes it resistant to manipulation.
- Almond, Doyle, Kowalski, and Williams 2010 (QJE 125(2)) with Barreca, Guldi, Lindo, and
  Waddell 2011 (QJE 126(4)) and Barreca, Lindo, and Waddell 2016 (Economic Inquiry 54(1)), the
  1500-gram very-low-birth-weight cutoff. The one published RD the
  chapter overturns. The density test found no sorting, heaping at round gram values biased the
  estimate anyway, and the donut cut the one-year mortality effect by about half while dropping
  2 percent of the sample.
- Lee, Moretti, and Butler 2004 (QJE 119(3)), US House Democratic vote share at 50 percent. The
  covariate-balance exhibit: predetermined district characteristics as bin means across the
  cutoff, one panel each.
- Hoekstra 2009 (REStat 91(4)), flagship-university admission test score. The take-up plot as the
  gate before estimation. He shows the jump in the probability of attending before he shows
  anything about earnings.
- Black 1999 (QJE 114(2)), school-district zoning boundaries. The origin of the spatial RD, and
  the precedent behind the DMA-border translation below, which otherwise cites nobody.

## Marketing translations (from the medical guide, adapted)

- Fuzzy algorithmic triggers: churn-score retention offers, lead-score outreach, credit
  approvals, fraud review. Human overrides make these fuzzy; the ITT-vs-complier distinction
  and in-bandwidth F carry over directly.
- Sharp tenure/calendar rules: trial expiry, promotional-rate rolloffs at month 12, student
  discounts, anniversary-based status expiry. Discrete running variables, so the
  local-randomization branch leads.
- Threshold designs with self-influenced scores: spend-based loyalty tiers, follower-count
  monetization bars. Manipulation is live (customers time purchases); density, binomial, and
  donut tests carry more weight here than in medicine.
- Compound treatment at one threshold: a spend value that switches on free shipping, a status
  badge, and a lifecycle email is three treatments at one cutoff, and the RD identifies the
  bundle. Enumerate what fires at that value before writing the design down, then either name
  the one you claim and defend it or report the bundle as the estimand.
- Multi-cutoff: tiered programs (silver/gold/platinum). Geographic RD: DMA advertising borders.
- Bunching at price breaks is adjacent but distinct; bunching identification needs parametric
  assumptions and is out of scope here.
