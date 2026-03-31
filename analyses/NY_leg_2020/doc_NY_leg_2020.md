# 2020 New York State House/Senate Districts

## Redistricting requirements
In New York, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL 186]
2. have equal populations [NCSL 24]
3. be geographically compact [NCSL 186]
4. preserve county and municipality boundaries as much as possible [NCSL 186]
5. preserve communities of interest [NCSL 186]
6. preserve cores of prior districts [NCSL 187]
7. be not favoring any incumbent [NCSL 187]
8. be not favoring any political party [NCSL 187]
9. maximize the number of politically competitive districts [NCSL 187]


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for New York comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Islands are connected to their nearest point on land. 
(To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan. Precincts in counties which are split by existing district boundaries are merged only within their county.)

## Simulation Notes
We sample 10,000 districting plans for New York's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for New York's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.
