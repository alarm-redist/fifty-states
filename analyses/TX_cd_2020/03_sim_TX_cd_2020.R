###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
library(sf)
library(tidyverse)

source("analyses/TX_cd_2020/TX_helpers.R")

nsims <- 1000

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2020}")

# Unique ID for each row, will use later to reconnect pieces
map$row_id <- 1:nrow(map)

# Greater Houston
clust1 <- c("Austin", "Brazoria", "Chambers", "Fort Bend",
            "Galveston", "Harris", "Liberty", "Montgomery", "Waller")

clust1 <- paste(clust1, "County")

m1 <- map %>% filter(county %in% clust1)
m1 <- set_pop_tol(m1, 0.005)
attr(m1, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m1, "pop_bounds")
attr(map, "pop_bounds")
attr(m1, "ndists")
attr(map, "ndists")

constraints <- redist_constr(m1) %>%
    add_constr_grp_hinge(
        150,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_grp_hinge(
        150,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_splits(strength=1)

n_steps <- (sum(m1$pop) / attr(map, "pop_bounds")[2]) %>% floor()

houston_plans <- redist_smc(m1, counties = county,
                    nsims = nsims, n_steps = n_steps,
                    constraints = constraints)

#############################################################
## Austin
clust2 <- c("Bastrop", "Caldwell", "Hays", "Travis", "Williamson")

clust2 <- paste(clust2, "County")

m2 <- map %>% filter(county %in% clust2)
m2 <- set_pop_tol(m2, 0.005)
attr(m2, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m2, "pop_bounds")
attr(map, "pop_bounds")
attr(m2, "ndists")
attr(m2, "ndists")

# dists <- m2$cd_2020 %>% unique()
#
# co1 <- map %>% st_drop_geometry() %>% group_by(cd_2020) %>% summarise(nfull = n())
# co2 <- m2 %>% st_drop_geometry() %>% group_by(cd_2020) %>% summarise(nlocal = n())
#
# counts <- left_join(co2, co1, by = "cd_2020")
#
# full_districts <- counts$cd_2020[counts$nlocal == counts$nfull]

m2 %>% st_drop_geometry() %>%
    filter(county %in% clust2) %>%
    group_by(cd_2020) %>%
    summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
              black_prop = sum(cvap_black) / sum(cvap))

constraints <- redist_constr(m2) %>%
    add_constr_grp_hinge(
        150,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_splits(strength=1)

n_steps <- (sum(m2$pop) / attr(map, "pop_bounds")[2]) %>% floor()

austin_plans <- redist_smc(m2, counties = county,
                            nsims = nsims, n_steps = n_steps,
                            constraints = constraints)

#############################################################

m0 <- map %>% filter(!(county %in% clust1) & !(county %in% clust2))
m0 <- set_pop_tol(m0, 0.005)
attr(m0, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m0, "pop_bounds") == attr(map, "pop_bounds")
attr(m0, "pop_bounds") == attr(m1, "pop_bounds")

constraints <- redist_constr(m0) %>%
    add_constr_grp_hinge(
        150,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_grp_hinge(
        150,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_splits(strength=1)

n_steps <- floor(sum(m0$pop) / attr(m0, "pop_bounds")[2])

# remaining_plans <- redist_smc(m0, counties = county, constraints = constraints,
#                             nsims = nsims, n_steps = n_steps)

houston_plans$dist_keep <- ifelse(houston_plans$district == 0, FALSE, TRUE)
austin_plans$dist_keep <- ifelse(austin_plans$district == 0, FALSE, TRUE)
# remaining_plans$dist_keep <- ifelse(remaining_plans$district == 0, FALSE, TRUE)

tx_plan_list <- list(list(map = m2, plans = austin_plans),
                     list(map = m1, plans = houston_plans))
                     # list(map = m0, plans = remaining_plans))

prep_mat <- prep_particles(map = map, map_plan_list = tx_plan_list,
               uid = row_id, dist_keep = dist_keep, nsims = nsims)

prep_mat[,1] %>% unique() %>% length()
prep_mat[,5] %>% unique() %>% length()

constraints <- redist_constr(map) %>%
    add_constr_grp_hinge(
        150,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_grp_hinge(
        150,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.50)
    ) %>%
    add_constr_splits(strength=1)

plans <- redist_smc(map, nsims = nsims,
                    counties = county, verbose = TRUE,
                    constraints = constraints, init_particles = prep_mat)

plans <- plans %>% filter(draw != "cd_2020")
plans <- plans %>% add_reference(ref_plan = map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TX_2020/TX_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_2020}")

plans <- add_summary_stats_cvap(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2020/TX_cd_2020_stats.csv")

cli_process_done()

validate_analysis(plans, map)

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    ## local results
    d1 <- redist.plot.distr_qtys(plans, cvap_black / total_cvap,
                                 color_thresh = NULL,
                                 color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                                 size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by CVAP') +
        labs(title = 'Yee Haw Proposed Plan versus Simulations') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()

    d2 <- redist.plot.distr_qtys(plans, cvap_hisp / total_cvap,
                                 color_thresh = NULL,
                                 color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                                 size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Hispanic by CVAP') +
        labs(title = 'Yee Haw Proposed Plan versus Simulations') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()

    ggsave(plot = d1 / d2, filename = "figs/cvap_plots.pdf")

}


# ###
#
# dist <- map %>%
#     group_by(cd_2020) %>%
#     summarise(geometry = st_union(geometry))
#
# county <- m1 %>%
#     group_by(county) %>%
#     summarise(geometry = st_union(geometry))
#
# # TODO FIGURE OUT PLOTS
#
# d <- m0 %>%
#     ggplot() +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1) +
#     geom_sf_label(data = county, aes(label = gsub(" County", "", county)))
# ggsave("data-out/TX_2020/m0.pdf", height = 20, width = 20)
#
# sim_pop <- m1 %>%
#     mutate(sim = get_plans_matrix(plans)[,45]) %>%
#     group_by(sim) %>%
#     summarise(pop = sum(pop))
#
#
# local_dists <- m1 %>%
#     group_by(cd_2020) %>%
#     summarise(geometry = st_union(geometry))
#
# d <- m1 %>%
#     mutate(sim = get_plans_matrix(plans)[,45]) %>%
#     ggplot() +
#     geom_sf(data = m1, fill = "black", color = "black") +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf_label(data = local_dists, aes(label = cd_2020), size = 3) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1) +
#     geom_sf_label(data = county, aes(label = gsub(" County", "", county)))
# ggsave("data-out/TX_2020/county_dist.pdf", height = 20, width = 20)
#
# sum(m1$pop) / 766987
#
#
#
# d <- ggplot(dist) +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1) +
#     geom_sf_label(aes(label = cd_2020), size = 5)
# ggsave("data-out/TX_2020/enacted_map.pdf", height = 50, width = 50, limitsize = FALSE)
#
# d <- ggplot(dist) +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1) +
#     geom_sf_label(data = county, aes(label = gsub(" County", "", county))) +
#     geom_sf_label(data = dist, aes(label = cd_2020))
# ggsave("data-out/TX_2020/state_map.pdf", height = 20, width = 20)
#
# # Enacted, remove "part" districts in this area
# dists <- m1$cd_2020 %>% unique()
#
# co1 <- map %>% st_drop_geometry() %>% group_by(cd_2020) %>% summarise(nfull = n())
# co2 <- m1 %>% st_drop_geometry() %>% group_by(cd_2020) %>% summarise(nlocal = n())
#
# counts <- left_join(co2, co1, by = "cd_2020")
#
# full_districts <- counts$cd_2020[counts$nlocal == counts$nfull]
#
# map %>% st_drop_geometry() %>%
#     filter(cd_2020 %in% full_districts) %>%
#     group_by(cd_2020) %>%
#     summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
#               black_prop = sum(cvap_black) / sum(cvap))
#
# z <- m1 %>%
#     filter(cd_2020 %in% full_districts)
# redist.splits(m1$cd_2020, m1$county)
# redist.multisplits(m1$cd_2020, m1$county)
#
# d <- ggplot(z) +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1)
# ggsave("data-out/TX_2020/local_map.pdf", height = 20, width = 20)
#
# z <- m2 %>%
#     filter(county %in% clust2)
#
# county <- m2 %>%
#     group_by(county) %>%
#     summarise(geometry = st_union(geometry))
#
# d <- ggplot(z) +
#     geom_sf(aes(fill = factor(cd_2020)), color = NA, lwd = 1) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1)
# ggsave("data-out/TX_2020/austin_map.pdf", height = 20, width = 20)
#
# plans %>%
#     mutate(hisp_prop = group_frac(m1, cvap_hisp, cvap),
#            black_prop = group_frac(m1, cvap_black, cvap)) %>%
#     filter(district != 0)
#
# idx <- get_plans_matrix(plans)[,22]
#
# redistmetrics::splits_count(plans, m1, county)
# redist::redist.district.splits(plans, m1$county)
#
# redist.splits(m1$cd_2020, m1$county)
# redist.splits(plans, m1$county)
# redist.multisplits(plans, m1$county)
# redist.multisplits(m1$cd_2020, m1$county)
#
# redist.splits(idx[idx != 0], m1$county[idx != 0])
#
# redist.multisplits(get_plans_matrix(plans)[idx != 0,22], m1$county[idx != 0])
#
# table(get_plans_matrix(plans)[,22], m1$county)[2:9,] %>% View()
#
# limited <- m1 %>%
#     mutate(sim = get_plans_matrix(plans)[,18]) %>%
#     filter(sim != 0)
#
# local_dists <- m1 %>%
#     mutate(sim = get_plans_matrix(plans)[,18]) %>%
#     filter(sim != 0) %>%
#     group_by(sim) %>%
#     summarise(geometry = st_union(geometry))
#
# d <- m1 %>%
#     ggplot() +
#     geom_sf(fill = "grey", color = "black") +
#     geom_sf(data = limited, aes(fill = factor(sim)), color = NA, lwd = 1) +
#     geom_sf_label(data = local_dists, aes(label = sim), size = 5) +
#     geom_sf(data = county, fill = NA, color = rgb(0, 0, 1, alpha = 0.5), lwd = 1) +
#     geom_sf_label(data = county, aes(label = gsub(" County", "", county)), size = 5) +
#     ggthemes::theme_map()
# ggsave("data-out/TX_2020/test_dist.pdf", height = 20, width = 20)
#
# mutate(plans, county_splits = county_splits(m1, county, .data = plans))
#
# # TODO customize as needed. Recommendations:
# #  - For many districts / tighter population tolerances, try setting
# #  `pop_temper=0.01` and nudging upward from there. Monitor the output for
# #  efficiency!
# #  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
# #  - Don't change the number of simulations unless you have a good reason
# #  - If the sampler freezes, try turning off the county split constraint to see
# #  if that's the problem.
# #  - Ask for help!
