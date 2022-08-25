# 2020 Hawaii Congressional Districts

## Redistricting requirements
In Hawaii, under [HRS Title 1 S25](https://www.capitol.hawaii.gov/hrscurrent/Vol01_Ch0001-0042F/HRS0025/HRS_0025-0002.htm), districts must:

1. be contiguous unless crossing islands (25-2 (b) (2))
1. be geographically compact (25-2(b)(3))
1. preserve tract boundaries as much as possible (25-2(b)(4))
1. not unduly favor any people or party (25-2(b)(6))
1. avoid mixing substantially different socioeconomic regions (25-2(b)(6))


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We use Census tracts are in accordance with (25-2(b)(4)).
We use municipalities to attempt to follow (25-2(b)(6)) in absence of regional knowledge.

## Data Sources
Data for Hawaii comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Islands are connecting in the adjacency graph, but this is not used for simulation purposes.

## Simulation Notes
We sample 5,000 districting plans for Hawaii across 2 independent runs of the SMC algorithm.
We use partial SMC to draw one district in the contiguous portion of Honolulu and assign the remainder to district 2.
We use municipalities (or the county name if a tract is not assigned to a municipality) for the algorithmic constraint.
