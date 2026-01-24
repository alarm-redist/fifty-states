# 1990 Florida Congressional Districts

## Redistricting requirements
In Florida, there are no specific legal requirements.
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
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 6,000 districting plans for Kentucky across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000.
We use a pseudo-county constraint to limit the county and municipality splits.
We also use new algorithmic mergesplit parameters to improve mixing.
Standardized CVAP data are unavailable for the 1990 cycle, so this analysis uses VAP by race instead.