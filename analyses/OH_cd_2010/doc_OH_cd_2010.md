# 2010 Ohio Congressional Districts

## Redistricting requirements
In Ohio, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions

### Algorithmic Constraints
We enforce a maximum population deviation of 0.05%. We use a pseudo-county constraint to help preserve county and municipality boundaries. See '02_setup_OH_cd_2010.R' file.

## Data Sources
Data for Ohio comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 13,000 districting plans for Massachusetts over two runs. We then thinned the number of samples to 5,000. No special techniques were needed to produce the sample.
