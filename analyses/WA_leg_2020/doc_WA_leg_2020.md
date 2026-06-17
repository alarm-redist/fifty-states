# 2020 Washington State House/Senate Districts

## Redistricting requirements
In Washington, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Washington must:

1. be contiguous [186]
2. have equal populations [24]
3. be geographically compact [186]
4. preserve county and municipality boundaries as much as possible [186]
5. preserve communities of interest [186]
6. not favor party [187]
7. be competitive [187]
8. have the House nested in Senate or Congress [187]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Washington comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Washington's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.

We sample XX,XXX districting plans for Washington's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [TODO delete if only 10,000 total samples].
No special techniques were needed to produce the sample.
