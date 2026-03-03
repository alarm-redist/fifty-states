# 2020 Kansas State House/Senate Districts

## Redistricting requirements
In Kansas, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 184]
2. have equal populations
3. be not favoring any incumbent [NCSL 185]
4. be geographically compact [NCSL 184]
5. generally follow county and municipal boundaries, minimizing splits where feasible [NCSL 184]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Kansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 100,0000 districting plans for Kansas's lower house across 5 independent runs of the SMC algorithm.
To ensure chain convergence for this 125-district simulation, we tune the MCMC parameters such that each run of merge-split should accept 92 changes, on average.

We sample 100,000 districting plans for Kansas's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
