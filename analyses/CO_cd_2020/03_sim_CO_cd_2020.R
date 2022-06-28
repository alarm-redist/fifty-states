###############################################################################
# Simulate plans for `CO_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CO_cd_2020}")

# Set up competitiveness targets ----
cons <- redist_constr(map) %>%
    add_constr_compet(30, ndv, nrv, pow = 1)

set.seed(2020)

plans <- redist_smc(
    map,
    nsims = 2500, runs = 2L,
    counties = pseudo_county,
    constraints = cons
)

plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_plans object. Do not edit this path.
write_rds(plans, here("data-out/CO_2020/CO_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CO_cd_2020}")
plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CO_2020/CO_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plans <- plans %>% mutate(dvs_20 = group_frac(map, adv_20, adv_20 + arv_20))

    set.seed(2022)
    plans2 <- redist_smc(
        map,
        nsims = 2500, runs = 2L,
        counties = pseudo_county
    )
    plans2 <- plans2 %>% mutate(dvs_20 = group_frac(map, adv_20, adv_20 + arv_20))

    redist.plot.distr_qtys(plans2, qty = dvs_20, geom = "boxplot") + theme_bw() +
        lims(y = c(0.25, 0.9)) +
        labs(title = "No Competitive Constraint") +
        redist.plot.distr_qtys(plans, qty = dvs_20, geom = "boxplot") +
        theme_bw() +
        lims(y = c(0.25, 0.9)) +
        labs(title = "With Competitive Constraint")
}
