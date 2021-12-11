# 2020 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, under SB 304, districts must:

1. be contiguous
2. be reasonably compact
3. be as equal in population as practicable
4. to the extent feasible, preserve communities of interest and take into consideration political and geographic boundaries
5. to the extent feasible, preserve the core of existing districts

Additionally, race-neutral districting principles shall not be subordinated to racial considerations

### Interpretation of requirements
We enforce a maximum population deviation of 0.05%, which is similar to the strict population deviation standards obvserved in both the 2000 and 2010 Congressional District maps. We apply a county/municipality constraint, as described below. We perform cores-based simulations, thereby preserving cores of prior districs.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We create pseudo-counties by splitting counties containing more than one municipality into county-municipality combinations. This is helpful for constricting the number of county and municipality divisions in the simulated plans. We create prior district cores by grouping all contiguous precincts found in the interiors (i.e., not on the boundaries) of each of the 2010 Congressional Districts.

## Simulation Notes
We sample 5,000 districting plans for New Mexico. No special techniques were needed to produce the sample.

