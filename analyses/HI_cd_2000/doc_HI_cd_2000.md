# 2000 Hawaii Congressional Districts

## Redistricting requirements
In ``Hawaii `, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts:

1\. shall not extend beyond the boundaries of any basic island unit.
2\. shall not be so drawn as to unduly favor a person or political faction.
3\. shall be contiguous, except in the case of districts encompassing more than one island, districts.
4\. shall be compact.
5\. shall follow permanent and easily recognized features, such as streets, streams and clear geographical features, and, when practicable, shall coincide with census tract boundaries.
8\. Where practicable, submergence of an area in a larger district wherein substantially different socio-economic interests predominate shall be avoided.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 

## Data Sources
Data for ``Hawaii`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Islands are manually connected in the adjacency graph, but this has no bearing on the simulation.

## Simulation Notes
We sample 5,000 districting plans for Hawaii using five independent runs of the Sequential Monte Carlo (SMC) algorithm. In each run, 2,000 districting plans are drawn for a single district confined to the contiguous portion of Honolulu County. These are then extended to full-state plans by assigning the remainder of the state to the second district. After thinning each chain to 1,000 plans, we obtain a final set of 5,000 statewide districting plans..
Because of data availability, we analyzed Hawaii at the county level.