# 50-State Redistricting Simulations

<img src="https://alarm-redist.github.io/assets/alarm_256_tr.png" align="right" height=128>

### The ALARM Project

[![License: CC BY-SA 4.0](https://img.shields.io/badge/Data%20License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![License: MIT](https://img.shields.io/badge/Software%20License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dataverse DOI-10.7910/DVN/SLCD3E](<https://img.shields.io/badge/Dataverse DOI-10.7910/DVN/SLCD3E-orange>)](https://doi.org/10.7910/DVN/SLCD3E)

This repository contains code to sample districting plans for all 50 U.S.
states, according to relevant legal requirements.

The sampled plans and accompanying summary statistics may be downloaded from
the [dataverse](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi%3A10.7910%2FDVN%2FSLCD3E)
for this project. These consist of four files for each analysis:
- a documentation file describing data formats, analysis decisions, and data sources
- a CSV file of summary statistics for each of the generated plans
- two `.rds` files containing `redist_map` and `redist_plans` objects, which
contain the actual shapefiles and district assignment matrices and may be used
for further analysis.

## Repository Structure

- `analyses/` contains the code for each self-contained analysis
- `R/` contains common analysis and repository management code

## Data Sources

Unless otherwise noted, data for each state comes from the ALARM Project's
[2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/),
which use U.S. Census demographic data (in the public domain) and election data 
from the [Voting and Election Science Team](https://dataverse.harvard.edu/dataverse/electionscience), 
which is licensed  under a [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license.  
In these cases, shapefiles are also taken from the U.S. Census Bureau.

Exceptions to these data sources are listed in the individual documentation files 
in the `analyses/` folder.

## Contributing an Analysis
Please read the [contribution guidelines](https://github.com/alarm-redist/fifty-states/blob/main/CONTRIBUTING.md).
