###############################################################################
# Simulate plans for `AZ_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_compet(25, ndv, nrv) %>%
    add_constr_grp_pow(130, vap_hisp, vap, 0.65, 0.1, pow = 1.2)

plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county,
                    constraints = constr, pop_temper = 0.01, seq_alpha = 0.6)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_2020/AZ_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_2020}")

plans <- add_summary_stats(plans, map)
validate_analysis(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_2020/AZ_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    constr <- redist_constr(map) %>%
        add_constr_grp_pow(130, vap_hisp, vap, 0.65, 0.1, pow = 1.2)

    plans_no <- redist_smc(map, nsims = 1e3, counties = pseudo_county) %>%
        add_summary_stats(map)

    p1 = plot(plans, ndshare, geom="boxplot") +
        geom_hline(yintercept=0.5, lty="dashed", color="red") +
        scale_y_continuous("Democratic share", labels=scales::percent) +
        labs(title="With competitiveness")
    p2 = plot(plans_no, ndshare, geom="boxplot") +
        geom_hline(yintercept=0.5, lty="dashed", color="red") +
        scale_y_continuous("Democratic share", labels=scales::percent) +
        labs(title="Without competitiveness")
    p1 + p2 + plot_layout(guides="collect")

}
