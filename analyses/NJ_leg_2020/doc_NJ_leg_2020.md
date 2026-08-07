# 2020 New Jersey State House/Senate Districts

## Redistricting requirements
In New Jersey, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in New Jersey must:

1. be contiguous [186]
2. have equal populations [24]
3. be geographically compact [186]
4. preserve county and municipality boundaries as much as possible [186]
5. have House nested in Senate or Congress [187]

Note: New Jersey is a state with simple multi-member legislative districts, where chambers
have identical plans with different numbers of members per district.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for New Jersey comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

Where NJ's total pop came from: https://www.census.gov/library/stories/state-by-state/new-jersey.html 

## Simulation Notes
We sample 15,000 districting plans for New Jersey's lower house across 5 independent runs of the SMC algorithm. We introduce
a total municipality splits constraint of strength 2.4 and increase the number of merge-split proposals per SMC step to 


We sample XX,XXX districting plans for Illinois's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.

New Jersey uses the same district plans for its upper house, do please note that the 
plans simulated for the State House were copy-and-pasted under "State Senate."
