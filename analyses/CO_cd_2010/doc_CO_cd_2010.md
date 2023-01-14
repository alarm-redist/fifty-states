# 2010 Colorado Congressional Districts

## Redistricting requirements
In Colorado, districts must, under Section 47 of the [2016 Colorado Revised Statutes](https://leg.colorado.gov/sites/default/files/images/olls/crs2016-title-00.pdf):

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. preserve whole communities of interest

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Colorado comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Colorado across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.
