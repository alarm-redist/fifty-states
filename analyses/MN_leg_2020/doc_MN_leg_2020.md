# 2020 Minnesota State House/Senate Districts

## Redistricting requirements
In Minnesota, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Minnesota must:

1. be contiguous [NCSL 184]
1. have equal populations [NCSL 24]
1. preserve county and municipality boundaries as much as possible [NCSL 184]
1. preserve communities of interest [NCSL 184]
1. avoid incumbent pairings [NCSL 185]
1. not favor incumbents [NCSL 185]
1. have House districts nested inside Senate districts [NCSL 185]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Minnesota comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 37,500 districting plans for Minnesota's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
We impose a total municipality splits constraint, and increase the number of merge-split proposals per SMC step (153).

We use the top-down nested procedure to sample Minnesota's lower house districts, with 50 inner-simulations for each of the 37,500 upper house districts.
11,783 districting plans remaining in the surviving sample.
We then thinned the number of samples to 10,000.
We impose a total municipality splits constraint on the inner-simulations.
