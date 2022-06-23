###############################################################################
# Simulate plans for `CA_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_cd_2020}")

# simulate southern CA ----
seam_south <- sapply(
    list(
        c("Los Angeles County", "Ventura County"),
        c("Los Angeles County", "Kern County"),
        c("San Bernardino County", "Kern County"),
        c("San Bernardino County", "Inyo County")
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = "county", seam = x) %>%
        pull(tract)
) %>% unlist()

map_south$boundary <- map_south$tract %in% seam_south

cons_south <- redist_constr(map_south) %>%
    add_constr_grp_hinge(
        strength = 15,
        group_pop = vap_hisp,
        total_pop = vap
    ) %>%
    add_constr_custom(
        strength = 10,
        fn = function(plan, distr) {
            as.numeric(!any(plan[map_south$boundary] == 0))
        }
    )


set.seed(2020)

plans_south <- redist_smc(
    map_south,
    nsims = 5e3, runs = 2L, ncores = 8,
    counties = pseudo_county,
    constraints = cons_south,
    n_steps = 27
)

# simulate large bay area ----
seam_bay <- sapply(
    list(
        c("San Francisco County", "Marin County"),
        c("Contra Costa County", "Marin County"),
        c("Solano County", "Sonoma County"),
        c("Solano County", "Napa County"),
        c("Yolo County", "Napa County"),
        c("Yolo County", "Lake County"),
        c("Yolo County", "Colusa County"),
        c("Yolo County", "Sutter County"),
        c("Sacramento County", "Sutter County"),
        c("Sacramento County", "Placer County"),
        c("Sacramento County", "El Dorado  County"),
        c("Sacramento County", "Amador County"),
        c("San Joaquin County", "Amador County"),
        c("San Joaquin County", "Calaveras County"),
        c("Stanislaus County", "Calaveras County"),
        c("Stanislaus County", "Tuolumne County"),
        c("Merced County", "Mariposa County"),
        c("Madera County", "Mariposa County"),
        c("Madera County", "Tuolumne County"),
        c("Madera County", "Mono County"),
        c("Fresno County", "Mono County"),
        c("Fresno County", "Inyo County"),
        c("Tulare County", "Inyo County"),
        c("Tulare County", "Kern County"),
        c("Kings County", "Kern County"),
        c("Monterey County", "San Luis Obispo County")
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = "county", seam = x) %>%
        pull(tract)
) %>% unlist()

map_bay$boundary <- map_bay$tract %in% seam_bay

cons_bay <- redist_constr(map_bay) %>%
    add_constr_grp_hinge(
        strength = 50,
        group_pop = vap_hisp,
        total_pop = vap
    ) %>%
    add_constr_grp_hinge(
        strength = 50,
        group_pop = vap_asian,
        total_pop = vap
    ) %>%
    add_constr_custom(
        strength = 10,
        fn = function(plan, distr) {
            as.numeric(!any(plan[map_bay$boundary] == 0))
        }
    )
set.seed(2020)

plans_bay <- redist_smc(
    map_bay,
    nsims = 5e3, runs = 2L, ncores = 8,
    counties = pseudo_county,
    constraints = cons_bay,
    n_steps = 15
)


# pull it all together ----
init <- prep_particles(
    map = map,
    map_plan_list = list(
        south = list(
            map = map_south,
            plans = plans_south %>% mutate(keep = district > 0)
        ),
        bay = list(
            map = map_bay,
            plans = plans_bay %>% mutate(keep = district > 0)
        )
    ),
    uid = uid,
    dist_keep = keep,
    nsims = 5e3 * 2
)


set.seed(2020)

plans <- redist_smc(
    map,
    nsims = 1e4, runs = 2L, ncores = 8,
    counties = county,
    init_particles = init
    )

attr(plans, "prec_pop") <- map$pop

plans <- match_numbers(plans, 'cd_2020')

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/CA_2020/CA_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CA_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CA_2020/CA_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    redist.plot.hist(plans %>% group_by(draw) %>%
        mutate(hisp_dem = sum((vap_hisp/total_vap > 0.5) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic and Dem. Majority")

    redist.plot.hist(plans %>% group_by(draw) %>%
        mutate(hisp_dem = sum((vap_hisp/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic > 40% and Dem. Majority")

    redist.plot.hist(plans %>% group_by(draw) %>%
        mutate(ha_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.5) & e_dvs > 0.5)), qty = ha_dem) +
        labs(x = "Number of Hispanic + Asian and Dem. Majority")

    redist.plot.hist(plans %>% group_by(draw) %>%
        mutate(asian_dem = sum((vap_asian/total_vap > 0.5) & e_dvs > 0.5)), qty = asian_dem) +
        labs(x = "Number of Asian and Dem. Majority")

    redist.plot.hist(plans %>% group_by(draw) %>%
        mutate(coalition_dem = sum(((vap_asian + vap_hisp + vap_black)/total_vap > 0.5) & e_dvs > 0.5)), qty = coalition_dem) +
        labs(x = "Number of Hispanic + Asian + Black and Dem. Majority")


    enac_sum <- plans %>%
        subset_ref() %>%
        mutate(minority = (total_vap - vap_white)/(total_vap),
            dist_lab = str_pad(district, width = 2, pad = "0"),
            minority_rank = rank(minority), # ascending order
            hisp_rank = rank(vap_hisp),
            asian_rank = rank(vap_asian),
            ha_rank = rank(vap_hisp + vap_asian),
            coalition_rank = rank(vap_hisp + vap_asian + vap_black),
            compact_rank = rank(comp_polsby)
        )

    redist.plot.distr_qtys(plans, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = hisp_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"))

    redist.plot.distr_qtys(plans, vap_asian/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = asian_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"))

    redist.plot.distr_qtys(plans, (vap_asian + vap_hisp)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic or Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = ha_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"))

    redist.plot.distr_qtys(plans, (vap_asian + vap_hisp + vap_black)/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted")

    redist.plot.distr_qtys(plans %>% number_by(e_dvs), (vap_asian + vap_hisp + vap_black)/total_vap, sort = FALSE,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted")

}
