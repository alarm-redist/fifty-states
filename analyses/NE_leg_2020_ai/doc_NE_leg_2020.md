# 2020 Nebraska Legislative Districts

## Redistricting requirements
Nebraska has a unicameral legislature, so this analysis covers the state's single set of 49 legislative districts. We consult the Nebraska Constitution, Article III, Section 5, and the 2020 NCSL redistricting criteria summary. In our simulations, legislative districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. preserve the cores of prior districts


### Algorithmic Constraints
We enforce a maximum population deviation of 5.0%. We also encourage preservation of prior district cores with a mild status quo constraint based on the 2010-cycle legislative districts.

## Data Sources
Data for Nebraska comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Municipality and legislative district assignments come from Census block assignment files. Because Nebraska is unicameral, the enacted 2020 legislative districts are reconstructed from the official 2023 `SSD2022` block assignment file aggregated to VTDs.

## Pre-processing Notes
No manual boundary edits were necessary. The generic legislative helper in this repository assumes separate upper and lower chambers, so for Nebraska we directly aggregate the unicameral enacted plan from the Census block assignment file and analyze it through the `ssd` workflow.

## Simulation Notes
We sample 10,000 districting plans for Nebraska's unicameral legislature across 5 independent runs of the SMC algorithm. We simulate 2,000 plans per run and retain all of them after combining runs. The simulation uses the built-in county-preservation mechanism through pseudo-counties, a compactness parameter of 1, and a mild status quo constraint to preserve prior district cores.
