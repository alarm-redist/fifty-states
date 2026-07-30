# 2020 Nevada State House/Senate Districts

## Redistricting requirements
In Nevada, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Nevada must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible (preserve political subdivisions)
5. preserve communities of interest
6. avoid pairing incumbents
7. House Nested in Senate or Congress


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. For Nevada's upper house,
convergence required a total county split constraint with strength 3 and an
increase to the target population size of pseudo-counties by a magnitude of
12.

## Data Sources
Data for Nevada comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample districting plans for Nevada's lower house using theTop-Down Nested State House District technique 
for the SMC algorithm across 5 outer runs with 2,000 inner simulations each, with each house-district
plan simulated within an already-sampled upper house plan to enforce
nesting of house districts within senate districts. No additional
constraints were used. The final sample contains 9,460 successfully
sampled plans.


We sample 10,000 districting plans for Nevada's upper house across 5
independent runs of the SMC algorithm, using the constraints described above.
