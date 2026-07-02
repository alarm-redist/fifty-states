# 2010 Michigan Congressional Districts

## Redistricting requirements
in Michigan, according to [Article IV, Section 6](http://www.legislature.mi.gov/(S(xxvumgge0jwzkeswmwt0bh4v))/mileg.aspx?page=GetObject&objectname=mcl-Article-IV-6) of the state constitution, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. cannot favor/disfavor incumbents


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to help preserve county and municipality boundaries, as described below.
We add hinge constraints to encourage a minority-opportunity district with minority (non-white) voting-age population above 52%, while discouraging minority VAP below 30% and above 62% to limit packing, in line with the Voting Rights Act.

## Data Sources
Data for Michigan comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 16,000 districting plans for Michigan across two independent runs of the SMC algorithm and then thinned our results to 5,000 simulations.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Wayne County, Oakland County, and Macomb County must all be split due to their large populations, although within the counties, we avoid splitting any municipality.
