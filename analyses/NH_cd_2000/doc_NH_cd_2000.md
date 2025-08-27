# 2000 New Hampshire Congressional Districts

## Redistricting requirements
In ``New Hampshire``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for ``New Hampshire`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Since the enacted plan has no minor civil division (MCD) splits, we merge precincts into MCDs prior to simulating districts.

## Simulation Notes
We sample 20,000 districting plans for ``New Hampshire`` across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
With only ten counties and a maximum population deviation of 0.5%, there is no valid way to split the state into two districts without violating the constraints. Therefore, we limit splits at the County Municipality level instead of the County level, which allows for more flexibility and feasible districting options.
