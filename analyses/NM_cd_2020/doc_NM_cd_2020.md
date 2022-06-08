# 2020 New Mexico Congressional Districts

## Redistricting requirements
In New Mexico, districts must, under [legislation code SB 304](https://www.nmlegis.gov/Legislation/Legislation?Chamber=S&LegType=B&LegNo=304&year=21):

1. be contiguous
2. be reasonably compact
3. be as equal in population as practicable
4. to the extent feasible, preserve communities of interest and take into consideration political and geographic boundaries
5. to the extent feasible, preserve the core of existing districts

Additionally, race-neutral districting principles shall not be subordinated to racial considerations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%, which is only slightly greater than the strict population deviation standards observed in both the 2000 and 2010 Congressional District maps. 
We constrain the number of county divisions to 1 less than the number of Congressional Districts.
We perform cores-based simulations, thereby preserving cores of prior districts.


## Data Sources
Data for New Mexico comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for New Mexico' 2020 congressional district map comes from New Mexico Legislature's [Maps and Data](https://www.nmlegis.gov/Redistricting2021/Maps_And_Data?ID202=221711.1).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan.

## Simulation Notes
We sample 5,000 districting plans for New Mexico. No special techniques were needed to produce the sample.

