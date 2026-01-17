# 1990 Maryland Congressional Districts

## Redistricting requirements
In Maryland, we consult [the Legal Standards for Plan Development](https://web.archive.org/web/20041217022537/http://www.senate.mn/departments/scr/redist/Red2000/mdprin.htm).
We impose the following constraints. 
In our simulations, districts should:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not dilute minority voting strengths
1. give due regard to natural boundaries, communities of interest, and existing districts

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Maryland comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
We edited the adjacency graph so that districts cannot traverse the Bay. Specifically, we identified the Bay precincts, removed all of their existing adjacency links, and then reconnected each Bay precinct to a selected same-side neighbor to prevent cross-Bay connections.

## Simulation Notes
We sample 10,000 districting plans for Maryland across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 