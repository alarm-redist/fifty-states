# 2020 Alabama Congressional Districts

## Redistricting requirements
In Alabama, according to the [Reapportionment Committee Redistricting Guidelines](https://www.legislature.state.al.us/aliswww/reapportionment/Reapportionment%20Guidelines%20for%20Redistricting.pdf), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest as much as possible
6. avoid competition between incumbents


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Alabama comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2021 Alabama enacted congressional map comes from the [American Redistricting Project](https://thearp.org/state/alabama/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 6,000 districting plans for Alabama and subset to 5,000 which contain at least one majority-minority district.