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
We use a helper function to identify 20 discontiguity merge-groups, involving 46 precincts (0.75% of all VTDs), which were merged prior to simulation.
Because the Essex MCDGRP identifiers are broken and produce a distorted baseline merge, several counties have raw Democratic shares far below the 2000 MEDSL targets. 
We apply a county-level logit shift to recalibrate ``ndv/nrv`` and widen the ``uniroot()`` search interval from ``[-1,1]`` to ``[-5,5]`` to accommodate the larger correction.

## Simulation Notes
We sample 5,000 districting plans for ``New Jersey`` across 5 independent runs of the SMC algorithm.
We also use the algorithmic mergesplit parameters to improve mixing.
To balance county and municipality splits, we create pseudo-counties for use in the county constraint. 
