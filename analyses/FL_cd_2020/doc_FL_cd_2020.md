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
We sample 192,000 districting plans for Florida across 16 independent runs of the SMC algorithm.
We keep the first 1,000 plans from each run, then randomly thin the sample to 5,000 plans, with 312 or 313 plans from each run.
We use merge-split steps after each SMC step, targeting 80 accepted merge-split moves, to improve mixing.
We add VRA constraints encouraging Black VAP and Hispanic VAP opportunity districts.
To balance county and municipality splits, we create pseudocounties for use in the county constraint.
