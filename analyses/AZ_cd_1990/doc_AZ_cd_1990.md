# 1990 Arizona Congressional Districts

## Redistricting requirements
We use the redistricting criteria established by the federal court in Arizonans for [Fair Representation v. Symington (1992), which governed Arizona’s 1990s congressional plan](https://law.justia.com/cases/federal/district-courts/FSupp/828/684/2352036/).

In Arizona, districts should: 

1. be contiguous
1. have nearly equal populations
1. be geographically compact
1. preserve communities of interest and city and county boundaries as much as practicable; and
1. comply with the Voting Rights Act.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
To operationalize the preservation of local administrative geography, we construct pseudocounties and pass them to the `counties` argument of the SMC algorithm.
We also use Hispanic voting-age-population hinge constraints to encourage the simulation to generate a district with a comparatively high Hispanic VAP.

## Data Sources
Data for Arizona comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing was required. We use predefined pseudocounties in the county constraint and penalize splits of county–municipality units.

## Simulation Notes
We use a two-stage SMC procedure. First, we generate 30,000 preliminary plans under a stronger Hispanic-VAP constraint and randomly select 4,000 as initial particles. We then sample 20,000 plans across five independent runs and retain 1,000 plans from each run, producing a final ensemble of 5,000 plans.
