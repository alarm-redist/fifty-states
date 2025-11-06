# 2020 Colorado State House/Senate Districts

## Redistricting requirements
In Colorado, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous (p. 184)
1. have equal populations (p. 24)
1. be geographically compact (p. 184)
1. preserve county and municipality boundaries as much as possible (p. 184)
1. preserve whole communities of interest (p. 184)
1. maximize the number of politically competitive districts (p. 185)
1. not be drawn protect incumbents (p. 185)


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Colorado comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample XX,XXX districting plans for Colorado's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.
