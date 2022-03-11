# 2020 Wisconsin Congressional Districts

## Redistricting requirements
In Wisconsin, districts must:

1. have equal populations
2. retain cores of existing districts

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a county/municipality constraint as described below.
Due to the WI Supreme Court ruling in [Johnson v. Wisconsin Elections Commission](https://www.wicourts.gov/sc/opinion/DisplayDocument.pdf?content=pdf&seqNo=459269), we retain the cores of existing districts and apply a status quo constraint, as described below.

## Data Sources
Data for Wisconsin comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We use a hybrid boundary-2 cores constraint, based on the 2010 map. Any VTDs more than 2 VTD from the boundary are frozen as a core. Pseudocounties which contain any of the non-frozen VTDs are frozen into remainder portions, separate from their district core. This avoids adding additional county splits. For the pseudocounties used in freezing cores, municipality lines are used within Milwaukee County, which is larger than a congressional district in population.

## Simulation Notes
We sample 5,000 districting plans for Wisconsin.
We use municipalities for use in the county constraint (or counties if a VTD is not assigned to a municipality) to match norms in the state of having low county and municipality splits, despite no rules regarding this. 
We use a status quo constraint to encourage simulated plans to be similar to the 2010 map.
We use a weak county split Gibbs constraint to keep county splits comparable to the enacted map.
