# 2000 Utah Congressional Districts

## Redistricting requirements
In ``Utah``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations (± 1%)
1. be geographically compact
1. not be drawn to intentionally protect or defeat any incumbent
1. efforts will be made to maintain communities of interest and geographical boundaries and to respect existing political subdivisions

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%, considering the enacted plan's low population deviation.

## Data Sources
Data for ``Utah`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for ``Utah`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
Since maintaining communities of interest and geographical boundaries and respecting existing political subdivisions are only encouraged in the requirements, we use the default counties argument in redist_smc().
