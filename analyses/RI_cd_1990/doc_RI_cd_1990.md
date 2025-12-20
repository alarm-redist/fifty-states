# 1990 Rhode Island Congressional Districts

## Redistricting requirements
In Rhode Island, we consult [Chapter 315, Section 2 of the 2001 Rhode Island Laws](https://webserver.rilegislature.gov/PublicLaws/law01/law01315.htm) and impose the following constraints. In our simulations, districts must:

1. be contiguous
1. have equal populations. In particular, congressional districts shall not vary in population by more than one percent (1%) from each other. 
1. be geographically compact
1. preserve county and municipality boundaries as much as possible. In particular, plans ought to avoid the creation of voting districts composed of fewer than one hundred (100) potential voters with respect to the division of state house and state senate districts.

### Algorithmic Constraints
We enforce a maximum population deviation of 1.0%.

## Data Sources
Data for Rhode Island comes from the [ALARM Project's update](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZV5KF3) to [The Record of American Democracy](https://road.hmdc.harvard.edu/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Rhode Island (10 independent runs with thinning to 500 plans for each run) to help manage low plan diversity.
We use the standard county constraint.
Although state law encourages avoiding the creation of voting districts with fewer than 100 potential voters when dividing state legislative districts, this constraint is not enforced in our simulation. Data on 1994 State Senate districts was not of sufficient quality to reliably apply this rule, and the affected population is minimal. Additionally, because House and Senate districts were drawn concurrently by the legislature, this constraint was not binding in practice during the actual redistricting process. We therefore document the constraint but do not enforce it in our simulation.
