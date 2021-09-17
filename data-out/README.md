# `data-out` README

The `data-out` folder contains draft, unvalidated redistricting simulations and supporting files.
It is not tracked by git.  Only validated analyses should be saved to the repository.

- The `maps/` subfolder contains `redist_map` objects, stored as RDS files,
  which contain geographic, adjacency, and demographic information on analyzed
  states.
- The `plans/` subfolder contains `redist_plans` objects, stored as RDS files,
  which contain the sampled district assignments and populations.
- The `summaries/` subfolder contains CSV files containing summary information
  on all of the sampled plans.

