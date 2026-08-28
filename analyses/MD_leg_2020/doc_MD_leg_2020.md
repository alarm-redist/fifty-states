# 2020 Maryland State House/Senate Districts

## Redistricting requirements
In Maryland, state legislative districts must, under [Article III of the Maryland Constitution](https://msa.maryland.gov/msa/mdmanual/43const/html/03art3.html):

1. consist of adjoining territory (§ 4)
2. be compact in form (§ 4)
3. be of substantially equal population (§ 4)
4. give due regard to natural boundaries and the boundaries of political subdivisions (§ 4)
5. contain one senator and three delegates. A legislative district may be subdivided into three single-member delegate districts or one single-member delegate district and one multi-member delegate district (§ 2-3).

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Maryland comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We edited the adjacency graph to prevent districts from crossing the Bay. 
Bay water precincts were reconnected to nearby same-side precincts, remaining cross-Bay edges were removed, and necessary land and island connections were restored to preserve enacted-district contiguity.

## Simulation Notes
We sample 32,500 districting plans for Maryland's upper house across 5 independent runs of the SMC algorithm. 
We then thinned the number of samples to 10,000. 
We impose total county constraints and increase the number of merge-split proposals per SMC step to 96.

We use the top-down nested procedure to sample Maryland's lower house districts. 
Because the Constitution permits delegate districts electing one, two, or three members, we follow the subdivision structure of the enacted plan within each simulated Senate district.
For each of the 32,500 sampled Senate plans, we run 50 inner SMC simulations within each of the 18 Senate districts that are subdivided under the enacted plan and retain one successful split per district. 
Of these, 6 Senate districts (1, 27, 29, 33, 38, 42) are divided into three single-member House districts, and the other 12 (2, 7, 9, 11, 12, 30, 34, 35, 37, 43, 44, 47) are divided into one single-member pieces, after which a randomly selected adjacent pair is combined to form one two-member district.
The remaining 29 Senate districts are carried forward as three-member House districts without an additional inner simulation. 
11,801 districting plans remain in the surviving sample.
We then thinned the number of samples to 10,000.
