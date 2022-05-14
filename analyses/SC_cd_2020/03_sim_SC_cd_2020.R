###############################################################################
# Simulate plans for `SC_cd_2020`
# © ALARM Project, April 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_2020}")

# TODO any pre-computation (VRA targets, etc.)

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_splits(strength = 1, admin = county_muni) %>%
    add_constr_grp_inv_hinge(strength = 50, group_pop = vap_minority, total_pop = vap, tgts_group = 0.65) %>%
    add_constr_grp_hinge(strength = 50, group_pop = vap_minority, total_pop = vap, tgts_group = 0.55)

plans <- redist_smc(map,
                    nsims = 5e3,
                    compactness = 1,
                    counties = county,
                    constraints = constr_sc)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

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
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.distr_qtys(
        plans, vap_black / total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by VAP') +
        labs(title = 'Approximate Performance') +
        scale_color_manual(values = c(cd_2020 = 'black'))

}
