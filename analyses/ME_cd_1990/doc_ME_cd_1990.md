# 1990 Maine Congressional Districts

## Redistricting requirements
In Maine, because redistricting laws relevant for 1990 are not publicly available, we consult both [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm) and impose the following constraints and [Forgette et al. 2009](http://www.jstor.org/stable/40421634). In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. respect political subdivisions


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Maine comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Rhode Island (10 independent runs of the SMC algorithm with thinning to 500 plans for each run) to help manage low plan diversity.
We then thinned the number of samples to 5,000. 
We weaken the compactness parameter to 0.8 due to the relatively small state size and total number of tracts to encourage more diversity in the sample.


