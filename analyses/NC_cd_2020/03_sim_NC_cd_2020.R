###############################################################################
# Simulate plans for `NC_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(35, vap_black, vap, 0.33) %>%
    add_constr_grp_hinge(-35, vap_black, vap, 0.30) %>%
    add_constr_grp_inv_hinge(20, vap_black, vap, 0.37)

set.seed(2020)
plans <- redist_smc(map, nsims = 10e3,
    runs = 2L,
    compactness = 1,
    counties = pseudo_county,
    constraints = constr,
    pop_temper = 0.01)

plans_5k <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans_5k <- match_numbers(plans_5k, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/NC_2020/NC_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_2020}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/NC_2020/NC_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(plans_5k, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "North Carolina Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black"))

    # Dem seats by BVAP rank -- numeric
    plans_5k %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans_5k %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)

}
