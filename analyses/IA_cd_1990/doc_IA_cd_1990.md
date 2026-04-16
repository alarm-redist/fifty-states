# 1990 Iowa Congressional Districts

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

## Data Sources
Data for Iowa comes from Iowa's [legislative guide to redistricting](https://www.legis.iowa.gov/docs/publications/LG/9461.pdf).

## Pre-processing Notes
Simulations are done at the county level, which is a requirement for congressional districts in Iowa per state law.

## Simulation Notes
We sample 5,000 districting plans for Iowa across five independent runs of the SMC algorithm.
