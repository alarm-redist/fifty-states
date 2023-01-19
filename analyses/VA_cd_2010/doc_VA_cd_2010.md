# 2010 Virginia Congressional Districts

## Redistricting requirements
In Virginia, districts must, under [Commitee Resolution No. 1](https://www.virginiaredistricting.org/2010/data/publications/2011Draw1.pdf) adopted by the Senate and House Committees on Privileges and Elections in 2001:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest, as defined by criteria that "may include, among others, economic factors, social factors, cultural factors, geographic features, governmental jurisdictions and service delivery areas, political beliefs, voting trends, and incumbency considerations"

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint described below which attempts to mimic the norms in Virginia of generally preserving county, city, and township boundaries.

## Data Sources
Data for Virginia comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Virginia across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Fairfax County must be split due to its large population, although within the county, we avoid splitting any municipality.
