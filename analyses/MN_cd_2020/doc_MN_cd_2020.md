# 2020 Minnesota Congressional Districts

## Redistricting requirements
In Minnesota, districts must:
1. be convenient and contiguous ([Minn. Const. art. IV, § 3](https://www.revisor.mn.gov/constitution/#section_4_3))
2. be substantially equal in population ([Minn. Stat. 2.91](https://www.revisor.mn.gov/statutes/2021/cite/2.91))
3. not divide political subdivisions more than necessary to meet constitutional requirements ([Minn. Stat. 2.91](https://www.revisor.mn.gov/statutes/2021/cite/2.91))

Furthermore, the following principles guide redistricting in Minnesota which stipulate that districts must:
4. have populations as nearly as equal as practical
5. preserve communities of interest
6. not abridge voting rights of minority groups
7. not unduly protect nor defeat incumbents
([Order of the Special Redistricting Panel, Hippert vs. Ritchie, No. A11-152](https://www.mncourts.gov/mncourtsgov/media/CIOMediaLibrary/2011Redistricting/A110152Order9-12-11.pdf))

### Interpretation of requirements
We enforce a maximum population deviation of 0.1%.
We use a pseudo-county constraint described below which attempts to mimic the norms in Minnesota of generally preserving county, city, and township boundaries.

## Data Sources
Data for Minnesota comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).
Data for Minnesota's 2020 congressional district map comes from the Minnesota Legislature's [Geographic Information Services](https://gis.lcc.mn.gov/redist2020/cong20.php?plname=C2022&pltype=court)

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Minnesota across two independent runs of the SMC algorithm.
We use a pseudo-county constraint to limit the county and municipality (i.e., city and township) splits.
Municipality lines are used in Anoka County, Dakota County, Hennepin County, and Ramsey County, which are all counties with populations larger than 40% the target population for a district.
