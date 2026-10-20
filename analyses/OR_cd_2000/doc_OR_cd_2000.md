# 2000 Oregon Congressional Districts

## Redistricting requirements
In Oregon, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must, as nearly as practicable:

1. be contiguous
1. be of equal population
1. utilize existing geographic or political boundaries
1. not divide communities of common interest
1. be connected by transportation links

Additionally, districts may not favor any political party or incumbent, and may not dilute the voting strength of any language or ethnic minority group.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below.
To reflect the transportation links constraint, we remove edges in the adjacency graph for counties not connected by a state or federal highway. 

## Data Sources
Data for Oregon comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Counties not linked by a state or federal highway were manually disconnected in the
adjacency graph, matching the treatment used in the 1990, 2010, and 2020 Oregon analyses.
The full list of these county pairs can be found in the `01_prep_OR_cd_2000.R` file.


## Simulation Notes
We sample 20,000 districting plans for Oregon across 10 independent runs and retain 500 plans from each run, yielding a final sample of 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
