# 2000 Idaho Congressional Districts

## Redistricting requirements
In Idaho, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. Preserve traditional neighborhoods and communities of interest where possible
2. Have equal populations
3. Be geographically compact and contiguous
4. Minimise the number of county splits
5. Retain local voting precinct boundaries if possible
6. Not split counties to favor a political party or incumbent

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 

## Data Sources
Data for Idaho comes from the ALARM Project's [2000 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20000 redistricting plans for Idaho across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5000.
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
No special techniques were needed to produce the sample.
