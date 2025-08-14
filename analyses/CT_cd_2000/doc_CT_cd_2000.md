# 2000 Connecticut Congressional Districts

## Redistricting requirements
In Connecticut, according to [NCSL Redistricting Law 2000](https://web.archive.org/web/20041216185957/https://www.senate.mn/departments/scr/redist/red2000/Tab5appx.htm), there are no state law requirements for congressional districts, other than that they must be consistent with federal standards; districts must:

1. be contiguous
1. have equal populations
1. be geographically compact

Senatorial and assembly districts must:

1. preserve county and municipality boundaries as much as possible

Additionally, the 1982 Connecticut Supreme Court's holding in [JOHN J. LOGAN V. WILLIAM A. O’NEILL & JOHNSON V. O’NEILL](https://www.cga.ct.gov/red2011/documents/CASESUM/2011CASESUM-20110426_OLR%20Report%20Court%20Challenges%20to%20Connecticut%20Redistricting%20Plans.pdf) states that challengers must demonstrate that town lines were cut for reasons other than:

1. to meet the federal equal population requirement
1. the plan was not the best judgment in harmonizing conflicting constitutional requirements 

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
We use a pseudo-county constraint described below which attempts to mimic the norms in Connecticut of generally preserving county and municipal boundaries (i.e., the "town integrity principle" in CT).

## Data Sources
Data for Connecticut comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Connecticut across 5 independent runs of the SMC algorithm.
We then thinned the number of samples to 5,000. 
We use a pseudo-county constraint to limit county and municipality splits.
No special techniques were needed to produce the sample.
