###############################################################################
# Simulate plans for `TX_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2010}")

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

constraints <- redist_constr(map) %>%
    #########################################################
    # HISPANIC
    add_constr_grp_hinge(
        3,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_hisp,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_hisp,
        cvap,
        0.70) %>%
    # BLACK
    add_constr_grp_hinge(
        3,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_black,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_black,
        cvap,
        0.70)

set.seed(2010)
plans <- redist_smc(
    map,
    nsims = 2500, runs = 5L,
    ncores = max(1, parallel::detectCores() - 1),
    counties = pseudo_county,
    constraints = constraints,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    pop_temper = 0.05,
    seq_alpha = 0.95
)

plans <- match_numbers(plans, "cd_2010")

plans <- plans %>% filter(draw != "cd_2010")

plans <- plans %>%
    mutate(district = as.numeric(district)) %>%
    add_reference(ref_plan = as.numeric(map$cd_2010), "cd_2010")

plans_5k <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/TX_2010/TX_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_2010}")

plans_5k <- add_summary_stats(plans_5k, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

summary(plans_5k)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans_5k <- mutate(plans_5k, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/TX_2010/TX_cd_2010_stats.csv")

cli_process_done()

validate_analysis(plans_5k, map)

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    summary(plans_5k)

    d1 <- redist.plot.distr_qtys(
        plans_5k,
        cvap_black/total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Black by CVAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black"))

    d2 <- redist.plot.distr_qtys(
        plans_5k,
        cvap_hisp/total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Hispanic by CVAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black"))

    d3 <- redist.plot.distr_qtys(
        plans_5k,
        vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black"))

    d4 <- redist.plot.distr_qtys(
        plans_5k,
        vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2010 = "black"))

    ggsave("data-raw/TX/cvap_rank_plots.png",
        d1/d2,
        height = 10, width = 10, units = "in")
    ggsave("data-raw/TX/vap_rank_plots.png",
        d3/d4,
        height = 10, width = 10, units = "in")

    psum <- plans_5k %>%
        group_by(draw) %>%
        summarize(
            all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
            dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
                (ndv > nrv)),
            rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
                (nrv > ndv)),
            all_bcvap = sum((cvap_black/total_cvap) > 0.4),
            dem_bcvap = sum((cvap_black/total_cvap) > 0.4 &
                (ndv > nrv)),
            rep_bcvap = sum((cvap_black/total_cvap) > 0.4 &
                (nrv > ndv)),
            mmd_coalition = sum(((
                vap_hisp + vap_black + vap_asian
            )/total_vap) > 0.5),
            all_hvap = sum((vap_hisp/total_vap) > 0.4),
            dem_hvap = sum((vap_hisp/total_vap) > 0.4 &
                (ndv > nrv)),
            rep_hvap = sum((vap_hisp/total_vap) > 0.4 &
                (nrv > ndv))
        )

    p1 <- redist.plot.hist(psum, all_hcvap) + xlab("HCVAP > .4")
    p2 <- redist.plot.hist(psum, dem_hcvap) + xlab("HCVAP > .4 & Dem > Rep")
    p3 <- redist.plot.hist(psum, rep_hcvap) + xlab("HCVAP > .4 & Rep > Dem")
    p4 <- redist.plot.hist(psum, all_bcvap) + xlab("BCVAP > .4")
    p5 <- redist.plot.hist(psum, dem_bcvap) + xlab("BCVAP > .4 & Dem > Rep")
    p6 <- redist.plot.hist(psum, rep_bcvap) + xlab("BCVAP > .4 & Rep > Dem")
    p7 <- redist.plot.hist(psum, all_hvap) + xlab("HVAP > .4")
    p8 <- redist.plot.hist(psum, dem_hvap) + xlab("HVAP > .4 & Dem > Rep")
    p9 <- redist.plot.hist(psum, rep_hvap) + xlab("HVAP > .4 & Rep > Dem")
    p10 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian VAP > .5")

    ggsave("data-raw/TX/cvap_plots.png",
        p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9 + p10,
        height = 10, width = 10, units = "in")
}
