###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
library(sf)
library(tidyverse)

source("analyses/TX_cd_2020/TX_helpers.R")
source("analyses/TX_cd_2020/01_prep_TX_cd_2020.R")
source("analyses/TX_cd_2020/02_setup_TX_cd_2020.R")

cluster_pop_tol <- 0.0025

map <- set_pop_tol(map, 0.01)
nsims <- 500

diag_plots <- FALSE

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2020}")

# Unique ID for each row, will use later to reconnect pieces
map$row_id <- 1:nrow(map)

########################################################################
# Cluster #1: Greater Houston
clust1 <- c("Austin", "Brazoria", "Chambers", "Fort Bend",
            "Galveston", "Harris", "Liberty", "Montgomery", "Waller")

clust1 <- paste(clust1, "County")

m1 <- map %>% filter(county %in% clust1)
m1 <- set_pop_tol(m1, cluster_pop_tol)
attr(m1, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m1, "pop_bounds")
attr(map, "pop_bounds")
attr(m1, "ndists")
attr(map, "ndists")

# Check for potential MMDs
m1 %>% st_drop_geometry() %>%
    filter(county %in% clust1) %>%
    group_by(cd_2020) %>%
    summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
              black_prop = sum(cvap_black) / sum(cvap))

constraints <- redist_constr(m1) %>%
    add_constr_grp_hinge(
        2,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        1,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45))

n_steps <- (sum(m1$pop) / attr(map, "pop_bounds")[2]) %>% floor()

houston_plans <- redist_smc(m1, counties = county,
                        nsims = nsims, n_steps = n_steps,
                        constraints = constraints)

p <- redist.plot.plans(houston_plans, draws = c(10, 20, 30, 50), m1)
ggsave("data-raw/houston.pdf")

#############################################################
## Cluster #2: Austin and San Antonio
## MSAs border each other
clust2 <- c("Bastrop", "Caldwell", "Hays", "Travis", "Williamson")
clust4 <- c("Atascosa", "Bandera", "Bexar", "Comal", "Guadalupe",
            "Kendall", "Medina", "Wilson")
clust2 <- c(clust2, clust4)

clust2 <- paste(clust2, "County")

m2 <- map %>% filter(county %in% clust2)
m2 <- set_pop_tol(m2, cluster_pop_tol)
attr(m2, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m2, "pop_bounds")
attr(map, "pop_bounds")
attr(m2, "ndists")
attr(m2, "ndists")

m2 %>% st_drop_geometry() %>%
    filter(county %in% clust2) %>%
    group_by(cd_2020) %>%
    summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
              black_prop = sum(cvap_black) / sum(cvap))

constraints <- redist_constr(m2) %>%
    add_constr_grp_hinge(
        2,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.50)
    )

n_steps <- (sum(m2$pop) / attr(map, "pop_bounds")[2]) %>% floor()

austin_plans <- redist_smc(m2, counties = county,
                            nsims = nsims, n_steps = n_steps,
                            constraints = constraints)

p <- redist.plot.plans(austin_plans, draws = c(10, 20, 30, 50), m2)
ggsave("data-raw/austin.pdf")

#########################################################################
## Cluster #3: Dallas

clust3 <- c("Collin", "Dallas", "Denton", "Ellis", "Hunt",
            "Kaufman", "Rockwall", "Johnson", "Parker",
            "Tarrant", "Wise")

clust3 <- paste(clust3, "County")

m3 <- map %>% filter(county %in% clust3)
m3 <- set_pop_tol(m3, cluster_pop_tol)
attr(m3, "pop_bounds") <-  attr(map, "pop_bounds")
attr(m3, "pop_bounds")
attr(map, "pop_bounds")
attr(m3, "ndists")
attr(m3, "ndists")

map %>% st_drop_geometry() %>%
    filter(county %in% clust3) %>%
    group_by(cd_2020) %>%
    summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
              black_prop = sum(cvap_black) / sum(cvap))

