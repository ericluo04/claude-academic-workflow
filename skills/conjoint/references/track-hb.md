# Conjoint: the preference-measurement track

Loaded from SKILL.md (section "Estimation: the preference-measurement track"). The sections
below moved from SKILL.md on 2026-10-09 without rewording. The 2026-11-17 Rao pass added
the screening, base-case, demand, and assumptions bullets and the section "Design on this
track". Paths are relative to the skill root, as in SKILL.md.

## The preference-measurement track (marketing)

When the deliverable is partworths, shares, WTP, pricing, or targeting:

- The stack is choice-based conjoint estimated by hierarchical Bayes, the field's
  accepted default ("comparable or even superior to the traditional methods both in
  part-worth estimation and predictive validity", Agarwal et al. 2015, p. 30). The reference
  implementation is bayesm's rhierMnlRwMixture (Rossi, Allenby, and Misra 2024; bayesm
  3.1-7): hierarchical MNL with a mixture-of-normals heterogeneity distribution. The
  six-step recipe, the prior-defaults table, and the verified input formats are in
  references/details.md, section "The HB recipe (bayesm 3.1-7, verified at source level)";
  the template implements them. Convergence follows Vehtari,
  Gelman, Simpson, Carpenter, and Bürkner (2021): four chains, split rank-normalized
  R-hat below 1.01 and bulk and tail ESS above 400 for every parameter, and rank plots.
  bayesm runs one chain per call, so the template runs four seeded calls, stacks their
  `betadraw` arrays, and diagnoses them with `posterior::summarise_draws()`. One chain's
  trace plot is not a convergence check. The HMC route is cmdstanr with a hand-written
  hierarchical conditional logit. Use it when the parameter count reaches about 100, or
  when a referee asks for HMC diagnostics. The threshold is an expectation Orme reports
  from Kevin Lattery's correspondence, and it is untested; van Horn's datasets had 15 to
  27 parameters. Van Horn (2024, reported by Orme) finds equal holdout prediction and
  better R-hat and ESS for HMC than for Metropolis-Hastings (Sawtooth's CBC/HB).
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
  wrong model on simulated data with known truth). In partworth space, WTP is a
  partworth divided by the price coefficient. When the price coefficient's
  heterogeneity distribution has density at zero (normal, or a mixture of normals),
  that ratio has no finite mean or variance, so posterior means and sds of WTP estimate
  nothing (Daly, Hess, and Train 2012). WTP moments exist when the price coefficient is
  lognormal (bayesm's sign constraint) or bounded away from zero. Compute WTP draw by
  draw for each respondent, never as a ratio of posterior means, report posterior
  quantiles, and keep the partworth-space posterior out of price optimizers. Caveat
  carried: WTP space assumes everyone has finite WTP, an assumption when
  noncompensatory price screening is plausible. Write the rule as "prior on the
  quantity you report", not "WTP space always fits better" (the founding papers
  disagree on the fit ranking).
- Noncompensatory screening. When it is plausible (a must-have attribute, a price ceiling,
  a high no-buy share), fit a screening model next to the HB MNL and compare the two on
  holdout prediction. The reference model is Gilbride and Allenby (2004): a heterogeneous
  probit in which only alternatives that pass a respondent-level conjunctive, disjunctive,
  or compensatory screen enter the choice set, estimated by data augmentation and MCMC. In
  their camera CBC (302 respondents, 14 scenarios of six profiles plus no-buy), the
  conjunctive model had the best log marginal density and 92% of respondents screened
  conjunctively. Its holdout gain over the standard probit was small, 276 against 266
  correct of 604 (pp. 396-399). That is one dataset, so treat screening as a hypothesis to
  test per study. Rao (2026, pp. 299-301) reports contrary evidence where compensatory
  models predicted as well (Yee et al. 2007; Dieckmann, Dippold, and Dietrich 2009;
  primaries unread). The maintained R route is echoice2 (references/details.md, package
  index). A price screen means some respondents have no finite WTP (see the WTP bullet).
