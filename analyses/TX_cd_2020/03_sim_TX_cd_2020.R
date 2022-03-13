###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
set.seed(02138)
library(sf)
library(tidyverse)
library(patchwork)

source("analyses/TX_cd_2020/TX_helpers.R")
source("analyses/TX_cd_2020/01_prep_TX_cd_2020.R")
source("analyses/TX_cd_2020/02_setup_TX_cd_2020.R")

cluster_pop_tol <- 0.0025

map <- set_pop_tol(map, 0.01)
nsims <- 5000

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

map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m1$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1,]

border_idxs <- which(m1$row_id %in% z$row_id)

constraints <- redist_constr(m1) %>%
    add_constr_grp_hinge(
        20,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        10,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45)) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(m1$pop) / attr(map, "pop_bounds")[2]) %>% floor()

houston_plans <- redist_smc(m1, counties = county,
                        nsims = nsims, n_steps = n_steps,
                        constraints = constraints)

#############################################################
## Local Diagnostic plots
i <- 25
p1 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")
i <- 35
p2 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")
i <- 45
p3 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")
i <- 11
p4 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")
i <- 8
p5 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")
i <- 5
p6 <- redist.plot.plans(houston_plans, draws = i, m1) +
    geom_sf(data = m1 %>% filter(get_plans_matrix(houston_plans)[,i] == 0),
            fill = "black")

ggsave("data-raw/houston.pdf", (p1 + p2 + p3) / (p4 + p5 + p6), width = 20, height = 20)

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

map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m2$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1,]

border_idxs <- which(m2$row_id %in% z$row_id)

constraints <- redist_constr(m2) %>%
    add_constr_grp_hinge(
        20,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

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

map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m3$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1,]

border_idxs <- which(m3$row_id %in% z$row_id)

constraints <- redist_constr(m3) %>%
    add_constr_grp_hinge(
        20,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

map %>% st_drop_geometry() %>%
    filter(county %in% clust3) %>%
    group_by(cd_2020) %>%
    summarise(hisp_prop = sum(cvap_hisp) / sum(cvap),
              black_prop = sum(cvap_black) / sum(cvap))

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

    z <- geomander::check_contiguity(adj = z$adj, group = z$ex_dist)

    length(unique(z$component[z$group == 1]))
})

table(test_vec) / nsims

constraints <- redist_constr(map) %>%
    add_constr_grp_hinge(
        5,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        2,
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
library(ggplot2)
library(patchwork)

## local results
d1 <- redist.plot.distr_qtys(
    plans,
    cvap_black / total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        '#3D77BB',
        '#B25D4C'
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous('Percent Black by CVAP') +
    labs(title = 'TX Proposed Plan versus Simulations') +
    scale_color_manual(values = c(cd_2020_prop = 'black')) +
    ggredist::theme_r21()

d2 <- redist.plot.distr_qtys(
    plans,
    cvap_hisp / total_cvap,
    color_thresh = NULL,
    color = ifelse(
        subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
        '#3D77BB',
        '#B25D4C'
    ),
    size = 0.5,
    alpha = 0.5
) +
    scale_y_continuous('Percent Hispanic by CVAP') +
    labs(title = 'TX Proposed Plan versus Simulations') +
    scale_color_manual(values = c(cd_2020_prop = 'black')) +
    ggredist::theme_r21()

d3 <-
    redist.plot.distr_qtys(
        plans,
        (cvap_hisp + cvap_black) / total_cvap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            '#3D77BB',
            '#B25D4C'
        ),
        size = 0.5,
        alpha = 0.5
    ) +
    scale_y_continuous('HCVAP + BCVAP / CVAP') +
    labs(title = 'TX Proposed Plan versus Simulations') +
    scale_color_manual(values = c(cd_2020_prop = 'black')) +
    ggredist::theme_r21()

ggsave(
    plot = d1 / d2,
    filename = "data-raw/cvap_plots.pdf",
    height = 9,
    width = 9
)
ggsave(
    plot = d3,
    filename = "data-raw/cvap_sum_plots.pdf",
    height = 9,
    width = 9
)

plans <- plans %>%
    group_by(draw) %>%
    summarise(
        all_hcvap = sum((cvap_hisp / total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp / total_cvap) > 0.4 &
                            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp / total_cvap) > 0.4 &
                            (nrv > ndv))
    )

