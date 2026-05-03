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
We sample 10,000 statewide candidate districting plans for Florida across five
independent linking-edge merge-split SMC runs, then keep the first 1,000 plans
from each run for a 5,000-plan ensemble. This replaces the prior Miami/South,
North, and Central Florida partial-SMC workflow with a statewide workflow
matching the newer convergent Florida simulations used for 2000 and 2020.

The simulation keeps the VRA hinge constraints from the prior regional workflow:
Black and Hispanic CVAP opportunity constraints from the South and North Florida
stages, plus the statewide remainder constraints used to encourage Black and
Hispanic opportunity districts. To balance county and municipality splits, we
continue to create pseudocounties for use in the county constraint.
