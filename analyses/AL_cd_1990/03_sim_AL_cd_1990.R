###############################################################################
# Simulate plans for `AL_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AL_cd_1990}")

BVAP_THRESH  <- 0.40
DEM_THRESH   <- 0.50
ndists <- attr(map, "ndists")
constr <- redist_constr(map) |>
  add_constr_min_group_frac(
    strength = -1,
    group_pops = list(map$vap_black, map$ndv),
    total_pops = list(map$vap, map$nrv + map$ndv),
    min_fracs = c(BVAP_THRESH, DEM_THRESH),
    thresh = -.9,
    only_nregions = seq.int(2, ndists)
  )

set.seed(1990)
plans <- redist_smc(map, nsims = 3e3, runs = 6,
                    counties = county, constraints=constr,
                    split_params = list(splitting_schedule = "any_valid_sizes"),
                    sampling_space = "spanning_forest",
                    ms_params = list(frequency = -5, mh_accept_per_smc = 50),
                    pop_temper = 0.01,
                    ncores = 112,
                    verbose = TRUE)

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AL_1990/AL_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AL_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AL_1990/AL_cd_1990_stats.csv")

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
        scale_color_manual(values = c(cd_2000 = "black"))

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
}
