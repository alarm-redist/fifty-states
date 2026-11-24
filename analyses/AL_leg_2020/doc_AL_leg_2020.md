# 2020 Alabama State House/Senate Districts

## Redistricting requirements
In Alabama, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Alabama must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions
5. preserve communities of interest
6. avoid pairing incumbents

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Alabama comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 15,000 districting plans for Alabama's lower house across 5 independent 
runs of the SMC algorithm. We introduce a total county splits constraint of strength 1.3 
and increase the number of merge-split proposals per SMC step to 347 total. The ncores
argument in redist_smc() was set to 0.

We sample 25,000 districting plans for Alabama's upper house across 5 independent 
runs of the SMC algorithm. We introduce a total county splits constraint of strength 2.4 
and increase the number of merge-split proposals per SMC step to 47 total.

