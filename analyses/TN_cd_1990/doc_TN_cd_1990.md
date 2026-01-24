# 1990 Tennessee Congressional Districts

## Redistricting requirements
In ``Tennessee``, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 
We use a pseudo-county constraint to limit the county and municipality splits. 
We apply a stronger county constraint, which is in line with the smaller number of county splits observed in the enacted congressional district map.

## Data Sources
Data for ``Tennessee`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 30,000 districting plans across five independent runs of the SMC algorithm, and then thin them to 5000 plans.
To reflect Tennessee's traditional norm of minimizing county splits while reducing unnecessary fragmentation of major cities, we create pseudo-counties for use in the county constraint.
We use a stronger algorithmic county constraint to limit the number of county splits.
We also use new algorithmic mergesplit parameters to improve mixing.
