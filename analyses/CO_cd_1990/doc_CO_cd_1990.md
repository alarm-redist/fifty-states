# 1990 Colorado Congressional Districts

## Redistricting requirements
In Colorado, we consult [Colorado Redistricting Cases: the 1990s](https://www.senate.mn/departments/scr/REDIST/Redsum/cosum.htm) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations, subject to permissible deviations
1. be geographically compact, recognizing that compactness is a threshold requirement rather than an absolute rule
1. preserve county and municipality boundaries as much as possible, allowing splits only when justified by competing redistricting criteria
1. avoid dividing identified communities of interest, except where such divisions are necessary and explicitly justified
1. consider alternative configurations when political subdivisions are split, ensuring that any split reflects a reasoned choice rather than inadvertence
1. comply with Section 2 of the Voting Rights Act, including the creation of minority-opportunity districts where required, even if doing so necessitates additional subdivision splits

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Colorado comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Colorado across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.

