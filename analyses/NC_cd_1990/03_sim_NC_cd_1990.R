###############################################################################
# Simulate plans for `NC_cd_1990`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NC_cd_1990}")

BVAP_THRESH  <- 0.30
DEM_THRESH   <- 0.50
ndists <- attr(map, "ndists")
constr <- redist_constr(map) |>
    add_constr_min_group_frac(
        strength = -1,
        group_pops = list(map$vap_black, map$ndv),
        total_pops = list(map$vap, map$nrv + map$ndv),
        min_fracs = c(BVAP_THRESH, DEM_THRESH),
        thresh = -.9,
        only_nregions = seq.int(2, ndists)
    ) |> add_constr_min_group_frac(
        strength = -1,
        group_pops = list(map$vap_black, map$ndv),
        total_pops = list(map$vap, map$nrv + map$ndv),
        min_fracs = c(BVAP_THRESH, DEM_THRESH),
        thresh = -1.9,
        only_nregions = seq.int(5, ndists)
    )

set.seed(1990)
plans <- redist_smc(map, nsims = 3e3, runs = 6,
    counties = county, constraints = constr,
    split_params = list(splitting_schedule = "any_valid_sizes"),
    sampling_space = "spanning_forest",
    ms_params = list(frequency = 1, mh_accept_per_smc = 50),
    ncores = 112,
    verbose = TRUE)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_1990")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NC_1990/NC_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Read in from local files -----
plans <- read_rds(
    here("data-out/NC_2000/NC_cd_2000_plans.rds")
)

map <- read_rds(
    here("data-out/NC_2000/NC_cd_2000_map.rds")
)

stats <- read_csv(
    here("data-out/NC_2000/NC_cd_2000_stats.csv")
)

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NC_cd_1990}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NC_1990/NC_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Dem seats by BVAP rank
    redist.plot.distr_qtys(
        plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2000 = "black"))

    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)


    map$prob_mmd <- proj_avg(plans, vap_black/total_vap > 0.4)
    map$prob_dem <- proj_avg(plans, ndshare > 0.5)

    redist.plot.map(map, fill = prob_mmd) +
        scale_fill_viridis_c("P(MMD)", limits = c(0, 1))

    redist.plot.map(map, fill = prob_dem) +
        scale_fill_gradient2("P(Dem)", low = "#B25D4C", high = "#3D77BB", mid = "white", midpoint = 0.5)

    redist.plot.distr_qtys(
        plans, ndshare,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        geom_hline(yintercept = 0.5, linetype = "dashed") +
        scale_y_continuous("Democratic Vote Share") +
        labs(title = "Democratic performance by district rank") +
        scale_color_manual(values = c(cd_2020 = "black"))
}