- Incentive alignment is the default for WTP-relevant tasks, with the mechanism chosen
  by product availability (the BDM-based WTP mechanism with one real product, Rank
  Order with several; Agarwal et al. 2015). Include the no-choice option when it is
  feasible and salient for consumers, knowing its mere presence shifts processing.
  Always field holdout tasks, holding out one randomly selected middle task per
  respondent, never task 1 and never the final repeat (both carry task 1's
  information); out-of-sample hit rate and LPD are this track's currency.
- Choice-share simulation. Simulate shares on the posterior draws, respondent by
  respondent and draw by draw, then average. van Horn (2024, reported by Orme 2024,
  p. 4) found that simulating on draws predicted holdout shares better than simulating
  on point estimates. Both authors guess that part of the gain is a lower scale factor
  in the simulated shares. Name the rule in the write-up. First choice gives each respondent's
  whole vote to the highest-utility product. Share of preference splits it by the logit
  formula. Share of preference inherits IIA within a respondent: adding a near-copy of
  a product draws share from every product in proportion, where real buyers would take
  it mostly from the copied product. Averaging over heterogeneous respondents and draws
  softens IIA without removing it. The skill's judgment: use share of preference on
  draws as the default, and run first choice on draws as the check whenever the
  scenario adds products similar to existing ones.
- Base case first. Before any what-if run, simulate the current market and report
  simulated against actual shares. Calibration has two standard forms: tune the scale of
  the share rule to current shares (Green and Krieger 1992, p. 125, fitted 4.3 for their
  power rule), or multiply each brand by actual over simulated share and renormalize
  (p. 124). Report raw and calibrated shares side by side. A calibrated base case is fit,
  not validation. The SIMOPT power rule changes with an additive constant (p. 131). The
  skill's judgment from that: with logit share of preference on HB utilities, tune the
  logit scale instead of the power rule, and remember that brand multipliers carry into
  every scenario and change its substitution pattern.
- Share is not demand. Volume for product j is (1/F) times the sum over respondents of
  Q_i P_ij, where F is the sampling fraction and Q_i the respondent's category quantity
  (Rao 2026, p. 135). Weight respondents to the market (Green and Krieger 1992, p. 123),
  and give each respondent the choice set they face in the market.
- State the simulator's assumptions: stable partworths, other marketing variables at
  parity, and a steady state with no competitive reaction (Green and Krieger 1992,
  p. 131). An optimized design's return holds only under no reaction. In their case it
  was $17.34 against a current $2.94 "given no competitive retaliation" (p. 127). In their
  reaction run, a competitor's best response to Beta's constrained optimum ($13.42)
  copied Beta's unconstrained optimum (p. 129). Report at least one
  competitor-response scenario next to any optimized return. Rao (2026, p. 324) prints
  the return as $17.43. The paper's figure is $17.34.
- Managerial translation (MVAI and its cost threshold, reservation-price pricing,
  product-line optimization, price as a quality signal, fusion with market data) is
  mapped in references/details.md, sections "Marketing translation and instrument
  threats" and "Product lines, price signals, and market data". Decisions ride on the
  posterior draws.
- Open question, flagged honestly: whether a measurement-error correction analogous to
  the IRR correction exists for HB partworths is unstudied; the canon does not answer
  it.

## Design on this track

These rules apply only when AMCEs are not a deliverable. A design built from priors, for
utility balance, or for a managerial quantity feeds the preference track alone. The fork in
SKILL.md refuses AMCEs from it.

