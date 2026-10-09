###############################################################################
# Simulate plans for `MD_shd_2020` SHD
# © ALARM Project, August 2026
###############################################################################
plans <- read_rds(here("data-out/MD_2020/MD_ssd_2020_plans_full.rds"))

n_ssd <- n_distinct(md_shp$ssd_2020)
inner_nsims <- 50
inner_runs <- 1
outer_runs <- 5
max_split_tries <- 100000

year <- 2020
ssd_col <- paste0("ssd_", year)
shd_col <- paste0("shd_", year)

# Identify the enacted House structure within Senate districts
ssd_split_structure <- md_shp |>
    st_drop_geometry() |>
    as_tibble() |>
    distinct(ssd_2020, shd_2020) |>
    count(ssd_2020, name = "n_shd") |>
    arrange(ssd_2020)

triple_split_ssds <- ssd_split_structure |>
    filter(n_shd == 3) |>
    pull(ssd_2020)

two_one_split_ssds <- ssd_split_structure |>
    filter(n_shd == 2) |>
    pull(ssd_2020)

mmd_ssds <- ssd_split_structure |>
    filter(n_shd == 1) |>
    pull(ssd_2020)

# Generate district assignment matrix
sample_ssd_matrix <- get_plans_matrix(subset_sampled(plans))
final_sims <- ncol(sample_ssd_matrix)

# Create shd map object
map_shd_iterate <- redist_map(md_shp, pop_tol = 0.05,
    ndists = 141, adj = md_shp$adj)

# Unique ID for each row, will use later to reconnect pieces
map_shd_iterate$row_id <- 1:nrow(map_shd_iterate)

map_shd_iterate_dummy <- map_shd_iterate

# Assign arbitrary bounds
# (districts elect one, two, or three members.
# Bounds prevent redist from rejecting the combined map)
attr(map_shd_iterate_dummy, "pop_bounds") <- c(1, 43810, 6177224)

# Run the nested simulation
cli_process_start("Running simulations for {.pkg MD_shd_2020}")

set.seed(2020)

