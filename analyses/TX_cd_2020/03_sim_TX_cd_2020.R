###############################################################################
# Simulate plans for `TX_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cluster_pop_tol <- 0.0025
nsims <- 12500
pop_temp <- 0.03
sa_city <- 0.99
sa <- 0.95

# Unique ID for each row, will use later to reconnect pieces
map$row_id <- 1:nrow(map)

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2020}")

########################################################################
# Cluster #1: Greater Houston

clust1 <- c("Austin", "Brazoria", "Chambers", "Fort Bend",
    "Galveston", "Harris", "Liberty", "Montgomery", "Waller")

clust1 <- paste(clust1, "County")

m1 <- map %>% filter(county %in% clust1)
attr(m1, "pop_bounds") <-  attr(map, "pop_bounds")
m1 <- set_pop_tol(m1, cluster_pop_tol)

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m1$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m1$row_id %in% z$row_id)
########################################################################

constraints <- redist_constr(m1) %>%
    #########################################################
    # HISPANIC
    add_constr_grp_hinge(
        3,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_hisp,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_hisp,
        cvap,
        0.70) %>%
    #########################################################
    # BLACK
    add_constr_grp_hinge(
        3,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45)) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(m1$pop)/attr(map, "pop_bounds")[2]) %>% floor()

set.seed(2020)
houston_plans <- redist_smc(m1, counties = county,
    nsims = nsims, n_steps = n_steps, runs = 2L,
    seq_alpha = sa_city,
    constraints = constraints, pop_temper = pop_temp + 0.02, verbose = TRUE)

houston_plans <- houston_plans %>%
    mutate(hvap = group_frac(m1, cvap_hisp, cvap),
        bvap = group_frac(m1, cvap_black, cvap),
        dem16 = group_frac(m1, adv_16, arv_16 + adv_16),
        dem18 = group_frac(m1, adv_18, arv_18 + adv_18),
        dem20 = group_frac(m1, adv_20, arv_20 + adv_20))

summary(houston_plans)

#############################################################
## Cluster #2: Austin and San Antonio
## MSAs border each other

clust2 <- c("Bastrop", "Caldwell", "Hays", "Travis", "Williamson")
clust4 <- c("Atascosa", "Bandera", "Bexar", "Comal", "Guadalupe",
    "Kendall", "Medina", "Wilson")
clust2 <- c(clust2, clust4)

clust2 <- paste(clust2, "County")

m2 <- map %>% filter(county %in% clust2)
attr(m2, "pop_bounds") <-  attr(map, "pop_bounds")
m2 <- set_pop_tol(m2, cluster_pop_tol)

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m2$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m2$row_id %in% z$row_id)
########################################################################

constraints <- redist_constr(m2) %>%
    #########################################################
    # HISPANIC
    add_constr_grp_hinge(
        3,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_hisp,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_hisp,
        cvap,
        0.70) %>%
    #########################################################
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(m2$pop)/attr(map, "pop_bounds")[2]) %>% floor()

set.seed(2020)
austin_plans <- redist_smc(m2, counties = county,
    nsims = nsims, n_steps = n_steps, runs = 2L, seq_alpha = sa_city,
    constraints = constraints, pop_temper = pop_temp)

austin_plans <- austin_plans %>%
    mutate(hvap = group_frac(m2, cvap_hisp, cvap),
        bvap = group_frac(m2, cvap_black, cvap),
        dem16 = group_frac(m2, adv_16, arv_16 + adv_16),
        dem18 = group_frac(m2, adv_18, arv_18 + adv_18),
        dem20 = group_frac(m2, adv_20, arv_20 + adv_20))

summary(austin_plans)
#########################################################################
## Cluster #3: Dallas

clust3 <- c("Collin", "Dallas", "Denton", "Ellis", "Hunt",
    "Kaufman", "Rockwall", "Johnson", "Parker",
    "Tarrant", "Wise")

clust3 <- paste(clust3, "County")

m3 <- map %>% filter(county %in% clust3)
attr(m3, "pop_bounds") <-  attr(map, "pop_bounds")
m3 <- set_pop_tol(m3, cluster_pop_tol)

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% m3$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(m3$row_id %in% z$row_id)
########################################################################

constraints <- redist_constr(m3) %>%
    #########################################################
    # HISPANIC
    add_constr_grp_hinge(
        3,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_hisp,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_hisp,
        cvap,
        0.70) %>%

    add_constr_grp_hinge(
        5,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45)) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(m3$pop)/attr(map, "pop_bounds")[2]) %>% floor()

set.seed(2020)
dallas_plans <- redist_smc(m3, counties = county,
    nsims = nsims, n_steps = n_steps, runs = 2L, seq_alpha = sa_city,
    constraints = constraints, pop_temper = pop_temp)

dallas_plans <- dallas_plans %>%
    mutate(hvap = group_frac(m3, cvap_hisp, cvap),
        bvap = group_frac(m3, cvap_black, cvap),
        dem16 = group_frac(m3, adv_16, arv_16 + adv_16),
        dem18 = group_frac(m3, adv_18, arv_18 + adv_18),
        dem20 = group_frac(m3, adv_20, arv_20 + adv_20))

summary(dallas_plans)

#############################################################
## Combine Clusters

houston_plans$dist_keep <- ifelse(houston_plans$district == 0, FALSE, TRUE)
austin_plans$dist_keep <- ifelse(austin_plans$district == 0, FALSE, TRUE)
dallas_plans$dist_keep <- ifelse(dallas_plans$district == 0, FALSE, TRUE)

tx_plan_list <- list(list(map = m1, plans = houston_plans),
    list(map = m2, plans = austin_plans),
    list(map = m3, plans = dallas_plans))

prep_mat <- prep_particles(map = map, map_plan_list = tx_plan_list,
    uid = row_id, dist_keep = dist_keep, nsims = nsims*2)

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
    #########################################################
    # HISPANIC
    add_constr_grp_hinge(
        3,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_hisp,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_hisp,
        cvap,
        0.70) %>%
    add_constr_grp_hinge(
        3,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(-3,
        cvap_black,
        cvap,
        0.35) %>%
    add_constr_grp_inv_hinge(3,
        cvap_black,
        cvap,
        0.70)


set.seed(2020)
plans <- redist_smc(map, nsims = nsims*2, runs = 2L,
    counties = county, verbose = TRUE,
    constraints = constraints, init_particles = prep_mat,
    pop_temper = pop_temp, seq_alpha = sa)

plans <- match_numbers(plans, "cd_2020")

plans <- plans %>% filter(draw != "cd_2020")

plans <- plans %>%
    mutate(district = as.numeric(district)) %>%
    add_reference(ref_plan = as.numeric(map$cd_2020))

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/TX_2020/TX_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_2020}")

plans <- add_summary_stats(plans, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

summary(plans)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/TX_2020/TX_cd_2020_stats.csv")

cli_process_done()

validate_analysis(plans, map)
