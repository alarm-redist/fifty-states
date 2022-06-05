# 2020 Utah Congressional Districts

## Redistricting requirements
In Utah, districts must, under [legislation code 20A-20-302](https://le.utah.gov/xcode/Title20A/Chapter20/20A-20-S302.html):

1. have a total population deviation of less than 1% (where total population deviation is calculated by adding together the percentage deviation of both the most populous and least populous districts from the average, or "ideal," district)
2. not be drawn with race used as a predominant factor
3. be contiguous and reasonably compact
4. to the extent practicable
    a. preserve communities of interest
    b. follow natural, geographic, or man-made features, boundaries, or barriers
    c. preserve cores of prior districts
    d. minimize the division of municipalities and counties across multiple districts
    e. achieve boundary agreement among different types of districts
    f. prohibit the purposeful or undue favoring or disfavoring of incumbents, candidates or prospective candidates, and political parties

### Interpretation of requirements
We enforce a maximum population deviation of 0.5% (which ensures that the total population deviation as defined by Utah legislation does not exceed 1%).
We constrain the number of "pseudo-county" divisions (see below for an explanation of pseudo-county).
We perform cores-based simulations, thereby preserving cores of prior districts.

## Data Sources
Data for Utah comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for the 2021 Utah Congressional adopted plans come from Utah Legislative Redistricting Committee's [MyDistricting site](https://citygate.utleg.gov/legdistricting/utah/comment_links#)

## Pre-processing Notes
We create pseudo-counties by splitting counties with a total population higher than the target district population into county-municipality combinations (in the end, this affects only Salt Lake County, which has a total population well above 1 million). 
To preserve the cores of prior districts, we merge all precincts which are more than two precincts away from a district border under the 2010 plan.


## Simulation Notes
We sample 6,000 districting plans for Utah across two independent runs of the SMC algorithm, and then thin the sample to down to 5,000 plans.
To balance county and municipality splits, we create pseudo-counties as described above.
