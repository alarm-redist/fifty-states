# 2000 Maine Congressional Districts

## Redistricting requirements
In Maine, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Maine comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Maine, across 10 independent runs of the SMC algorithm.
We use the standard county constraint.
We weaken the compactness parameter to 0.8 due to the relatively small state size and total number of tracts to encourage more diversity in the sample.
