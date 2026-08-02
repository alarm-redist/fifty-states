###############################################################################
# Simulate plans for `AZ_cd_1990`
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AZ_cd_1990}")

set.seed(1990)

constr_seed <- redist_constr(map) %>%
    add_constr_splits(strength = 0.25, admin = county_muni) %>%
    add_constr_grp_hinge(120, vap_hisp, vap, 0.50, only_districts = TRUE)

plans_seed <- redist_smc(map, nsims = 30000, counties = pseudo_county,
    constraints = constr_seed, n_steps = 1)

init_m <- get_plans_matrix(plans_seed)
init_m <- init_m[, sample(ncol(init_m), 4000), drop = FALSE]

constr_az <- redist_constr(map) %>%
    add_constr_splits(strength = 0.10, admin = county_muni) %>%
    add_constr_grp_hinge(30, vap_hisp, vap, 0.45, only_districts = TRUE) %>%
    add_constr_grp_hinge(-30, vap_hisp, vap, 0.20, only_districts = TRUE)

set.seed(1990)
plans <- redist_smc(map, nsims = 4000, runs = 5, counties = pseudo_county,
    constraints = constr_az, init_particles = init_m)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AZ_1990/AZ_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AZ_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AZ_1990/AZ_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Opportunity-district benchmarks, computed from the current data
    enacted <- sf::st_drop_geometry(map) |>
        group_by(cd_1990) |>
        summarize(hvap = sum(vap_hisp)/sum(vap), hpop = sum(pop_hisp)/sum(pop))
    enacted_hvap <- max(enacted$hvap) # 0.4344, CD 5
    enacted_hpop <- max(enacted$hpop) # 0.4923, CD 5

    # Hispanic VAP by district, against the opportunity-district benchmarks
    plans |>
        mutate(hvap = vap_hisp/total_vap) |>
        redist.plot.distr_qtys(hvap, sort = "asc", geom = "boxplot",
            color_thresh = NULL, size = 0.2) +
        geom_hline(yintercept = 0.40, linetype = "dashed", color = "#1f6f8b") +
        geom_hline(yintercept = enacted_hvap, linetype = "solid", color = "#b3382c") +
        geom_hline(yintercept = 0.4477, linetype = "dotted", color = "#5a5a5a") +
        scale_y_continuous("Percent Hispanic by VAP", labels = scales::percent) +
        labs(x = "Districts, ordered by Hispanic VAP",
            title = "Hispanic VAP against the 1992 court-plan benchmarks")

    # Opportunity districts, defined on Hispanic VAP alone
    plans |>
        subset_sampled() |>
        mutate(hvap = vap_hisp/total_vap) |>
        group_by(draw) |>
        summarize(max_hvap = max(hvap)) |>
        summarize(median_max_hvap = median(max_hvap),
            q10_max_hvap = quantile(max_hvap, 0.10),
            q90_max_hvap = quantile(max_hvap, 0.90),
            p_ge_0.35 = mean(max_hvap >= 0.35),
            p_ge_0.40 = mean(max_hvap >= 0.40),
            p_ge_enacted = mean(max_hvap >= enacted_hvap),
            p_ge_0.4477 = mean(max_hvap >= 0.4477)) |>
        print(width = Inf)
}
