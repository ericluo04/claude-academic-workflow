# RDD canon

Current as of 2026-07-28. These sources are hand-picked; nothing enters this file without
explicit human approval. BibTeX keys point into ../../causal-design/references/causal.bib.
Refresh: litreview on the method since the date above, results proposed as flagged addenda.

## Cattaneo and Titiunik (2022)

Annual Review of Economics 14: 821-851. Key: `cattaneo2022rdd`.

- Role: the survey of record; the two-framework spine and the consensus defaults.
- Settles: an RD needs a score, a known cutoff, and an ex-ante verifiable rule; precise
  manipulation is the central threat; conventional CIs at the MSE-optimal bandwidth cover about
  80 percent, robust bias correction restores coverage at the same bandwidth; ad hoc bandwidths
  are discouraged outright; global polynomials are visualization only (Gelman-Imbens); fuzzy RD
  is local IV with a complier estimand; covariates are precision-only; discrete scores route to
  local randomization, with mass points as the effective sample size; density test (CJM) plus
  exact binomial count as complements; extrapolation needs added assumptions; ex-post power is
  unreliable, report MDEs.
- Binds when: any RD analysis; framework choice; every prohibition above.
- Implement: the rdpackages suite (rdrobust, rddensity, rdlocrand, rdpower, rdmulti);
  RDHonest is the rival school's package.
- Quote: bandwidths chosen "in an arbitrary manner" are discouraged; global polynomials "not
  recommended for analysis beyond visualization"; the 95-to-80 percent coverage fact.

## Cattaneo, Keele, and Titiunik (2023)

Statistics in Medicine 42(24): 4484-4513. Key: `cattaneo2023guide`.

- Role: the applied workflow companion, adapted here from medicine to marketing; the failure
  anatomy.
- Settles: the ordered empirical workflow (qualitative account, plots, both frameworks,
  falsification, fuzzy diagnostics) with exact code in R/Stata/Python; the roughly-30-distinct-
  values discreteness rule; window-selection mechanics (10 per side minimum, loose p < 0.15
  threshold, no multiplicity correction); first stage tested inside the bandwidth, never
  full-sample (F 698 valid vs F 1.51 failed); fuzzy-ratio balance; per-check bandwidth
  conventions (fresh per covariate for balance, original for donut, one-sided placebo cutoffs);
  the two disqualifying red flags (off-cutoff take-up jumps, smallest-window imbalance; the
  skill conditions the second on outcome relevance, per SKILL.md) and the refusal to estimate
  when a design fails.
- Binds when: executing any RD; every fuzzy design; deciding whether to walk away.
- Implement: the verbatim R workflow block (reproduced in scripts/rdd_template.R); replication
  at rdpackages.github.io.
- Quote: "a weak IV test that uses all observations is likely to overstate the strength of the
  instrument"; the failed application "does not pass basic RD validation/diagnostic tests, and
  the evidence does not support an RD analysis."

## Named dispute the skill carries

Robust bias-corrected inference (this canon) vs honest uniform-in-bias inference
(Armstrong-Kolesar; Imbens-Wager; package RDHonest). The canon's critique: a data-driven
smoothness constant destroys the uniformity, and a manual one is hand-picking the bandwidth by
another name. Default RBC; offer RDHonest alongside on request with the M choice defended in
text. Presented as live, not settled.

## Primary papers cited through the canon

Resolver-verified entries in causal.bib (see the RDD block there for keys and PREPRINT flags):
Calonico-Cattaneo-Titiunik 2014 (robust bias correction); Hahn-Todd-van der Klaauw 2001
(continuity identification); Cattaneo-Frandsen-Titiunik 2015 (local randomization);
Cattaneo-Jansson-Ma 2020 (density test); McCrary 2008 (manipulation test); Lee 2008 (close
elections); Gelman-Imbens 2019 (against global polynomials); Calonico-Cattaneo-Farrell 2020
(CE-optimal bandwidths); Calonico-Cattaneo-Farrell-Titiunik 2019 (covariates);
Cattaneo-Titiunik-Vazquez-Bare 2017 (inference comparison, binomial test) and 2019 (power);
Card-Lee-Pei-Weber 2015 (kink); Imbens-Wager 2019 and Armstrong-Kolesar (honest school);
Kolesar-Rothe 2018 (discrete scores, and the prohibition on clustering standard errors by the
running variable, which binds for continuous scores too); Pei-Lee-Card-Weber (polynomial order);
Cattaneo-Idrobo-Titiunik Foundations and Extensions volumes; Ludwig-Miller 2007 (placebo-outcome
exemplar); Calonico-Cattaneo-Titiunik 2015 (RD plots); Hartman (equivalence testing).

Added 2026-08-26 from the Mixtape ch. 6 pass. BibTeX is Crossref-verified and merged into causal.bib: Imbens-Kalyanaraman 2012 (`imbens2012optimal`,
the origin of the data-driven MSE-optimal bandwidth rule this skill enforces); Lee-Card 2008
(`lee2008specification`, specification error with a discrete running variable, and the origin of
the clustering-on-the-score practice Kolesar-Rothe overturned); Calonico-Cattaneo-Farrell-Titiunik
2017 (`calonico2017rdrobust`, the rdrobust software paper a methods section cites for the
implementation).

## Exemplar rows

The recognition table's canonical cases, Crossref-verified and merged into causal.bib 2026-08-26. One line each, with the design shape the case is the precedent for.

- Card, Dobkin, and Maestas 2008 (`card2008impact`), the age or tenure eligibility rule, and the
  compound-treatment discipline that goes with it.
- Hansen 2015 (`hansen2015punishment`), the agency-measured sharp score, breathalyzer BAC at 0.08.
- Almond, Doyle, Kowalski, and Williams 2010 (`almond2010estimating`), the heaped or rounded score
  at the 1500-gram very-low-birth-weight cutoff, where the density test passes and heaping biases
  the estimate anyway.
- Barreca, Guldi, Lindo, and Waddell 2011 (`barreca2011saving`), the donut-hole re-estimate at that
  same cutoff, which is where the halved one-year mortality effect comes from.
- Barreca, Lindo, and Waddell 2016 (`barreca2016heaping`), the heaping methodology behind the donut,
  and the general case against reading a passing density test as clearance.
- Lee, Moretti, and Butler 2004 (`lee2004voters`), a share crossing a fixed bar, and the
  covariate-balance exhibit as bin means panel by panel.
- Hoekstra 2009 (`hoekstra2009effect`), the admission cutoff with a fuzzy first stage, and the
  take-up plot shown before any outcome.
- Black 1999 (`black1999schools`), the boundary or geographic RD, and the precedent behind the
  DMA-border translation.
