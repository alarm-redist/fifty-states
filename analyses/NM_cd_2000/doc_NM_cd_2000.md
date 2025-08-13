# 2000 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2000 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20000 redistricting plans for New Mexico across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5000.
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
