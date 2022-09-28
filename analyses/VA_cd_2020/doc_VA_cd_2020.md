# 2020 Virginia Congressional Districts

## Redistricting requirements
In Virginia, districts must, under Va. Code Ann. § 24.2-304.04:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. "not, when considered on a statewide basis, unduly favor or disfavor any political party"

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Virginia comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Virginia across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Fairfax County must be split due to its large population, although within the county, we avoid splitting any municipality.
