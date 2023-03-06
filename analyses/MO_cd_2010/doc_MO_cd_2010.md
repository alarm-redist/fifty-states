# 2010 Missouri Congressional Districts

## Redistricting requirements
In Missouri, according to [Mo. Const. art. III, § 2](https://redistricting.lls.edu/wp-content/uploads/MO-2000-constitution.pdf#page=26), districts must:
1. be contiguous
1. have equal populations
1. be geographically compact

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use a standard algorithmic county constraint. We add a hinge Gibbs constraint targeting one majority-minority district to comply with VRA requirements and match the number in the enacted plan.

## Data Sources
Data for Missouri comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Missouri across two independent runs of the SMC algorithm.