p1 <- redist.plot.hist(plans, all_hcvap)
p2 <- redist.plot.hist(plans, dem_hcvap)
p3 <- redist.plot.hist(plans, rep_hcvap)

ggsave("data-raw/hist.pdf", p1 / p2 / p3)

psum <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white) %>%
    summarise(
        all_hcvap = sum((cvap_hisp / total_cvap) > 0.4),
        dem_hcvap = sum((cvap_hisp / total_cvap) > 0.4 &
                            (ndv > nrv)),
        rep_hcvap = sum((cvap_hisp / total_cvap) > 0.4 &
                            (nrv > ndv)),
        all_bcvap = sum((cvap_black / total_cvap) > 0.4),
        dem_bcvap = sum((cvap_black / total_cvap) > 0.4 &
                            (ndv > nrv)),
        rep_bcvap = sum((cvap_black / total_cvap) > 0.4 &
                            (nrv > ndv)),
        mmd_all = sum(cvap_nonwhite / total_cvap > 0.5),
        mmd_coalition = sum(((
            cvap_hisp + cvap_black
        ) / total_cvap) > 0.5)
    )

plans %>%
    filter(draw == "cd_2020") %>%
    mutate(bvap_pct = cvap_black / total_cvap) %>%
    arrange(desc(bvap_pct)) %>%
    select(district, bvap_pct)

map <- map %>% mutate(bvap_pct = cvap_black / cvap)

p <- redist.plot.map(
    map,
    plan = cd_2020,
    zoom_to = map$cd_2020 %in% c(30, 9, 18),
    boundaries = FALSE,
    fill_label = bvap_pct
)
ggsave("bcvap_zoom.pdf", p)

p <- plans %>%
    group_by(draw) %>%
    mutate(cvap_nonwhite = total_cvap - cvap_white,
           cvap_nw_prop = cvap_nonwhite / total_cvap)  %>%
    redist.plot.distr_qtys(
        cvap_nw_prop,
        color = ifelse(
            subset_sampled(plans)$ndv > subset_sampled(plans)$nrv,
            '#3D77BB',
            '#B25D4C'
        ),
        color_thresh = NULL
    ) +
    scale_y_continuous('Percent Non-White by CVAP') +
    labs(title = 'TX Proposed Plan versus Simulations') +
    scale_color_manual(values = c(cd_2020_prop = 'black'))
ggsave("data-raw/qty_nonwhite.pdf", p, width = 9)

p0 <-
    redist.plot.hist(psum, mmd_all) + labs(x = "Nonwhite CVAP > 0.5", y = NULL)
p1 <-
    redist.plot.hist(psum, mmd_coalition) + labs(x = "HCVAP + BCVAP > 0.5", y = NULL)
p2 <-
    redist.plot.hist(psum, all_hcvap) + labs(x = "HCVAP > 0.4", y = NULL)
p3 <-
    redist.plot.hist(psum, dem_hcvap) + labs(x = "HCVAP > 0.4 & Dem. > Rep.", y = NULL)
p4 <-
    redist.plot.hist(psum, rep_hcvap) + labs(x = "HCVAP > 0.4 & Dem. < Rep.", y = NULL)
p5 <-
    redist.plot.hist(psum, all_bcvap) + labs(x = "BCVAP > 0.4", y = NULL)
p6 <-
    redist.plot.hist(psum, dem_bcvap) + labs(x = "BCVAP > 0.4 & Dem. > Rep.", y = NULL)

ggsave("data-raw/hist.pdf", p0 / p1 / p2 / p3 / p4 / p5 / p6, height = 9)
