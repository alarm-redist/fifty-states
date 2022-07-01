# 2010 South Carolina Congressional Districts

## Redistricting requirements
In South Carolina, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. pass pre-clearance from the DOJ

https://redistricting.scsenate.gov/Documents/RedistrictingGuidelinesAdopted041311.pdf
https://redistricting.schouse.gov/archives/2011/6334-1500-2011-Redistricting-Guidelines-(A0404871).pdf

### Interpretation of requirements
We do not adhere to all criteria in the guidelines. We include the following constraints:

1. We enforce a maximum population deviation of 0.5%.
2. We impose a hinge constraint on the Black Voting Age Population so that it encourages district BVAP between 40 percent and 60 percent, but districts with BVAP of 30% or less are not penalized as much.
3. We impose a municipality-split constraint to lower the number of municipality splits.

## Data Sources
Data for South Carolina comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). <- not sure what I should put for 2010 because I couldn't find it in the ALARM website :(

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 6,000 districting plans for South Carolina.
No special techniques were needed to produce the sample.
