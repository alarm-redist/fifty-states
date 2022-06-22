# 2020 Mississippi Congressional Districts

## Redistricting requirements
In Mississippi, [under Mississippi Code 5-3-123](https://advance.lexis.com/documentpage/?pdmfid=1000516&crid=d062935b-fafc-45ea-a1f4-dc1ba2a3377c&nodeid=AAEAACAAFAAC&nodepath=%2FROOT%2FAAE%2FAAEAAC%2FAAEAACAAF%2FAAEAACAAFAAC&level=4&haschildren=&populated=false&title=%C2%A7+5-3-123.+Preparation+of+plan+to+redistrict+congressional+districts.&config=00JABhZDIzMTViZS04NjcxLTQ1MDItOTllOS03MDg0ZTQxYzU4ZTQKAFBvZENhdGFsb2f8inKxYiqNVSihJeNKRlUp&pddocfullpath=%2Fshared%2Fdocument%2Fstatutes-legislation%2Furn%3AcontentItem%3A8P6B-7XD2-8T6X-701X-00008-00&ecomp=_g1_kkk&prid=4f3abbc9-f98b-4883-a5ce-fcb4020b7438) and [Committee agreement](https://www.dropbox.com/s/z36sc17c3m1cewv/MississippiLegislativeAndCongressionalRedistrictingCommitteeMinutes2012-04-05.pdf), districts must:

1. be contiguous
1. have equal populations
1. be geographically compact
1. preserve county and municipality boundaries as much as possible
1. comply with the Voting Rights Act of 1965


### Interpretation of requirements
We enforce a maximum population deviation of 0.5%.
We ensure that there is a majority minority district with at least 55% VAP.

## Data Sources
Data for Mississippi comes from the ALARM Project's [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

## Pre-processing Notes
No manual pre-processing decisions were necessary.

## Simulation Notes
We sample 5,000 districting plans for Mississippi, across two independent runs of the SMC algorithm.
We apply a hinge Gibbs constraint of strength 25 to encourage drawing a majority black district.
