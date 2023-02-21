# 2010 Oregon Congressional Districts

## Redistricting requirements
In Oregon, according to [Or. Rev. Stat. § 188.010](https://www.oregonlegislature.gov/bills_laws/archive/2011ors188.pdf) of the state constitution, districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. be connected by transportation links
5. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a pseudo-county constraint to help preserve county and municipality boundaries, as described below.

## Data Sources
Data for Oregon comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Oregon does not submit precinct boundaries to the Census Bureau. The base shapefile consists of tracts, but where tracts are split by the enacted congressional districts, we create separate sub-tracts. As described above, counties not linked by a state or federal highway were manually disconnected. The full list of these counties can be found in the '01_prep_OR_cd_2010.R' file.

## Simulation Notes
We sample 5,000 districting plans for Oregon across two independent runs of the SMC algorithm. To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of Multnomah county. Within Multnomah county, each municipality is its own pseudocounty as well. Multnomah county were chosen since it is necessarily split by congressional districts.
