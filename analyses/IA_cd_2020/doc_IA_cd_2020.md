# 2020 Iowa Congressional Districts

## Redistricting requirements
In Iowa, districts must:

1. be contiguous
1. have equal populations
1. be constructed only from counties
1. be geographically compact, as defined by two compactness measures:
    1. length-width compactness, which measures the total absolute difference between the length and width of a district, across all districts
    1. perimeter compactness, which measures the total perimeter of all districts


### Interpretation of requirements
We enforce a maximum population deviation of 0.01%, given strict historical deviation standards.
We also merge VTDs into counties and run the simulation at the county level.
For compactness, we increase the `compactness` parameter to 1.1, which does not create too much inefficiency.

## Data Sources
Data for Iowa comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Iowa across two independent runs of the SMC algorithm.
As noted above, we set `compactness=1.1`. 
