# 2020 Wisconsin Congressional Districts

## Redistricting requirements
In Wisconsin, districts must:

1. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a county/municipality constraint as described below.

## Data Sources
Data for Wisconsin comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Wisconsin.
We create pseudocounties for use in the county constraint to match norms in the state of having low county and municipality splits, despite no rules regarding this. Municipality lines are used within Milwukee County, which is larger than a congressional district in population.
