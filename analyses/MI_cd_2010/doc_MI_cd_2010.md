# 2010 Michigan Congressional Districts

## Redistricting requirements
In Michigan, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. Cannot favor/disfavor incumbents


### Algorithmic Constraints
We enforce a maximum population deviation of 0.05%. We applied a constraint to limit county and municipality splits (see '02_setup_MI_cd_2010.R' file).

## Data Sources
Data for Michigan comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 8,000 districting plans for Michigan across four independent runs of the SMC algorithm and then thinned our results to 5,000 simulations.
No special techniques were needed to produce the sample.
