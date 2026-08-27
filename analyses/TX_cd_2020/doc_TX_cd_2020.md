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
We sample 12,500 statewide candidate districting plans for Texas across five
independent linking-edge merge-split SMC runs, then keep the first 1,000 plans
from each run for a 5,000-plan ensemble. This replaces the prior Greater
Houston, Austin/San Antonio, and Dallas-Fort Worth partial-SMC workflow with a
statewide workflow matching the newer convergent Texas simulations used for
1990, 2000, and the Callais 2020 run.

The simulation keeps the statewide VRA hinge constraints from the prior
recombination stage: Hispanic and Black CVAP opportunity constraints that nudge
opportunity districts above 45%, discourage districts below 35%, and discourage
packing above 70%. To balance county and municipality splits, we use
pseudocounties for the county constraint.
