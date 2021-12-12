# 2020 West Virginia Congressional Districts

## Redistricting requirements
[In West Virginia, under the state constitution, districts must](http://www.wvlegislature.gov/WVCODE/WV_CON.cfm):

1. be contiguous (I 1-4)
1. have equal populations (I 1-4)
1. be geographically compact (I 1-4)
1. districts must be made of contiguous counties (I 1-4)


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We simulate at the county level.

## Data Sources
Data for West Virginia comes from the [The Upshot Presidential Precinct Map data](https://github.com/TheUpshot/presidential-precinct-map-2020) and are joined with county level Census data.

## Pre-processing Notes
Data is aggregated to the county level.

## Simulation Notes
We sample 5,000 districting plans for West Virginia.
No special techniques were needed to produce the sample.
