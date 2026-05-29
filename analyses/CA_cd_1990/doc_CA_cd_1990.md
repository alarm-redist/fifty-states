# 1990 California Congressional Districts

## Redistricting requirements
In ``California``, according to [the California Constitution. XXI., Sec. 1](https://clerk.assembly.ca.gov/sites/clerk.assembly.ca.gov/files/archive/Statutes/1990/90Vol1_Index.pdf). We impose the following constraints.
In our simulations, districts must:

1. be contiguous
1. have equal populations
1. respect the geographic integrity of cities, counties, and geographic regions to the extent possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to limit the county and municipality splits. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for ``California`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Islands are manually connected in the adjacency graph, but this has no bearing on the simulation.

## Simulation Notes
We sample 6,000 districting plans for ``California`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We also used new algorithmic mergesplit parameters to improve mixing.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
