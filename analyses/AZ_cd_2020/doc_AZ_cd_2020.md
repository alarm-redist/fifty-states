# 2020 Arizona Congressional Districts

## Redistricting requirements
In Arizona, districts must, [under the state constitution](https://www.azleg.gov/viewDocument/?docName=http://www.azleg.gov/const/4/1.p2.htm):

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. favor competitive districts to the extent practicable


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a county/municipality constraint, as described below.
We add a VRA constraint to ensure the proper number of majority-minority districts.

## Data Sources
Data for Arizona comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Arizona.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
These are counties outside Maricopa County and Pima County, which are larger than a congressional district in population.
Within Maricopa County and Pima County, municipalities are each their own pseudocounty as well.
Overall, this approach leads to much fewer county and municipality splits than using either a county or county/municipality constraint.
We add a VRA constraint targeting districts with 65% HVAP, which is sufficient to create two majority-Hispanic districts.
