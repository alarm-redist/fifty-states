# 1990 Washington Congressional Districts

## Redistricting requirements
In Washington, according to [State Constitution, Article II, Section 43, as adopted by Amendment 74 in 1983](https://apps.leg.wa.gov/billsummary/?BillNumber=4409&Year=2011&Initiative=false), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact and convenient
1. respect natural, artificial, and political subdivision boundaries where reasonable
1. not be drawn to favor or discriminate against any political party or group

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%. We also used ferry routes in order to create districts linking precincts that are offshore. 

## Data Sources
Data for Washington comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
As described above, the adjacency graph was modified by hand to reflect Washington's contiguity requirements. The full list of these changes can be found in the '01_prep_WA_cd_1990.R' file.

## Simulation Notes
We sample 50,000 districting plans for Washington across 5 independent runs using the SMC algorithm and thinned the samples down to 5,000.
To balance county and municipality splits, we create pseudocounties for use in the county constraint, which leads to fewer municipality splits than using a county constraint.