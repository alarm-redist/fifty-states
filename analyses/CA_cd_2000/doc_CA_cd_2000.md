# 2000 California Congressional Districts

## Redistricting requirements
In ``California``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. preserve city, county, neighborhood, and community of interest boundaries as much as possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to limit the county and municipality splits. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for ``California`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 6,000 districting plans for ``California`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We also used new algorithmic mergesplit parameters to improve mixing.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
