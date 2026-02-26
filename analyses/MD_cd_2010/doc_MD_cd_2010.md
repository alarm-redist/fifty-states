# 2010 Maryland Congressional Districts

## Redistricting requirements
In Maryland, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. not consider incumbent or partisan information

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Maryland comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We edited the adjacency graph so that districts cannot traverse the Bay. All polygons were preserved, but Bay units were isolated within the adjacency. Specifically, we identified the Bay precincts, removed all of their existing adjacency links, and then reconnected each Bay precinct to a selected same-side neighbor to prevent cross-Bay connections. In other words, Bay precincts on the east side were linked to one chosen east-side neighbor, and those on the west side were linked to one chosen west-side neighbor. One isolated island precinct was manually connected to its nearest neighbor.

## Simulation Notes
We sample 5,000 districting plans for Maryland across 2 independent runs of the SMC algorithm. No special techniques were needed to produce the sample.
