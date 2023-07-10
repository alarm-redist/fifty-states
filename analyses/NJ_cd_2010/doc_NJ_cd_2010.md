# 2010 New Jersey Congressional Districts

## Redistricting requirements
In New Jersey, districts must:

1. be contiguous
2. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We use a pseudo-county constraint described below which attempts to mimic the norms in New Jersey of generally preserving county and municipal boundaries.

## Data Sources
Data for New Jersey comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for New Jersey across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans. To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of Bergen, Burlington, Camden, Essex, Hudson, Mercer, Middlesex, Monmouth, Morris, Ocean, Passaic, and Union County, which are the counties larger than 50% of the target district population. WithinBergen, Burlington, Camden, Essex, Hudson, Mercer, Middlesex, Monmouth, Morris, Ocean, Passaic, and Union County, which are the counties larger than 50% of the target district population, each municipality is its own pseudocounty as well.
