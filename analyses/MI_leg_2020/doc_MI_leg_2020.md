# 2020 Michigan State House/Senate Districts

## Redistricting requirements
In Michigan, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 184]
2. have equal populations
3. be not favoring any incumbent [NCSL 185]
4. be not favoring any political party [NCSL 185]
5. be geographically compact
6. generally follow county and municipal boundaries, minimizing splits where feasible [NCSL 184]


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Michigan comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We generated an ensemble of plans for the Kansas State House using the merge-split SMC sampler. We ran 5 independent chains with 2,000 simulated plans per run.
We tuned the MCMC parameters so that each run accepted about 82 merge-split proposals on average.
We constructed pseudo-counties using `pick_county_muni()` with `pop_muni = 3.5 * get_target(map_shd)`.

We generated an ensemble of plans for the Kansas State Senate using the merge-split SMC sampler. We ran 5 independent chains with 2,000 simulated plans per run.
We tuned the MCMC parameters so that each run accepted about 24 merge-split proposals on average.
We constructed pseudo-counties using `pick_county_muni()` with `pop_muni = 3.5 * get_target(map_ssd)`.
We added a soft total municipality-splits constraint during sampling using `add_constr_total_splits()` with `strength = 0.5` and `admin = muni_constr`.
