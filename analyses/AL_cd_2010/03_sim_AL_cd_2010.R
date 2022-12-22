###############################################################################
# Simulate plans for `AL_cd_2010`
# © ALARM Project, November 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AL_cd_2010}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(30, vap_black, vap, 0.40) %>%
    add_constr_grp_hinge(-30, vap_black, vap, 0.33)

set.seed(2010)
plans <- redist_smc(map, nsims = 10e3, runs = 2L,
    counties = county, constr = constr, pop_temper = 0.05)
plans <- match_numbers(plans, "cd_2010")

# Subset plans that are not performing
n_perf <- plans %>%
    mutate(bvap = group_frac(map, vap_black, vap),
        ndshare = group_frac(map, ndv, nrv + ndv)) %>%
    group_by(draw) %>%
    summarize(n_blk_perf = sum(bvap > 0.3 & ndshare > 0.5))

plans_5k <- plans %>%
    # subset non-performing plan
    anti_join(filter(n_perf, n_blk_perf == 0), by = "draw") %>%
    # thin to 5000 draws
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>%
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/AL_2010/AL_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AL_cd_2010}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/AL_2010/AL_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans_5k, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Alabama Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans_5k, (total_vap - vap_white)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Minority Percentage by VAP") +
        labs(title = "Alabama Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)

    # Total Black districts that are performing from subset
    plans_5k %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)

}
