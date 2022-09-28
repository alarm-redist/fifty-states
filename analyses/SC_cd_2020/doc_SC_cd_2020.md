# 2020 South Carolina Congressional Districts

## Redistricting requirements
South Carolina has no state constitution or statute for redistricting. However, the state legislature committees do provide _guidelines_ for redistricting.  ([House link](https://redistricting.schouse.gov/docs/2021%20Redistricting%20Guidelines.pdf), [Senate link](https://redistricting.scsenate.gov/docs/Senate%20Redistricting%20Guidelines%20Adopted%209-17-21.DOCX)), According to these guidelines, districts should:

1. be contiguous (including contiguity by water)
1. have equal populations as is practicable
1. comply with VRA Section 2
1. be geographically compact
1. preserve boundaries of counties, municipalities, voting tabulation districts, cores of previous districts, and other communities of interests as much as possible
1. preserve separation of incumbents as much as possible

The House guidelines state that if the criteria come into conflict, federal law (including the VRA) and population parity should be prioritized over others.

### Algorithmic Constraints

We do not adhere to all criteria in the guidelines. We include the following constraints:

1. We enforce a maximum population deviation of 0.5%.
1. We impose a hinge constraint on the Black Voting Age Population so that it encourages district BVAP of above 40%. Districts with BVAP of 30% or less are not penalized as much. Together, these aim to ensure that Black voters can elect their candidate of choice in districts with high BVAP.
1. We impose a municipality-split constraint to lower the number of municipality splits.

## Data Sources
Data for South Carolina comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). 
The state's new district lines come from [All About Redistricting](https://redistricting.lls.edu/state/south-carolina/?cycle=2020&level=Congress).

## Pre-processing Notes
We take municipalities and concatenate them with counties in order to apply a constraint to avoid too many municipality splits.


## Simulation Notes
We sample 6,000 districting plans across two independent runs of the SMC algorithm. We set the population tempering at 0.05 to avoid bottlenecks. We then remove all plans that do not contain any district that has both a BVAP of over 30% and an average voteshare that is more Democratic than Republican. This remove occurs after verifying that such plans comprise less than 1% of the 6,000 plans. We then thin the sample down to exactly 5,000 plans. 

