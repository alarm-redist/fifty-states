###############################################################################
# Simulate plans for `IA_cd_1990`
# © ALARM Project, February 2026
###############################################################################

suppressMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(redist)
  library(geomander)
  library(cli)
  library(here)
  library(ggplot2)
  library(patchwork)
  devtools::load_all()
})

map <- read_rds(here("data-out/IA_1990/IA_cd_1990_map.rds"))

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IA_cd_1990}")
set.seed(1990)
plans <- redist_smc(
  map, nsims = 5000, runs = 5,
  pop_temper = 0.05, seq_alpha = 1,
  # sampling_space = sampling_space_val,
  ms_params = list(frequency = 1L, mh_accept_per_smc = 70),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  verbose = T,
  ncores = 112
)

plans <- plans %>% filter(draw != "cd_1990") %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_1990)

plans <- match_numbers(plans, map$cd_1990)
cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IA_1990/IA_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IA_cd_1990}")

# special functions to calculate compactness metrics
M_PER_MI <- 1609.34
comp_lw <- function(map, plans = redist:::cur_plans()) {
  m <- as.matrix(plans)
  n_distr <- attr(map, "ndists")
  lw <- matrix(0, nrow = n_distr, ncol = ncol(m))
  for (i in seq_len(ncol(m))) {
    for (j in seq_len(n_distr)) {
      bbox <- st_bbox(map[m[, i] == j, ])
      lw[j, i] <- abs((bbox["xmax"] - bbox["xmin"]) -
                        (bbox["ymax"] - bbox["ymin"]))/M_PER_MI
    }
  }
  as.numeric(lw)
}
plans <- add_summary_stats(plans, map,
                           comp_lw = comp_lw(map),
                           area = tally_var(map, as.numeric(st_area(map))),
                           comp_polsby = comp_polsby(plans = plans, shp = map,
                                                     perim_path = here("data-out/IA_1990/perim.rds")),
                           comp_perim = sqrt(4*pi*area/comp_polsby)/M_PER_MI)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IA_1990/IA_cd_1990_stats.csv")
cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map)
  summary(plans)

  plans_sum <- plans %>%
    group_by(draw) %>%
    summarize(comp_lw = sum(.data$comp_lw),
              comp_perim = sum(.data$comp_perim))
  p_lw <- hist(plans_sum, comp_lw, bins = 40) + labs(title = "Length-width compactness") + theme_bw()
  p_perim <- hist(plans_sum, comp_perim, bins = 40) + labs(title = "Perimeter compactness") + theme_bw()
  p <- p_lw + p_perim + plot_layout(guides = "collect")
  ggsave("data-raw/IA/validation_comp.png", p, width = 10, height = 5)
}
