###############################################################################
# Simulate plans for ```SLUG```
# ``COPYRIGHT``
###############################################################################

# Run the simulation -----

suppressMessages({
  library(cli)
  library(here)
  library(dplyr)
})

cli_process_start("Running simulations for {.pkg IA_ssd_2020}")

set.seed(2020)

mh_accept_per_smc <- 25

# Compute total SMC steps explicitly to avoid ms_frequency schedule issues
nd <- attr(map, "ndists")
if (is.null(nd)) nd <- length(unique(map[[attr(map, "existing_col")]]))
stopifnot(is.numeric(nd), nd > 1L)
n_steps <- nd - 1L

# Check which API is available
has_new_api <- "ms_frequency" %in% names(formals(redist::redist_smc))

if (has_new_api) {
  # --- New API (redist >= version that promotes params to top-level) ---
  plans <- redist::redist_smc(
    map,
    nsims = 2000, runs = 5,
    counties = pseudo_county,
    sampling_space = "linking_edge",
    n_steps = n_steps,
    ms_frequency = 1L,                      # was ms_params$frequency
    mh_accept_per_smc = mh_accept_per_smc,  # was inside ms_params
    splitting_schedule = "any_valid_sizes", # was inside split_params
    # pop_temper = 0.01,                    # enable if sampling stalls
    verbose = TRUE
  )
} else {
  # --- Old API (expects ms_params / split_params) ---
  plans <- redist::redist_smc(
    map,
    nsims = 2000, runs = 5,
    counties = pseudo_county,
    sampling_space = "linking_edge",
    n_steps = n_steps,  # <-- explicitly set steps to avoid "wrong sign in 'by'"
    ms_params    = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    # pop_temper = 0.01,
    verbose = TRUE
  )
}



# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans %>%
  dplyr::group_by(chain) %>%
  dplyr::filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
  dplyr::ungroup()

plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Ensure output directory exists (first run convenience)
dir.create(here::here("data-out/IA_2020"), recursive = TRUE, showWarnings = FALSE)

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IA_2020/IA_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IA_ssd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IA_2020/IA_ssd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)
}
