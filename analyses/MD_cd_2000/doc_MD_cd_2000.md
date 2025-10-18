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
We edited the adjacency graph so that districts cannot traverse the Bay. All polygons were preserved, but Bay units were isolated within the adjacency. Specifically, we identified the Bay precincts, removed all of their existing adjacency links, and then reconnected each Bay precinct to a selected same-side neighbor to prevent cross-Bay connections. In other words, Bay precincts on the east side were linked to one chosen east-side neighbor, and those on the west side were linked to one chosen west-side neighbor. One isolated island precinct was manually connected to its nearest neighbor. Additionally, we used a helper function to exclude simulated plans containing discontiguous districts.

## Simulation Notes
We sample 450,000 districting plans for ``Maryland`` across 10 independent runs of the SMC algorithm.
After the simulation, we filtered out plans with discontiguous districts and then thinned the remaining sample to 5,000 plans.
