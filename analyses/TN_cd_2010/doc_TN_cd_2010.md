# 2010 Tennessee Congressional Districts

## Redistricting requirements
In Tennessee, districts should:

1. Be contiguous
2. Preserve political subdivisions


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for Tennessee comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
In order to prevent the over splitting of larger cities in Tennessee, we concatenated them with counties in order to create a pseudo-counties. These pseudo-counties limited our maximum number of county splits to 8.

## Simulation Notes
We sample 5,000 districting plans for Tennessee across two separate runs.
No special techniques were needed to produce the sample.
