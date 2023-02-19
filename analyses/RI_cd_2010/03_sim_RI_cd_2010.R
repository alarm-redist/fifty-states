###############################################################################
# Simulate plans for `RI_cd_2010`
# © ALARM Project, January 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg RI_cd_2010}")

set.seed(2010)

plans <- redist_smc(map, nsims = 1500, runs = 4L, counties = county)

# count the population of the smallest division of a state senate district
# used in forming CDs in each plan.
plans <- plans %>% mutate(min_ssd_overlap = 0)
plans_mat <- get_plans_matrix(plans)
for (i in seq(length(plans_mat[1,]))) {
    ssd_overlap <- redist.dist.pop.overlap(plan_old = map$ssd_2010, plan_new = plans_mat[,i], total_pop = map, normalize_rows = NULL)
    min_overlap <- min(ssd_overlap[ssd_overlap > 0])
    plans[2*i - 1,] <- plans[2*i - 1,] %>% mutate(min_ssd_overlap = min_overlap)
    plans[2*i,] <- plans[2*i,] %>% mutate(min_ssd_overlap = min_overlap)
}

# keep only plans where the smallest SSD division has more than 100 residents.
plans <- plans %>%
    filter(min_ssd_overlap > 100 | draw == "cd_2010")
plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(droplevels(draw)) < min(as.integer(droplevels(draw))) + 1250) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/RI_2010/RI_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg RI_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/RI_2010/RI_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plans %>%
        mutate(ssd_split = county_splits(map, map$ssd_2010)) %>%
        group_by(draw) %>%
        summarize(ssd_split = ssd_split[1]) %>%
        hist(ssd_split) +
        labs(title = "State Senate District Splits") +
        theme_bw() +
        theme(aspect.ratio = 3/4)

    plans %>%
        hist(min_ssd_overlap, breaks = seq(0, max(plans$min_ssd_overlap)+500, 500)) +
        scale_x_continuous(breaks = seq(0, max(plans$min_ssd_overlap), 2000)) +
        labs(title = "Smallest SSD Voting District in any CD") +
        theme_bw() +
        theme(aspect.ratio = 3/4)
}
