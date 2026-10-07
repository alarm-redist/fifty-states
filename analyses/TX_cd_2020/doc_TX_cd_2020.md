# 2020 Texas Congressional Districts

## Redistricting requirements
In Texas, districts must meet US constitutional requirements, but there are 
[no state-specific statutes](https://redistricting.capitol.texas.gov/reqs#congress-section).

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Texas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We estimate CVAP populations with the [`cvap`](https://github.com/christopherkenny/cvap)
R package.
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 12,500 districting plans for Texas across 5 independent runs of the SMC algorithm.
We then thin the sample to 5,000 plans by keeping the first 1,000 plans from each run.
We use merge-split steps after each SMC step to improve mixing.
We add VRA constraints for Hispanic CVAP and Black CVAP that nudge opportunity districts above 45%, discourage districts below 35%, and discourage packing above 70%.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
