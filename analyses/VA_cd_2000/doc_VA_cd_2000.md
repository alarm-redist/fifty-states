# 2000 Virginia Congressional Districts

## Redistricting requirements
In Virginia, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous, allowing for contiguity by water if there is reasonable opportunity for travel
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. follow sections 2 and 5 of the VRA, submitting districts for preclearance


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Virginia comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 100,000 districting plans for Virginia across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We also used new algorithmic mergesplit parameters to improve mixing.
