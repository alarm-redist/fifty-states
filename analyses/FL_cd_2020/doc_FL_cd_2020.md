# 2020 Florida Congressional Districts

## Redistricting requirements
In Florida, according to [the state constitution Art. III §§ 20](http://www.leg.state.fl.us/statutes/index.cfm?submenu=3#A3S20), districts must:
1. not be drawn with the intent to favor or disfavor a political party or an incumbent
2. not be drawn with the intent or result of denying or abridging the electoral opportunities of racial or language minorities
(The following are required in so much as they do not impose on the above requirements)
3. be as nearly equal in population as is practicable
4. be compact
5. utilize existing political and geographical boundaries
6. preserve county and municipality boundaries as much as possible


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Florida comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for Florida's 2020 congressional district map comes from the [Dave's Redistricting](https://davesredistricting.org/maps#home)

## Pre-processing Notes
We estimate CVAP populations with the [cvap](https://github.com/christopherkenny/cvap) R package. We also pre-process the map to split it into clusters for simulation, which has a slight effect on the types of redistrict plans that will be sampled.

## Simulation Notes
We sample 160,000 districting plans for Florida across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans. Due to the size, shape, and complexity of Florida, we split the simulations into multiple steps.

1. Regional clustering
First, we cluster Florida counties into 3 regions--Southern Florida, Northern Florida, and Central Florida--with the following county assignments:

Southern Florida: Broward, Charlotte, Collier, DeSoto, Glades, Hardee, Hendry, Highlands, Lee, Manatee, Martin, Miami-Dade, Monroe, Okeechobee, Palm Beach, Sarasota, and St. Lucie

Northern Florida: Alachua, Baker, Bay, Bradford, Calhoun, Clay, Columbia, Dixie, Duval, Escambia, Franklin, Gadsden, Gilchrist, Gulf, Hamilton, Holmes, Jackson, Jefferson, Lafayette, Leon, Levy, Liberty, Madison, Marion, Nassau, Okaloosa, Putnam, Santa Rosa, St. Johns, Suwannee, Taylor, Union, Wakulla, Walton, and Washington

Central Florida: Brevard, Citrus, Flagler, Hernando, Hillsborough, Indian River, Lake, Lake, Orange, Osceola, Pasco, Pinellas, Polk, Seminole, Sumter, and Volusia

County assignments were based on the collections of counties that define Metropolitan and Combined Statistical Areas and on past and current Congressional district maps.

2. Simulating Northern and Southern Florida
We run simulations first in Northern and Southern Florida. These simulations run the SMC algorithm within each cluster with a 1.75% population tolerance. Because each cluster will have leftover population, we apply an additional constraint that encourages unassigned areas to be set on each cluster's border with the Central Florida cluster, thereby avoiding district discontiguities.

In both the Northern Florida cluster and the Southern Florida cluster, we apply Gibbs constraints to encourage the formation of Black and Hispanic opportunity districts. To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using only a county constraint.

3. Simulating Central Florida
The partial map simulations from the Southern and Northern Florida clusters are then combined, with unassigned areas being absorbed into the Central Florida cluster. We then run simulations in Central Florida, applying Gibbs hinge constraints to encourage the formation of minority opportunity districts. To limit county and municipality splits, we create pseudocounties for use in the county constraint.
