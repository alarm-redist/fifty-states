# 2020 Tennessee Congressional Districts

## Redistricting requirements
In Tennessee, there are no rules for redistricting Congressional districts ([NCSL](https://www.ncsl.org/research/redistricting/redistricting-criteria.aspx)).

### Interpretation of requirements

Although there are no rules, in practice, the state does avoid splitting its boundaries. The 2010 map split 8 of its 95 counties, and split only 4 of the 228 municipalities that comes with our default tigris call, and only 2 of the 20 largest municipalities. However, the 2020 map will reportedly split the city of Nashville, splitting its county into three CDs. 

To enforce some county splitting avoidence, we labelled the 20 largest cities in Tennessee (each with a population of at least 40,000) and concatenated them with counties so that these "pseudo-counties" were smaller units of geography that delineated major cities as well as counties. We then allowed the simulation to split at most 9 - 1 number of thse pseudo-counties.

We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Tennessee comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

As of 2022-02-02, the 2022 plans have reached the Governor's desk but are not signed. The plots now show 2010 enacted.

## Pre-processing Notes
See pseudo-county definition above.

## Simulation Notes
We sample 5,000 districting plans for Tennessee.
Pseudo-counties created as above and used as a hard SMC constraint.
No special techniques were needed to produce the sample.
