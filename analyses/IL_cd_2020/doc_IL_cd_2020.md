# 2020 Illinois Congressional Districts

## Redistricting requirements
In Illinois, districts must, under Ill. Const. Art. IV, § 3:

1. be contiguous
2. have equal populations
3. be geographically compact

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Illinois comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Illinois.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.
