# 2000 West Virginia Congressional Districts

## Redistricting requirements
In ``West Virginia``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts shall:

1. be made of contiguous counties
1. have equal populations
1. be geographically compact

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We also merge VTDs into counties and run the simulation at the county level.

## Data Sources
Data for ``West Virginia`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for ``West Virginia`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
Although we analyze ``West Virginia`` at the county level, Barbour and Braxton counties are split by the enacted plan. To assign a single district to each county, we identify the district number that appears most often among its VTDs in the enacted plan and assign that district code to the county.
