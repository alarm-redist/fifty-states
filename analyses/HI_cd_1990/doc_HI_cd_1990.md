# 1990 Hawaii Congressional Districts

## Redistricting requirements
In Hawaii, we consult [Hawaii Revised Statutes 25-2(b)(1)-(4) and (6), as in force for the 1990 cycle](https://archive.org/stream/hawaii-session-laws/1979-regular_djvu.txt#:~:text=%2A%2ASec.%2025,consult%20with%20the%20apportionment%20advisory). 
We impose the following constraints. 
In our simulations, districts must:

1. not unduly favor any person or party;
2. be contiguous, except when encompassing more than one island;
3. be compact;
4. where possible, follow geographical and recognized features and coincide with tract boundaries;
6. where practicable, avoid mixing regions with different socioeconomic interests.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use Census tracts in line with 25-2(b)(4). In absence of regional knowledge about features and socioeconomic interests, we use municipalities to attempt to enforce 25-2(b)(4) and (6).

## Data Sources
Data for Hawaii comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Precicnts, including islands, are manually connected in the adjacency graph.

## Simulation Notes
We run statewide SMC (2 runs, 30,000 candidate draws per run) and retain only plans where all non-Honolulu units are assigned to the same district, yielding one district confined to Honolulu. From the retained plans, we keep the first 2,500 per run, for 5,000 total statewide plans.