###############################################################################
# Simulate plans for IN_ssd_2020 (counties-only; ±5% tol)
###############################################################################
suppressMessages({
  library(cli); library(here); library(dplyr); library(readr); library(redist)
  devtools::load_all()
})
stopifnot(packageVersion("redist") >= "5.0.0")
set.seed(2020)

# Load map
cli_process_start("Loading map for {.pkg IN_ssd_2020}")
ssd_map <- readr::read_rds(here::here("data-out/IN_2020/IN_ssd_2020_map.rds"))
cli_process_done()

constr <- redist_constr(map)
plans_file <- here("data-out/IN_2020/IN_ssd_2020_plans.rds")

# Run SMC
set.seed(2020)
mh_accept_per_smc <- 35L

plans <- redist_smc(
  ssd_map,
  nsims = 6000, runs = 5,
  counties = county,                 # counties-only baseline
  sampling_space = "linking_edge",
  ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  pop_temper = 0.02, seq_alpha = 1,
  verbose = TRUE,
  ncores = max(1, parallel::detectCores() - 1)
)


plans <- match_numbers(plans, "ssd_2020")

cli_process_start("Saving {.cls redist_plans} object")
readr::write_rds(plans, here::here("data-out/IN_2020/IN_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()


# ---- Compute & save summary stats ----
cli_process_start("Computing summary statistics for {.pkg IN_ssd_2020}")
plans <- add_summary_stats(plans, ssd_map)
save_summary_stats(plans, "data-out/IN_2020/IN_ssd_2020_stats.csv")
cli_process_done()

# ---- Validation ----
if (interactive()) {
  validate_analysis(plans, ssd_map)
  summary(plans)
}

