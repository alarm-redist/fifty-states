# 2020 New Jersey State House/Senate Districts

## Redistricting requirements
In New Jersey, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in New Jersey must:

1. be contiguous [186]
2. have equal populations [24]
3. be geographically compact [186]
4. preserve county and municipality boundaries as much as possible [186]
5. have House nested in Senate or Congress [187]

Note: New Jersey is a state with simple multi-member legislative districts, where chambers have identical plans with different numbers of members per district.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for New Jersey comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
The [State of New Jersey](https://www.nj.gov/redistricting/legislative/) requires that "no county or municipality shall be divided among Assembly districts unless it shall contain more than one-fortieth of the total number of inhabitants of the State..." Therefore, municipalities with populations less than one-fourtieth of the total population of New Jersey were merged. MCD data was used to accommodate the merging of small towns, as not all towns are included in Census place data. [Census data from 2020](https://www.census.gov/library/stories/state-by-state/new-jersey.html) provided the figure used for New Jersey's total population.

## Simulation Notes
We sample 15,000 districting plans for New Jersey's lower house across 5 independent runs of the SMC algorithm. We introduce a total municipality splits constraint of strength 2.4 and increase the number of merge-split proposals per SMC step to 139 total. Additionally, we balanced county/muni splits by setting pop_muni in the shd merged map to 3*get_target(map_shd_merged).

New Jersey uses the same district plans for its upper house, so please note that the plans simulated for the State House were copy-and-pasted under "State Senate."
