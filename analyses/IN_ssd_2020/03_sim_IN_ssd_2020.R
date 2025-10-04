###############################################################################
# Simulate plans for IN_ssd_2020 — template-conformant (counties-only; ±5% tol)
###############################################################################
suppressMessages({
  library(cli); library(here); library(dplyr); library(readr); library(redist)
  devtools::load_all()
})
stopifnot(packageVersion("redist") >= "5.0.0")
set.seed(2020)

# Load map (keep your current path for this PR)
cli_process_start("Loading map for {.pkg IN_ssd_2020}")
map <- read_rds(here("data-out/IN_2020/IN_ssd_2020_map.rds"))
cli_process_done()

constr <- redist_constr(map)
plans_file <- here("data-out/IN_2020/IN_ssd_2020_plans.rds")

# Run SMC
cli_process_start("Running simulations for {.pkg IN_ssd_2020}")
if (file.exists(plans_file)) {
  cli_alert_info("Using existing plans from disk (no re-sampling).")
  plans <- read_rds(plans_file)
} else {
  plans <- redist_smc(
    map,
    nsims = 6000, runs = 5,
    constraints = constr,
    counties = county,
    sampling_space = "linking_edge",
    ms_params = list(frequency = 1L, mh_accept_per_smc = 35L),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    pop_temper = 0.02, seq_alpha = 1,
    verbose = TRUE,
    ncores = max(1, parallel::detectCores() - 1)
  )
  attr(plans, "existing_col") <- "ssd_2020"
  plans <- match_numbers(plans, "ssd_2020")
  # add enacted once (guarded below as well)
  if ("ssd_2020" %in% names(map))
    plans <- add_reference(plans, map$ssd_2020, name = "enacted")
  write_rds(plans, plans_file, compress = "xz")
}
cli_process_done()

# Compute & save summary stats
cli_process_start("Computing summary statistics for {.pkg IN_ssd_2020}")

# keep numbering consistent
attr(plans, "existing_col") <- "ssd_2020"
plans <- match_numbers(plans, "ssd_2020")

# add reference only if not already present (robust)
refs <- attr(plans, "reference"); has_enacted <- FALSE
if (!is.null(refs)) {
  if (is.data.frame(refs) && "name" %in% names(refs)) has_enacted <- any(refs$name == "enacted")
  else if (is.list(refs)) has_enacted <- "enacted" %in% names(refs)
}
if (!has_enacted && "ssd_2020" %in% names(map)) {
  plans <- tryCatch(add_reference(plans, map$ssd_2020, name = "enacted"),
                    error = function(e) if (grepl("already exists", conditionMessage(e))) plans else stop(e))
}

# force recompute & save stats (fixes missing plan_dev)
attr(plans, "summary") <- NULL
plans <- add_summary_stats(plans, map)
save_summary_stats(plans, here("data-out/IN_2020/IN_ssd_2020_stats.csv"))
cli_process_done()

# Optional: validation (keep in interactive only)
if (interactive()) {
  validate_analysis(plans, map)
}

