# 2020 New Hampshire Congressional Districts

## Redistricting requirements
In New Hampshire, districts must:

1. be contiguous
1. have equal populations

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Hampshire comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Precincts are merged by minor civil division, as the enacted has 0 minor civil division splits.

## Simulation Notes
We sample 5,000 districting plans for New Hampshire across two independent runs of the SMC algorithm.
We use a standard county algorithmic constraint.
