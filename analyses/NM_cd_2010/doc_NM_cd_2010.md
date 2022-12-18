# 2010 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, according to the [New Mexico Legislative Council Guidelines](https://www.nmlegis.gov/Redistricting/Documents/187014.pdf), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest
6. preserve the core of existing districts


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 New Mexico enacted congressional map comes from [All About Redistricting](https://redistricting.lls.edu/state/new-mexico/?cycle=2010&level=Congress&startdate=2011-12-29).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border under the 2000 plan.

## Simulation Notes
We sample 5,000 districting plans for New Mexico across two independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
