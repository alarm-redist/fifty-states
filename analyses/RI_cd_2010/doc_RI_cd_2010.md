# 2010 Rhode Island Congressional Districts

## Redistricting requirements
In Rhode Island, according to [Chapter 106, Section 2 of the 2011 Rhode Island Laws](http://webserver.rilin.state.ri.us/PublicLaws/law11/law11106.htm), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve state senate districts as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Rhode Island comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Rhode Island across four independent runs of the SMC algorithm.
We assign state senate districts to act like counties so that the simulations minimize the number of state senate district splits.
