# 1990 Arkansas Congressional Districts

## Redistricting requirements
In ``Arkansas``, according to [HOUSE CONCURRENT RESOLUTION](https://arkleg.state.ar.us/Home/FTPDocument?path=%2FBills%2F1991%2FPublic%2FHCR1006.pdf#:~:text=17%20as%20little%20as%20possible,be%2021%20maintained%2C%20if%20possible), districts should:

1. be contiguous
1. have equal populations
1. maintain counties, cities, and established geographical boundaries, if possible
1. not dilute the voting strength of minority citizens

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We apply a stronger county constraint, which is in line with the small number or absence of county splits observed in past congressional district maps.

## Data Sources
Data for ``Arkansas`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for ``Arkansas`` across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a stronger algorithmic county constraint to limit the number of county splits.