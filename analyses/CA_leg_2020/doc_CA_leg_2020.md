# 2020 California State House/Senate Districts

## Redistricting requirements
In California, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in California must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve political subdivisions
5. preserve communities of interest
6. not favor the incumbent
7. not favor party
8. have House nested in Senate or Congress

Note: California is a state whose constitution encourages (though does not strictly require)
simple nesting, and simple nesting does not occur. However, house and senate
districts may follow the same lines more frequently than otherwise.

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for California comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Block data was downloaded for California's redistricting data file. The data was grouped
by the first 11 characters of the GEOID (tract ID) to get tract sums.

Manual adjacency edits were made to connect precincts 7296 and 3443 with mainland California.
According to the [state of California](https://wedrawthelines.ca.gov/faqs/), "Actual islands
are to be considered connected to the nearest land mass." For the manual adjacency edits made in this 
analysis, reference was made to [California's congressional analysis](https://github.com/alarm-redist/fifty-states/blob/main/analyses/CA_cd_2020/01_prep_CA_cd_2020.R).

## Simulation Notes
We sample 15,000 districting plans for California's lower house across 5 independent 
runs of the SMC algorithm. We introduce a total county splits constraint of strength 1.5 
and increase the number of merge-split proposals per SMC step to 177 total. The ncores 
argument in redist_smc() was set to 0.


We sample 15,000 districting plans for California's upper house across 5 independent 
runs of the SMC algorithm. We introduce a total county splits constraint of strength 1 
and increase the number of merge-split proposals per SMC step to 64 total. The ncores 
argument in redist_smc() was set to 0.
