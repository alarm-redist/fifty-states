# 2020 Louisiana State House/Senate Districts

## Redistricting requirements
In Louisiana, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in Louisiana must:

1. be contiguous [NCSL 184]
2. have equal populations [NCSL 24]
3. preserve county and municipality boundaries as much as possible [NCSL 184]
4. preserve cores of prior districts [NCSL 185]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. 
For Louisiana's upper house, to preserve the cores of prior districts, we use the previous SSDs as county-like units in the counties argument, which limits splits of prior districts during simulation.

## Data Sources
Data for Louisiana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Four zero-population placeholder VTDs missing enacted Senate assignments were manually assigned to their corresponding districts. Two adjacency bridges were also added to address disconnected components caused by water separation or VTD geometry.

For Louisiana's lower house, to preserve the cores of prior districts, reduce county splits, and improve simulation convergence,
we construct grouping units based on the 2010 SHDs, treating counties split spanning two prior districts as single units.
We use these grouping units in the counties argument for simulation.

## Simulation Notes
We sample 40,000 districting plans for Louisiana's lower house across 5 independent runs of the SMC algorithm. 
We impose Black VAP hinge and county-split constraints. We increase the number of merge-split proposals per SMC step to 885. 

We sample 10,000 districting plans for Louisiana's upper house across 5 independent runs of the SMC algorithm. 
We introduce population tempering and impose Black VAP hinge and inverse-hinge constraints. We increase the number of merge-split proposals per SMC step to 563.
