# 2010 Wisconsin Congressional Districts

## Redistricting requirements
In Wisconsin, districts must:

1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5% and add a pseudo-county constraint to reduce county and municipality splits. Since Milwaukee County has a greater population than the target district population, we split Milwaukee County by municipality lines.

## Data Sources
Data for Wisconsin comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Wisconsin over 2 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
