###############################################################################
# Simulate plans for `NV_shd_2020` SHD
# © ALARM Project, June 2026
###############################################################################

library(foreach)
library(doParallel)
library(doRNG)

# Nested SMC function -----
nested_smc <- function(plans, map_ssd, map_shd, shp,
                       inner_nsims = 2000, inner_runs = 1, outer_runs = 5,
                       year = 2020, state, max_split_tries = 100000,
                       ncores = 60) {

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
    map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

    # Simulation hyperparameters
    inner_splits <- n_distinct(map_shd[[shd_col]])/n_distinct(map_ssd[[ssd_col]])
    final_sims <- ncol(sample_ssd_matrix)
    stopifnot(final_sims %% outer_runs == 0)

    mh_accept_per_smc <- ceiling(n_distinct(map_shd[[shd_col]])/3)

    # Set up log file
    dir.create(sprintf("data-out/%s_%s", state, year), recursive = TRUE, showWarnings = FALSE)
    logfile <- sprintf("data-out/%s_%s/nested_log.txt", state, year)
    file.create(logfile)

    # Set up parallelization
    cl <- parallel::makeCluster(ncores, outfile = logfile, methods = FALSE,
        useXDR = .Platform$endian != "little")
    registerDoParallel(cl)

    # Make sure the fifty.states package is loaded on each worker
    clusterEvalQ(cl, {
        devtools::load_all("/n/home08/mquintero/50StatesALARM")
    })

    # Outer loop: senate simulations
    plans_shd <- foreach(i = 1:final_sims, .combine = "rbind",
        .packages = c("tidyverse", "redist")) %dorng% {

        t_outer_start <- Sys.time()
        map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[, i])
        plan_list <- vector("list", max(map_shd_iterate$ssd_sim))
        failed <- FALSE

        # Inner loop: simulated senate districts
        for (j in 1:max(map_shd_iterate$ssd_sim)) {
            m <- map_shd_iterate %>% filter(ssd_sim == j)
            map_j <- redist_map(m, pop_bounds = attr(map_shd_iterate, "pop_bounds"), ndists = inner_splits, adj = m$adj)

            output <- capture.output(
                {
                    result <- tryCatch(
                        {
                            redist_smc(
                                map_j,
                                nsims = inner_nsims, runs = inner_runs,
                                counties = ssd_sim,
                                sampling_space = "linking_edge",
                                ms_params = list(frequency = 1L, mh_accept_per_smc = mh_accept_per_smc),
                                split_params = list(splitting_schedule = "any_valid_sizes"),
                                verbose = TRUE,
                                control = list(max_split_tries = max_split_tries),
                                ncores = 1
                            )
                        },
                        error = function(e) NULL)
                },
                type = "output")

            # Catch fail-to-split or outright error
            if (is.null(result) || any(grepl("Failed to split", output))) {
                failed <- TRUE
                cat("\nFAILURE at outer i =", i, "inner j =", j, "\n", file = logfile, append = TRUE)
                break
            }

            plans_j <- result %>% filter(draw == inner_nsims*inner_runs)
            plans_j$dist_keep <- TRUE
            plan_list[[j]] <- list(map = map_j, plans = plans_j)
        }

        if (failed) {
            # Return dummy plan so foreach/.combine doesn't break; filtered out later via `survive`
            prep_mat <- rep(1:n_distinct(map_shd[[shd_col]]), length.out = nrow(map_shd_iterate))
            plans_dummy <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")
            plans_dummy$draw <- as.factor(99999)
            return(plans_dummy)
        }

        # Combine into single state-wide plan
        prep_mat <- prep_particles(map = map_shd_iterate, map_plan_list = plan_list,
            uid = row_id, dist_keep = dist_keep, nsims = 1)
        plans_i <- redist_plans(plans = prep_mat, map_shd_iterate, algorithm = "smc")

        cat("\nFINISHED HOUSE DISTRICT ", i, " OF ", final_sims,
            " | TOTAL outer time:", round(as.numeric(Sys.time() - t_outer_start), 2), "sec\n",
            file = logfile, append = TRUE)

        plans_i
    }

    stopCluster(cl)

    # Determine effective sample size (drop failed/dummy plans)
    survive <- plans_shd %>%
        as.data.frame() %>%
        filter(district == 1) %>%
        mutate(survive = ifelse(draw != 99999, TRUE, FALSE)) %>%
        dplyr::select(survive)

    survive_all <- plans_shd %>%
        as.data.frame() %>%
        mutate(survive_all = ifelse(draw != 99999, TRUE, FALSE)) %>%
        dplyr::select(survive_all)

    plans_shd_matrix <- get_plans_matrix(plans_shd)
    plans_shd_matrix <- plans_shd_matrix[, survive$survive]

    plans_shd <- redist_plans(plans = plans_shd_matrix, map = map_shd, algorithm = "smc")

    # Add draw and chain numbering
    plans_shd$draw <- as.factor(rep(1:sum(survive$survive), each = n_distinct(map_shd[[shd_col]])))

    full_chain <- rep(1:outer_runs, each = n_distinct(map_shd[[shd_col]])*final_sims/outer_runs)
    plans_shd$chain <- full_chain[survive_all$survive_all]

    # Add enacted plan
    plans_shd <- add_reference(plans_shd, ref_plan = map_shd[[shd_col]], name = shd_col)

    return(plans_shd)
}

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NV_shd_2020}")

set.seed(2020)

plans_shd <- nested_smc(
    plans = plans,
    map_ssd = map_ssd,
    map_shd = map_shd,
    shp = nv_shp,
    inner_nsims = 2000,
    inner_runs = 1,
    outer_runs = 5,
    year = 2020,
    state = "NV",
    ncores = 60
)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans_shd |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NV_2020/NV_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NV_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NV_2020/NV_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)

    redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020_prop = "black"))

}
