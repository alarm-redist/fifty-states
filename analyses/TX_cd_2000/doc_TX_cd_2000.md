# 2000 Texas Congressional Districts

## Redistricting requirements
In Texas, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must meet US constitutional requirements, but there are no binding state-specific statutes. 

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to limit the county and municipality splits. We add VRA constraints encouraging Hispanic VAP and Black VAP majorities in districts.

## Data Sources
Data for Texas comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/). We estimate CVAP population totals with the `cvap` and `censable` packages, using data from the [Census Bureau's 2000 Special Tabulation](https://www.census.gov/data/datasets/2000/dec/rdo/2000-cvap.html).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Texas across 5 independent runs of the SMC mergesplit algorithm. After each SMC step, we take 40 mergesplit moves.
We then thinned the number of samples to 5,000. 
