# 2020 Rhode Island Congressional Districts

## Redistricting requirements
In Rhode Island, according to the [Rhode Island Laws, Chapter 100, Section 2](http://webserver.rilin.state.ri.us/PublicLaws/law11/law11100.htm) districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve state senate district boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a VRA constraint targeting one minority opportunity district.

## Data Sources
Data for Rhode Island comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2022 Rhode Island enacted congressional map comes from the [American Redistricting Project](https://thearp.org/state/rhode-island/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Rhode Island.
We assigned state senate districts to act like counties so that the simulations minimize the number of senate district splits.
