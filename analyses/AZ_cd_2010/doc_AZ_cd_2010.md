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
We add a hinge Gibbs constraint targeting two majority-HVAP districts, one within Maricopa County and one outside of it (as exist in the enacted plan.) However, not all plans are guaranteed to have two majority-HVAP districts.

## Data Sources
Data for Arizona comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 32,000 districting plans for Arizona across four independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans.
To satisfy the Voting Rights Act constraint, we run the simulation in two steps.

#### 1. Simulate three districts outside of Maricopa County
We target a Hispanic-majority district outside of Maricopa County (HVAP 50-55%). We avoid splitting municipalities in this region.

#### 2. Simulate six more districts in the remainder of the map
We target 1 Hispanic-majority district in Maricopa County (HVAP 50-55%), and only keep plans where the district with the second-highest HVAP exceeds 30% (including the districts outside Maricopa County).

To balance county and municipality splits, we create pseudocounties for use in the county constraint.
These are counties outside Maricopa County and Pima County, which are larger than a congressional district in population.
Within Maricopa County and Pima County, municipalities are each their own pseudocounty as well.
Overall, this approach leads to much fewer county and municipality splits than using either a county or county/municipality constraint.
