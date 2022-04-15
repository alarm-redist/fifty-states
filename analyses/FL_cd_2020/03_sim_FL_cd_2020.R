###############################################################################
# Simulate plans for `FL_cd_2020`
# © ALARM Project, March 2022
###############################################################################

set.seed(719)

cluster_pop_tol <- 0.005
nsims <- 5000

# Unique ID for each row, will use later to reconnect pieces
map$row_id <- 1:nrow(map)

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_cd_2020}")

########################################################################
# Cluster #1: Southern Florida

map_south <- map %>% filter(region == "South")
map_south <- set_pop_tol(map_south, cluster_pop_tol)
attr(map_south, "pop_bounds") <-  attr(map, "pop_bounds")

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% map_south$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(map_south$row_id %in% z$row_id)

########################################################################

constraints <- redist_constr(map_south) %>%
    add_constr_grp_pow(
        35,
        vap_black,
        total_pop = vap,
        tgt_group = c(0.48),
        tgt_other = c(0),
        pow = 0.25) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(map_south$pop)/attr(map, "pop_bounds")[2]) %>% floor()

plans_south <- redist_smc(map_south, counties = county,
    nsims = nsims, n_steps = n_steps,
    constraints = constraints,
    compactness = 0.85,
    pop_temper = 0.01)

plans_south <- plans_south %>% filter(draw != "cd_2020")

#############################################################

# Cluster #2: North Florida

map_north <- map %>% filter(region == "North")
map_north <- set_pop_tol(map_north, cluster_pop_tol)
attr(map_north, "pop_bounds") <-  attr(map, "pop_bounds")

########################################################################
# Setup for cluster constraint
map <- map %>%
    mutate(cluster_edge = ifelse(row_id %in% map_north$row_id, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_idxs <- which(map_north$row_id %in% z$row_id)

########################################################################

constraints <- redist_constr(map_north) %>%
    add_constr_grp_hinge(
        5,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        20,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.40)) %>%
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_idxs] == 0), 0, 1)
    })

n_steps <- (sum(map_north$pop)/attr(map, "pop_bounds")[2]) %>% floor()

plans_north <- redist_smc(map_north, counties = pseudo_county,
    nsims = nsims, n_steps = n_steps,
    constraints = constraints)

#############################################################

## Combine North and South Clusters

plans_south$dist_keep <- ifelse(plans_south$district == 12, FALSE, TRUE)
plans_north$dist_keep <- ifelse(plans_north$district == 0, FALSE, TRUE)

fl_plan_list <- list(list(map = map_south, plans = plans_south),
    list(map = map_north, plans = plans_north))

prep_mat <- prep_particles(map = map, map_plan_list = fl_plan_list,
    uid = row_id, dist_keep = dist_keep, nsims = nsims)

#############################################################

# Cluster #3: Central Florida (with leftover VTDs from North and South)

constraints <- redist_constr(map) %>%
    add_constr_grp_hinge(
        5,
        cvap_hisp,
        total_pop = cvap,
        tgts_group = c(0.40)
    ) %>%
    add_constr_grp_hinge(
        5,
        cvap_black,
        total_pop = cvap,
        tgts_group = c(0.40))

plans <- redist_smc(map, nsims = nsims, counties = pseudo_county,
    constraints = constraints,
    init_particles = prep_mat,
    pop_temper = 0.01)

plans <- plans %>% filter(draw != "cd_2020")
plans <- plans %>% add_reference(ref_plan = map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2020/FL_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_2020}")

plans <- add_summary_stats(plans, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2020/FL_cd_2020_stats.csv")

cli_process_done()

validate_analysis(plans, map)
