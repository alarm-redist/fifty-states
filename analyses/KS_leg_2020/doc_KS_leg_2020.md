# 2020 Kansas State House/Senate Districts

## Redistricting requirements
In Kansas, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Kansas must:

1. be contiguous [NCSL 184]
1. have equal populations [NCSL 24]
1. be geographically compact [NCSL 184]
1. preserve political subdivision boundaries as much as possible [NCSL 184]
1. preserve communities of interest [NCSL 184]
1. avoid pairing incumbents [NCSL 185]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Kansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Kansas's lower house across 5 independent runs of the SMC algorithm. We add a soft constraint on total county-municipality splits and increase the number of merge-split proposals per SMC step.

We sample 10,000 districting plans for Kansas's upper house across 5 independent runs of the SMC algorithm. We increase the number of merge-split proposals per SMC step.
