# 2020 Florida Congressional Districts

## Redistricting requirements
In Florida, according to [the state constitution Art. III §§ 20](http://www.leg.state.fl.us/statutes/index.cfm?submenu=3#A3S20), districts must:
1. not be drawn with the intent to favor or disfavor a political party or an incumbent
2. not be drawn with the intent or result of denying or abridging the electoral opportunities of racial or language minorities
(The following are required so much as they do not impose on the above requirements)
3. be as nearly equal in population as is practicable
4. be compact
5. utilize existing political and geographical boundaries
6. preserve county and municipality boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.05%.

## Data Sources
Data for Florida comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for Florida's 2020 congressional district map comes from the [Florida Redistricting website](https://www.floridaredistricting.gov/pages/submitted-plans)

## Pre-processing Notes
We estimate CVAP populations with the [cvap](https://github.com/christopherkenny/cvap) R package. We also pre-process the map to split it into clusters for simulation, which has a slight effect on the types of redistrict plans that will be sampled.

## Simulation Notes
We sample 5,000 districting plans for Florida. Due to the size, shape, and complexity of Florida, we split the simulations into multiple steps.

1. Regional clustering
First, we cluster Florida counties into 3 regions: Southern Florida, Northern Florida, and Central Florida, with the following regional clusters:

Southern Florida: Broward County, Charlotte County, Collier County, DeSoto County, Glades County, Hardee County, Hendry County, Highlands County, Lee County, Manatee County, Martin County, Miami-Dade County, Monroe County, Okeechobee County, Palm Beach County, Sarasota County,  and St. Lucie County

Northern Florida: Alachua County, Baker County, Bay County, Bradford County, Calhoun County, Clay County, Columbia County, Dixie County, Duval County, Escambia County, Franklin County, Gadsden County, Gilchrist County, Gulf County, Hamilton County, Holmes County, Jackson County, Jefferson County, Lafayette County, Leon County, Levy County, Liberty County, Madison County, Marion County, Nassau County, Okaloosa County, Putnam County, Santa Rosa County, St. Johns County, Suwannee County, Taylor County, Union County, Wakulla County, Walton County, and Washington County

Central Florida: Brevard County, Citrus County, Flagler County, Hernando County, Hillsborough County, Indian River County, Lake County, Lake County, Orange County, Osceola County, Pasco County, Pinellas County, Polk County, Seminole County, Sumter County, and Volusia County

Clusters were based on the collections of counties that define Metropolitan and Combined Statistical Areas and on past and current Congressional district maps.

2. Simulating Northern and Southern Florida
We run simulations first in Southern and Northern Florida. These simulations run the SMC algorithm within each cluster with a 0.5% population tolerance. Because each cluster will have leftover population, we apply an additional constraint that encourages unassigned areas to be set on the cluster's border with the Central Florida cluster, thereby avoiding discontiguities.

In each cluster, we apply hinge Gibbs constraints of strength 25 to strongly encourage the formation of Black CVAP opportunity districts, and a hinge Gibbs constraint of strength 2 to weakly encourage the formation of Hispanic CVAP opportunity districts. 

To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using only a county constraint.

3. Simulating Central Florida
The partial map simulations from the Southern and Northern Florida clusters are then combined, with unassigned areas being absorbed into the Central Florida cluster. We then run simulations in Central Florida, again applying the Gibbs hinge constraints to encourage the formation of minority opportunity districts, though with weaker strength since most of these districts are found in the Northern and Southern clusters. To limit county and municipality splits, we again create pseudocounties for use in the county constraint.
