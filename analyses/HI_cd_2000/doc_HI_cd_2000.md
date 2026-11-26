# 2000 Hawaii Congressional Districts

## Redistricting requirements
In Hawaii, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:
1. not unduly favor any person or party;
1. be contiguous, except when encompassing more than one island;
1. be compact;
1. where possible, follow geographical and recognized features and coincide with tract boundaries;
1. where practicable, avoid mixing regions with different socioeconomic interests.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use Voting Tabulation Districts—the closest available geographic units to census tracts—as the basic geographic units for simulation. VTDs allow us to approximate the tract-alignment principle where feasible. In absence of regional knowledge about features and socioeconomic interests, we use municipalities to attempt to enforce the fourth and fifth requirements.

## Data Sources
Data for ``Hawaii`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Islands are manually connected in the adjacency graph.

## Simulation Notes
We use SMC to split the Honolulu County sub-map into two regions with relaxed population bounds and a custom constraint ensuring that one region and its statewide complement satisfy the original statewide population bounds. The remaining Honolulu units and all non-Honolulu units form the other district. We run two SMC runs with 30,000 draws each and, after resampling, retain the first 2,500 draws from each run, yielding 5,000 statewide plans.
