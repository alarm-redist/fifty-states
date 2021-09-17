# 50-State Redistricting Simulations

<img src="https://alarm-redist.github.io/assets/alarm_256_tr.png" align="right">

### The ALARM Project

[![License: CC BY-SA 4.0](https://img.shields.io/badge/Data%20License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![License: MIT](https://img.shields.io/badge/Software%20License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains code to sample districting plans for all 50 U.S.
states, along with the sampled plans and accompanying summary statistics.

## Repository Structure

- `data-final/` contains validated redistricting samples
- `analyses/` contains the code for each self-contained analysis
- `R/` contains common analysis and repository management code

## Data Sources

Unless otherwise noted, data for each state comes from the ALARM Project's
[2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/),
which use U.S. Census demographic data (in the public domain) and election data 
from the [Voting and Election Science Team](https://dataverse.harvard.edu/dataverse/electionscience), 
which is licensed  under a Creative Commons Attribution license 
(CC BY 4.0, <https://creativecommons.org/licenses/by/4.0/>).  In these cases,
shapefiles are also taken from the U.S. Census Bureau.

Exceptions to these data sources are listed here:

