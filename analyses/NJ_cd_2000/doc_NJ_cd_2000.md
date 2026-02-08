# 2000 New Jersey Congressional Districts

## Redistricting requirements
In ``New Jersey``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be geographically contiguous
2. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint described below which attempts to mimic the norms in New Jersey of generally preserving county and municipal boundaries.

## Data Sources
Data for ``New Jersey`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
We used a helper function to exclude simulated plans containing discontiguous districts.

## Simulation Notes
We sample 30,000 districting plans for ``New Jersey`` across 5 independent runs of the SMC algorithm.
After the simulation, we filtered out plans with discontiguous districts and then thinned the remaining sample to 5,000 plans.
To balance county and municipality splits, we create pseudo-counties for use in the county constraint. 
