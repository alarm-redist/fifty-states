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


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Florida comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for Florida's 2020 congressional district map comes from the [Dave's Redistricting](https://davesredistricting.org/maps#home)

## Pre-processing Notes
We estimate CVAP populations with the [cvap](https://github.com/christopherkenny/cvap) R package.

## Simulation Notes
We sample 10,000 statewide candidate districting plans for Florida across five
independent linking-edge merge-split SMC runs, then keep the first 1,000 plans
from each run for a 5,000-plan ensemble. This replaces the prior Southern,
Northern, and Central Florida partial-SMC workflow with a statewide workflow
matching the newer convergent Florida simulations used for 2000 and the Callais
2020 run.

The simulation keeps the VRA hinge constraints from the prior regional workflow:
Black and Hispanic VAP opportunity constraints from the South and North Florida
stages, plus the statewide remainder constraints used to encourage Black and
Hispanic opportunity districts. To balance county and municipality splits, we
continue to create pseudocounties for use in the county constraint.
