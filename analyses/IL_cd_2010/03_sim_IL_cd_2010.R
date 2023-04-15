###############################################################################
# Simulate plans for `IL_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IL_cd_2010}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(18, vap_black, vap, tgts_group = 0.48) %>%
    add_constr_grp_hinge(-18, vap_black, vap, tgts_group = 0.30) %>%
    add_constr_grp_inv_hinge(18, vap_black, vap, tgts_group = 0.62) %>%
    add_constr_grp_hinge(24, vap_hisp, vap, tgts_group = 0.62) %>%
    add_constr_grp_hinge(12, vap_hisp, vap, tgts_group = 0.45) %>%
    add_constr_grp_hinge(-24, vap_hisp, vap, tgts_group = 0.32)

set.seed(2010)
plans <- redist_smc(map, nsims = 2e4, runs = 2L, counties = pseudo_county) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IL_2010/IL_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IL_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IL_2010/IL_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)

    redist.plot.distr_qtys(
        plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2010 = "black"))

    redist.plot.distr_qtys(
        plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Partisanship of seats by HVAP rank") +
        scale_color_manual(values = c(cd_2010 = "black"))

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

    # Dem seats by HVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(hvap = vap_hisp/total_vap, hvap_rank = rank(hvap)) %>%
        subset_sampled() %>%
        select(draw, district, hvap, hvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(hvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Hispanic districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_hisp_perf = sum(vap_hisp/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_hisp_perf)

    redist.plot.scatter(plans, vap_black/total_vap, vap_hisp/total_vap,
        color = c("red", "blue")[((subset_sampled(plans)$nrv/subset_sampled(plans)$ndv) > 0.5) + 1]) + facet_wrap(~district)

}
