# 2010 Maryland Congressional Districts

## Redistricting requirements
In Maryland, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. not consider incumbent or partisan information

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Maryland comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Maryland across 2 independent runs of the SMC algorithm. No special techniques were needed to produce the sample.
