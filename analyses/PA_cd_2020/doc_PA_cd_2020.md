# 2020 Pennsylvania Congressional Districts

## Redistricting requirements
In Pennsylvania, there are few formal districting requirements, but districts must generally:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below.

## Data Sources
Data for Pennsylvania comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Pennsylvania.
To balance county and municipality splits, we create pseudocounties for use in
the county constraint. These are counties, outside of Allegheny County,
Montgomery County, and Philadelphia County. Within Allegheny County, Montgomery
County, and Philadelphia County, each municipality is its own pseudocounty as
well. These counties were chosen since they are necessarily split by
congressional districts.
We also apply an additional Gibbs constraint to further avoid splitting municipalities.
