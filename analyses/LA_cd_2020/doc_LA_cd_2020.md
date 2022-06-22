# 2020 Louisiana Congressional Districts

## Redistricting requirements
In Louisiana, according to [Louisiana Joint Rule No. 21](https://www.legis.la.gov/Legis/Law.aspx?d=1238755) districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve parish and municipality boundaries as much as possible
5. preserve the cores of traditional district alignments


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. We add a VRA constraint targeting one majority-minority district.

## Data Sources
Data for Louisiana comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border, under the 2010 plan.

## Simulation Notes
We sample 16,000 districting plans for Louisiana across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans. To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.
