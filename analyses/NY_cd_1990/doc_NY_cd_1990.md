# 1990 New York Congressional Districts

## Redistricting requirements
In New York, we consult [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We use a pseudo-county constraint described below, which attempts to mimic the norms in New York of preserving political subdivisions, communities of interest, and cores of existing districts. This also reflects that districts are generally structured around counties.

## Data Sources
Data for New York comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Ellis Island (2393) was connected to Governor's Island (2394), and the shorelines were connected (2617) and (2616).

## Simulation Notes
We sample 150,000 districting plans for New York across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
To balance county and municipality splits, we create pseudo-counties for use in the county constraint.
