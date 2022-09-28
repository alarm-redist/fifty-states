# 2020 Connecticut Congressional Districts

## Redistricting requirements
In Connecticut, there are no state law requirements for congressional districts

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%, which is in line with the low population deviation observed in the 2000 and 2010 congressional district plans.
We use a pseudo-county constraint described below which attempts to mimic the norms in Connecticut of generally preserving county and municipal boundaries.

## Data Sources
Data for Connecticut comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for Connecticut's 2020 congressional district map comes from [Redistricting Data Hub](https://redistrictingdatahub.org/dataset/2022-connecticut-congressional-districts-approved-plan/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Connecticut across two independent runs of the SMC algorithm.
We use a pseudo-county constraint to limit the county and municipality splits.
Municipality lines are used in Fairfield County, Hartford County, and New Haven County, which are all counties with populations larger than 40% the target population for a district.
No special techniques were needed to produce the sample.
