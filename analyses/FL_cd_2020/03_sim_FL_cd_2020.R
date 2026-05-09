###############################################################################
# Simulate plans for `FL_cd_2020`
# © ALARM Project, March 2022
###############################################################################

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

constraints <- redist_constr(map) %>%
    # Use one statewide VRA bundle rather than stacking the prior regional
    # Florida bundles, following the converged FL 2000 statewide run.
    add_constr_grp_hinge(5, vap_black, vap, 0.45) %>%
    add_constr_grp_hinge(-7, vap_black, vap, 0.20) %>%
    add_constr_grp_hinge(5, vap_hisp, vap, 0.55) %>%
    add_constr_grp_hinge(-7, vap_hisp, vap, 0.25) %>%
    add_constr_grp_hinge(
        12,
        vap_hisp,
        total_pop = vap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_grp_hinge(
        12,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.50)
    )

set.seed(2020)
plans <- redist_smc(
    map, nsims = 2500, runs = 8L,
    counties = pseudo_county,
    constraints = constraints,
    pop_temper = 0.05, seq_alpha = 1,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    ncores = max(1, parallel::detectCores() - 1)
) %>%
    filter(draw != "cd_2020") %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 625) %>%
    ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_2020)
plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2020/FL_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_2020}")

plans <- add_summary_stats(plans, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

summary(plans)

validate_analysis(plans, map)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2020/FL_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    redist.plot.distr_qtys(
        plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2020 = "black"))

    redist.plot.distr_qtys(
        plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Partisanship of seats by HVAP rank") +
        scale_color_manual(values = c(cd_2020 = "black"))

    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    plans %>%
        group_by(draw) %>%
        mutate(hvap = vap_hisp/total_vap, hvap_rank = rank(hvap)) %>%
        subset_sampled() %>%
        select(draw, district, hvap, hvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(hvap_rank) %>%
        summarize(dem = mean(dem))

    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)

    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_hisp_perf = sum(vap_hisp/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_hisp_perf)

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
        labs(title = "FL Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black"))

    d2 <- redist.plot.distr_qtys(
        plans,
        vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "FL Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black"))

    d3 <- redist.plot.distr_qtys(
        plans,
        (vap_hisp + vap_black)/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB",
            "#B25D4C"
        ),
        size = 0.5,
        alpha = 0.5
    ) +
        scale_y_continuous("HVAP + BVAP / VAP") +
        labs(title = "FL Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black"))

    ggsave(
        plot = d1/d2,
        filename = "data-raw/FL/vap_plots.png",
        height = 9,
        width = 9
    )
    ggsave(
        plot = d3,
        filename = "data-raw/FL/vap_sum_plots.png",
        height = 9,
        width = 9
    )

    psum <- plans %>%
        group_by(draw) %>%
        mutate(vap_nonwhite = total_vap - vap_white) %>%
        summarize(
            all_hvap = sum((vap_hisp/total_vap) > 0.4),
            dem_hvap = sum((vap_hisp/total_vap) > 0.4 &
                (ndv > nrv)),
            rep_hvap = sum((vap_hisp/total_vap) > 0.4 &
                (nrv > ndv)),
            all_bvap_40 = sum((vap_black/total_vap) > 0.4),
            all_bvap_25 = sum((vap_black/total_vap) > 0.25),
            dem_bvap_25 = sum((vap_black/total_vap) > 0.25 & (ndv > nrv)),
            mmd_all = sum(vap_nonwhite/total_vap > 0.5),
            mmd_coalition = sum(((
                vap_hisp + vap_black
            )/total_vap) > 0.5)
        )

    p1 <- redist.plot.hist(psum, mmd_coalition) + labs(x = "HVAP + BVAP > 0.5", y = NULL)
    p2 <- redist.plot.hist(psum, all_hvap) + labs(x = "HVAP > 0.4", y = NULL)
    p3 <- redist.plot.hist(psum, dem_hvap) + labs(x = "HVAP > 0.4 & Dem > Rep", y = NULL)
    p4 <- redist.plot.hist(psum, rep_hvap) + labs(x = "HVAP > 0.4 & Dem < Rep", y = NULL)
    p5 <- redist.plot.hist(psum, all_bvap_40) + labs(x = "BVAP > 0.4", y = NULL)
    p6 <- redist.plot.hist(psum, all_bvap_25) + labs(x = "BVAP > 0.25", y = NULL)
    p7 <- redist.plot.hist(psum, dem_bvap_25) + labs(x = "BVAP > 0.25 & Dem > Rep", y = NULL)

    ggsave("data-raw/FL/vap_histograms.png", p1/p2/p3/p4/p5/p6/p7, height = 10)

    cpsum <- plans %>%
        group_by(draw) %>%
        mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
        summarize(
            all_hvap = sum((cvap_hisp/total_cvap) > 0.4),
            dem_hvap = sum((cvap_hisp/total_cvap) > 0.4 &
                (ndv > nrv)),
            rep_hvap = sum((cvap_hisp/total_cvap) > 0.4 &
                (nrv > ndv)),
            all_bvap_40 = sum((cvap_black/total_cvap) > 0.4),
            all_bvap_25 = sum((cvap_black/total_cvap) > 0.25),
            dem_bvap_25 = sum((cvap_black/total_cvap) > 0.25 & (ndv > nrv)),
            mmd_all = sum(cvap_nonwhite/total_cvap > 0.5),
            mmd_coalition = sum(((
                cvap_hisp + cvap_black
            )/total_cvap) > 0.5)
        )

    p8 <- redist.plot.hist(cpsum, mmd_coalition) + labs(x = "HCVAP + BCVAP > 0.5", y = NULL)
    p9 <- redist.plot.hist(cpsum, all_hvap) + labs(x = "HCVAP > 0.4", y = NULL)
    p10 <- redist.plot.hist(cpsum, dem_hvap) + labs(x = "HCVAP > 0.4 & Dem > Rep", y = NULL)
    p11 <- redist.plot.hist(cpsum, rep_hvap) + labs(x = "HCVAP > 0.4 & Dem < Rep", y = NULL)
    p12 <- redist.plot.hist(cpsum, all_bvap_40) + labs(x = "BCVAP > 0.4", y = NULL)
    p13 <- redist.plot.hist(cpsum, all_bvap_25) + labs(x = "BCVAP > 0.25", y = NULL)
    p14 <- redist.plot.hist(cpsum, dem_bvap_25) + labs(x = "BCVAP > 0.25 & Dem > Rep", y = NULL)

    ggsave("data-raw/FL/cvap_histograms.png", p8/p9/p10/p11/p12/p13/p14, height = 10)
}
