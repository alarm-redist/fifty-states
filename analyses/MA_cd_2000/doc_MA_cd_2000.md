# 2000 Massachusetts Congressional Districts

## Redistricting requirements
In Massachusetts, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We use a pseudo-county constraint described below which helps to preserve town and county boundaries.

## Data Sources
Data for Massachusetts comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/)

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Massachusetts across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
Municipality lines are used in Essex County, Middlesex County, Norfolk County, Suffolk County, and Worcester County, which are all counties with populations larger than 100% the target population for a district.
