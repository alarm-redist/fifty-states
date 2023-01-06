###############################################################################
# Simulate plans for `SC_cd_2010`
# © ALARM Project, June 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_2010}")

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_splits(strength = 0.5, admin = county_muni) %>%
    add_constr_grp_hinge(11, vap_black, vap, 0.5) %>%
    add_constr_grp_hinge(-10, vap_black, vap, 0.3) %>%
    add_constr_grp_hinge(-10, vap_black, vap, 0.2)

# Sample
set.seed(2010)
plans <- redist_smc(map,
    nsims = 3000,
    runs = 2L,
    ncores = 1,
    pop_temper = 0.01,
    counties = county,
    constraints = constr_sc) %>%
    match_numbers("cd_2010")

# Subset < 1% of plans that are not performing
n_perf <- plans %>%
    mutate(bvap = group_frac(map, vap_black, vap),
        ndshare = group_frac(map, ndv, nrv + ndv)) %>%
    group_by(draw) %>%
    summarize(n_blk_perf = sum(bvap > 0.3 & ndshare > 0.5))
stopifnot(mean(n_perf$n_blk_perf == 0) <= 0.01) # stop if more than 1%

plans_5k <- plans %>%
    # subset non-performing plan
    anti_join(filter(n_perf, n_blk_perf == 0), by = "draw") %>%
    # thin to 5000 draws
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>%
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/SC_2010/SC_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg SC_cd_2010}")

plans <- add_summary_stats(plans, map) # to check convergence
plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/SC_2010/SC_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans_5k, map)

    redist.plot.distr_qtys(
        plans_5k, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Partisanship of seats by BVAP rank") +
        scale_color_manual(values = c(cd_2010 = "black"))

    # Dem seats by BVAP rank -- numeric
    plans_5k %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans_5k %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)

    redist.plot.hist(plans = plans_5k, qty = e_dem) +
        # scale_x_continuous(name = 'Expected Number of Democratic Districts') +
        theme_bw()

    redist.plot.plans(plans, draw = 100, shp = map, qty = ndv/(ndv + nrv), ) +
        # scale_fill_party_c() +
        # theme_map() +
        theme(legend.position = "right") +
        labs(title = "")
}
