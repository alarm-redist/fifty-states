# 2000 Michigan Congressional Districts

## Redistricting requirements
In Michigan, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
2. be geographically compact
3. follow incorporated city or township boundary lines to the extent possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to help preserve county and municipality boundaries, as described below.

## Data Sources
Data for ``Michigan`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 40,000 districting plans for Michigan across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Wayne County, Oakland County, and Macomb County must all be split due to their large populations, although within the counties, we avoid splitting any municipality.
