# 2020 Montana Congressional Districts

## Redistricting requirements
In Montana, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below.

## Data Sources
Data for Montana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Montana.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
These are counties for all counties with a population under 50,000.
Within counties larger than 50,000, municipalities are each their own pseudocounty as well.
Overall, this approach leads to much fewer county and municipality splits than using either a county or county/municipality constraint.
