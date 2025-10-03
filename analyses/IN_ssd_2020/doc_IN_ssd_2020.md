# 2020 Indiana State Senate (SSD)

## Redistricting requirements
In Indiana, consistent with the baseline criteria used in this project, districts must:
1. be contiguous;
1. have equal populations (we target a ±5% tolerance at the plan level);
1. be geographically compact; and
1. preserve county and municipality boundaries where practicable.

These reflect the core criteria referenced in the project documentation template; we follow the same baseline across states unless special constraints are required. 

### Algorithmic Constraints
We enforce a **maximum population deviation of 5.0%** at the plan level (max |population deviation| across districts in a plan ≤ 0.05 target). No additional compactness or split penalties were imposed beyond the default SMC compactness nudge.

## Data Sources
- Geography: 2020 TIGER/Line Voting Tabulation District (VTD) geometry and county boundaries (U.S. Census Bureau).
- Enacted plan: 2020-cycle Indiana state senate plan, incorporated as a reference in the `redist_plans` object.
- All files produced by this analysis are written to `data-out/IN_2020/…` per project conventions (no `data-raw/` or `data-out/` data are committed to GitHub). 

## Pre-processing Notes
No manual pre-processing was necessary. The analysis followed the standard pipeline:
- `01_prep` to ingest and harmonize inputs,
- `02_setup` to build `IN_ssd_2020_map.rds` with a ±5% population tolerance, and
- `03_sim` to run SMC and compute diagnostics.

## Simulation Notes
We sampled **30,000** state senate plans for Indiana using `redist_smc` across **5 independent chains × 6,000 plans** each (no thinning).

**Sampler configuration (baseline):**
- Sampling space: `linking_edge`;
- County handling: counties only (no additional municipality-split penalties);
- SMC merge–split every step; `mh_accept_per_smc = 35`;
- `pop_temper = 0.02`;
- `seq_alpha = 1` (default tempering schedule used for this run).

## Diagnostics (summary)

- Convergence and mixing are excellent: **max R-hat = 1.0016 (< 1.05)**; effective sample sizes (bulk/tail) ≈ **24k–27k** across key plan-level metrics.
- Plan weights are unimodal with no extreme concentration.
- Population deviation is tightly concentrated near the ±5% target; only **2 / 30,000** plans slightly exceed 5%. A strict ≤5% subset can be obtained by filtering those plans without re-running the sampler.
- Validation artifacts are written to `data-out/IN_2020/diagnostics/`: `IN_validation.png`, `rhat.png` (with `rhat_table.csv`), `plan_dev_hist.png`, and `weights_hist.png`. Per the contribution guide, these plots are attached in the PR and not committed to Git.



