# 2020 Michigan Congressional Districts

## Redistricting requirements
In Michigan, districts must:

1. be contiguous (Mich. Const. art. IV, § 6(13)(b)). Island areas are considered to be contiguous by land to the county of which they are a part.
1. have equal populations (Mich. Const. art. IV, § 6(13)(a))
1. be geographically compact (Mich. Const. art. IV, § 6(13)(g))
1. reflect consideration of county, city, and township boundaries (Mich. Const. art. IV, § 6(13)(f))
1. not provide a disproportionate advantage to any political party, determined using accepted measures of partisan fairness (Mich. Const. art. IV, § 6(13)(d))

Based on the current plan, two districts should be majority-minority in order to comply with the Voting Rights Act.


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply a county/municipality constraint, as described below. 
We target a 52-62% minority share in two districts.

## Data Sources
Data for Michigan comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To meet contiguity requirements, we removed precincts with more water area than land area and no population.
We then manually connected any disconnected islands with the nearest precinct on the mainland and in the same county: precincts 26029029017 and 26029029016 in Charlevoix county, and precincts 26047047022 and 26097097010 for the Upper Peninsula.

## Simulation Notes
We sample 48,000 districting plans for Michigan across four independent runs of the SMC algorithm, then filter down to 5,000 total plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of Wayne, Macomb, and Oakland counties. Within these counties, municipalities are each their own pseudocounty as well.  These counties were chosen since they are necessarily split by congressional districts.  Overall, this approach leads to much fewer county and municipality splits than using either a county or county/municipality constraint.
