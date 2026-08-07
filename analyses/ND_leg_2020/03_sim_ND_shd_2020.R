###############################################################################
# Simulate plans for `ND_shd_2020` SHD
# © ALARM Project, July 2026
###############################################################################

plans <- read_rds(here("data-out/ND_2020/ND_ssd_2020_plans5000.rds"))

`%notin%` <- Negate(`%in%`)

n_ssd <- n_distinct(nd_shp$ssd_2020)
inner_nsims <- 50
inner_runs <- 1
outer_runs <- 5
max_split_tries <- 100000
split_ssds <- c(4L, 9L)

year <- 2020
shd_col <- paste0("shd_", year)
ssd_col <- paste0("ssd_", year)

# Generate district assignment matrix
sample_ssd_matrix <- get_plans_matrix(subset_sampled(plans))
final_sims <- ncol(sample_ssd_matrix)

# Create shd map object
map_shd_iterate <- redist_map(nd_shp, pop_tol = 0.05,
    ndists = 94, adj = nd_shp$adj)

# Unique ID for each row, will use later to reconnect pieces
map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

map_shd_iterate_dummy <- map_shd_iterate

# Assign arbitrary bounds
attr(map_shd_iterate_dummy, "pop_bounds") <- c(1, 8288, 40000)

# run the nested simulation
cli_process_start("Running simulations for {.pkg ND_shd_2020}")

set.seed(2020)

for (i in 1:(nrow(plans[plans$draw != "ssd_2020", ])/n_ssd)) {
    # Add senate district assignment from simulation i
    map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[, i])

    plan_list <- vector("list", 3)

    failed <- FALSE

    # Iterate through SSD districts 4 and 9, to be split
    for (j in c(1, 2)) {

        dist <- case_when(j == 1 ~ 4,
            j == 2 ~ 9,
            TRUE ~ NA)

        m <- map_shd_iterate %>%
            filter(ssd_sim == dist)
        map_j <- redist_map(m, pop_bounds = attr(map_shd_iterate, "pop_bounds"),
            ndists = 2, adj = m$adj)

        output <- capture.output(
            {
                result <- tryCatch(
                    {

                        plans_j <- redist_smc(
                            map_j,
                            nsims = inner_nsims, runs = inner_runs,
                            counties = county,
                            sampling_space = "linking_edge",
                            split_params = list(splitting_schedule = "any_valid_sizes"),
                            verbose = TRUE,
                            control = list(max_split_tries = max_split_tries))

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
            cat("\nFAILURE at outer i =", i, "inner j =", j, "\n")
            break
        }

        plans_j <- plans_j %>% filter(draw == inner_nsims*inner_runs)
        plans_j$dist_keep <- TRUE
        plan_list[[j]] <- list(map = map_j, plans = plans_j)
    }
    if (failed) {
        # Return dummy plan
        prep_mat <- rep(1:n_distinct(map_shd$shd_2020), length.out = nrow(map_shd_iterate))
        plans_dummy <- redist_plans(plans = prep_mat, map_shd_iterate_dummy, algorithm = "smc")
        plans_dummy$draw <- as.factor(99999)

        plans_i <- plans_dummy
    }

    # Create plans object for remaining districts
    if (!failed) {
        m <- map_shd_iterate %>%
            filter(ssd_sim %notin% c(4, 9))

        # Custom adjacency edits because remaining adjacency graph is non-contiguous
        if (i == 10876) {
            m$adj <- m$adj |>
                geomander::add_edge(383, 278)
        }

        if (i == 22725) {
            m$adj <- m$adj |>
                geomander::add_edge(379, 22)
        }

        map_j <- redist_map(m, pop_bounds = attr(map_ssd, "pop_bounds"),
            ndists = 45, adj = m$adj)


        remaining_assignment <- map_shd_iterate$ssd_sim[map_shd_iterate$ssd_sim %notin% c(4, 9)]
        remaining_assignment <- case_when(remaining_assignment == 46 ~ 4,
            remaining_assignment == 47 ~ 9,
            TRUE ~ remaining_assignment)


        plans_j <- redist_plans(plans = matrix(remaining_assignment),
            map = map_j,
            algorithm = "smc")

        plans_j$dist_keep <- TRUE
        plan_list[[3]] <- list(map = map_j, plans = plans_j)


        # Combine sub plans
        prep_mat <- prep_particles(map = map_shd_iterate,
            map_plan_list = plan_list,
            uid = row_id, dist_keep = dist_keep, nsims = 1)

        plans_i <- redist_plans(plans = prep_mat, map_shd_iterate_dummy, algorithm = "smc")

        cat("\nFINISHED HOUSE DISTRICT ", i, " OF ", nrow(plans[plans$draw != "ssd_2020", ])/n_ssd)
    }

    if (i == 1) {
        plans_shd <- plans_i
    } else {
        plans_shd <- rbind(plans_shd, plans_i)
    }
}

# Survival rate
survive <- plans_shd %>%
    as.data.frame() %>%
    filter(district == 1) %>%
    mutate(survive = ifelse(draw == 1, TRUE, FALSE)) %>%
    dplyr::select(survive)

# Sample size
sum(survive$survive)

survive_all <- plans_shd %>%
    as.data.frame() %>%
    mutate(survive_all = ifelse(draw == 1, TRUE, FALSE)) %>%
    dplyr::select(survive_all)

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
map_shd[[shd_col]]

plans_shd <- add_reference(plans_shd, ref_plan = as.integer(factor(map_shd[[shd_col]])), name = shd_col)

plans <- plans_shd |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/ND_2020/ND_shd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg ND_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/ND_2020/ND_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)

}
