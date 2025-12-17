# 1990 Ohio Congressional Districts

## Redistricting requirements
In Ohio, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a hinge Gibbs constraint targeting the same number of majority-minority districts as the enacted plan.

## Data Sources
Data for Ohio comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
A precinct is manually connected in the adjacency graph, but this has no bearing on the simulation.

## Simulation Notes
We sample 5,000 districting plans for Ohio across 10 independent runs of the SMC algorithm.
We also used new algorithmic mergesplit parameters to improve mixing.