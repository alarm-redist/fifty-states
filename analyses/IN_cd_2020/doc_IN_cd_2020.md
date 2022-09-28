# 2020 Indiana Congressional Districts

## Redistricting requirements
In Indiana, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Indiana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Indiana across 2 independent runs of the SMC algorithm.
We use counties, despite the lack of requirements, as the enacted does generally follow county lines.
No special techniques were needed to produce the sample.
