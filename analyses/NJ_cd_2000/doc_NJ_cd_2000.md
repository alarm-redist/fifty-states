# 2000 New Jersey Congressional Districts

## Redistricting requirements
In ``New Jersey``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be geographically contiguous
2. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint described below, which attempts to mimic the norms in New Jersey of generally preserving county and municipal boundaries.
We add thresholded hard constraints to ensure at least one black performant district.

## Data Sources
Data for ``New Jersey`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Because New Jersey contains an unusually large number of discontiguous precincts, we used a helper function to identify 20 discontiguity merge-groups, involving 46 precincts (0.75% of all VTDs). These units were merged prior to simulation.
We apply a county-level logit shift to recalibrate ``ndv/nrv``. The adjustment needed to correct the vote shares was fairly large in several counties: Essex required a logit shift of about 1.39, Hudson about 1.33, Passaic about 0.98, and Union about 1.07. Because some of these values exceed 1, the original search interval [-1, 1] was too narrow for ``uniroot()`` to find the solution, so we widened the search interval to [-1.5, 1.5] to accommodate the larger correction.

## Simulation Notes
We sample 5,000 districting plans for ``New Jersey`` across 5 independent runs of the SMC algorithm.
To improve mixing, we apply the merge-split procedure at every step of the algorithm and allow up to 20 updates within each step.
To balance county and municipality splits, we create pseudo-counties for use in the county constraint. 
