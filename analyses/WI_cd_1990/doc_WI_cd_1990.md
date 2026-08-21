# 1990 Wisconsin Congressional Districts

## Redistricting requirements
In Wisconsin, there are no specific legal requirements.
We impose the following constraints. 
In our simulations, districts must:

1. be contiguous
1. have equal populations

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We add a pseudocounty constraint as described below.

## Data Sources
Data for Wisconsin comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Wisconsin across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We create pseudocounties for use in the county constraint to match norms in the state of having low county and municipality splits, despite no rules regarding this.