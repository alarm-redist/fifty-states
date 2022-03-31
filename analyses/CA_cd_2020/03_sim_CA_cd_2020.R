###############################################################################
# Simulate plans for `CA_cd_2020`
# © ALARM Project, February 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_cd_2020}")

# simulate southern CA ----
seam_south <- sapply(
    list(
        c('Los Angeles County', 'Ventura County'),
        c('Los Angeles County', 'Kern County'),
        c('San Bernardino County', 'Kern County'),
        c('San Bernardino County', 'Inyo County')
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = 'county', seam = x) %>%
        pull(tract)
) %>% unlist()

map_south$boundary <- map_south$tract %in% seam_south

cons_south <- redist_constr(map_south) %>%
    add_constr_grp_hinge(
        strength = 30,
        group_pop = vap_hisp,
        total_pop = vap
    ) %>%
    add_constr_custom(
        strength = 10,
        fn = function(plan, distr) {
            as.numeric(!any(plan[map_south$boundary] == 0))
        }
    )
set.seed(1)
plans_south <- redist_smc(
    map_south, nsims = 5e3, counties = pseudo_county,
    constraints = cons_south, n_steps = 27
)

# simulate large bay area ----
seam_bay <- sapply(
    list(
        c('San Francisco County', 'Marin County'),
        c('Contra Costa County', 'Marin County'),
        c('Solano County', 'Sonoma County'),
        c('Solano County', 'Napa County'),
        c('Yolo County', 'Napa County'),
        c('Yolo County', 'Lake County'),
        c('Yolo County', 'Colusa County'),
        c('Yolo County', 'Sutter County'),
        c('Sacramento County', 'Sutter County'),
        c('Sacramento County', 'Placer County'),
        c('Sacramento County', 'El Dorado  County'),
        c('Sacramento County', 'Amador County'),
        c('San Joaquin County', 'Amador County'),
        c('San Joaquin County', 'Calaveras County'),
        c('Stanislaus County', 'Calaveras County'),
        c('Stanislaus County', 'Tuolumne County'),
        c('Merced County', 'Mariposa County'),
        c('Madera County', 'Mariposa County'),
        c('Madera County', 'Tuolumne County'),
        c('Madera County', 'Mono County'),
        c('Fresno County', 'Mono County'),
        c('Fresno County', 'Inyo County'),
        c('Tulare County', 'Inyo County'),
        c('Tulare County', 'Kern County'),
        c('Kings County', 'Kern County'),
        c('Monterey County', 'San Luis Obispo County')
    ),
    FUN = \(x) seam_geom(adj = map$adj, shp = map, admin = 'county', seam = x) %>%
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
set.seed(1)
plans_bay <- redist_smc(
    map_bay, nsims = 5e3, counties = pseudo_county,
    constraints = cons_bay, n_steps = 15
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
    nsims = 5e3
)


set.seed(1)
plans <- redist_smc(map, nsims = 5e3, counties = county,
                    init_particles = init)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

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
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
