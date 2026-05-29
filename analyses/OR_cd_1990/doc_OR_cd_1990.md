# 1990 Oregon Congressional Districts

## Redistricting requirements
In Oregon, districts must, under [Or. Rev. Stat. § 188.010](https://oregon.public.law/statutes/ors_188.010):

1. be contiguous
1. be of equal population
1. utilize existing geographic or political boundaries
1. not divide communities of common interest
1. be connected by transportation links

Additionally, districts may not favor any political party or incumbent, and may not dilute the voting strength of any language or ethnic minority group.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below.
To reflect the transportation links constraint, we remove edges in the adjacency graph for counties not connected by a state or federal highway. 

## Data Sources
Data for New Hampshire comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
As described above, counties lacking state or federal highway links were manually disconnected. Given the stability of major highway connectivity over time, we apply the same county disconnections as in prior analyses.
The full list of these counties can be found in the `01_prep_OR_cd_1990.R` file.

## Simulation Notes
We sample 10,000 districting plans for Oregon across 5 independent runs of the SMC algorithm.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
