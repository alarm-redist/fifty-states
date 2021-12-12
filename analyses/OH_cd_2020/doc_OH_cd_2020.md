# 2020 Ohio Congressional Districts

## Redistricting requirements
In Ohio, districts must, under [Article XIX of the Ohio Constituion](https://www.legislature.ohio.gov/laws/ohio-constitution/article?id=19):

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. not split Cincinnati or Cleveland
1. minimize splitting of Columbus
1. split no more than 18 counties once, and no more than 5 counties twice, and no counties three times


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We employ a variety of anti-split constraints, both in pre-processing and in simulation, as detailed below.
Ohio also has one VRA district in Cuyahoga county.

## Data Sources
Data for Ohio comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We merge the precincts all counties which are not split by the enacted plan.
We merge the cities of Cincinnati and Cleveland.

## Simulation Notes
We sample 5,000 districting plans for Ohio.
We begin by sampling plans in Cuyahoga county to generate a VRA district with BVAP at least 40%. Then we sample the remaining districts.
We apply a Gibbs constraint to discourage multiple splits (a penalty of 100.0 for 3 splits, and 3.0 for 2 splits)
We apply a Gibbs constraint to discourage splitting Columbus (a penalty of 0.5 per spliting district)
We use population tempering of 0.01 to encourage efficiency.
