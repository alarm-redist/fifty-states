###############################################################################
# Simulate plans for `HI_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_2000}")

set.seed(2000)

plans_honolulu <- redist_smc(
  map_honolulu,
  nsims = 2e3, runs = 5,
  n_steps = 1,
  counties = county
)
plan_mat <- get_plans_matrix(plans_honolulu)[, -1]
wts      <- get_plans_weights(plans_honolulu)[-1]
cli_process_done()

keep_idx <- unlist(lapply(
  0:4,
  function(i) (i*2000 + 1):(i*2000 + 1000) + 1
))

plan_mat_thin <- plan_mat[, keep_idx, drop = FALSE]
wts_thin      <- wts     [       keep_idx ]

n_units  <- nrow(map)
full_mat_thin <- matrix(2L, n_units, ncol = ncol(plan_mat_thin))
hono_idx      <- map$GEOID %in% map_honolulu$GEOID
full_mat_thin[hono_idx, ] <- plan_mat_thin

plans <- redist_plans(
  plans       = full_mat_thin,
  map         = map,
  algorithm   = "smc",
  wgt         = wts_thin,
  diagnostics = attr(plans_honolulu, "diagnostics")
) %>%
  add_reference(map$cd_2000, "cd_2000") %>%
  match_numbers("cd_2000")

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/HI_2000/HI_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_2000/HI_cd_2000_stats.csv")

cli_process_done()
