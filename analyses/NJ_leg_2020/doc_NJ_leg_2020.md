# 2020 New Jersey State House/Senate Districts

## Redistricting requirements
In New Jersey, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in New Jersey must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. have House nested in Senate or Congress


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Illinois comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

Where NJ's total pop came from: https://www.census.gov/library/stories/state-by-state/new-jersey.html 

## Simulation Notes
We sample XX,XXX districting plans for Illinois's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.

We sample XX,XXX districting plans for Illinois's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.

