# 2010 Iowa Congressional Districts

## Redistricting requirements
In Iowa, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact with compactness defined as length-width compactness and perimeter compactness
4. not split counties
5. preserve municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.01%.

## Data Sources
Data for Iowa comes from https://redistricting.lls.edu/wp-content/uploads/ia_2010_congress_2011-04-19_2021-12-31.zip

## Pre-processing Notes
Shape file was grouped by county to prevent county splits.

## Simulation Notes
We sample 5,000 districting plans for Iowa.
No special techniques were needed to produce the sample.
