# 2010 California Congressional Districts

## Redistricting requirements
In California, according to the [California Constitution Article XXI](https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&division=&title=&part=&chapter=&article=XXI), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve city, county, neighborhood, and community of interest boundaries as much as possible
5. not favor or discriminate against incumbents, candidates, or parties
6. comply with the federal Voting Rights Act


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to limit the county and municipality splits. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for California comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 California enacted congressional map comes from [All About Redistricting](https://redistricting.lls.edu/state/california/?cycle=2010&level=Congress&startdate=2012-01-17). 

## Pre-processing Notes
Islands were connected to their nearest point within county on the mainland.

## Simulation Notes
We sample 25,000 districting plans in each cluster across 2 independent runs of the SMC algorithm.
We next sample 50,000 districting plans for California across 2 independent runs of the SMC algorithm for the remainder.
We then thin the sample to down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties are Alameda County, Contra Costa County, Fresno County, Kern County, Los Angeles County, Orange County, Riverside County, Sacramento County, San Bernardino County, San Diego County, San Francisco County, San Joaquin County, San Mateo County, Santa Clara County, and Ventura County, which are larger than a congressional district in population.
A small population tempering value was used for each cluster to avoid losing diversity at the final step based on initial runs.

### 1. Clustering Procedure
First, we run partial SMC in two pieces: the south and the Bay Area. The counties in each cluster are:
- South: Los Angeles, San Bernardino, Orange, Riverside, San Diego, and Imperial
- Bay: Alameda, Contra Costa, Fresno, Kings, Madera, Madera, Merced, Monterey, Sacramento, San Benito, San Francisco, San Joaquin, San Mateo, Santa Clara, Santa Cruz, Solano, Stanislaus, Tulare, and Yolo

We sample in each of these regions with a population deviation of 0.5%. We sample 28 districts in the southern region and 14 districts in the Bay Area. Because each cluster will have leftover population, we apply an additional constraint that
incentivizes leaving any unassigned areas on the edge of these clusters to
avoid discontiguities. For each cluster, we add VRA constraints encouraging Hispanic VAP and Asian VAP concentrations in districts, in line with the enacted plan.

### 2. Combination Procedure

Then, these partial map simulations are combined to run statewide simulations. We sample 11 districts in the remainder.
