# 2010 Kentucky Congressional Districts

## Redistricting requirements
In Kentucky, under the [Criteria and Standards for Congressional Redistricting](https://web.archive.org/web/20220101204327/http://ncsl.org/Portals/1/Documents/Redistricting/Redistricting_2010.pdf) adopted by Interim Joint Committee on State Government’s Redistricting Subcommittee in 1991, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest as much as possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint described below which attempts to mimic the norms in Kentucky of generally preserving county, city, and township boundaries.

## Data Sources
Data for Kentucky comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 8,000 districting plans for Kentucky across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
We use a pseudo-county constraint to limit the county and municipality (i.e. city and township) splits. Municipality lines are used in Jefferson County, which has a population larger than the target population for a congressional district.
