###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
set.seed(02138)

cluster_pop_tol <- 0.0025
nsims <- 5000

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2020}")

########################################################################
# Cluster #1: Greater Houston

clust1 <- c("Austin", "Brazoria", "Chambers", "Fort Bend",
    "Galveston", "Harris", "Liberty", "Montgomery", "Waller")

clust1 <- paste(clust1, "County")

m1 <- map %>% filter(county %in% clust1)
m1 <- set_pop_tol(m1, cluster_pop_tol)
attr(m1, "pop_bounds") <-  attr(map, "pop_bounds")

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m1$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m1$row_id %in% z$row_id)
########################################################################

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

n_steps <- (sum(m1$pop)/attr(map, "pop_bounds")[2]) %>% floor()

houston_plans <- redist_smc(m1, counties = county,
    nsims = nsims, n_steps = n_steps,
    constraints = constraints)

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

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m2$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m2$row_id %in% z$row_id)
########################################################################

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

n_steps <- (sum(m2$pop)/attr(map, "pop_bounds")[2]) %>% floor()

austin_plans <- redist_smc(m2, counties = county,
    nsims = nsims, n_steps = n_steps,
    constraints = constraints)

#########################################################################
## Cluster #3: Dallas

clust3 <- c("Collin", "Dallas", "Denton", "Ellis", "Hunt",
    "Kaufman", "Rockwall", "Johnson", "Parker",
    "Tarrant", "Wise")

clust3 <- paste(clust3, "County")

m3 <- map %>% filter(county %in% clust3)
m3 <- set_pop_tol(m3, cluster_pop_tol)
attr(m3, "pop_bounds") <-  attr(map, "pop_bounds")

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m3$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m3$row_id %in% z$row_id)
########################################################################

constraints <- redist_constr(m3) %>%
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

n_steps <- (sum(m3$pop)/attr(map, "pop_bounds")[2]) %>% floor()

dallas_plans <- redist_smc(m3, counties = county,
    nsims = nsims, n_steps = n_steps,
    constraints = constraints)

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
if (FALSE) {
    test_vec <- sapply(1:ncol(prep_mat), function(i) {
        cat(i, "\n")
        z <- map %>%
            mutate(ex_dist = ifelse(prep_mat[, i] == 0, 1, 0))

        z <- geomander::check_contiguity(adj = z$adj, group = z$ex_dist)

        length(unique(z$component[z$group == 1]))
    })

    table(test_vec)/nsims
}

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

plans <- add_summary_stats(plans, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after=total_vap)

# cvap columns
cvap_cols = names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2020/TX_cd_2020_stats.csv")

cli_process_done()

validate_analysis(plans, map)

