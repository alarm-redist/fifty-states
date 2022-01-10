# 2020 Georgia Congressional Districts

## Redistricting requirements
In Georgia, districts must, under the 2021-22 State House and Senate Reapportionment Committee guidelines:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve county and municipality boundaries as much as possible
5. "efforts should be made to avoid the unnecessary pairing of incumbents"

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Georgia comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Georgia.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.
We apply a hinge Gibbs constraint of strength 20 to encourage drawing majority black districts.
