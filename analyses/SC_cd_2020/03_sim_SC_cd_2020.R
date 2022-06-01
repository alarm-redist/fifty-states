###############################################################################
# Simulate plans for `SC_cd_2020`
# © ALARM Project, April 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_2020}")

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_splits(strength = 0.5, admin = county_muni) %>%
    add_constr_grp_hinge(strength = 23, group_pop = vap_black, total_pop = vap, tgts_group = 0.49) %>%
    add_constr_grp_inv_hinge(strength = 1, group_pop = vap_black, total_pop = vap, tgts_group = 0.60)

set.seed(2020)
plans <- redist_smc(map,
                    nsims = 1e4,
                    runs = 2L,
                    ncores = 1,
                    compactness = 1,
                    pop_temper = 0.05,
                    counties = county,
                    constraints = constr_sc)

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/SC_2020/SC_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg SC_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/SC_2020/SC_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(
        plans, vap_black / total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by VAP') +
        labs(title = 'Partisanship of seats by BVAP rank') +
        scale_color_manual(values = c(cd_2020 = 'black'))


    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black / total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district,bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

}
