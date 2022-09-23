# 2020 New York Congressional Districts

## Redistricting requirements
[In New York, districts must](https://www.nysenate.gov/sites/default/files/ckeditor/Oct-21/ny_state_constitution_2021.pdf):

1. be contiguous (III.4(c)(3))
1. have equal populations (III.4(c)(2))
1. be geographically compact (III.4(c)(4))
1. preserve cores of existing districts, political subdivisions, and communities of interest (III.4(c)(5))
1. not be drawn to discourage competition (III.4(c)(5))
1. not be drawn to favor or disfavor incumbents (III.4(c)(5))
1. not be drawn to favor or disfavor parties (III.4(c)(5))
1. not abridge minority group vote power (III.4(c)(1))


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We preserve cores of the many geographic regions by using a pseudo county constraint.

## Data Sources
Data for New York comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Islands are connected to their nearest point on land.

## Simulation Notes
We sample 40,000 districting plans for New York across 2 independent runs of the SMC algorithm.
We then thin the sample to down to 5,000 plans.
We apply a pseudo-county algorithmic constraint, which encourages keeping together counties in less populated counties and municipalities in the largest counties.
The boundary here is set at the size of one district, so Bronx County, Erie County, Kings County, Nassau County, New York County, Queens County, Suffolk County, and Westchester County use municipalities over counties.
The core constraint here is unclear, as the number of districts have changed, and because it is crossed with preserving other communities.
As such, the pseudo-county constraint should weakly preserve the cores, as the prior map generally held together counties and municipalities.
A small population tempering value was used to avoid losing diversity at the final step based on initial runs.
