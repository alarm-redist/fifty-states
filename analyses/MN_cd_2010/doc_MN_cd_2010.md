# 2010 Minnesota Congressional Districts

## Redistricting requirements
In Minnesota, districts must:

1. be contiguous
2. have equal populations
3. comply with VRA section 2
4. be geographically compact
5. preserve political subdivisions and communities of interest as possible 
6. avoid pairing incumbents but also cannot give unfair advantage to incumbents (least important criteria)

https://www.mncourts.gov/mncourtsgov/media/CIOMediaLibrary/2011Redistricting/A110152Order11-4-11.pdf

### Interpretation of requirements
We do not adhere to all criteria in the guidelines. We include the following constraints:

1. We enforce a maximum population deviation of 0.5%. 
2. We use a pseudo-county constraint to help preserve county and municipality boundaries.

## Data Sources
Data for Minnesota comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Minnesota across two independent runs of the SMC algorithm. To balance county and municipality splits, we create pseudocounties for use in the county constraint. These are counties, outside of Dakota County, Hennepin County, Ramsey, which are the counties with populations larger than 60% the target population for districts. Within Allegheny County, Montgomery County, and Philadelphia County, each municipality is its own pseudocounty as well. 
