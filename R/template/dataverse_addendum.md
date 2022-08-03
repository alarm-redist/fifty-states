## Contents

* ```SLUG``_stats.csv` contains summary statistics on the sampled redistricting plans
* ```SLUG``_plans.rds` is a compressed `redist_plans` object, which contains the matrix of precinct/block assignments and may be used for further analysis.
* ```SLUG``_map.rds` is a compressed `redist_map` object, which contains the precinct/block shapefile and demographic data.

Both the `redist_plans` and `redist_map` object are intended to be used with the
[redist package](https://alarm-redist.github.io/redist/).

### Codebook for summary statistics

* `draw`: unique identifier for each sample. Non-numeric draw names are real-world plans, e.g., `cd_2010` for an enacted 2010 plan.
* `district`: a district identifier. District numbers roughly match those in the enacted plan, but the correspondence is not perfect.
* `chain`: a number identifying the run of the redistricting algorithm used to produce this draw. Used for diagnostic purposes.
* `pop_overlap`: a number indicating the fraction of people in this plan who reside in the same-numbered district in the enacted plan.
* `total_pop`: the total population of each district.
* `total_vap`: the total voting-aged population of each district.
* `pop_*`, `vap_*`: total (voting-aged) population within racial and ethnic groups for each district. Variable codes documented [here](https://github.com/alarm-redist/census-2020#data-format).
* `plan_dev`: the maximum population deviation among districts in the plan. Computed as `max(abs(distr_pop - target_pop)/target_pop)`.
* `comp_edge`: compactness, as measured by the fraction of internal edges kept. Higher values indicate more compactness.
* `comp_polsby`: compactness, as measured by the Polsby-Popper score. Higher values indicate more compactness.
* `county_splits`: the number of counties which belong to more than one district.
* `muni_splits`: the number of Census Designated Places which belong to more than one district.
* `*_##_dem_*`, `*_##_rep_*`: vote counts for statewide Democratic and Republican candidates in a certain election. More information [here](https://github.com/alarm-redist/census-2020#data-format).
* `adv_##`, `arv_##`: average vote counts for statewide Democratic and Republican candidates in a certain year. More information [here](https://github.com/alarm-redist/census-2020#data-format).
* `ndv`, `nrv`: averages of the `adv_##` and `arv_##` variables across all available elections.
* `ndshare`: normal Democratic share, computed as `ndv / (ndv + nrv)`
* `e_dvs`: average Democratic vote share, computed as the average of the Democratic vote share when first scored under each statewide election.
* `pr_dem`: probability seat is represented by a Democrat; calculated as the fraction of statewide elections under which the district had a majority Democratic share.
* `e_dem`: expected number of Democratic seats for the plan; equivalent to summing the `pr_dem` values across districts
* `pbias`: partisan bias at 50% vote share, averaged across all available elections. Positive values indicate Republican bias.
* `egap`: the efficiency gap, averaged across all available elections. Positive values indicate Republican bias.
