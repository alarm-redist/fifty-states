# 2020 Maine Congressional Districts

## Redistricting requirements
[In Maine, following Title 21-A, Chapter 15, Section 1206, districts must](https://legislature.maine.gov/legis/statutes/21-A/title21-Asec1206.html):

1. be contiguous (1)
1. have equal populations (1)
1. be geographically compact (1)
1. preserve county and municipality boundaries as much as possible (1)

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply the standard algorithmic county constraint.

## Data Sources
Data for Maine comes from the [Voting and Election Science Team](https://dataverse.harvard.edu/dataverse/electionscience) for 2016, 2018, and 2020. It is retabulated to 2020 Census tracts, as 2020 Census VTDs do not cover the majority of Maine's geography.

## Pre-processing Notes
Islands tracts were connected to the nearest tract within the same district.

## Simulation Notes
We sample 5,000 districting plans for Maine across 4 independent runs of the SMC algorithm.
We use the standard county constraint.
We weaken the compactness parameter to 0.8 due to the relatively small state size and total number of tracts to encourage more diversity in the sample.
