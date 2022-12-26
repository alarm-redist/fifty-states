# 2010 Arkansas Congressional Districts

## Redistricting requirements
In Arkansas, there are no state law requirements for congressional districts.

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%, which is in line with the low deviation seen in past congressional district maps.
We apply a county constraint, as described below, which is in line with the small number of county/municipality splits observed in past congressional district maps.

## Data Sources
Data for Arkansas comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Arkansas across two independent runs of the SMC algorithm.
We use the standard algorithmic county constraint to limit the number of county splits.

