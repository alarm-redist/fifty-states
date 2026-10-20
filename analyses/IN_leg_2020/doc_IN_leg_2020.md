# 2020 Indiana State House/Senate Districts

## Redistricting requirements
In Indiana, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. Be contiguous [NCSL, 184]
2. Equal population [NCSL, 23]


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Indiana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Indiana's lower house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for Indiana's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
