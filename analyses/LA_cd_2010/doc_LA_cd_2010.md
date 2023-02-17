# 2010 Louisiana Congressional Districts

## Redistricting requirements
In Louisiana, according to [La. Const. art. III, § 6](https://senate.la.gov/Documents/Constitution/Article3.htm#%C2%A76%20Legislative%20Reapportionment;%20Reapportionment%20by%20Supreme%20Court;%20Procedure), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve parish and municipality boundaries as much as possible
5. preserve the cores of traditional district alignments


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a hinge Gibbs constraint targeting the same number of majority-minority districts as the enacted plan. We also apply a hinge Gibbs constraint to discourage packing of minority voters.

## Data Sources
Data for Louisiana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 enacted plan comes from [State of Louisiana Redistricting](https://redist.legis.la.gov/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2000 plan.

## Simulation Notes
We sample 16,000 districting plans for Louisiana across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans. To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.
