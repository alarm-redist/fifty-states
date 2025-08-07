###############################################################################
# Simulate plans for `AL_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AL_cd_2000}")

constr_al <- redist_constr(map) %>%
  add_constr_grp_hinge(21, vap_black, vap, 0.42) %>%
  add_constr_grp_hinge(-15, vap_black, vap, 0.30) %>%
  add_constr_grp_inv_hinge(10, vap_black, vap, 0.45)

set.seed(2000)
plans <- redist_smc(map, nsims = 2e3, runs = 20, counties = county, constraints = constr_al,
                    pop_temper   = 0.05)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AL_2000/AL_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AL_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AL_2000/AL_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}

bottleneck_split <- 6

plot(
  map,
  rowMeans(as.matrix(plans) == bottleneck_split),
)
