# 2000 Iowa Congressional Districts

## Redistricting requirements
In Iowa, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not split any county
1. not favor any political party, incumbent, or other person or group
1. not augment or dilute the voting strength of a racial or linguistic minority
1. use addresses of incumbents, political affiliations of registered voters, previous election results, or demographic information not required by the Constitution


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Iowa comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Iowa across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
No special techniques were needed to produce the sample.
