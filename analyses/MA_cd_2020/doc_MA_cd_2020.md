# 2020 Massachusetts Congressional Districts

## Redistricting requirements
In Massachusetts, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We use the basic algorithmic county constraint applied to pseudo counties, as Congressional plans in MA do seem to follow county and municipal boundaries, despite no legal constraint. Pseudo counties are constructed by following municipal boundaries in counties larger than a district and county lines.

## Data Sources
Data for Massachusetts comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Massachusetts across 2 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
