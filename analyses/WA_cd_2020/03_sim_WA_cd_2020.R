###############################################################################
# Simulate plans for `WA_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WA_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(10.0, vap - vap_white, vap, c(0.52, 0.35, 0.25)) %>%
    add_constr_grp_hinge(-8.0, vap - vap_white, vap, c(0.35, 0.25))

set.seed(2020)

plans <- redist_smc(map, nsims = 8e3, runs = 2L, counties = pseudo_county,
    constraints = constr, pop_temper = 0.02, seq_alpha = 0.9) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WA_2020/WA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WA_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WA_2020/WA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)

    if (exists("d_water")) {
        # checking contiguity
        redist.plot.plans(plans, 25, map) +
            geom_sf(data = d_water, size = 0.0, fill = "white", color = NA)
    }
}
