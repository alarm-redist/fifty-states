# 2020 California Congressional Districts

## Redistricting requirements
In California, under [Article XXI](https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&division=&title=&part=&chapter=&article=XXI), districts must:

1. be contiguous (2d3)
1. have equal populations (2d1) 
1. be geographically compact (2d5)
1. preserve city, county, neighborhood, and community of interest boundaries as much as possible (2d4)
1. not favor or discriminate against incumbents, candidates, or parties (2e)
1. comply with the Voting Rights Act (2d2)


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We add a pseudo-county constraint, as described below. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for California comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Islands were connected to their nearest point within county on the mainland.

## Simulation Notes
We sample 10,000 statewide candidate districting plans for California across
five independent linking-edge merge-split SMC runs, then keep the first 1,000
plans from each run for a 5,000-plan ensemble. This replaces the prior South
California / Bay Area partial-SMC workflow with a statewide workflow matching
the newer convergent California simulations used for 1990, 2000, and the
Callais 2020 run.

The simulation keeps the VRA hinge constraints from the prior regional workflow:
Hispanic VAP concentration constraints from the Southern California stage, and
Hispanic and Asian VAP concentration constraints from the Bay Area stage. To
balance county and municipality splits, we continue to create pseudocounties for
use in the county constraint. These are Alameda County, Contra Costa County,
Fresno County, Kern County, Los Angeles County, Orange County, Riverside County,
Sacramento County, San Bernardino County, San Diego County, San Francisco
County, San Joaquin County, San Mateo County, Santa Clara County, and Ventura
County, which are larger than a congressional district in population.