- Adaptive designs. An adaptive design is ignorable for likelihood or HB estimation only
  when the analysis conditions on every response the algorithm used to choose questions
  (Liu, Otter, and Allenby 2007, pp. 646, 650). Dropping those responses distorts the
  partworths, as when ACA's "pairs only" option drops the self-explicated answers that
  chose the pairs (p. 649). For ACA's adaptive metric paired questions estimated by OLS,
  ignoring the adaptation produced a winner's-curse bias of roughly 12% to 18%, near the
  size of response error (Hauser and Toubia 2005, pp. 501-504). In their simulation,
  adaptive polyhedral choice questions showed no relative bias (p. 506). Hauser and
  Toubia report that HB shrinkage does not remove the ACA bias. Liu et al.
  dispute this for HB, and the disagreement is unresolved. Ignorability does not recover
  the efficiency loss Hauser and Toubia report. Fixed efficient designs adapt nothing to
  the respondent, so this bias does not arise for them (Hauser and Toubia 2005, p. 505,
  fn. 9). Liu et al.'s worked examples are linear models, so the extension to HB logit is
  our inference from their likelihood argument.
- Priors. The MNL information matrix depends on the partworths it estimates (Sandor and
  Wedel 2001, p. 430). Take priors from managers' beliefs with their uncertainty, or from a
  pilot fielded on an orthogonal or zero-prior design (Huber and Zwerina 1996, pp. 307-308;
  Traets, Sanchez, and Vandebroek 2020, p. 4). Minimize the DB-error, the expected D-error
  over the prior (Sandor and Wedel 2001, p. 432). A point prior discards its uncertainty.
- The price of the fork. Utility-balanced designs cut the respondents needed for a given
  error by 10-50% (Huber and Zwerina 1996, p. 307). The gain shrinks with wrong priors. Swap
  levels only with confident priors, and relabel when in doubt (p. 315).
- A dominated alternative carries no information (Huber and Zwerina 1996, p. 308), so
  screen out or repair choice sets that contain one. This screen is for this track only.
- When WTP or a feature-versus-price decision is the deliverable, design for the error of
  that quantity, not of the partworths (M-efficiency; Toubia and Hauser 2007, pp. 851-852).
  For choice designs this rests on one worked example (p. 857), so state it as a principle.
- Power before fielding. Simulate choices from the priors, fit the planned model, and report
  each parameter's standard error (the skill's rule; Rao 2026, p. 224, reports the
  aggregate-logit version). Design with idefix (Traets, Sanchez, and Vandebroek 2020). Run
  the simulation with cbcTools, which calls idefix (package index in references/details.md).
- Set size. J = 2 is the experiment track's default. Here, pretest respondent burden,
  include a no-choice option under the incentive-alignment bullet's rule (feasible and
  salient for consumers; Agarwal et al. 2015), and check robustness
  across set sizes of 3 to 5 (Rao 2026, p. 172). Branded sets need brand-by-attribute terms
  (p. 172).
- Holdouts for shares. Beside the random middle holdout, field one or two fixed holdout
  sets shown to every respondent, so that holdout share error can be reported (practice
  reported in Rao 2026, pp. 218, 227).
- Ranges. Set numeric ranges, price above all, to cover every value the simulator or
  optimizer will be asked about. Avoid extrapolating past the end levels, which "can yield
  misleading results" (Rao 2026, p. 15).
  Ranges may exceed the market but must stay believable (p. 74).
- Range-based importance is the range of the partworth function (Rao 2026, p. 15), so it
  moves with the chosen range, the number of levels, and the units (pp. 74-75). Report it
  with the ranges, never as a property of the attribute.
- Scale. Partworths are scaled by the inverse of the error scale, so raw partworths differ
  across groups, conditions, or studies even when preferences do not (Swait and Louviere
  1993, p. 305). Compare scale-free quantities (WTP or partworth ratios, the skill's
  inference) or run their test of equal scale first (pp. 307-309).

## Live disputes on this track

- Preference-space vs WTP-space fit ranking: contested between the founding papers;
  the durable claim is about the implied prior, and the rule is stated accordingly
  (above).
- Continuous vs discrete heterogeneity in HB: unresolved in the marketing literature
  (Agarwal et al. 2015); the skill defaults to mixtures and flags latent class for
  segmentation deliverables.
