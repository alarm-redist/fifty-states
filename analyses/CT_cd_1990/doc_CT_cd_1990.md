# 1990 Connecticut Congressional Districts

## Redistricting requirements
In Connecticut, we consult [Connecticut Constitution Art. III., Sec. 5](https://www.cga.ct.gov/red2011/2001/section5article3.htm) and [Section 9-9 of the Connecticut General Statutes](https://www.cga.ct.gov/red2011/2001/section9-9.htm). 
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. generally preserve county and municipality boundaries


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Connecticut comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Connecticut across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
Municipality lines are used in Fairfield County, Hartford County, and New Haven County, which are all counties with populations larger than 40% the target population for a district.
No special techniques were needed to produce the sample.
