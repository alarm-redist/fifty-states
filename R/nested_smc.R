nested_smc <- function(plans, map_ssd, map_shd, shp, inner_nsims = 50, inner_runs = 1, outer_runs = 5, max_split_tries = 100000, ncores = min(inner_runs, parallel::detectCores() - 1)){

  library(foreach)
  library(doParallel)
  library(doRNG)

  # Generate district assignment matrix
  sample_ssd_matrix <- get_plans_matrix(subset_sampled(plans))

  # Create shd map object
  map_shd_iterate <- redist_map(shp, pop_tol = 0.05,
                              ndists = n_distinct(map_shd$shd_``YEAR``), adj = shp$adj)

  # Unique ID for each row, will use later to reconnect pieces
  map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

  # Simulation hyperparameters
  inner_splits <- n_distinct(map_shd$shd_``YEAR``)/n_distinct(map_ssd$ssd_``YEAR``)
  final_sims <- ncol(sample_shd_matrix)

  # Set up log file
  logfile <- "data-out/``STATE``_``YEAR``/nested_log.txt"
  file.create(logfile)

  # Set up parallelization
  cl <- parallel::makeCluster(ncores, outfile = logfile, methods = FALSE,
                            useXDR = .Platform$endian != "little")

  registerDoParallel(cl)
  clusterExport(cl, c("rep_cols", "rep_col", "prep_particles"))

  # Outer loop: senate simulations
  plans_shd <- foreach(i = 1:final_sims, .combine='rbind',
                    .export = c("prep_particles", "rep_cols", "rep_col"),
                    .packages = c('tidyverse', 'redist')) %dorng% {

    # Add senate district assignment from simulation i
    map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[,i])

    plan_list <- vector("list", max(map_shd_iterate$ssd_sim))

    failed <- FALSE

    # Inner loop: simulated senate districts
    for (j in 1:max(map_shd_iterate$ssd_sim)) {
      m <- map_shd_iterate %>%
        filter(ssd_sim == j)
      map_j <- redist_map(m, pop_tol = 0.05,
                          ndists = inner_splits, adj = m$adj)

      output <- capture.output({
        result <- tryCatch({
          plans_j <- redist_smc(
            map_j,
            nsims = inner_nsims, runs = inner_runs,
            counties = ssd_sim,
            sampling_space = "linking_edge",
            ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
            split_params = list(splitting_schedule = "any_valid_sizes"),
            verbose = TRUE,
            control = list(max_split_tries = max_split_tries)
          )

          # Catch error
        }, error = function(e) {

          NULL
        })
      }, type = "output")

      # Catch fail to split warning
      if (is.null(result) || any(grepl("Failed to split", output))) {
        failed <- TRUE
        cat("\nFAILURE at outer i =", i, "inner j =", j, "\n", file = "log.txt", append = TRUE)
        break
      }

      plans_j <- plans_j %>% filter(draw == inner_nsims * inner_runs)
      plans_j$dist_keep <- TRUE
      plan_list[[j]] <- list(map = map_j, plans = plans_j)
    }

    if (failed) {
      # Return dummy plan
      prep_mat <- rep(1:n_distinct(map_shd$shd_2020), length.out = nrow(map_shd_iterate))
      plans_dummy <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")
      plans_dummy$draw <- as.factor(999)

      return(plans_dummy)
    }

    # Combine into single state-wide plan
    prep_mat <- prep_particles(map = map_shd_iterate,
                               map_plan_list = plan_list,
                               uid = row_id, dist_keep = dist_keep, nsims = 1)

    plans_i <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")

    # Counter for log file
    cat("\n FINISHED HOUSE DISTRICT ", i, " OF ", final_sims, file = "log.txt", append = TRUE)

    plans_i

  }
  stopCluster(cl)

  # Determine effective sample size
  survive <- plans_shd %>%
    as.data.frame() %>%
    filter(district == 1) %>%
    mutate(survive = ifelse(draw == 1, TRUE, FALSE)) %>%
    dplyr::select(survive)

  ess_prop <- mean(survive$survive)
  ess <- ess_prop*final_sims

  # Add draw and chain numbering
  plans_shd <- plans_shd %>%
    filter(draw != 999)

  # Add draw and chain numbering
  plans_shd$draw <- as.factor(rep(1:final_sims, each = n_distinct(map_shd$shd_``YEAR``)))
  plans_shd$chain <- rep(1:outer_runs, each = n_distinct(map_shd$shd_``YEAR``)*final_sims/outer_runs)

  # Add enacted plan
  plans_shd <- add_reference(plans_shd, ref_plan = map_shd$shd_``YEAR``, name = "shd_``YEAR``")

  return(list(plans_shd, ess, survive$survive))

}


