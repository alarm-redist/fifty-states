###############################################################################
# Simulate plans for `SC_cd_2010`
# © ALARM Project, June 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_2010}")

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_splits(strength = 0.5, admin = county_muni) %>%
    add_constr_grp_hinge(5, vap_black, vap, 0.4) %>%
    add_constr_grp_hinge(-5, vap_black, vap, 0.3) %>%
    add_constr_grp_inv_hinge(2, vap_black, vap, 0.6)

# Sample
set.seed(2010)
plans <- redist_smc(map,
    nsims = 3000,
    runs = 2L,
    ncores = 1,
    compactness = 1,
    pop_temper =  0.01,
    counties = county,
    constraints = constr_sc) %>%
    match_numbers("cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/SC_2010/SC_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg SC_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/SC_2010/SC_cd_2010_stats.csv")

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
}
