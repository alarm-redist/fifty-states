# 2020 Alaska State House/Senate Districts

## Redistricting requirements
In Alaska, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Alaska must:

1. be contiguous [NCSL 184]
1. have equal populations [NCSL 24]
1. preserve county and municipality boundaries as much as possible [NCSL 184]
1. be compact [NCSL 184]
1. preserve communities of interest [NCSL 184]
1. have House districts nested inside Senate districts [NCSL 185]


### Algorithmic Constraints
We enforce a maximum population deviation of 2.5% for State Senate districts and 5.0% for State House districts..

## Data Sources
Data for Alaska comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To make the adjacency graph contiguous, a few remote island precincts are connected with neighboring islands and the nearest precincts on the mainland.

## Simulation Notes
We sample 100,000 districting plans for Alaska's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000,
We impose a total county splits constraint and a Polsby-Popper compactness constraint on the inner-simulations.

We use the top-down nested procedure to sample Minnesota's lower house districts, with 50 inner-simulations for each of the 100,000 upper house districts.
16,516 districting plans remain in the surviving sample.
We then thinned the number of samples to 10,000.
We impose a total municipality splits constraint and a Polsby-Popper compactness constraint on the inner-simulations.
