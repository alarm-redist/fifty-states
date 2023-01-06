# 2010 Connecticut Congressional Districts

## Redistricting requirements
In Connecticut, there are no state law requirements for congressional districts. 
The Supreme Court of Connecticut set out the [following guidelines](https://www.cga.ct.gov/red2011/documents/special_master/Merged%20Draft%20Report%20with%20Exhibits.pdf) in the order appointing a special master.
1. Districts shall be as equal in population as is practicable. 
1. Districts shall be made of contiguous territory. 
1. Districts shall comply with 42 U.S.C. § 1973(b) and with other applicable provisions of the Voting Rights Act and federal law. 
1. Districts shall not be substantially less compact than the existing congressional districts.
1. Districts shall not substantially violate town lines more than the existing congressional districts. 
1. Districts shall not consider either the residency of incumbents or potential candidates or other political data, such as party registration statistics or election returns.

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%, which is in line with the low population deviation observed in the 2000 congressional district plan.
We use a pseudo-county constraint described below which attempts to mimic the norms in Connecticut of generally preserving county and municipal boundaries.

## Data Sources
Data for Connecticut comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Connecticut across two independent runs of the SMC algorithm.
We use a pseudo-county constraint to limit county and municipality splits.
Municipality lines are used in Fairfield County, Hartford County, and New Haven County, which are all counties with populations larger than 40% the target population for a district.
No special techniques were needed to produce the sample.
