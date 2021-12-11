# 2020 Oklahoma Congressional Districts

## Redistricting requirements
[In Oklahoma, districts must](https://oksenate.gov/sites/default/files/inline-files/Senate%20Redistricting%20Guidelines.pdf):

1. be contiguous (C)
1. have equal populations (A.2)
1. be geographically compact (C)
1. preserve county and municipality boundaries as much as possible (C)

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Oklahoma comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Oklahoma.
We use a pseudo county constraint which uses counties, except for Oklahoma County which uses municipalities.
No special techniques were needed to produce the sample.
