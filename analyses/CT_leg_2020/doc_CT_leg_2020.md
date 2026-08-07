# 2020 Connecticut State House/Senate Districts

## Redistricting requirements
In Connecticut, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Connecticut comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Due to Connecticut's large number of state house districts, we used Census block data for VTDs that were split between enacted districts. 

## Simulation Notes
We sample 60,000 districting plans for Connecticut's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for Connecticut's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
