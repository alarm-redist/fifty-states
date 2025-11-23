###############################################################################
# Simulate plans for `AL_shd_2020` SHD
# © ALARM Project, November 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AL_shd_2020}")

set.seed(2020)

mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3) + 75. # increase by 75 to 110

plans <- redist_smc(
    map_shd,
    nsims = 5e3, runs = 5,       # increase sample size from 2000 to 5000
    counties = pseudo_county,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AL_2020/AL_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AL_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AL_2020/AL_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)
}

# Load shd data
map <- read_rds(here("data-out/AL_2020/AL_leg_2020_map_shd.rds"))
plans <- read_rds(here("data-out/AL_2020/AL_shd_2020_plans.rds"))

plans <- add_summary_stats(plans, map)
write_rds(plans, here("data-out/AL_2020/AL_shd_2020_plans.rds"), compress = "xz")
plans <- read_rds(here("data-out/AL_2020/AL_shd_2020_plans.rds"))
names(plans)

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)

  # Create output directory
  dir.create(here("data-out/AL_2020/shd_bvap_plots"), showWarnings = FALSE, recursive = TRUE)

  # Black VAP Performance Plot
  p1 <- redist.plot.distr_qtys(plans, vap_black/total_vap,
                               color_thresh = NULL,
                               color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                               size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "Alabama Proposed Plan versus Simulations") +
    scale_color_manual(values = c(shd_2020 = "black")) +
    theme_bw()

  ggsave(here("data-out/AL_2020/shd_bvap_plots/bvap_performance.png"), p1, width = 10, height = 6)

  # Dem seats by BVAP rank -- numeric
  tbl1 <- plans %>%
    group_by(draw) %>%
    mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
    subset_sampled() %>%
    select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
    mutate(dem = ndv > nrv) %>%
    group_by(bvap_rank) %>%
    summarize(dem = mean(dem))

  print(tbl1, n = 105)
  write_csv(tbl1, here("data-out/AL_2020/shd_bvap_plots/dem_seats_by_bvap_rank.csv"))

  # Total Black districts that are performing
  tbl2 <- plans %>%
    subset_sampled() %>%
    group_by(draw) %>%
    summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
    count(n_black_perf)

  print(tbl2)
  write_csv(tbl2, here("data-out/AL_2020/shd_bvap_plots/total_black_performant.csv"))
}
