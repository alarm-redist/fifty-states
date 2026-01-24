# 2000 Georgia Congressional Districts

## Redistricting requirements
In Georgia, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. comply with the Voting Rights Act
1. preserve the cores of existing districts and avoid contests between incumbents
1. use voting district boundaries as building blocks for districts


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Georgia comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 15,000 districting plans for Georgia across 3 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
No special techniques were needed to produce the sample.
