###############################################################################
# Simulate plans for `IA_cd_2020`
# © ALARM Project, September 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg IA_cd_2020}")

set.seed(2020)
plans <- redist_smc(map, nsims = 2500, runs = 2, compactness = 1.1, seq_alpha = 0.9)
plans <- match_numbers(plans, map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/IA_2020/IA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg IA_cd_2020}")

# special functions to calculate compactness metrics
M_PER_MI <- 1609.34
comp_lw <- function(map, plans = redist:::cur_plans()) {
    m <- as.matrix(plans)
    n_distr <- attr(map, "ndists")
    lw <- matrix(0, nrow = n_distr, ncol = ncol(m))
    for (i in seq_len(ncol(m))) {
        for (j in seq_len(n_distr)) {
            bbox <- st_bbox(map[m[, i] == j, ])
            lw[j, i] <- abs((bbox["xmax"] - bbox["xmin"]) -
                (bbox["ymax"] - bbox["ymin"]))/M_PER_MI
        }
    }
    as.numeric(lw)
}

plans <- add_summary_stats(plans, map,
    comp_lw = comp_lw(map),
    area = tally_var(map, area_land + area_water),
    comp_perim = sqrt(4*pi*area/comp_polsby)/M_PER_MI) # based on definition

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/IA_2020/IA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    plans_sum <- plans %>%
        group_by(draw) %>%
        summarize(comp_lw = sum(comp_lw),
            comp_perim = sum(comp_perim))
    p_lw <- hist(plans_sum, comp_lw, bins = 40) + labs(title = "Length-width compactness") + theme_bw()
    p_perim <- hist(plans_sum, comp_perim, bins = 40) + labs(title = "Perimeter compactness") + theme_bw()
    p <- p_lw + p_perim + plot_layout(guides = "collect")
    ggsave("data-raw/IA/validation_comp.png", width = 10, height = 5)
}