# For each sampled Senate plan, split districts following the enacted structure
# and recombine them into one statewide House plan
for (i in 1:final_sims) {
    # Add Senate district assignment from simulation i
    map_shd_iterate$ssd_sim <- as.numeric(sample_ssd_matrix[, i])

    # Completed House plan combines 47 Senate district pieces
    plan_list <- vector("list", 47)

    failed <- FALSE

    # Split 1+1+1 Senate districts into three single-member districts
    for (ssd in triple_split_ssds) {

        m <- map_shd_iterate |>
            filter(ssd_sim == ssd)

        map_j <- redist_map(m,
            pop_bounds = attr(map_shd_iterate, "pop_bounds"),
            ndists = 3, adj = m$adj)

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
                    },
                    error = function(e) {
                        NULL
                    })
            },
            type = "output")

        # Catch failed splits
        if (is.null(result) || any(grepl("Failed to split", output))) {
            failed <- TRUE
            cat("\nFAILURE at outer i =", i, "inner SSD =", ssd, "\n")
            break
        }

        plans_j <- plans_j |> filter(draw == inner_nsims*inner_runs)
        plans_j$dist_keep <- TRUE
        plan_list[[ssd]] <- list(map = map_j, plans = plans_j)
    }

    # Split 2+1 Senate districts into one two-member and one
    # single-member district
    if (!failed) {
        for (ssd in two_one_split_ssds) {

            m <- map_shd_iterate |>
                filter(ssd_sim == ssd)

            # first split the Senate district into three single-seat pieces
            map_three <- redist_map(m,
                pop_bounds = attr(map_shd_iterate, "pop_bounds"),
                ndists = 3, adj = m$adj)

            output <- capture.output(
                {
                    result <- tryCatch(
                        {
                            plans_three <- redist_smc(
                                map_three,
                                nsims = inner_nsims, runs = inner_runs,
                                counties = county,
                                sampling_space = "linking_edge",
                                split_params = list(splitting_schedule = "any_valid_sizes"),
                                verbose = TRUE,
                                control = list(max_split_tries = max_split_tries))
                        },
                        error = function(e) {
                            NULL
                        })
                },
                type = "output")

            # Catch failed splits
            if (is.null(result) || any(grepl("Failed to split", output))) {
                failed <- TRUE
                cat("\nFAILURE at outer i =", i, "inner SSD =", ssd, "\n")
                break
            }

            plans_three <- plans_three |> filter(draw == inner_nsims*inner_runs)

            assignment <- get_plans_matrix(subset_sampled(plans_three))[, 1]

            # create adjacency among the three simulated House districts
            district_adj <- redist.coarsen.adjacency(map_three$adj, assignment)

            # select one adjacent pair to form the two-member district
            merge_from_candidates <- which(lengths(district_adj) > 0L)

            merge_from <- merge_from_candidates[
                sample.int(length(merge_from_candidates), 1L)
            ]

            merge_to_candidates <- district_adj[[merge_from]] + 1L

            merge_to <- merge_to_candidates[
                sample.int(length(merge_to_candidates), 1L)
            ]

            merge_pair <- c(merge_from, merge_to)

            collapsed_assignment <- ifelse(assignment %in% merge_pair, 1L, 2L)

            m$inner_plan <- collapsed_assignment

            map_j <- redist_map(m, existing_plan = inner_plan,
                pop_bounds = c(1, 43810, sum(m$pop)), adj = m$adj)

            plans_j <- redist_plans(plans = matrix(collapsed_assignment),
                map = map_j, algorithm = "smc")

            plans_j$dist_keep <- TRUE
            plan_list[[ssd]] <- list(map = map_j, plans = plans_j)
        }
    }

    # Preserve the remaining Senate districts as three-member districts
    if (!failed) {
        for (ssd in mmd_ssds) {

            m <- map_shd_iterate |> filter(ssd_sim == ssd)

            m$inner_plan <- 1L

            mmd_result <- tryCatch(
                {
                    map_j <- redist_map(m, existing_plan = inner_plan,
                        pop_tol = 0.05, adj = m$adj)

                    plans_j <- redist_plans(plans = matrix(m$inner_plan),
                        map = map_j, algorithm = "smc")

                    plans_j$dist_keep <- TRUE

                    list(map = map_j, plans = plans_j)
                },
                error = function(e) {
                    NULL
                })

            if (is.null(mmd_result)) {
                failed <- TRUE
                cat("\nFAILURE at outer i =", i, "inner SSD =", ssd, "\n")
                break
            }

            plan_list[[ssd]] <- mmd_result
        }
    }

    # Combine all simulated plans and unchanged districts
    if (!failed) {
        prep_mat <- prep_particles(map = map_shd_iterate, map_plan_list = plan_list,
            uid = row_id, dist_keep = dist_keep, nsims = 1)
    }

    if (failed) {
        # Return dummy plan
        prep_mat <- rep(1:n_distinct(map_shd$shd_2020), length.out = nrow(map_shd_iterate))
        plans_dummy <- redist_plans(plans = prep_mat, map_shd_iterate_dummy, algorithm = "smc")
        plans_dummy$draw <- as.factor(99999)

        plans_i <- plans_dummy
    }

    if (!failed) {
        plans_i <- redist_plans(plans = prep_mat, map_shd_iterate_dummy, algorithm = "smc")

        cat("\nFINISHED HOUSE DISTRICT ", i, " OF ", final_sims)
    }

    if (i == 1) {
        plans_shd <- plans_i
    } else {
        plans_shd <- rbind(plans_shd, plans_i)
    }
}

# Survival rate
survive <- plans_shd |>
    as.data.frame() |>
    filter(district == 1) |>
    mutate(survive = ifelse(draw == 1, TRUE, FALSE)) |>
    dplyr::select(survive)

# Sample size
sum(survive$survive)

survive_all <- plans_shd |>
    as.data.frame() |>
    mutate(survive_all = ifelse(draw == 1, TRUE, FALSE)) |>
    dplyr::select(survive_all)

# retain successful outer simulations only
plans_shd_matrix <- get_plans_matrix(plans_shd)
plans_shd_matrix <- plans_shd_matrix[, survive$survive, drop = FALSE]

plans_shd <- redist_plans(plans = plans_shd_matrix,
    map = map_shd,
    algorithm = "smc")

# Add draw and chain numbering
plans_shd$draw <- as.factor(rep(1:sum(survive$survive), each = n_distinct(map_shd[[shd_col]])))

full_chain <- rep(1:outer_runs, each = n_distinct(map_shd[[shd_col]])*final_sims/outer_runs)

plans_shd$chain <- full_chain[survive_all$survive_all]

# Add enacted plan
plans_shd <- add_reference(plans_shd, ref_plan = as.integer(factor(map_shd[[shd_col]])), name = shd_col)

plans <- plans_shd |>
    group_by(chain) |>
    filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
    ungroup()
plans <- match_numbers(plans, "shd_2020")

cli_process_done()

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path
write_rds(plans, "data-out/MD_2020/MD_shd_2020_plans.rds", compress = "xz")

cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MD_shd_2020}")

plans <- add_summary_stats(plans, map_shd)

# Output the summary statistics. Do not edit this path
save_summary_stats(plans, "data-out/MD_2020/MD_shd_2020_stats.csv")

cli_process_done()

if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map_shd)
    summary(plans)
}
