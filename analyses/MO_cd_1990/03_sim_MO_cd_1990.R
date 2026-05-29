###############################################################################
# Simulate plans for `MO_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MO_cd_1990}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(+8, vap_black, vap, 0.47) %>%
    add_constr_grp_hinge(-8, vap_black, vap, 0.15) %>%
    add_constr_grp_hinge(-4, vap_black, vap, 0.10)

set.seed(1990)
plans <- redist_smc(map, nsims = 5e3, runs = 5, counties = county,
    constraints = constr)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MO_1990/MO_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MO_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MO_1990/MO_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
