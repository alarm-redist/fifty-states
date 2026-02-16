# 2020 Idaho State House/Senate Districts

## Redistricting requirements
In Idaho, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 184]
2. have equal populations [NCSL 24]
3. be geographically compact [NCSL 184]
4. preserve county and municipality boundaries as much as possible
5. be not favoring any incumbent [NCSL 185]
6. be not favoring any political party [NCSL 185]
7. preserve political subdivisions  [NCSL 184]
8. preserve communities of interest  [NCSL 184]

The districts for the General Assembly and the Senate are identical, so we only simulate districts once with the `03_sim_ID_shd_2020.R` script.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Idaho comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Idaho's lower house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
