# 2000 Maryland Congressional Districts

## Redistricting requirements
In ``Maryland``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts should:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not dilute minority voting strengths
1. give due regard to natural boundaries

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for ``Maryland`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
We edited the adjacency graph so districts cannot traverse the Bay. Bay units were isolated in the adjacency while all polygons were preserved on disk. For the simulation, we derived a land-only map to ensure ``redist_map()`` saw a contiguous graph. One isolated island precinct was manually connected to its nearest neighbor.

## Simulation Notes
We sample 10,000 districting plans for ``Maryland`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
No special techniques were needed to produce the sample.
