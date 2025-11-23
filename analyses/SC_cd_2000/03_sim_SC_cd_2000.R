###############################################################################
# Simulate plans for `SC_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg SC_cd_2000}")

# Custom constraints
constr_sc <- redist_constr(map) %>%
    add_constr_grp_hinge(40, vap_black, vap, 0.5) %>%
    add_constr_grp_hinge(-5, vap_black, vap, 0.65)


set.seed(2000)
plans <- redist_smc(map, nsims = 5e3, runs = 5, ncores = 1, pop_temper = 0.01, counties = county_muni, constraints = constr_sc)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/SC_2000/SC_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg SC_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/SC_2000/SC_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)


    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "South Carolina Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Minority Percentage by VAP") +
        labs(title = "Tennessee Proposed Plan versus Simulations") +
        scale_color_manual(values = c(cd_2020_prop = "black")) +
        theme_bw()

    # Dem seats by BVAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
        subset_sampled() %>%
        select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(bvap_rank) %>%
        summarize(dem = mean(dem))

    # Dem seats by Minority VAP rank -- numeric
    plans %>%
        group_by(draw) %>%
        mutate(tmvap = (total_vap - vap_white)/total_vap, tmvap_rank = rank(tmvap)) %>%
        subset_sampled() %>%
        select(draw, district, tmvap, tmvap_rank, ndv, nrv) %>%
        mutate(dem = ndv > nrv) %>%
        group_by(tmvap_rank) %>%
        summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & e_dvs > 0.5)) %>%
        count(n_black_perf)

    # Total Minority districts that are performing
    plans %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_minority_perf = sum((total_vap - vap_white)/total_vap < 0.5 & e_dvs > 0.5)) %>%
        count(n_minority_perf)

    # democratic vote
    plans <- plans %>%
        mutate(Compactness = distr_compactness(map),
            `Population deviation` = plan_parity(map),
            `Democratic vote` = group_frac(map, ndv, (ndv + nrv)))
    plot(plans, `Democratic vote`, size = 0.5, color_thresh = 0.5) +
        scale_color_manual(values = c("black", "tomato2", "dodgerblue")) +
        labs(title = "Democratic vote share by district")

    # majority minority districts
    plans <- plans %>%
        mutate(majmin = if_else(total_vap/2 > vap_white, 1, 0))
    majminavgs <- avg_by_prec(plans, majmin, draws = NA)
    redist.plot.map(
        tn_shp,
        adj = redist.adjacency(tn_shp, plan),
        plan = NULL,
        fill = majminavgs,
        fill_label = "",
        zoom_to = NULL,
        title = ""
    )

    # majority black districts
    plans <- plans %>%
        mutate(bvappct = vap_black/total_vap)
    blackavgs <- avg_by_prec(plans, bvappct, draws = NA)
    redist.plot.map(
        tn_shp,
        adj = redist.adjacency(tn_shp, plan),
        plan = NULL,
        fill = blackavgs,
        fill_label = "",
        zoom_to = NULL,
        title = ""
    )
}
