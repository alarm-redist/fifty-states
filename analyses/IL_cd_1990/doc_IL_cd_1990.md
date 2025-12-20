# 1990 Illinois Congressional Districts

## Redistricting requirements
In Illinois, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 

## Data Sources
Data for Illinois comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 6,000 districting plans for Illinois across 10 independent runs of the SMC algorithm.
We also used new algorithmic mergesplit parameters to improve mixing.