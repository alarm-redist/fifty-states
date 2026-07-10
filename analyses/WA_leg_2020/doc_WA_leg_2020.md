# 2020 Washington State House/Senate Districts

## Redistricting requirements
In Washington, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Washington must:

1. be contiguous [186]
2. have equal populations [24]
3. be geographically compact [186]
4. preserve county and municipality boundaries as much as possible [186]
5. preserve communities of interest [186]
6. not favor party [187]
7. be competitive [187]
8. have the House nested in Senate or Congress [187]

Note: Washington is a state with simple multi-member legislative districts, where chambers have identical plans with different numbers of members per district.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Washington comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 25,000 district plans for Washington's lower house across 5 independent runs of the SMC algorithm. We 
introduce a Polsby-Popper constraint of strength 3 and increase the number of merge-split proposals per SMC step 
to 27 total. The ncores argument in redist_smc() was set to 0.

Washington uses the same district plans for its upper house, so please note that the
plans simulated for the State House were copy-and-pasted under "State Senate."
