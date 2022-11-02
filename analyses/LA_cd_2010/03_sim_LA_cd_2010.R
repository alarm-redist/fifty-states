###############################################################################
# Simulate plans for `LA_cd_2010`
# © ALARM Project, October 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_2010}")

constr <- redist_constr(map_m) %>%
    add_constr_grp_hinge(30, vap - vap_white, vap, 0.50) %>%
    add_constr_grp_hinge(-25, vap - vap_white, vap, 0.41) %>%
    add_constr_grp_inv_hinge(10, vap - vap_white, vap, 0.55)

set.seed(2010)
plans <- redist_smc(map_m,
    runs = 2L,
    nsims = 8e3,
    counties = pseudo_county,
    constraints = constr) %>%
    pullback(map) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/LA_2010/LA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/LA_2010/LA_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010_prop = "black")) +
        theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Minority Percentage by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010_prop = "black")) +
        theme_bw()

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
