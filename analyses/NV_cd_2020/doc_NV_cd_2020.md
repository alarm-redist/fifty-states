# 2020 Nevada Congressional Districts

## Redistricting requirements
In Nevada, districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. preserve communities of interest.

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We use a county constraint to avoid splitting counties, municipalities, and potential COIs.

## Data Sources
Data for Nevada comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Nevada.
We use a standard algorithmic county constraint.
