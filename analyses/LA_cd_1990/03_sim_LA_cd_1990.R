###############################################################################
# Simulate plans for `LA_cd_1990`
# © ALARM Project, March 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg LA_cd_1990}")

BVAP_THRESH <- 0.30
DEM_THRESH  <- 0.45

constr <- redist_constr(map) |>
    add_constr_grp_hinge(
        0.01,
        vap_black,
        vap,
        BVAP_THRESH)

set.seed(1990)
plans <- redist_smc(
    map,
    nsims = 2e4,
    runs = 5,
    counties = county,
    constraints = constr
)
plans <- match_numbers(plans, "cd_1990")

# Subset plans that are not performing
n_perf <- plans %>%
  mutate(
    bvap = group_frac(map, vap_black, vap),
    ndshare = group_frac(map, ndv, nrv + ndv)
  ) %>%
  group_by(draw) %>%
  summarize(n_black_perf = sum(bvap > BVAP_THRESH & ndshare > DEM_THRESH))

plans_5k <- plans %>%
  anti_join(filter(n_perf, n_black_perf == 0), by = "draw") %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
  ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/LA_1990/LA_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg LA_cd_1990}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/LA_1990/LA_cd_1990_stats.csv")

cli_process_done()

# Validation plots
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Louisiana Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2000 = "black")) +
        theme_bw()

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)
}
