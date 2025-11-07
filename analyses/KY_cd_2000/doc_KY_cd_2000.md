# 2000 Kentucky Congressional Districts

## Redistricting requirements
In Kentucky, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. meet the requirements of Section 2 of the Voting Rights Act
1. preserve communities of interest
1. preserve cores of existing districts

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint described below which attempts to mimic the norms in Kentucky of generally preserving county, city, and township boundaries.

## Data Sources
Data for Kentucky comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 1990 plan. Precincts in counties which are split by existing district boundaries are merged only within their county.

## Simulation Notes
We sample 10,000 districting plans for Kentucky across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a pseudo-county constraint to limit the county and municipality (i.e. city and township) splits.