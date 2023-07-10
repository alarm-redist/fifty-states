# 2010 Massachusetts Congressional Districts

## Redistricting requirements
In Massachusetts, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.05%. 
We use a pseudo-county constraint to help preserve county and municipality boundaries.
These counties are Dukes, Middlesex, and Worcester--these three counties have populations larger than 60% of the target population for districts. To preserve municipality splits, each municipality is its own pseudocounty.

## Data Sources
Data for Massachusetts comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 7,000 districting plans for Massachusetts over two runs.
We then thinned the number of samples to 5,000.
No special techniques were needed to produce the sample.
