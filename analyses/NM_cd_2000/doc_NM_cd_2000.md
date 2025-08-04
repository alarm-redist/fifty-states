# 2000 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible

The house of representatives is composed of seventy members to be elected from districts that are contiguous and that are as compact as is practical and possible.
The senate is composed of forty-two members to be elected from districts that are contiguous and that are as compact as is practical and possible.
nsims = 2000, runs = 10 (20000 plans total)
pop_temper=0.05

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2000 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20000 redistricting plans for New Mexico across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5000.
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
