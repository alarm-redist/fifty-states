# 2010 Washington Congressional Districts

## Redistricting requirements
In Washington, districts must according to [RCW 44.05.090](https://app.leg.wa.gov/RCW/default.aspx?cite=44.05.090):

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. not be connected across geographic barriers, although ferries across water may establish contiguity
6. "provide fair and effective representation and ... encourage electoral competition"

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. 
To reflect the barriers and contiguity requirements, we remove edges across water regions and mountains in the adjacency graph, but reconnect precincts which are linked by a bridge, highway, or ferry.

## Data Sources
Data for Washington comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
As described above, the adjacency graph was modified by hand to reflect Washington's contiguity requirements. The full list of these changes can be found in the '01_prep_WA_cd_2010.R' file.

## Simulation Notes
We sample 13,000 districting plans for Washington using the SMC algorithm and thinned the samples down to 5,000. To comply with the federal VRA and to respect communities of interest, we add a weak VRA constraint targeting one majority-minority district (currently WA-09).
To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of King County, Pierce County, and Snohomish County. Within King County, Pierce County, and Snohomish County, each municipality is its own pseudocounty as well. King County, Pierce County, and Snohomish County were chosen since they are necessarily split by congressional districts.
