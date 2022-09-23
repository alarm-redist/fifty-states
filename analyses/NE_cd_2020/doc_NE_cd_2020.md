# 2020 Nebraska Congressional Districts

## Redistricting requirements
In Nebraska, districts must, under a [legislative resolution](https://nebraskalegislature.gov/FloorDocs/107/PDF/Intro/LR134.pdf):

1. be contiguous
1. have equal populations (specifically, within 0.5% of equality)
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. preserve the cores of prior districts
1. not be drawn using partisan information


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We apply a county constraint.
We preprocess the map to ensure the cores of prior districts are preserved, as described below.

## Data Sources
Data for Nebraska comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan.
Precincts in counties which are split by existing district boundaries are merged only within their county.

## Simulation Notes
We sample 5,000 districting plans for Nebraska across four independent runs of the SMC algorithm.
In addition to a county constraint applied to the residual counties left over from the cores operation, we apply an additional Gibbs constraint of strength 2 to avoid splitting counties.
