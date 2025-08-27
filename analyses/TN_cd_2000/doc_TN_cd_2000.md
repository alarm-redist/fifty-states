# 2000 Tennessee Congressional Districts

## Redistricting requirements
In ``Tennessee``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to help preserve county and municipality boundaries, as described below.

## Data Sources
Data for ``Tennessee`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans across five independent runs of the SMC algorithm, and then thin them to 5000 plans.
To reflect Tennessee's traditional norm of minimizing county splits while reducing unnecessary fragmentation of major cities, we create pseudo-counties for use in the county constraint.