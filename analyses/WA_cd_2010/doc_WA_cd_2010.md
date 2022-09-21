# 2010 Washington Congressional Districts

## Redistricting requirements
In Washington, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.05%. We applied a constraint to limit county and municipality splits (see 02_setup_WA_cd_2010 file). We also used ferry routes in order to create districts linking precincts that are offshore. 

## Data Sources
Data for Washington comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
As described above, the adjacency graph was modified by hand to reflect Washington's contiguity requirements. The full list of these changes can be found in the 01_prep_WA_cd_2010.R file.

## Simulation Notes
We sample 14,000 districting plans for Washington using the SMC algorithm and thinned the samples down to 5,000. To comply with the federal VRA and to respect communities of interest, we add a weak VRA constraint targeting one majority-minority district (currently WA-09).
