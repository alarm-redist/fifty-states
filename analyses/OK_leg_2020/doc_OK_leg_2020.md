# 2020 Oklahoma State House/Senate Districts

## Redistricting requirements
In Oklahoma, we consult the [Oklahoma Constitution](https://oklegal.onenet.net/okcon/V-9A.html) and the [Oklahoma House of Representatives's guidelines](https://redistricting.lls.edu/wp-content/uploads/OK-House-20210225-guidelines.pdf) and impose the following constraints. In our simulations, legislative districts must:

1. be contiguous [§V-9A; Guidelines 3]
1. have equal populations [§V-9A; Guidelines 1]
1. be geographically compact [§V-9A; Guidelines 3]
1. preserve county and municipality boundaries as much as possible [§V-9A; Guidelines 2]

### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%.

## Data Sources
Data for Oklahoma comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 10,000 districting plans for Oklahoma's lower house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.

We sample 10,000 districting plans for Oklahoma's upper house across 5 independent runs of the SMC algorithm.
No special techniques were needed to produce the sample.
