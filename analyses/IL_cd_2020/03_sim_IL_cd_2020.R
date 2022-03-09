###############################################################################
# Simulate plans for `IL_cd_2020`
# © ALARM Project, January 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IL_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(20, vap_black, vap, tgts_group = 0.55) %>%
    add_constr_grp_hinge(20, vap_hisp, vap, tgts_group = 0.55)

plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county,
    constraints = constr)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IL_2020/IL_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IL_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IL_2020/IL_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)

    redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        ggredist::theme_r21()
    ggsave("figs/performance.pdf", height = 7, width = 7)

    fake_map <- map
    fake_map$Enacted <- get_plans_matrix(plans)[,1000]
    fake_map %>%
        group_by(Enacted) %>%
        summarize(geometry = st_union(geometry),
                  hisp = sum(vap_hisp) / sum(vap)) %>%
        ggplot() +
        geom_sf(aes(fill = hisp), lwd = 0.25) +
        # geom_sf(data = ctys, fill = NA, lwd = 2.5, alpha = 0.3, color = "grey") +
        # geom_sf(data = dists, fill = NA, lwd = 1) +
        geom_sf(data = fake_map, fill = NA, lwd = 0) +
        theme_void()
    # coord_sf(xlim=c(bbox$xmin, bbox$xmax),
    #          ylim=c(bbox$ymin, bbox$ymax))
    ggsave("figs/il_hisp.pdf", height = 10, width = 10)
}
