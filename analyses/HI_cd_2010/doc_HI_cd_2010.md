# 2010 Hawaii Congressional Districts

## Redistricting requirements
Per Hawaii Revised Statutes 25-2(b)(1)-(4) and (6), [as in force for the 2010 cycle](https://www.ncsl.org/Portals/1/Documents/Redistricting/Redistricting_2010.pdf), districts must:

1. not unduly favor any person or party;
2. be contiguous, except when encompassing more than one island;
3. be compact;
4. where possible, follow geographical and recognized features and coincide with tract boundaries;
6. where practicable, avoid mixing regions with different socioeconomic interests.

### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%. We use Census tracts in line with 25-2(b)(4). In absence of regional knowledge about features and socioeconomic interests, we use municipalities to attempt to enforce 25-2(b)(4) and (6).

## Data Sources
Data for Hawaii comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Hawaii.
No special techniques were needed to produce the sample.
