# 2020 South Carolina State House/Senate Districts

## Redistricting requirements
In South Carolina, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [NCSL, 186]
2. have equal populations [NCSL, 23]
3. be geographically compact [NCSL, 186]
4. preserve political subdivisions and communities of interests [NCSL, 186]
5. preserve cores of prior districts [NCSL, 187]
6. avoid pairing incumbents [NCSL, 187]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for South Carolina comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 17,500 districting plans for South Carolina's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for South Carolina's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.
