# 2020 Utah Congressional Districts

## Redistricting requirements
In Utah, districts must:

1. have a total population deviation of less than 1% -- Section 20A-20-302(4)(a)(iii)
2. not be drawn with race used as a predominant factor -- Section 20A-20-302(4)(a)(iv)
3. be contiguous and reasonably compact -- Section 20A-20-302(4)(b)(iii)
4. to the extent practicable -- Section 20A-20-302(5)
    a. preserve communities of interest
    b. follow natural, geographic, or man-made features, boundaries, or barriers
    c. preserve cores of prior districts
    d. minimize the division of municipalities and counties across multiple districts
    e. achieve boundary agreement among different types of districts
    f. prohibit the purposeful or undue favoring or disfavoring of incumbents, candidates or prospective candidates, and political parties



### Interpretation of requirements
We enforce a maximum population deviation of 1.0%.
We constrict the number of "pseudo-county" divisions to 3 or fewer (see below for the definition of pseudo-county).
We perform cores-based simulations, thereby preserving cores of prior districs.

## Data Sources
Data for Utah comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
We create pseudo-counties by splitting counties containing more than one municipality into county-municipality combinations. This is helpful for constricting the number of county and municipality divisions in the simulated plans.
We create prior district cores by grouping all contiguous precincts found in the interiors (i.e., not on the boundaries) of each of the 2010 Congressional Districts.


## Simulation Notes
We sample 5,000 districting plans for Utah.
No special techniques were needed to produce the sample.
