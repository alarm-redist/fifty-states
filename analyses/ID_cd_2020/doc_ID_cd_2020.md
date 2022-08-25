# 2020 Idaho Congressional Districts

## Redistricting requirements
[In Idaho, districts must](https://legislature.idaho.gov/statutesrules/idstat/Title72/T72CH15/SECT72-1506/):

1. be contiguous (72-1506(6)).
1. have equal populations (72-1506(3)).
1. be geographically compact (72-1506(4), 72-1506(5)).
1. preserve county and municipality boundaries as much as possible (72-1506(2)).
1. not be drawn to favor party or incumbents (72-1506(8)).
1. connect counties based on highways (72-1506(9)).


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Idaho comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
Borders between counties which are not connected by highways were removed.

## Simulation Notes
We sample 5,000 districting plans for Idaho across 2 independent runs of the SMC algorithm.
We sample using the standard algorithmic county constraint.
No special techniques were needed to produce the sample.
