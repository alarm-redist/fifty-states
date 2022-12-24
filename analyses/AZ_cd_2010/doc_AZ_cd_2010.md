# 2010 Arizona Congressional Districts

## Redistricting requirements
In Arizona, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. favor competitive districts to the extent practicable


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We add a county/municipality constraint, as described below.
We add a VRA constraint targeting two majority-HVAP districts which are also substantially majority-minority.
Not every plans is guaranteed to have two majority-HVAP districts, however.

## Data Sources
Data for Arizona comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 32,000 districting plans for Arizona across four independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans.
To satisfy the Voting Rights Act constraint, we run the simulation in two steps.

#### 1. Simulate three districts outside of Maricopa County
We target a Hispanic-majority district outside of Maricopa county (HVAP 53-58%).
However, most realized districts, while electing Democratic candidates, have a lower HVAP.
We avoid splitting municipalities in this region.


#### 2. Simulate six more districts in the remainder of the map
We target 1 Hispanic-majority district in Maricopa county (HVAP 53-58%).
We are able to realize this target values.

To balance county and municipality splits, we create pseudocounties for use in the county constraint.
These are counties outside Maricopa County and Pima County, which are larger than a congressional district in population.
Within Maricopa County and Pima County, municipalities are each their own pseudocounty as well.
Overall, this approach leads to much fewer county and municipality splits than using either a county or county/municipality constraint.
