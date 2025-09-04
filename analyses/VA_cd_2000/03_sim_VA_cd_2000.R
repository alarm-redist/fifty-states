###############################################################################
# Simulate plans for `VA_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg VA_cd_2000}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(50, vap_black, vap, 0.55) %>%
    add_constr_grp_hinge(
        strength   = 50,                # lower so it doesn't force all seats >50%
        group_pop  = ndv,               # Dem votes
        total_pop  = ndv + nrv,         # total two-party votes
        tgts_group = c(0.50)
    )

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(2000)
plans <- redist_smc(map, nsims = 10e3, runs = 10, counties = county, constraints = constr)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/VA_2000/VA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg VA_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/VA_2000/VA_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)


    redist.plot.distr_qtys(
        plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2000 = "black"))

    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)
}
