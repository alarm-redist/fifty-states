# 1990 Texas Congressional Districts

## Redistricting requirements
In Texas, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a pseudocounty constraint as described below.
We add hinge constraints to encourage a Hispanic-opportunity district with Hispanic VAP above 60% (while limiting packing above 75%) and a district with Black VAP above 35%, in line with the Voting Rights Act.

## Data Sources
Data for Texas comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
A precinct is manually connected in the adjacency graph, but this has no bearing on the simulation.

## Simulation Notes
We sample 5,000 districting plans for Texas across 5 independent runs of the SMC algorithm.
To approximate traditional redistricting practice that avoids unnecessary subdivision splits, we create pseudocounties for use in the county constraint.
We also use new algorithmic mergesplit parameters to improve mixing.
Standardized CVAP data are unavailable for the 1990 cycle, so this analysis uses VAP by race instead.
