# Attribution

This workflow stands on other researchers' public Claude Code setups. The skills that came from other repos were adapted, never copied verbatim, but the ideas are theirs and the links let you read the originals. If you are an author listed here and want a credit removed, added, or reworded, please open an issue.

## Skill and agent lineage

| In this repo | Source | Author | What was borrowed |
|---|---|---|---|
| `research-talk`, `teaching-lecture`, `slide-review` (architecture) | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | The slide-excellence orchestrator and its review agents are the ancestors of these three skills: the review-before-the-talk discipline, the visual/pedagogy/proofread agent lineup, and the audit taxonomy (overflow, font consistency, box fatigue, spacing). |
| `agents/tikz-reviewer.md` | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | The sub-agent definition this repo's visual TikZ critic descends from. |
| `preregister` | [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) | Pedro H.C. Sant'Anna | The OSF / AsPredicted / AEA RCT three-registry structure, the MUST / SHOULD / MAY clarity flags, and the refusal gate for retrospective preregistration. |
| `bibcheck` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Per-entry `.bib` verification against canonical metadata. |
| `tikz-iterate` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | The iterative TikZ refinement concept, extended here into a full compile / rasterize / review / fix loop. |
| `compile-latex` | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | Diffing the warning and overfull-box set between successive compiles and reporting the deltas. |
| Assertion titles in the slide skills | [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools) | Scott Cunningham | The titles-as-assertions lens from his `beautiful_deck` work. |
| `council` | [`chrisblattman/claudeblattman`](https://github.com/chrisblattman/claudeblattman) | Chris Blattman | N parallel critic subagents plus a separate synthesizer that does not majority-vote. |
| `review-paper` | [`claesbackman/AI-research-feedback`](https://github.com/claesbackman/AI-research-feedback) | Claes Bäckman | The six-agent referee-review fanout and the agent role names. |
| Buried-contribution gate in `review-paper` | [`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation) | aspi6246 | The mechanical check that flags a contribution sentence arriving too late in the abstract. |
| `referee-response` (stress-test lineage) | [`aspi6246/Claude-Code-Presentation`](https://github.com/aspi6246/Claude-Code-Presentation) | aspi6246 | The hostile-editor five-question stress test its response checking descends from. |
| Ghost-deck test and action titles in `research-talk` | [`Gabberflast/academic-pptx-skill`](https://github.com/Gabberflast/academic-pptx-skill) | Gabberflast | Read the titles alone and they should compose into the argument; communication-first slide design. |
| Slide-skill phase structure | [`zarazhangrui/frontend-slides`](https://github.com/zarazhangrui/frontend-slides) | Zara Zhang | The staged intake-to-polish phase architecture the earlier slide skills were scaffolded on, which shaped the current ones. |

Each source repo above ships under MIT, so redistribution under this repo's MIT license is straightforward. An earlier revision of this repo carried many more skills and credits; this table keeps only what the current contents still contain or descend from.

## Vendored assets and tooling

- Inter, by Rasmus Andersson ([rsms/inter](https://github.com/rsms/inter)). SIL Open Font License 1.1; the license ships at `slide-tooling/fonts/inter/LICENSE.txt`.
- MathJax 2.7.9 ([mathjax/MathJax](https://github.com/mathjax/MathJax)). Apache License 2.0; the license ships at `slide-tooling/mathjax/LICENSE`.
- reveal.js, by Hakim El Hattab ([hakimel/reveal.js](https://github.com/hakimel/reveal.js)). MIT. Bundled into the rendered decks by Quarto.
- Quarto ([quarto-dev/quarto-cli](https://github.com/quarto-dev/quarto-cli)). MIT. The render pipeline everything in `slide-tooling/` extends.
