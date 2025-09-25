# ``YEAR`` ``STATE NAME`` ``TYPE``

## Redistricting requirements
In ``STATE NAME``, according to [NCSL Redistricting Law 2020](    - https://documents.ncsl.org/wwwncsl/Redistricting-Census/Redistricting-Law-2020_NCSL%20FINAL.pdf#page=204.99), legislative districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible


### Algorithmic Constraints
We enforce a maximum population deviation of X.X%.

## Data Sources
Data for ``STATE NAME`` comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample XX,XXX districting plans for ``STATE NAME``'s lower house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [delete if only 10,000 total samples].
No special techniques were needed to produce the sample.

We sample XX,XXX districting plans for ``STATE NAME``'s upper house across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 10,000 [delete if only 10,000 total samples].
No special techniques were needed to produce the sample.
