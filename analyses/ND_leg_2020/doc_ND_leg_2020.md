# 2020 North Dakota State House/Senate Districts

## Redistricting requirements
In North Dakota, we consult [NCSL Redistricting Law 2020](https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf). State legislative districts in North Dakota must:

1. be contiguous [NCSL186]
1. have equal populations [NCSL 24]
1. be geographically compact [NCSL 186]
1. House nested in Senate or Congress [NCSL 187]

([N.D. Century Code § 54-03-01.14](https://ndlegis.gov/cencode/t54c03.pdf#nameddest=54-03-01p14): "Each legislative district is entitled to one senator and two representatives. Districts 4 and 9
are divided into subdistricts, and one representative must be elected from each subdistrict.")

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for North Dakota comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
One VTD exceeded the population limit for a simulation unit, and several VTDs crossed enacted SSD or SHD boundaries. We use 2020 Census blocks and block assignment files to divide these VTDs and create a common geography for the nested simulations. 
We also divide VTDs along the Fort Berthold Reservation boundary and merge the reservation pieces into a single SSD sampling unit. This helps better represent the AIAN VAP distribution associated with enacted District 4A.

## Simulation Notes
We sample 25,000 districting plans for North Dakota's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
We impose total county- and municipality- constraints, Polsby-Popper compactness constraint, and increase the number of merge-split proposals per SMC step (136).

We use the top-down nested procedure to sample North Dakota's lower house districts.
For each of the 25,000 sampled Senate plans, we run 50 inner SMC simulations within simulated Senate District 4 and another 50 within simulated Senate District 9. One successful split is retained for each district. The remaining 45 simulated Senate districts are carried forward as two-member House districts without an additional inner simulation.
17,636 districting plans remaining in the surviving sample.
We then thinned the number of samples to 10,000.
