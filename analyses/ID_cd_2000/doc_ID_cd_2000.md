# 2000 Idaho Congressional Districts

## Redistricting requirements
In Idaho, districts must:

(1) To the maximum extent possible, districts shall preserve traditional neighborhoods and local communities of interest.
(2) Districts shall be substantially equal in population and should seek to comply with all applicable federal standards and statutes.
(3) To the maximum extent possible, the plan should avoid drawing districts that are oddly shaped.
(4) Division of counties should be avoided whenever possible. Counties should be divided into districts not wholly contained within that county only to the extent reasonably necessary to meet the requirements of the equal population principle. In the event that a county must be divided, the number of such divisions, per county, should be kept to a minimum.
(5) To the extent that counties must be divided to create districts, such districts shall be composed of contiguous counties.
(6) District boundaries should retain, as far as practicable, the local voting precinct boundary lines to the extent those lines comply with the provisions of section 34-306, Idaho Code.
(7) Counties shall not be divided to protect a particular political party or a particular incumbent.

A senatorial or representative district, when more than one county shall constitute the same, shall be composed of contiguous counties, and a county may be divided in creating districts only to the extent it is reasonably determined by statute that counties must be divided to create senatorial and representative districts which comply with the constitution of the United States.
A county may be divided into more than one legislative district when districts are wholly contained within a single county. No floterial district shall be created. Multi-member districts may be created in any district composed of more than one county only to the extent that two representatives may be elected from a district from which one senator is elected.
The provisions of this section shall apply to any apportionment adopted following the 1990 decennial census.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.
nsims = 2000, runs = 10 (20000 plans total)
pop_temper=0.05

## Data Sources
Data for Idaho comes from the ALARM Project's [2000 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 20000 redistricting plans for Idaho across 10 independent runs of the SMC algorithm.
We then thinned the number of samples to 5000.
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
