###############################################################################
# Simulate plans for `MS_cd_1990`
# © ALARM Project, December 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_1990}")

set.seed(1990)

# attempt to create single bvap mmd
constr_sc <- redist_constr(map) %>%
  add_constr_grp_hinge(20, vap_black, vap, 0.60) %>%
  add_constr_grp_hinge(-15, vap_black, vap, 0.3) %>%
  add_constr_grp_hinge(-15, vap_black, vap, 0.3)

plans <- redist_smc(map, nsims = 2e3, runs = 5, counties = county)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MS_1990/MS_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MS_1990/MS_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
