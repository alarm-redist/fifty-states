# 2010 New York Congressional Districts

## Redistricting requirements
In New York, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions, communities of interest, and cores of existing districts
5. not be drawn to discourage competition
6. not be drawn to (dis)favor incumbents or parties
7. not abridge minority group voting power

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New York comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 40,000 districting plans for New York over two runs of the SMC algorithm and thin the sample down to 5,000 plans.

No special techniques were needed to produce the sample.
