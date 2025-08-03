# 2000 Illinois Congressional Districts

## Redistricting requirements
In ``Illinois``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), there are no state law requirements for congressional districts.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for ``Illinoi`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary. We use a pseudo-county constraint to help preserve county and municipality boundaries, as described below.

## Simulation Notes
We sample 60,000 districting plans for ``Illinois`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
To balance county and municipality splits, we create pseudo-counties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. These are counties, outside of Cook and DuPage counties, which are the counties with populations larger than the target population for districts and thus necessarily split. Within Cook and DuPage counties counties, each municipality is its own pseudocounty as well.