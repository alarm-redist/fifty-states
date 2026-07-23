###############################################################################
# Simulate plans for `NY_shd_2020` SHD
# © ALARM Project, March 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NY_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 150

constr <- redist_constr(map_shd) |>
    add_constr_total_splits(strength = 1.6, admin = map_shd$county)

plans <- redist_smc(
    map_shd,
    nsims = 2e3, runs = 5,
    # ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")),
    constraints = constr,
    counties = map_shd$shd_2010,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NY_2020/NY_shd_2020_plans.rds"), compress = "xz")

cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NY_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "NY_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)
    validate_analysis(plans, map_shd)
    summary(plans)

    # competitiveness plot -----
    plans_comp <- plans |> mutate(dvs_20 = group_frac(map_shd, adv_20, adv_20 + arv_20))
    p_comp <- redist.plot.distr_qtys(plans_comp, qty = dvs_20, geom = "boxplot") + theme_bw() +
        lims(y = c(0.25, 0.9)) +
        labs(title = "Competitiveness")
    print(p_comp)

    # cores preservation plot -----
    p_core <- plans |>
        match_numbers(map_shd$shd_2010) |>
        hist(pop_overlap)
    print(p_core)
}
