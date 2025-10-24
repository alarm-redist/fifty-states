# 2020 Delaware State House/Senate Districts

## Redistricting requirements
In Delaware, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Delaware comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Delaware's lower house across 5 independent runs of the SMC algorithm.
To ensure chain convergence for this 41-district simulation, the mh_accept_per_smc mixing parameter was increased by 10.

We sample 10,000 districting plans for Delaware's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
