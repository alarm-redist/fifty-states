# 1990 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, we consult [A GUIDE TO STATE AND CONGRESSIONAL REDISTRICTING IN NEW MEXICO](https://www.nmlegis.gov/Redistricting/Documents/134250.pdf) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. satisfy the Voting Rights Act


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Mexico comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for New Mexico across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
No special techniques were needed to produce the sample.
