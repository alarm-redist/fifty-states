###############################################################################
# Simulate plans for `TX_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2000}")

constraints <- redist_constr(map) |>
    add_constr_grp_hinge(
        4,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.6)
    ) |>
    add_constr_grp_inv_hinge(
        2,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.75)
    ) |>
    add_constr_grp_hinge(
        2,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.35))

set.seed(2000)

plans <- redist_smc(map,
    nsims = 2e3,
    runs = 5,
    counties = county,
    sampling_space = redist:::FOREST_SPACE_SAMPLING,
    constraints = constraints,
    ms_params = list(ms_frequency = 1L, ms_moves_multiplier = 40),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = T, pop_temper = 0.01)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TX_2000/TX_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_2000}")

plans <- add_summary_stats(plans, map) |>
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap) |>
    mutate(cvap_hisp = tally_var(map, cvap_hisp), .after = vap_hisp)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2000/TX_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    d1 <- redist.plot.distr_qtys(
        plans,
        vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2000 = "black"))

    d2 <- redist.plot.distr_qtys(
        plans,
        cvap_hisp/total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Hispanic by CVAP") +
        labs(title = "TX Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2000 = "black"))

    psum <- plans %>%
        group_by(draw) %>%
        summarise(
            all_hcvap = sum((cvap_hisp/total_cvap) > 0.4),
            dem_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
                (ndv > nrv)),
            rep_hcvap = sum((cvap_hisp/total_cvap) > 0.4 &
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
    p4 <- redist.plot.hist(psum, all_hvap) + xlab("HVAP > .4")
    p5 <- redist.plot.hist(psum, dem_hvap) + xlab("HVAP > .4 & Dem > Rep")
    p6 <- redist.plot.hist(psum, rep_hvap) + xlab("HVAP > .4 & Rep > Dem")
    p7 <- redist.plot.hist(psum, mmd_coalition) + xlab("Hisp + Black + Asian VAP > .5")

    ggsave("data-raw/TX/cvap_plots.png",
        p1 + p2 + p3 + p4 + p5 + p6 + p7,
        height = 10, width = 10, units = "in")
}
