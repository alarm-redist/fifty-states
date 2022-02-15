# 2020 Kansas Congressional Districts

## Redistricting requirements
In Kansas, according to the [Kansas Legislative Research Department Guidelines and Criteria for Congressional Redistricting](http://www.kslegislature.org/li_2012/b2011_12/committees/misc/ctte_h_redist_1_20120109_01_other.pdf) districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of social, cultural, racial, ethnic, and economic interest to the extent possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Kansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan.

## Simulation Notes
We sample 5,000 districting plans for Kansas.
No special techniques were needed to produce the sample.
