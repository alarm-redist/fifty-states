###############################################################################
# Simulate plans for `OR_shd_2020` SHD
# © ALARM Project, January 2026
###############################################################################

nested_smc <- function(plans, map_ssd, map_shd, shp, inner_nsims = 50, inner_runs = 1, outer_runs = 5, year = 2020, state, max_split_tries = 100000, ncores = 8) {

  library(foreach)
  library(doParallel)
  library(doRNG)

  shd_col <- paste0("shd_", year)
  ssd_col <- paste0("ssd_", year)

  # Generate district assignment matrix
  sample_ssd_matrix <- get_plans_matrix(subset_sampled(plans))

  # Create shd map object
  map_shd_iterate <- redist_map(shp, pop_tol = 0.05,
                                ndists = n_distinct(map_shd[[shd_col]]), adj = shp$adj)

  # Unique ID for each row, will use later to reconnect pieces
  map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

  # Simulation hyperparameters
  inner_splits <- n_distinct(map_shd[[shd_col]])/n_distinct(map_ssd[[ssd_col]])
  final_sims <- ncol(sample_ssd_matrix)

  # Set up log file
  logfile <- sprintf("data-out/OR_2020/nested_log.txt", state, year)
  file.create(logfile)

  # Set up parallelization
  cl <- parallel::makeCluster(ncores, outfile = logfile, methods = FALSE,
                              useXDR = .Platform$endian != "little")

  registerDoParallel(cl)

  # Outer loop: senate simulations
  plans_shd <- foreach(i = 1:final_sims, .combine = "rbind",
                       .export = c("prep_particles", "rep_cols", "rep_col"),
                       .packages = c("tidyverse", "redist")) %dorng% {
                         # mh_accept_per_smc <- 1
                         devtools::load_all()

                         # Add senate district assignment from simulation i
                         map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[, i])

                         plan_list <- vector("list", max(map_shd_iterate$ssd_sim))

                         failed <- FALSE

                         # Inner loop: simulated senate districts
                         for (j in 1:max(map_shd_iterate$ssd_sim)) {
                           m <- map_shd_iterate %>%
                             filter(ssd_sim == j)
                           map_j <- redist_map(m, pop_bounds = attr(map_shd_iterate, "pop_bounds"),
                                               ndists = inner_splits, adj = m$adj)


                           # Constraints here

                           output <- capture.output(
                             {
                               result <- tryCatch(
                                 {
                                   plans_j <- redist_smc(
                                     map_j,
                                     nsims = inner_nsims, runs = inner_runs,
                                     counties = county,
                                     sampling_space = "linking_edge",
                                     # constraints = constr,
                                     pop_temper = 0.02,
                                     # ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
                                     split_params = list(splitting_schedule = "any_valid_sizes"),
                                     verbose = TRUE,
                                     control = list(max_split_tries = max_split_tries)
                                   )

                                   # Catch error
                                 },
                                 error = function(e) {

                                   NULL
                                 })
                             },
                             type = "output")

                           # Catch fail to split warning
                           if (is.null(result) || any(grepl("Failed to split", output))) {
                             failed <- TRUE
                             cat("\nFAILURE at outer i =", i, "inner j =", j, "\n", file = logfile, append = TRUE)
                             break
                           }

                           plans_j <- plans_j %>% filter(draw == inner_nsims*inner_runs)
                           plans_j$dist_keep <- TRUE
                           plan_list[[j]] <- list(map = map_j, plans = plans_j)
                         }

                         if (failed) {
                           # Return dummy plan
                           prep_mat <- rep(1:n_distinct(map_shd$shd_2020), length.out = nrow(map_shd_iterate))
                           plans_dummy <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")
                           plans_dummy$draw <- as.factor(99999)

                           return(plans_dummy)
                         }

                         # Combine into single state-wide plan
                         prep_mat <- prep_particles(map = map_shd_iterate,
                                                    map_plan_list = plan_list,
                                                    uid = row_id, dist_keep = dist_keep, nsims = 1)

                         plans_i <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")

                         # Counter for log file
                         cat("\nFINISHED HOUSE DISTRICT ", i, " OF ", final_sims, file = logfile, append = TRUE)

                         plans_i

                       }

  stopCluster(cl)

  # Determine effective sample size
  survive <- plans_shd %>%
    as.data.frame() %>%
    filter(district == 1) %>%
    mutate(survive = ifelse(draw == 1, TRUE, FALSE)) %>%
    dplyr::select(survive)

  survive_all <- plans_shd %>%
    as.data.frame() %>%
    mutate(survive_all = ifelse(draw == 1, TRUE, FALSE)) %>%
    dplyr::select(survive_all)

  saveRDS(survive_all, "data-out/OR_2020/survive_all.rds")

  plans_shd_matrix <- get_plans_matrix(plans_shd)
  plans_shd_matrix <- plans_shd_matrix[, survive$survive]

  plans_shd <- redist_plans(plans = plans_shd_matrix,
                            map = map_shd,
                            algorithm = "smc")

  # Add draw and chain numbering
  plans_shd$draw <- as.factor(rep(1:sum(survive$survive), each = n_distinct(map_shd[[shd_col]])))

  full_chain <- rep(1:outer_runs, each = n_distinct(map_shd[[shd_col]])*final_sims/outer_runs)

  plans_shd$chain <- full_chain[survive_all$survive_all]

  # Add enacted plan
  plans_shd <- add_reference(plans_shd, ref_plan = map_shd[[shd_col]], name = shd_col)

  return(plans_shd)

}

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OR_shd_2020}")

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
set.seed(2020)

# TODO set equal to one third of number of districts, increase by 10-15 if no convergence
#mh_accept_per_smc <- ceiling(n_distinct(map_shd$shd_2020)/3)

plans <- readRDS("data-raw/OR/OR_ssd_2020_plans_oversample.rds")

plans <- nested_smc(plans, map_ssd, map_shd, shp = or_shp, state = "OR", ncores = 64)


# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
  ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OR_2020/OR_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OR_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OR_2020/OR_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map_shd)
  summary(plans)

  # Extra validation plots for custom constraints -----
  # TODO remove this section if no custom constraints
}
