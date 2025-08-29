# 2000 Ohio Congressional Districts

## Redistricting requirements
In ``Ohio``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a hinge Gibbs constraint targeting the same number of majority-minority districts as the enacted plan.

## Data Sources
Data for ``Ohio`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions are necessary.

## Simulation Notes
We sample 5,000 districting plans for ``Ohio`` across 10 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
