# 2020 Arkansas State House/Senate Districts

## Redistricting requirements
In Arkansas, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Arkansas must:

1. be contiguous (p. 184)
2. have equal populations (p. 24)
3. be geographically compact (p. 184)
4. preserve county and municipality boundaries as much as possible (p. 184)
5. preserve communities of interest (p. 184)
6. preserve cores of prior districts (p. 185)
7. avoid pairing incumbents (p. 185)

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. To accommodate the preservation of cores of prior districts, we incorporate a status quo constraint (strength 500) against the 2010 plan in both chambers.

## Data Sources
Data for Arkansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary. The final simulation used the status quo constraint described in the algorithmic constraints section.

## Simulation Notes
We sample 10,000 districting plans for Arkansas's lower house across 5 independent runs of the SMC algorithm.

We sample 25,000 districting plans for Arkansas's upper house across 5 independent runs of the SMC algorithm. We then thinned the number of samples to 10,000.
