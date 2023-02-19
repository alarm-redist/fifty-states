# 2010 California Congressional Districts

## Redistricting requirements
In California, according to the [California Constitution Article XXI](https://leginfo.legislature.ca.gov/faces/codes_displayText.xhtml?lawCode=CONS&division=&title=&part=&chapter=&article=XXI), districts must:

1. be contiguous
2. have equal populations
3. be geographically compact
4. preserve city, county, neighborhood, and community of interest boundaries as much as possible
5. not favor or discriminate against incumbents, candidates, or parties
6. comply with the federal Voting Rights Act


### Algorithmic Constraints
We enforce a maximum population deviation of 0.5%.

## Data Sources
Data for California comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/). Data for the 2010 California enacted congressional map comes from [All About Redistricting](https://redistricting.lls.edu/state/california/?cycle=2010&level=Congress&startdate=2012-01-17).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for California.
No special techniques were needed to produce the sample.
