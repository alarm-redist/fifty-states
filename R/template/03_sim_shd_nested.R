###############################################################################
# Simulate plans for ```SLUG``` SSD
# ``COPYRIGHT``
###############################################################################
library(foreach)
library(doParallel)
library(doRNG)

# Run the simulation -----
cli_process_start("Running simulations for {.pkg ``SLUG``}")

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(``YEAR``)

# Generate district assignment matrix
sample_ssd_matrix <- get_plans_matrix(subset_sampled(plans))

# Create shd map object
map_shd_iterate <- redist_map(``state``_shp, pop_tol = 0.05,
                              ndists = n_distinct(map_shd$shd_``YEAR``), adj = ``state``_shp$adj)

# Unique ID for each row, will use later to reconnect pieces
map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

# TODO set equal to one third of number of districts, increase by 10-15 if no convergence
mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_``YEAR``)/3)

# Simulation hyperparameters
inner_nsims <- 2000
inner_runs <- 1
inner_splits <- n_distinct(map_shd$shd_``YEAR``)/n_distinct(map_ssd$ssd_``YEAR``)
final_sims <- ncol(sample_shd_matrix)

# TODO set equal to number of runs in state senate simulations
outer_runs <- 5

ncores <- min(inner_runs, parallel::detectCores() - 1)

# Set up log file
logfile <- "log.txt"
file.create(logfile)

# Set up parallelization
cl <- parallel::makeCluster(ncores, outfile = logfile, methods = FALSE,
                            useXDR = .Platform$endian != "little")

registerDoParallel(cl)

# Outer loop: senate simulations
plans_shd <- foreach(i = 1:final_sims, .combine='rbind',
                    .export = c("prep_particles", "rep_cols", "rep_col"),
                    .packages = c('tidyverse', 'redist')) %dorng% {

  # Add senate district assignment from simulation i
  map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[,i])

  plan_list <- vector("list", max(map_shd_iterate$ssd_sim))

  # Inner loop: simulated senate districts
  for (j in 1:max(map_shd_iterate$ssd_sim)) {
    # Filter by senate district
    m <- map_shd_iterate %>%
      filter(ssd_sim == j)

    map_j <- redist_map(m, pop_tol = 0.05,
                            ndists = inner_splits, adj = m$adj)

    # Run inner simulation
    plans_j <- redist_smc(
      map_j,
      nsims = inner_nsims, runs = inner_runs,
      counties = ssd_sim,
      sampling_space = "linking_edge",
      ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
      split_params = list(splitting_schedule = "any_valid_sizes"),
      verbose = T
    ) %>%
      filter(draw == inner_nsims*inner_runs) # select final plan

    plans_j$dist_keep = T

    # Save map and plan
    plan_list[[j]] <- list(map = map_j, plans = plans_j)

  }

  # Combine into single state-wide plan
  prep_mat <- prep_particles(map = map_shd_iterate,
                             map_plan_list = plan_list,
                             uid = row_id, dist_keep = dist_keep, nsims = 1)

  plans_i <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")

  # Counter for log file
  cat("\n FINISHED HOUSE DISTRICT", i, "OF", final_sims, "\n")

  plans_i

}

stopCluster(myCluster)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Add draw and chain numbering
plans_shd$draw <- as.factor(rep(1:final_sims, each = n_distinct(map_shd$shd_``YEAR``)))
plans_shd$chain <- rep(1:outer_runs, each = n_distinct(map_shd$shd_``YEAR``)*final_sims/outer_runs)

# Add enacted plan
plans_shd <- add_reference(plans_shd, ref_plan = map_shd$shd_``YEAR``, name = "shd_``YEAR``")

# Output the redist_map object. Do not edit this path.
write_rds(plans_shd, here("data-out/``STATE``_``YEAR``/``SLUG``_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ``SLUG``}")

plans <- add_summary_stats(plans_shd, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/``STATE``_``YEAR``/``SLUG``_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map_shd)
  summary(plans)

  # Extra validation plots for custom constraints -----
  # TODO remove this section if no custom constraints

}

# Delete log file when done
file.remove(logfile)
