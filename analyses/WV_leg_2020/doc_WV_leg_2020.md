# 2020 West Virginia State House/Senate Districts

## Redistricting requirements
In West Virginia, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in West Virginia must:

1. be contiguous [NCSL 186]
2. have equal populations [NCSL 24]
3. be geographically compact [NCSL 186]
4. preserve political subdivision boundaries as much as possible [NCSL 186]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for West Virginia comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We remove geographic units without enacted state House or Senate district assignments. The automatically generated adjacency graph contains disconnected components, so we add a nearest-neighbor bridge edge from each disconnected component to the main component before checking contiguity.

## Simulation Notes
We sample 10,000 districting plans for West Virginia's lower house across 5 independent runs of the SMC algorithm. We impose a total county splits constraint and increase the number of merge-split proposals per SMC step.

We sample 10,000 districting plans for West Virginia's upper house across 5 independent runs of the SMC algorithm. We impose a total county splits constraint and increase the number of merge-split proposals per SMC step.
