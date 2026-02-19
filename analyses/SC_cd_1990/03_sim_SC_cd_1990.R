###############################################################################
# Simulate plans for `SC_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_1990}")

ndists <- attr(map, "ndists")

constr <- redist_constr(map) |>
  # Black VAP: push for >= 0.40 in at least 2 districts
  add_constr_min_group_frac(
    strength      = -1,
    group_pops    = list(map$vap_black),
    total_pops    = list(map$vap),
    min_fracs     = c(0.4),
    thresh        = -.9,
    only_nregions = seq.int(3L, ndists)
  ) |>
  # anti-cracking: encourage more districts with less BVAP share
  add_constr_grp_inv_hinge(
    3,
    vap_black,
    total_pop = vap,
    tgts_group = c(0.2)
  )

set.seed(1990)
plans <- redist_smc(
  map,
  nsims = 5000,
  runs = 6,
  counties = pseudo_county,
  constraints = constr,
  split_params = list(splitting_schedule = "any_valid_sizes"),
  sampling_space = "spanning_forest",
  ms_params = list(frequency = 5L, mh_accept_per_smc = 20L),
  ncores = 112,
  pop_temper = 0.01,
  seq_alpha = 0.95,
  verbose = TRUE
)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/SC_1990/SC_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# read in from FASRC
map <- readRDS(
  here("data-out/SC_1990/SC_cd_1990_map.rds")
)
plans <- readRDS(
  here("data-out/SC_1990/SC_cd_1990_plans.rds")
)
stats <- read_csv(
  here("data-out/SC_1990/SC_cd_1990_stats.csv"),
  show_col_types = FALSE
)

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg SC_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/SC_1990/SC_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Black VAP Performance Plot
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
