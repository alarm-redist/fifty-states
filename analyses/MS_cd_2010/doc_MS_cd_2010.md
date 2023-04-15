# 2010 Mississippi Congressional Districts

## Redistricting requirements
In Mississippi, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. be VRA compliant (Voting Rights Act, 1965)


### Algorithmic Constraints
We ensure that there is a majority minority district with at least 55% VAP.

## Data Sources
Data for Mississippi comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Mississippi, across two independent runs of the SMC algorithm.
We apply a hinge Gibbs constraint of strength 20 to encourage drawing a majority black district.
