# 2010 Idaho Congressional Districts

## Redistricting requirements
[In Idaho, districts must:](https://legislature.idaho.gov/statutesrules/idstat/Title72/T72CH15/SECT72-1506/)

1. be contiguous (72-1506(6)).
2. have equal populations (72-1506(3)).
3. be geographically compact (72-1506(4), 72-1506(5)).
4. preserve county and municipality boundaries as much as possible (72-1506(2)).
5. not be drawn to favor party or incumbents (72-1506(8)).
6. connect counties based on highways (72-1506(9)).

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Idaho comes from the [Loyala Law School (LLS) All About Redistricting](https://redistricting.lls.edu/state/idaho/?cycle=2010&level=Congress&startdate=2011-10-17) project

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 15,000 districting plans for Idaho, across 2 independent runs of the SMC algorithm, and then thin to 5,000 sampled population.
We sample using the standard algorithmic municipality constraint.
No special techniques were needed to produce the sample.
