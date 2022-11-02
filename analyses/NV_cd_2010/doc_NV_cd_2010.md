# 2010 Nevada Congressional Districts

## Redistricting requirements

In Nevada, districts must (per [judicial order](https://www.ncsl.org/Portals/1/Documents/Redistricting/NV_11-OC-00042-1B_2011-09-21_Order_Re-Redistricting_20076.pdf) for the 2010 cycle):

1.  be contiguous
2.  have equal populations
3.  be geographically compact
4.  preserve county and municipality boundaries as much as possible
5.  preserve communities of interest
6.  avoid pairing incumbents "to the extent practicable"

### Algorithmic Constraints

1.  We enforce a maximum population deviation of 0.5%.
2.  We use a county constraint (with pseudo-counties in Clark County) to preserve communities of interests, municipalities, and counties.
3.  We **do not** include a restriction for avoiding incumbent pairings.

## Data Sources

Data for Nevada comes from the ALARM Project's [2010 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes

No manual pre-processing decisions were necessary.

## Simulation Notes

We sample 5,000 districting plans for Nevada across 2 independent runs of the sequential Markov Chain algorithm. No special techniques were needed to produce the sample.
