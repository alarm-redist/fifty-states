# 2020 Kansas Congressional Districts

## Redistricting requirements
In Kansas, according to the [Proposed Guidelines and Criteria for 2022 Kansas Congressional Redistricting](https://redistricting.lls.edu/wp-content/uploads/KS-Proposed-redistricting-guidelines.pdf) districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve the cores of existing districts
6. preserve communities of social, cultural, racial, ethnic, and economic interest to the extent possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. We add a county constraint.

## Data Sources
Data for Kansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2022 Kansas enacted congressional map comes from the [American Redistricting Project](https://thearp.org/state/kansas/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan.
Precincts in counties which are split by existing district boundaries are merged only within their county.

## Simulation Notes
We sample 5,000 districting plans for Kansas across two independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
