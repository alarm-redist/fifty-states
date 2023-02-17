# 2010 Georgia Congressional Districts

## Redistricting requirements
In Georgia, under the 2011-12 Guidelines for the House Legislative and Congressional Reapportionment Committee: districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions and communities of interest 
5. avoid pairing incumbents 

[Guidelines for the House Legislative and Congressional Reapportionment Committee](https://www.dropbox.com/s/i8zqyivtr8iozs8/GeorgiaSenateCommitteeGuidelines2011-12.pdf)

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Georgia comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 60,000 districting plans for Georgia across two independent runs of the SMC algorithm. We then thin the sample to exactly 5,000 plans.

We impose a hinge constraint on the Black Voting Age Population so that it encourages districts with BVAP above 43%, but districts with BVAP of 34% or less are not penalized as much. In addition, we impose an inverse hinge constraint on the Black Voting Age Population to penalize districts with BVAP above 61% to prevent packing. 
