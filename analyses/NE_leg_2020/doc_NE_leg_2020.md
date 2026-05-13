# 2020 Nebraska State House/Senate Districts

## Redistricting requirements
In Nebraska, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 184] 
2. have equal populations [NCSL 24] 
3. be geographically compacts [NCSL 184] 
4. preserve county and municipality boundaries as much as possible [NCSL 184] 
5. preserve cores of prior districts  [NCSL 185]
6. be not favoring any incumbent [NCSL 185]
7. be not favoring any political party [NCSL 185]

Nebraska has a unicameral legislature, and thus only one set of state legislative districts is drawn. Accordingly, we simulate a single legislative plan using the 03_sim_NE_ssd.R script.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Nebraska comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan. Precincts in counties which are split by existing district boundaries are merged only within their county.

## Simulation Notes
We sample 10,000 districting plans for Nebraska's unicameral legislature across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
