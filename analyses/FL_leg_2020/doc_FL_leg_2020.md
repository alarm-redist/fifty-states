# 2020 Florida State House/Senate Districts

## Redistricting requirements
In Florida, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Florida must:

1. be contiguous [NCSL 184]
2. have equal populations [NCSL 24]
3. be geographically compact [NCSL 184]
4. preserve county and municipality boundaries as much as possible [NCSL 184]
5. be not favoring any incumbent [NCSL 185]
6. be not favoring any political party [NCSL 185]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Florida comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Florida's lower house across 5 independent runs of the SMC algorithm.
We introduce mild population tempering (pop_temper = 0.04), impose a county-split constraint, and increase the number of merge-split proposals per SMC step (270).

We sample 10,000 districting plans for Florida's upper house across 5 independent runs of the SMC algorithm.
We introduce mild population tempering (pop_temper = 0.03), impose a county-split constraint, and increase the number of merge-split proposals per SMC step (104).
