# 1990 Mississippi Congressional Districts

## Redistricting requirements
In Mississippi, we consult [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not dilute minority voting strength
1. not result in a political gerrymander

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We add three hinge Gibbs constraints on Black voting-age population (VAP): a positive constraint with strength 15 targeting a 55% Black VAP district, to encourage a single Black-opportunity district; and negative constraints with strengths -8 and -10 at 40% and 20% Black VAP, to discourage the packing and cracking of Black voters across the remaining districts.

## Data Sources
Data for Mississippi comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
The ROAD data are joined to the 1990 Mississippi Census tract geometry using geographic identifiers. We then apply a county-level logit shift to the Democratic and Republican vote totals so that each county's Democratic two-party vote share matches its 1992 presidential election share in the LEIP baseline data. This adjustment preserves total two-party turnout within each geographic unit while changing the division of votes between the two parties.

## Simulation Notes
We sample 10,500 districting plans for Mississippi across five independent runs of the SMC algorithm.
We reject every sampled plan that does not contain at least one Black-performing district, defined as a district with Black VAP above 30% and Democratic two-party vote share above 50%.
After applying this rejection rule, we retain 1,000 accepted plans from each of the five runs, producing a final ensemble of 5,000 sampled plans.
