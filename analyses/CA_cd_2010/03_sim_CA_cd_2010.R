###############################################################################
# Simulate plans for `CA_cd_2010`
# © ALARM Project, February 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_cd_2010}")

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

constr <- redist_constr(map) %>%
    # Keep the VRA hinge constraints from the prior Southern California stage.
    add_constr_grp_hinge(
        strength = 9,
        group_pop = vap_hisp,
        total_pop = vap
    ) %>%
    add_constr_grp_hinge(
        strength = -6,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -6,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .2
    ) %>%
    # Keep the VRA hinge constraints from the prior Bay Area stage.
    add_constr_grp_hinge(
        strength = 3,
        group_pop = vap_hisp,
        total_pop = vap
    ) %>%
    add_constr_grp_hinge(
        strength = -3,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -3,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .2
    ) %>%
    add_constr_grp_hinge(
        strength = 4,
        group_pop = vap_asian,
        total_pop = vap
    ) %>%
    add_constr_grp_hinge(
        strength = -4,
        group_pop = vap_asian,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -4,
        group_pop = vap_asian,
        total_pop = vap,
        tgts_group = .2
    )

set.seed(2010)
plans <- redist_smc(
    map,
    nsims = 2000, runs = 5L,
    ncores = max(1, parallel::detectCores() - 1),
    counties = pseudo_county,
    constraints = constr,
    pop_temper = 0.05, seq_alpha = 0.95,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)
attr(plans, "prec_pop") <- map$pop

plans_5k <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
    ungroup()

plans_5k <- match_numbers(plans_5k, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/CA_2010/CA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CA_cd_2010}")

plans_5k <- add_summary_stats(plans_5k, map)

summary(plans_5k)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/CA_2010/CA_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    p1 <- redist.plot.hist(plans_5k %>% group_by(draw) %>%
        mutate(hisp_dem = sum((vap_hisp/total_vap > 0.5) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_hisp/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_hisp/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic > 30% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(ha_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.5) & e_dvs > 0.5)), qty = ha_dem) +
        labs(x = "Number of Hispanic + Asian and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic + Asian > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic + Asian > 30% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(asian_dem = sum((vap_asian/total_vap > 0.5) & e_dvs > 0.5)), qty = asian_dem) +
        labs(x = "Number of Asian and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_asian/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Asian > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(coalition_dem = sum(((vap_asian + vap_hisp + vap_black)/total_vap > 0.5) & e_dvs > 0.5)), qty = coalition_dem) +
        labs(x = "Number of Hispanic + Asian + Black and Dem. Majority") &
        theme_bw()

    ggsave("data-raw/CA/hist_5k.pdf", p1, width = 11, height = 8)


    enac_sum <- plans_5k %>%
        subset_ref() %>%
        mutate(minority = (total_vap - vap_white)/(total_vap),
            dist_lab = str_pad(district, width = 2, pad = "0"),
            minority_rank = rank(minority), # ascending order
            hisp_rank = rank(vap_hisp),
            asian_rank = rank(vap_asian),
            ha_rank = rank(vap_hisp + vap_asian),
            coalition_rank = rank(vap_hisp + vap_asian + vap_black),
            compact_rank = rank(comp_polsby)
        )

    p2 <- redist.plot.distr_qtys(plans_5k, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = hisp_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, vap_asian/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = asian_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, (vap_asian + vap_hisp)/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic or Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = ha_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, (vap_asian + vap_hisp + vap_black)/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        redist.plot.distr_qtys(plans_5k %>% number_by(e_dvs), (vap_asian + vap_hisp + vap_black)/total_vap, sort = FALSE,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted")

    ggsave("data-raw/CA/boxplot.pdf", p2, width = 11, height = 8)

}
