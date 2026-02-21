# 1990 Missouri Congressional Districts

## Redistricting requirements
In Missouri, we consult [Forgette et al.](https://www.jstor.org/stable/40421634) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a hinge Gibbs constraint targeting one majority-minority district to comply with VRA requirements and match the number in the enacted plan.

## Data Sources
Data for Missouri comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 25,000 districting plans for Missouri across 5 independent runs of the SMC algorithm to aid with convergence.
We then thinned the number of samples to 5,000. 
