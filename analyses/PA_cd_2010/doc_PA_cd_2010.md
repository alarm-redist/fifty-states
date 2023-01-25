# 2010 Pennsylvania Congressional Districts

## Redistricting requirements
In Pennsylvania, districts must generally:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible

We use a (pseudo-)county constraint to preserve boundaries as much as possible.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Pennsylvania comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Pennsylvania over two independent runs of the SMC algorithm, and thin the total 20,000 plans down to 5,000. Pseudo-counties for the county constraint are generated for Allegheny, Montgomery, and Philadelphia counties, as they have more residents than a district's population.

No special techniques were needed to produce the sample.
