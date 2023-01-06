# 2010 New York Congressional Districts

## Redistricting requirements
In New York, districts must, per [judicial order](https://redistricting.lls.edu/wp-content/uploads/NY-favors-20120319-cong-opinion.pdf):

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions, communities of interest, and cores of existing districts
7. protect incumbents where possible.

When developing the 2010 map, the courts decided to assign zero weight to incumbent protection and minimal weight to core preservation.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 

## Data Sources
Data for New York comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We use a county constraint to preserve district cores, since districts are generally structured around counties.

## Simulation Notes
We sample 60,000 districting plans for New York over two runs of the SMC algorithm and thin the sample down to 5,000 plans.

No special techniques were needed to produce the sample.

