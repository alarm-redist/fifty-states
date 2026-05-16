###############################################################################
# Simulate plans for `NY_ssd_2020` SSD
# © ALARM Project, March 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NY_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_ssd$ssd_2020)/3) + 150

constr <- redist_constr(map_ssd) |>
    add_constr_total_splits(strength = 1.5, admin = map_ssd$county)

plans <- redist_smc(
    map_cores_ssd,
    nsims = 2e3, runs = 5,
    # ncores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")),
    counties = pseudo_county,
    constraints = constr,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
) |> pullback(map_ssd)

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NY_2020/NY_ssd_2020_plans.rds"), compress = "xz")

cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NY_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "NY_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)
    validate_analysis(plans, map_ssd)
    summary(plans)

    # competitiveness plot -----
    plans <- plans |> mutate(dvs_20 = group_frac(map_ssd, adv_20, adv_20 + arv_20))
    redist.plot.distr_qtys(plans, qty = dvs_20, geom = "boxplot") + theme_bw() +
        lims(y = c(0.25, 0.9)) +
        labs(title = "Competitiveness")

    # cores preservation plot -----
    plans_nocores <- redist_smc(
        map_ssd,
        nsims = 200,
        runs = 2,
        counties = map_ssd$pseudo_county
    )

    d_overl <- bind_rows(
        with_cores = as_tibble(match_numbers(plans, map_ssd$ssd_2010)),
        no_cores = as_tibble(match_numbers(plans_nocores, map_ssd$ssd_2010)),
        .id = "run"
    )

    ggplot(d_overl |> distinct(run, draw, pop_overlap),
        aes(x = pop_overlap, color = run, fill = run)) +
        geom_density(alpha = 0.3)
}
