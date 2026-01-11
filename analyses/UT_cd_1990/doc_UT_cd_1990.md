# 1990 Utah Congressional Districts

## Redistricting requirements
In Utah, according to [Guidelines adopted by Redistricting Committee, May 29, 1991](https://www.senate.mn/departments/scr/REDIST/Red2000/TAB5APPX.htm#:~:text=Guidelines%20adopted%20by%20Redistricting%20Committee%2C,May%2029%2C%201991), districts must:

1. be contiguous
1. have equal populations (± 1%)
1. be geographically compact
1. not be drawn to intentionally protect or defeat any incumbent
1. efforts will be made to preserve county and municipality boundaries

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply a stronger county constraint, which is in line with the smaller number of county splits observed in the enacted congressional district map.

## Data Sources
Data for ``Utah`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for ``Utah`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a stronger algorithmic county constraint to limit the number of county splits.