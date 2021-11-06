# 2020 Oregon Congressional Districts

## Redistricting requirements
In Oregon, districts must, under Or. Rev. Stat. § 188.010:

1. be contiguous
1. be of equal population
1. utilize existing geographic or political boundaries
1. not divide communities of common interest
1. be connected by transportation links

Additionally, districts may not favor any political party or incumbent, and may not dilute the voting strength of any language or ethnic minority group.

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below.
To reflect the transportation links constraint, we remove edges in the adjacency graph for counties not connected by a state or federal highway.

## Data Sources
Data for Oregon comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Oregon does not submit precinct boundaries to the Census Bureau.
The base shapefile consists of tracts, but where tracts are split by the enacted congressional districts, we create separate sub-tracts.
As described above, counties not linked by a state or federal highway were manually disconnected.
The full list of these counties can be found in the `01_prep_OR_cd_2020.R` file.

## Simulation Notes
We sample 5,000 districting plans for Oregon.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
These are counties, outside of Multnomah county. Within Multnomah county, each municipality is its own pseudocounty as well.
Multnomah county were chosen since it is necessarily split by congressional districts.
