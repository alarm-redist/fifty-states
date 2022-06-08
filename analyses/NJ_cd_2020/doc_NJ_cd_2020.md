# 2020 New Jersey Congressional Districts

## Redistricting requirements
In New Jersey, districts must:

1. be contiguous
1. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We use a pseudo-county constraint described below which attempts to mimic the norms in New Jersey of generally preserving county and municipal boundaries.

## Data Sources
Data for New Jersey comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 16,000 districting plans for New Jersey across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans.
We use a pseudo-county constraint to limit the county and municipality splits.
Municipality lines are used in Bergen County, Burlington County, Camden County, Essex County, Hudson County, Mercer County, Middlesex County, Monmouth County, Morris County, Ocean County, Passaic County, Somerset County, and Union County.
These are larger than 40% the target population for a district.
No special techniques were needed to produce the sample.
