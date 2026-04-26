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
We sample 10,000 districting plans for Michigan's lower house across 5 independent runs of the SMC algorithm.
To ensure chain convergence for this 110-district simulation, we tune the MCMC parameters such that each run of merge-split should accept 52 changes, on average.

We sample 10,000 districting plans for Michigan's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
