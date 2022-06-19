# 2020 Georgia Congressional Districts

## Redistricting requirements
In Georgia, districts must, under the 2021-22 Guidelines for the House Legislative and Congressional Reapportionment Committee:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. avoid the unnecessary pairing of incumbents

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Georgia comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20,000 districting plans for Georgia across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. Note that Cobb, Fulton, and Gwinnett Counties must be split due to their large populations, although within each of these counties, we avoid splitting any municipality.
We apply a hinge Gibbs constraint of strength 20 to encourage drawing the same number of majority-Black districts as the enacted plan, focusing on districts with relatively higher proportions of Black voters. We also apply a hinge Gibbs constraint of strength 10 to discourage packing of Black voters.
