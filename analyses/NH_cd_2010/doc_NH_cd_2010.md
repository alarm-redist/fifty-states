# 2010 New Hampshire Congressional Districts

## Redistricting requirements
In New Hampshire, districts must:

1. be contiguous
2. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Hampshire comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Since the enacted plan has no minor civil division (MCD) splits, we merge precincts into MCDs prior to simulating districts.

## Simulation Notes
We sample 5,000 districting plans for New Hampshire in 2 independent runs of the sequential Monte Carlo algorithm.
No special techniques were needed to produce the sample.
