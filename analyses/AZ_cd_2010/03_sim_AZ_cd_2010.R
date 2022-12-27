###############################################################################
# Simulate plans for `AZ_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_2010}")

Nsim_final <- 8e3 # sims per run in the final map

## Get 1 HVAP outside Maricopa ------
map_nomaricopa <- filter(map, county != "Maricopa County")
attr(map_nomaricopa, "pop_bounds") <- attr(map, "pop_bounds")

# ID precincts on the border of Maricopa
border_idxs <- as_tibble(map) %>%
    mutate(cluster_edge = ifelse(GEOID %in% map_nomaricopa$GEOID, 0, 1)) %>%
    geomander::seam_geom(.$adj, ., admin = "cluster_edge", seam = c(0, 1)) %>%
    suppressWarnings() %>%
    filter(cluster_edge == 1) %>%
    pull(GEOID) %>%
    match(., map_nomaricopa$GEOID)


constr <- redist_constr(map_nomaricopa) %>%
    add_constr_compet(15, ndv, nrv) %>%
    add_constr_grp_hinge(20, vap_hisp, vap, 0.5) %>%
    add_constr_grp_hinge(-20, vap_hisp, vap, 0.3) %>%
    add_constr_grp_inv_hinge(5, vap_hisp, vap, 0.55) %>%
    add_constr_custom(100, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    }) %>%
    suppressWarnings()

set.seed(2010)
plans_nomaricopa <- redist_smc(map_nomaricopa, nsims = 1500, runs = 8L, n_steps = 3,
    counties = county_muni, constraints = constr,
    pop_temper = 0.05, verbose = TRUE)

# diagnostic check on HVAP
if (FALSE) {
    plot(constr)
    plans_nomaricopa %>%
        mutate(hisp = group_frac(map_nomaricopa, vap_hisp, vap),
            min = 1 - group_frac(map_nomaricopa, vap_white, vap)) %>%
        filter(district > 0) %>%
        plot(hisp, geom = "boxplot")
}

# subsample 8k to init next stage
init_m <- matrix(0, nrow = nrow(map), ncol = Nsim_final)
idxs <- sample(ncol(as.matrix(plans_nomaricopa)), Nsim_final, replace = F)
init_m[match(map_nomaricopa$GEOID, map$GEOID), ] <- as.matrix(plans_nomaricopa)[, idxs]


## Finish simulations ------
constr <- redist_constr(map) %>%
    add_constr_compet(15, ndv, nrv) %>%
    add_constr_grp_hinge(20, vap_hisp, vap, 0.5) %>%
    add_constr_grp_hinge(-20, vap_hisp, vap, 0.3) %>%
    add_constr_grp_inv_hinge(5, vap_hisp, vap, 0.55) %>%
    suppressWarnings()

set.seed(2010)

plans <- redist_smc(map, nsims = 8e3, runs = 4L, counties = pseudo_county,
    constraints = constr, init_particles = init_m, pop_temper = 0.05,
    verbose = TRUE) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1250) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_2010/AZ_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_2010/AZ_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plot(constr)

    # competitiveness
    constr <- redist_constr(map) %>%
        add_constr_grp_pow(1e3, vap_hisp, vap, 0.51, 0.15, pow = 1.4)
    plans_no <- redist_smc(map, nsims = 1e3, counties = pseudo_county) %>%
        add_summary_stats(map)
    p1 <- plot(plans, ndshare, geom = "boxplot") +
        geom_hline(yintercept = 0.5, lty = "dashed", color = "red") +
        scale_y_continuous("Democratic share", labels = scales::percent) +
        labs(title = "With competitiveness")
    p2 <- plot(plans_no, ndshare, geom = "boxplot") +
        geom_hline(yintercept = 0.5, lty = "dashed", color = "red") +
        scale_y_continuous("Democratic share", labels = scales::percent) +
        labs(title = "Without competitiveness")
    p1 + p2 + patchwork::plot_layout(guides = "collect")

    # VRA
    plans %>%
        mutate(min = vap_hisp/total_vap) %>%
        number_by(min) %>%
        redist.plot.distr_qtys(ndshare, sort = "none", geom = "boxplot") +
        labs(x = "Districts, ordered by HVAP", y = "Average Democratic share")

    redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.1) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2010_prop = "black"))
}
