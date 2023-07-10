# 2010 Florida Congressional Districts

## Redistricting requirements
In Florida, per Art. III, sec. 20 of the [state constitution](http://www.leg.state.fl.us/Statutes/index.cfm?Mode=Constitution&Submenu=3#A3S16), districts must:

1. may not favor or disfavor political parties or incumbents 
2. may not be drawn with the intent or result of denying or diluting minority representation 
3. must be contiguous 
4. must be compact 
5. must be equal in population as practicable 
6. and, must utilize, where feasible, existing political and geographical boundaries.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. 

## Data Sources
Data for Florida comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). We obtain the 2010 Florida Congressional map from [All About Redistricting](https://redistricting.lls.edu/state/florida/?cycle=2010&level=Congress&startdate=2012-04-30).

## Pre-processing Notes
We estimate CVAP populations with the [cvap](https://github.com/christopherkenny/cvap) R package.

## Simulation Notes

We sample 35,000 districting plans for the full state of Florida, thinned down to a set of 7,500. To appropriately district the entire state, we split the state into three regions, simulate two of the regions (North and the Miami area, as defined below) separately, and then simulate districts in the remainder of the state. In all simulations, we constrain county and municipality splits. Since some county populations are greater than the target population for one Congressional district, we create pseudocounties where needed.

**Regional clustering:** We split Florida into the following three regions:

1. Miami metropolitan area, consisting of Miami-Dade and Broward Counties.
2. Northern Florida, consisting of Alachua County, Baker County, Bay County, Bradford County, Calhoun County, Citrus County, Clay County, Columbia County, Dixie County, Duval County, Escambia County, Flagler County, Franklin County, Gadsden County, Gilchrist County, Gulf County, Hamilton County, Holmes County, Jackson County, Jefferson County, Lafayette County, Leon County, Levy County, Liberty County, Madison County, Marion County, Nassau County, Okaloosa County, Putnam County, St. Johns County, Santa Rosa County, Sumter County, Suwannee County, Taylor County, Union County, Volusia County, Wakulla County, Walton County, and Washington County.
3. Central Florida, composed of Brevard County, Charlotte County, Collier County, DeSoto County, Glades County, Hardee County, Hendry County, Hernando County, Highlands County, Hillsborough County, Indian River County, Lake County, Lee County, Manatee County, Martin County, Monroe County, Okeechobee County, Orange County, Osceola County, Palm Beach County, Pasco County, Pinellas County, Polk County, St. Lucie County, Sarasota County, and Seminole County.

We simulate the Miami metropolitan area and Northern Florida independently. Since each cluster has leftover population, we include a constraint to encourage unassigned precincts to be set along each cluster's boundary with Central Florida so those precincts can be assigned to contiguous districts in the final simulation step.

**Simulating Miami:** We simulate four SMC runs with 60,000 maps each for the Miami metropolitan area. To encourage Black and Hispanic opportunity districts, we apply Gibbs constraints in the simulation. We then subset down the plans to those where there exists one district with a Black voting-age population (BVAP) share of at least .4 and another district with a BVAP share of at least .25. From this set, we randomly sample 35,000 plans.

**Simulating Northern Florida:** We simulate two SMC runs with 40,000 maps each for Northern Florida. To encourage Black and Hispanic opportunity districts, we apply Gibbs constraints in the simulation. We then subset down the plans to those where at least one district has a BVAP share of .25 or greater. From this set, we randomly sample 35,000 plans.

**Simulating Central Florida:** Using the unassigned areas from the partial SMC simulations for Miami and Northern Florida, we simulate two SMC runs with 35,000 plans each for Central Florida. We apply Gibbs constraints to encourage Black and Hispanic opportunity districts. We then thin these maps down to the final set of 5,000.
