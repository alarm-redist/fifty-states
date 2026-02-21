# 1990 Idaho Congressional Districts

## Redistricting requirements
In Idaho, we consult [Idaho Redistricting Law 1990](https://www.commoncause.org/wp-content/uploads/2019/12/Idaho-Redistricting-Law.pdf) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible 
1. prevent floterial districts
1. be connected by highways


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Idaho comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
A custom adjacency map based on the highways of Idaho was created. Columns where muni = NA had their muni values set to the county_muni values of that column.

## Simulation Notes
We sample 10,000 districting plans for Idaho across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
No special techniques were needed to produce the sample.
