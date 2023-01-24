# 2010 Iowa Congressional Districts

## Redistricting requirements
In Iowa, districts must:

1. be contiguous
1. have equal populations
1. be constructed only from counties
1. be geographically compact, as defined by two compactness measures:
    1. length-width compactness, which measures the total absolute difference between the length and width of a district, across all districts
    1. perimeter compactness, which measures the total perimeter of all districts


### Algorithmic Constraints
We enforce a maximum population deviation of 0.01%, given strict historical deviation standards.
We also merge VTDs into counties and run the simulation at the county level.
For compactness, we increase the `compactness` parameter to 1.1, which does not create too much inefficiency.

## Data Sources
Data for Iowa comes from [All About Redistricting](https://redistricting.lls.edu/wp-content/uploads/ia_2010_congress_2011-04-19_2021-12-31.zip)

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 8,000 districting plans for Iowa across four independent runs of the SMC algorithm and randomly select 1,250 of the plans from each of the four runs.
As noted above, we set `compactness=1.1`.
