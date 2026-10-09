# Conjoint: the preference-measurement track

Loaded from SKILL.md (section "Estimation: the preference-measurement track"). The sections
below moved from SKILL.md on 2026-10-09 without rewording. Paths are relative to the skill
root, as in SKILL.md.

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
- Managerial translation (MVAI and its cost threshold, reservation-price pricing,
  product-line optimization) is mapped in references/details.md. Decisions ride on the
  posterior draws.
- Open question, flagged honestly: whether a measurement-error correction analogous to
  the IRR correction exists for HB partworths is unstudied; the canon does not answer
  it.

## Live disputes on this track

- Preference-space vs WTP-space fit ranking: contested between the founding papers;
  the durable claim is about the implied prior, and the rule is stated accordingly
  (above).
- Continuous vs discrete heterogeneity in HB: unresolved in the marketing literature
  (Agarwal et al. 2015); the skill defaults to mixtures and flags latent class for
  segmentation deliverables.
