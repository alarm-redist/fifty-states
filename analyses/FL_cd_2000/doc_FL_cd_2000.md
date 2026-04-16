# 2000 Florida Congressional Districts

## Redistricting requirements
In Florida, per [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), there are no specific legal requirements.
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 
We use a pseudo-county constraint described below.
We add VRA constraints encouraging Black VAP and Hispanic VAP majorities in districts.

## Data Sources
Data for Florida comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
We estimate CVAP populations with the [cvap](https://github.com/christopherkenny/cvap) R package.

## Simulation Notes
We sample 10,000 districting plans for Florida across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000.
We use a pseudo-county constraint to limit the county and municipality splits.
We also use new algorithmic mergesplit parameters to improve mixing.
