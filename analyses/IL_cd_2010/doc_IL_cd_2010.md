# 2010 Illinois Congressional Districts

## Redistricting requirements
In Illinois, districts must, under Ill. Const. Art. IV, § 3:

1. be contiguous
2. have equal populations
3. be geographically compact

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Illinois comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 40,000 districting plans for Illinois across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans. To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of Cook and DuPage counties, which are the counties with populations larger than the target population for districts and thus necessarily split. Within Cook and DuPage counties counties, each municipality is its own pseudocounty as well.
