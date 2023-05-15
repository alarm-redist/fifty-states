# 2010 Kansas Congressional Districts

## Redistricting requirements
In Kansas, under the [Guidelines And Criteria For 2012 Kansas Congressional And Legislative Redistricting](https://web.archive.org/web/20160128190356/http://www.kslegislature.org/li_2012/b2011_12/committees/misc/ctte_h_redist_1_20120109_01_other.pdf) districts must:

1. be contiguous (5)
1. have equal populations (2)
1. be geographically compact (5)
1. preserve county and municipality boundaries as much as possible (4c)
1. preserve communities of interest (4a)
1. preserve cores of existing districts (4b)
1. be built primarily from counties and VTDs (1)


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Kansas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan. Precincts in counties which are split by existing district boundaries are merged only within their county.

## Simulation Notes
We sample 5,000 districting plans for Kansas across four independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
