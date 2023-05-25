# 2010 Alabama Congressional Districts

## Redistricting requirements
In Alabama, according to [Article IX of the Constitution Of Alabama 1901](http://alisondb.legislature.state.al.us/alison/codeofalabama/constitution/1901/constitution1901_toc.htm), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. preserve communities of interest as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a hinge Gibbs constraint targeting the same number of majority-minority districts as the enacted plan.

## Data Sources
Data for Alabama comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 Alabama enacted congressional map comes from [All About Redistricting](https://redistricting.lls.edu/state/alabama/?cycle=2020&level=Congress&startdate=2021-11-04).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20,000 districting plans for Alabama across two independent runs of the SMC algorithm. We set population temperance at 0.05 to avoid bottlenecks. We remove all plans that do not have any district that has BVAP of over 30% and a majority Democratic average vote share, in order to maintain similar standards as the enacted plan. Such plans comprise less than 2% of the original simulation sample. We then thin the sample to down to 5,000 plans.
