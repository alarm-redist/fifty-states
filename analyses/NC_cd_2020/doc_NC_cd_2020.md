# 2020 North Carolina Congressional Districts

## Redistricting requirements
In North Carolina, under [North Carolina State Constitution Article II Sections 3 & 5](https://www.ncleg.gov/Laws/Constitution/Article2), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a county constraint.
We add a VRA constraint targeting two majority-minority districts.

## Data Sources
Data for North Carolina comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2022 North Carolina ratified congressional map comes from the [North Carolina General Assembly](https://www.ncleg.gov/Redistricting).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 36,000 districting plans for North Carolina across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans.
