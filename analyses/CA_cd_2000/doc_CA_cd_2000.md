# 2000 California Congressional Districts

## Redistricting requirements
In ``California``, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), districts must:

1. be contiguous
1. have equal populations
1. preserve city, county, neighborhood, and community of interest boundaries as much as possible

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to limit the county and municipality splits. We add VRA constraints encouraging Hispanic VAP and Asian VAP majorities in districts.

## Data Sources
Data for ``California`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
We reallocated the population and voting data from two offshore precincts, which left the adjacency graph disconnected even after linking them to mainland neighbors, to their nearest mainland precincts, and dropped them from the adjacency graph to ensure both statistical integrity and topological contiguity.

## Simulation Notes
We sample 200 districting plans in each cluster across 5 independent runs of the SMC algorithm.
We next sample 5,000 districting plans for California across 5 independent runs of the SMC algorithm for the remainder.
To balance county and municipality splits, we create pseudocounties for use in the county constraint. 

### 1. Clustering Procedure
First, we run partial SMC in two pieces: the south and the Bay Area. The counties in each cluster are:
- South: Los Angeles, San Bernardino, Orange, Riverside, San Diego, and Imperial
- Bay: Alameda, Contra Costa, Fresno, Kings, Madera, Madera, Merced, Monterey, Sacramento, San Benito, San Francisco, San Joaquin, San Mateo, Santa Clara, Santa Cruz, Solano, Stanislaus, Tulare, and Yolo

We sample in each of these regions with a population deviation of 0.5%. We sample 30 districts in the southern region and 15 districts in the Bay Area. Because each cluster will have leftover population, we apply an additional constraint that
incentivizes leaving any unassigned areas on the edge of these clusters to avoid discontiguities. For each cluster, we add VRA constraints encouraging Hispanic VAP and Asian VAP concentrations in districts, in line with the enacted plan.

### 2. Combination Procedure
Then, these partial map simulations are combined to run statewide simulations. The statewide run fills in the remainder of the state’s 53 districts.