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
We enforce a maximum population deviation of 1%, which is only slightly less than the 2010 population deviation of 1.6%. We apply a county/municipality constraint, as described below. We perform cores-based simulations, thereby preserving cores of prior districs.

## Data Sources
Data for New Mexico comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To balance county and municipality splits, we create pseudocounties for use in the county constraint. We create prior district cores by grouping all contiguous precincts found in the interiors (i.e., not on the boundaries) of each of the 2010 Congressional Districts.

## Simulation Notes
We sample 5,000 districting plans for New Mexico. No special techniques were needed to produce the sample.



