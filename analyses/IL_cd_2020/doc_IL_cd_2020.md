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
We sample 20,000 districting plans for Illinois across two independent runs of the SMC algorithm, and then thin the sample down to 5,000 plans.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint. These are counties outside of Cook County and DuPage County. Within Cook County and DuPage County, each municipality is its own pseudocounty as well. Cook County and DuPage County were chosen since they are necessarily split by congressional districts.
To comply with the federal VRA and to respect communities of interest, we add hinge constraints of strength 20 targeting one majority-Black district (IL-01) and one majority-Hispanic district (IL-04).
