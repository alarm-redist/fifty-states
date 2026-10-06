# 2000 Oregon Congressional Districts

## Redistricting requirements
In ``Oregon `, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not favor any political party or incumbent legislator or individual
1. not dilute the voting strength of any linguistic or ethnic minority group


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Oregon comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
Counties not linked by a state or federal highway were manually disconnected in the
adjacency graph, matching the treatment used in the 1990, 2010, and 2020 Oregon analyses.
The full list of these county pairs can be found in the `01_prep_OR_cd_2000.R` file.

## Simulation Notes
We sample 20,000 districting plans for Oregon across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000.
No special techniques were needed to produce the sample.
