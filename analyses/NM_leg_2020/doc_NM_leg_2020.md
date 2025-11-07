# 2020 New Mexico State House/Senate Districts

## Redistricting requirements
In New Mexico, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 186]
2. have equal populations
3. be geographically compact [NCSL 186]
4. preserve county and municipality boundaries as much as possible [NCSL 186]
5. preserve cores of prior districts [NCSL 187]
6. avoid pairing incumbents [NCSL 187]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. We perform cores-based simulations, thereby preserving cores of prior districts.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border under the 2010 plan.

## Simulation Notes
We sample 10,000 districting plans for New Mexico's lower house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for New Mexico's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
