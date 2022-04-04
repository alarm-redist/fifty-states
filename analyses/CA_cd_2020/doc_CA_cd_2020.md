# 2020 California Congressional Districts

## Redistricting requirements
In California, under [Article XXI](https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&division=&title=&part=&chapter=&article=XXI), districts must:

1. be contiguous (2d3)
1. have equal populations (2d1) 
1. be geographically compact (2d5)
1. preserve city, county, neighborhood, and community of interest boundaries as much as possible (2d4)
1. not favor or discriminate against incumbents, candidates, or parties (2e)
1. comply with the Voting Rights Act (2d2)


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. We add a pseudo-county constraint, as described below. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for California comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Islands were connected to their nearest point within county on the mainland.

## Simulation Notes
We sample 5,000 districting plans for California. To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties are Alameda County, Contra Costa County, Fresno County, Kern County, Los Angeles County, Orange County, Riverside County, Sacramento County, San Bernardino County, San Diego County, San Francisco County, San Joaquin County, San Mateo County, Santa Clara County, and Ventura County, which are larger than a congressional district in population.

### 1. Clustering Procedure
First, we run partial SMC in two pieces: the south and the Bay Area. The counties in each cluster are:

* Los Angeles, San Bernardino, Orange, Riverside, San Diego, and Imperial

* Alameda, Contra Costa, Fresno, Kings, Madera, Madera, Merced, Monterey, Sacramento, San Benito, San Francisco, San Joaquin, San Mateo, Santa Clara, Santa Cruz, Solano, Stanislaus, Tulare, and Yolo

We sample in each of these regions with a population deviation of 0.5%. We sample 27 districts in the southern region and 15 districts in the Bay Area. Because each cluster will have leftover population, we apply an additional constraint that
incentivizes leaving any unassigned areas on the edge of these clusters to
avoid discontiguities. For each cluster, we add VRA constraints encouraging Hispanic VAP and Asian VAP concentrations in districts, in line with the enacted plan.

### 2. Combination Procedure
Then, these partial map simulations are combined to run statewide simulations. We sample 10 districts in the remainder.
