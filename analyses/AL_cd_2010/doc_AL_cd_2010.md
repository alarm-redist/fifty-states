# 2010 Alabama Congressional Districts

## Redistricting requirements
In Alabama, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Alabama comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 Alabama enacted congressional map comes from [All About Redistricting](https://redistricting.lls.edu/state/alabama/?cycle=2020&level=Congress&startdate=2021-11-04).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Alabama across two independent runs of the SMC algorithm. We then thin the sample to down to 5,000 plans.
