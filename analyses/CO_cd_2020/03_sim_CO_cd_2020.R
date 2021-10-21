###############################################################################
# Simulate plans for `CO_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CO_cd_2020}")

# Set up competitiveness targets ----
cons <- list(party = list(strength = 700, rvote = map$nrv,
    dvote = map$ndv, tgts_party = 0.50))

plans <- redist_smc(map, nsims = 5e3,
                    counties = pseudo_county,
                    constraints = cons)
plans2 <- redist_smc(map, nsims = 5e3,
                     counties = pseudo_county)

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
    redist.plot.distr_qtys(plans, qty = dvs_20, geom = "boxplot") + theme_bw()
    ggsave('data-raw/CO/competitiveness_20211010_2001.png')
}
