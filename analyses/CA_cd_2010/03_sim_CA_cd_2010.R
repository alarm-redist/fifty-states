###############################################################################
# Simulate plans for `CA_cd_2010`
# © ALARM Project, February 2023
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_cd_2010}")

nsim <- 12500

# Simulate southern CA ----
seam_south <- sapply(
    list(
        c("037", "111"),
        c("037", "029"),
        c("071", "029"),
        c("071", "027")
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = "county", seam = x) %>%
        pull(GEOID)
) %>% unlist()

map_south$boundary <- map_south$GEOID %in% seam_south

cons_south <- redist_constr(map_south) %>%
    add_constr_grp_hinge(
        strength = 9,
        group_pop = vap_hisp,
        total_pop = vap,
    ) %>%
    add_constr_grp_hinge(
        strength = -6,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -6,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .2
    ) %>%
    add_constr_custom(
        strength = 10,
        fn = function(plan, distr) {
            as.numeric(!any(plan[map_south$boundary] == 0))
        }
    )

n_steps <- (sum(map_south$pop)/attr(map, "pop_bounds")[2]) %>% floor()

set.seed(2010)

plans_south <- redist_smc(
    map_south,
    nsims = nsim, runs = 2L, ncores = 8,
    counties = pseudo_county,
    compactness = 1,
    constraints = cons_south,
    n_steps = n_steps, pop_temper = 0.03, seq_alpha = 0.95
)

write_rds(plans_south, here("data-raw/CA/plans_south.rds"), compress = "xz")

# Simulate large bay area ----
seam_bay <- sapply(
    list(
        c("075", "041"),
        c("013", "041"),
        c("095", "097"),
        c("095", "055"),
        c("113", "055"),
        c("113", "033"),
        c("113", "011"),
        c("113", "101"),
        c("067", "101"),
        c("067", "061"),
        c("067", "017"),
        c("067", "005"),
        c("077", "005"),
        c("077", "009"),
        c("099", "009"),
        c("099", "109"),
        c("047", "043"),
        c("047", "019"),
        c("039", "043"),
        c("039", "109"),
        c("039", "051"),
        c("039", "019"),
        c("069", "019"),
        c("053", "079"),
        c("053", "031"),
        c("053", "029")
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = "county", seam = x) %>%
        pull(GEOID)
) %>% unlist()

map_bay$boundary <- map_bay$GEOID %in% seam_bay

cons_bay <- redist_constr(map_bay) %>%
    add_constr_grp_hinge(
        strength = 3,
        group_pop = vap_hisp,
        total_pop = vap,
    ) %>%
    add_constr_grp_hinge(
        strength = -3,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -3,
        group_pop = vap_hisp,
        total_pop = vap,
        tgts_group = .2
    ) %>%
    add_constr_grp_hinge(
        strength = 4,
        group_pop = vap_asian,
        total_pop = vap,
    ) %>%
    add_constr_grp_hinge(
        strength = -4,
        group_pop = vap_asian,
        total_pop = vap,
        tgts_group = .3
    ) %>%
    add_constr_grp_hinge(
        strength = -4,
        group_pop = vap_asian,
        total_pop = vap,
        tgts_group = .2
    ) %>%
    add_constr_custom(
        strength = 10,
        fn = function(plan, distr) {
            as.numeric(!any(plan[map_bay$boundary] == 0))
        }
    )

n_steps <- (sum(map_bay$pop)/attr(map, "pop_bounds")[2]) %>% floor()

set.seed(2010)

plans_bay <- redist_smc(
    map_bay,
    nsims = nsim, runs = 2L, ncores = 8,
    counties = pseudo_county,
    constraints = cons_bay,
    n_steps = n_steps, pop_temper = 0.05
)

write_rds(plans_bay, here("data-raw/CA/plans_bay.rds"), compress = "xz")


# Pull it all together ----
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
    nsims = nsim*2
)


set.seed(2010)

plans <- redist_smc(
    map,
    nsims = nsim*2, runs = 2L, ncores = 8,
    counties = county,
    compactness = 1,
    init_particles = init
)

attr(plans, "prec_pop") <- map$pop

# Thin plans
plans_5k <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans_5k <- match_numbers(plans_5k, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/CA_2010/CA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg CA_cd_2010}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/CA_2010/CA_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    p1 <- redist.plot.hist(plans_5k %>% group_by(draw) %>%
        mutate(hisp_dem = sum((vap_hisp/total_vap > 0.5) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_hisp/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_hisp/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic > 30% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(ha_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.5) & e_dvs > 0.5)), qty = ha_dem) +
        labs(x = "Number of Hispanic + Asian and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic + Asian > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Hispanic + Asian > 30% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(asian_dem = sum((vap_asian/total_vap > 0.5) & e_dvs > 0.5)), qty = asian_dem) +
        labs(x = "Number of Asian and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(hisp_dem = sum((vap_asian/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
        labs(x = "Number of Asian > 40% and Dem. Majority") +
        redist.plot.hist(plans_5k %>% group_by(draw) %>%
            mutate(coalition_dem = sum(((vap_asian + vap_hisp + vap_black)/total_vap > 0.5) & e_dvs > 0.5)), qty = coalition_dem) +
        labs(x = "Number of Hispanic + Asian + Black and Dem. Majority") &
        theme_bw()

    ggsave("data-raw/CA/hist_5k.pdf", p1, width = 11, height = 8)


    enac_sum <- plans_5k %>%
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

    p2 <- redist.plot.distr_qtys(plans_5k, vap_hisp/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = hisp_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, vap_asian/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = asian_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, (vap_asian + vap_hisp)/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Hispanic or Asian by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        geom_text(data = enac_sum, aes(x = ha_rank, label = round(e_dvs, 2)),
            vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
            color = ifelse(subset_ref(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
        redist.plot.distr_qtys(plans_5k, (vap_asian + vap_hisp + vap_black)/total_vap,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted") +
        redist.plot.distr_qtys(plans_5k %>% number_by(e_dvs), (vap_asian + vap_hisp + vap_black)/total_vap, sort = FALSE,
            color_thresh = NULL,
            color = ifelse(subset_sampled(plans_5k)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
            size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Coalition by VAP") +
        labs(title = "CA Enacted versus Simulations") +
        scale_color_manual(values = c(cd_2020 = "black")) +
        geom_hline(yintercept = 0.5, linetype = "dotted")

    ggsave("data-raw/CA/boxplot.pdf", p2, width = 11, height = 8)

}
