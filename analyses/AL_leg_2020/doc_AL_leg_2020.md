# 2020 Alabama State House/Senate Districts

## Redistricting requirements
In Alabama, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. Be contiguous [NCSL, 186]
2. Have substantially equal populations, as required by the 14th Amendment’s Equal Protection Clause and the Supreme Court’s decision in Reynolds v. Sims (1964) [NCSL, 243]
3. Be compact and geographically coherent [NCSL, 186]
4. Preserve the integrity of counties and other political subdivisions where feasible [NCSL, 186]
5. Use population data derived from the federal decennial census or equivalent state enumeration if necessary [NCSL, 177]


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Alabama comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 25,000 districting plans for Alabama's lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for Alabama's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
