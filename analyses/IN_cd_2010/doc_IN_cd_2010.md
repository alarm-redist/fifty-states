# 2010 Indiana Congressional Districts

## Redistricting requirements
In Indiana, districts must:

1. be contiguous
1. have equal populations


### Algorithmic Constraints
We enforce a maximum population deviation of 0.05%.

## Data Sources
Data for Indiana comes from [All About Redistricting](https://redistricting.lls.edu/state/indiana/?cycle=2010&level=Congress&startdate=2011-05-10) and the ALARM Project's [Redistricting Data Files](https://alarm-redist.org/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Indiana via two independent runs of 2,500 each.
No special techniques were needed to produce the sample.
