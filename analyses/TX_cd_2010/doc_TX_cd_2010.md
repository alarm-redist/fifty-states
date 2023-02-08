# 2010 Texas Congressional Districts

## Redistricting requirements
In Texas, districts must meet US constitutional requirements, but there are
[no state-specific statutes](https://redistricting.capitol.texas.gov/pdf/Guide_to_2011_Redistricting.pdf).


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Texas comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). We estimate CVAP populations with the `cvap` R package.

## Pre-processing Notes
We pre-process the map to split it into clusters for simulation, which has a slight effect on the types of district plans that will be sampled.

## Simulation Notes
We sample 50,000 districting plans for Texas across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans. We use a pseudo-county constraint to limit the county and municipality splits. Due to the size and complexity of Texas, we split the simulations into multiple steps. 

### 1. Clustering procedure
First, we run simulations in three major metropolitan areas: Greater Houston, a combination of Greater San Antonio and Austin, and Dallas-Fort Worth. We use collections of counties that define the Metropolitan Statistical Areas.
The counties in each cluster are those in each Census MSA:

- Houston–The Woodlands–Sugar Land: Austin, Brazoria, Chambers, Fort Bend,
Galveston, Harris, Liberty, Montgomery, Waller.

- Austin–Round Rock-Georgetown: Bastrop, Caldwell, Hays, Travis, Williamson.

- San Antonio–New Braunfels: Atascosa, Bandera, Bexar, Comal, Guadalupe,
Kendall, Medina, Wilson.

- Dallas–Fort Worth–Arlington: Collin, Dallas, Denton, Ellis, Hunt,
Kaufman, Rockwall, Johnson, Parker, Tarrant, Wise.

These simulations run the SMC algorithm within each cluster with a 0.25% population tolerance. Because each cluster will have leftover population, we apply an additional constraint that incentivizes leaving any unassigned areas on the edge of these clusters to avoid discontiguities.

In each cluster, we apply hinge Gibbs constraints of strength 3 to encourage the formation of Hispanic CVAP opportunity districts. In Houston and Dallas, we also apply a hinge Gibbs constraint of strength 3 to encourage the formation of Black CVAP opportunity districts. These districts nudge the formation of opportunity districts are above 35%, and penalize districts with minority populations above 70%.

### 2. Combination procedure
Then, these partial map simulations are combined to run statewide simulations. We again apply Gibbs hinge constraints to encourage the formation of minority opportunity districts, with strength 3 to further encourage Hispanic CVAP opportunity districts.
