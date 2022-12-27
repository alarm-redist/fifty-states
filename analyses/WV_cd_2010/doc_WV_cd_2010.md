# 2010 West Virginia Congressional Districts

## Redistricting requirements
[In West Virginia, according to [W.V. Const. art. I, § 4](https://www.wvlegislature.gov/WVCODE/Code.cfm?chap=01&art=2), districts must:

1. be made of contiguous counties
1. have equal populations
1. be geographically compact

### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for West Virginia comes from the ALARM Project's [Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for West Virginia across 4 independent runs of the SMC algorithm.
We also merge VTDs into counties and run the simulation at the county level.