constraints <- redist_constr(m3) %>%
    add_constr_grp_hinge(
        2,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        1,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45))

n_steps <- (sum(m3$pop) / attr(map, "pop_bounds")[2]) %>% floor()

dallas_plans <- redist_smc(m3, counties = county,
                           nsims = nsims, n_steps = n_steps,
                           constraints = constraints)

p <- redist.plot.plans(dallas_plans, draws = c(10, 20, 30, 50), m3)
ggsave("data-raw/dallas.pdf")
#############################################################
## Combine Clusters

houston_plans$dist_keep <- ifelse(houston_plans$district == 0, FALSE, TRUE)
austin_plans$dist_keep <- ifelse(austin_plans$district == 0, FALSE, TRUE)
dallas_plans$dist_keep <- ifelse(dallas_plans$district == 0, FALSE, TRUE)

tx_plan_list <- list(list(map = m1, plans = houston_plans),
                     list(map = m2, plans = austin_plans),
                     list(map = m3, plans = dallas_plans))

prep_mat <- prep_particles(map = map, map_plan_list = tx_plan_list,
               uid = row_id, dist_keep = dist_keep, nsims = nsims)

## Check contiguity
test_vec <- sapply(1:ncol(prep_mat), function(i) {
    cat(i, "\n")
    z <- map %>%
        mutate(ex_dist = ifelse(prep_mat[,i] == 0, 1, 0))

    z <- geomander::check_contiguity(adjacency = z$adj, group = z$ex_dist)

    length(unique(z$component[z$group == 1]))
})

table(test_vec) / nsims
# 1     2     3     4
# 0.014 0.240 0.508 0.238

if (diag_plots) {
    counties <- map %>%
        group_by(county) %>%
        summarise(geometry = st_union(geometry))

    p <- map %>%
        ggplot() + geom_sf(fill = NA, color = "black", lwd = 0.001) +
        geom_sf(data = m2, fill = "blue", lwd = 0.001) +
        geom_sf(data = m3, fill = "red", lwd = 0.001) +
        geom_sf(data = m1, fill = "green", lwd = 0.001) +
        geom_sf(data = counties, fill = NA, lwd = 0.05, col = "blue") +
        geom_sf_label(data = counties, aes(label = gsub(" County", "", county)))
    ggsave("data-raw/county_test.pdf", width = 20, height = 20)

    p <- redist.plot.map(map, plan = prep_mat[,which(test_vec == 1)[1]]) +
        geom_sf(data = map %>% filter(prep_mat[,which(test_vec == 1)[1]] == 0),
                fill = "black")
    ggsave("data-raw/contig.pdf", width = 20, height = 20)

}


prep_mat[,1] %>% unique() %>% length()
prep_mat[,5] %>% unique() %>% length()

constraints <- redist_constr(map) %>%
    add_constr_grp_hinge(
        2,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        1,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45))

map <- set_pop_tol(map, 0.01)

plans <- redist_smc(map, nsims = nsims,
                    counties = county, verbose = TRUE,
                    constraints = constraints, init_particles = prep_mat,
                    pop_temper = 0.01)

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
    library(ggplot2)
    library(patchwork)

    ## local results
    d1 <- redist.plot.distr_qtys(plans, cvap_black / total_cvap,
                                 color_thresh = NULL,
                                 color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                                 size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Black by CVAP') +
        labs(title = 'TX Proposed Plan versus Simulations') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()

    d2 <- redist.plot.distr_qtys(plans, cvap_hisp / total_cvap,
                                 color_thresh = NULL,
                                 color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, '#3D77BB', '#B25D4C'),
                                 size = 0.5, alpha = 0.5) +
        scale_y_continuous('Percent Hispanic by CVAP') +
        labs(title = 'TX Proposed Plan versus Simulations') +
        scale_color_manual(values = c(cd_2020_prop = 'black')) +
        ggredist::theme_r21()

    ggsave(plot = d1 / d2, filename = "data-raw/cvap_plots.pdf", height = 9, width = 9)


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
