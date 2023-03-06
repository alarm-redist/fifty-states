# 2010 Ohio Congressional Districts

## Redistricting requirements
In Ohio, districts must, under [HB 319](https://legiscan.com/OH/text/HB319/2011):

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to help preserve county and municipality boundaries.

## Data Sources
Data for Ohio comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 13,000 districting plans for Ohio  over two runs. We then thinned the number of samples to 5,000. 
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Cuyahoga County, Franklin County, and Hamilton Counrt must be split due to their large population, although within the county, we avoid splitting any municipality.
