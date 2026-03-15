# 1990 Louisiana Congressional Districts

## Redistricting requirements
In Louisiana, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add group hinge constraints to encourage at least one majority-minority district.

## Data Sources
Data for Louisiana comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 100,000 districting plans for Louisiana across 5 independent runs of the SMC algorithm. We remove all plans that do not contain at least one district with BVAP above 30% and Democratic vote share above 45%. We then thin the filtered sample to 5,000 plans.
