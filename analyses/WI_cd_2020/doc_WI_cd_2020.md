# 2020 Wisconsin Congressional Districts

## Redistricting requirements
In Wisconsin, districts must:

1. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a pseudo-county constraint as described below.

## Data Sources
Data for Wisconsin comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Wisconsin across 2 independent runs of the SMC algorithm.
We use a pseudo-county constraint to limit the county and municipality splits. Municipality lines are used in Milwaukee County. 
These are larger than the target population for a district. 
No special techniques were needed to produce the sample.
