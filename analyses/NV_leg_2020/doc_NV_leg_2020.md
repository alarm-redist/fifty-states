# 2020 Nevada State House/Senate Districts

## Redistricting requirements
In Nevada, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Nevada must:

1. be contiguous (p. 186)
2. have equal populations (p. 24)
3. be geographically compact (p. 186)
4. preserve county and municipality boundaries as much as possible (preserve political subdivisions)
5. preserve communities of interest (p. 186)
6. avoid pairing incumbents (p. 187)
7. nest state House districts inside state Senate districts or Congressional districts (p. 187)


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. For Nevada's upper house, convergence required a total county split constraint with strength 3, an increase to the target population size of pseudo-counties by a magnitude of 12, and a population tempering value of 0.01.

## Data Sources
Data for Nevada comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample districting plans for Nevada's lower house using the Top-Down Nested State House District technique for the SMC algorithm across 5 outer runs with each house-district plan simulated within an already-sampled upper house plan to enforce nesting of house districts within senate districts. Each upper house district is simulated with 50 inner simulations, and one successful split is retained. Plans in which an inner simulation failed to split are discarded. 14,078 of 15,000 upper house districting plans remain in the surviving sample, which is then thinned to 10,000 plans. No additional constraints were used. The final sample contains 10,000 successfully sampled plans.

We sample 15,000 districting plans for Nevada's upper house across 5 independent runs of the SMC algorithm to provide additional plans for the later lower house simulations, before filtering down to 10,000 plans, using the constraints described above. The upper house sample is then filtered and thinned to match the 10,000 lower house plans, so every upper house plan has a corresponding lower house plan.
