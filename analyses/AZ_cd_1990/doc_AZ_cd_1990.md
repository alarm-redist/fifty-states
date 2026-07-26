# 1990 Arizona Congressional Districts

## Redistricting requirements
We use the redistricting criteria established by the federal court in Arizonans for [Fair Representation v. Symington (1992), which governed Arizona’s 1990s congressional plan](https://law.justia.com/cases/federal/district-courts/FSupp/828/684/2352036/).

In Arizona, districts should: 

1. be contiguous
1. have nearly equal populations
1. be geographically compact
1. preserve communities of interest and city and county boundaries as much as practicable; and
1. comply with the Voting Rights Act.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Arizona comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Arizona across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
To preserve communities of interest and city and county boundaries, we create pseudocounties for use in the county constraint.
