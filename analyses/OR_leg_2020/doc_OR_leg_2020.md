# 2020 Oregon State House/Senate Districts

## Redistricting requirements
In Oregon, districts must, under [Or. Rev. Stat. § 188.010](https://www.oregonlegislature.gov/bills_laws/ors/ors188.html):

1. be contiguous
1. have equal populations
1. utilize existing geographic or political boundaries
1. not divide communities of common interest
1. be connected by transportation links
1. not favor any political party, incumbent legislator or other person
1. not dilute the voting strength of any language or ethnic minority group
1. have House districts nested inside Senate districts

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.
To reflect the transportation links constraint, we remove edges in the adjacency graph for counties not connected by a state or federal highway.

## Data Sources
Data for Oregon comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Oregon does not submit precinct boundaries to the Census Bureau, so the base shapefile consists of census tracts.
As described above, counties not linked by a state or federal highway were manually disconnected.
The full list of these counties can be found in the `01_prep_OR_leg_2020.R` file.

## Simulation Notes
We sample 55,000 districting plans for Minnesota's upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000.
We increase the number of merge-split proposals per SMC step (30).

We use the top-down nested procedure to sample Minnesota's lower house districts, with 50 inner-simulations for each of the 55,000 upper house districts.
11,373 districting plans remain in the surviving sample.
We then thinned the number of samples to 10,000.
