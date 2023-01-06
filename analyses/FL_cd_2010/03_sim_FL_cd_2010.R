###############################################################################
# Simulate plans for `FL_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg FL_cd_2010}")

set.seed(2010)

# Global settings
cluster_tol <- .005
nsims <- 30000

map$row_num <- 1:nrow(map)

# South Florida

map_south <- map %>% filter(section == "South")

map_south <- set_pop_tol(map_south, cluster_tol)

map <- map %>%
    mutate(cluster_edge = ifelse(row_num %in% map_south$row_num, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_south <- which(map_south$row_num %in% z$row_num)

constraints <- redist_constr(map_south) %>%
    # encourage Black VAP <10% and >40%
    add_constr_grp_hinge(8, vap_black, vap, 0.4) %>%
    add_constr_grp_inv_hinge(-10, vap_black, vap, 0.1) %>%
    # encourage Hispanic VAP <30% and >70%
    add_constr_grp_hinge(5, vap_hisp, vap, 0.7) %>%
    add_constr_grp_hinge(-8, vap_hisp, vap, 0.3) %>%
    # push unassigned area to border for later assignment
    add_constr_custom(strength = 8, function(plan, distr) {
        ifelse(any(plan[border_south] == 0), 0, 1)
    })

n_steps <- (sum(map_south$pop)/attr(map, "pop_bounds")[2]) %>% floor()

plans_south <- redist_smc(map_south,
                          counties = pseudo_county,
                          nsims = nsims/2,
                          runs = 2L, ncores = 3L,
                          n_steps = n_steps,
                          constraints = constraints,
                          pop_temper = 0.01,
                          verbose = T)

plans_south <- plans_south %>%
    mutate(hvap = group_frac(map_south, vap_hisp, vap),
           bvap = group_frac(map_south, vap_black, vap),
           dem16 = group_frac(map_south, adv_16, arv_16 + adv_16),
           dem18 = group_frac(map_south, adv_18, arv_18 + adv_18),
           dem20 = group_frac(map_south, adv_20, arv_20 + adv_20))

summary(plans_south)

###

# North Florida

map_north <- map %>% filter(section == "North")

map_north <- set_pop_tol(map_north, cluster_tol)

map <- map %>%
    mutate(cluster_edge = ifelse(row_num %in% map_north$row_num, 1, 0))

z <- geomander::seam_geom(map$adj, map, admin = "cluster_edge", seam = c(0, 1))

z <- z[z$cluster_edge == 1, ]

border_north <- which(map_north$row_num %in% z$row_num)

constraints <- redist_constr(map_north) %>%
    # reward districts with hispanic vap % above 45%
    add_constr_grp_hinge(
        10,
        vap_hisp,
        total_pop = vap,
        tgts_group = c(0.45)
    ) %>%
    # reward districts with black vap % below 15% and above 30%, enforcing barrier in between
    add_constr_grp_hinge(
        10,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.30)) %>%
    add_constr_grp_hinge(-12, vap_black, vap, 0.15) %>%
    # constrain the unassigned area be on the border, to ensure contiguity
    add_constr_custom(strength = 10, function(plan, distr) {
        ifelse(any(plan[border_north] == 0), 0, 1)
    })

n_steps <- (sum(map_north$pop)/attr(map, "pop_bounds")[2]) %>% floor()

plans_north <- redist_smc(map_north,
                          counties = pseudo_county,
                          nsims = nsims/2,
                          runs = 2L, ncores = 3L,
                          n_steps = n_steps,
                          constraints = constraints,
                          pop_temper = 0.01,
                          verbose = T)

plans_north <- plans_north %>%
    mutate(hvap = group_frac(map_north, vap_hisp, vap),
           bvap = group_frac(map_north, vap_black, vap),
           dem16 = group_frac(map_north, adv_16, arv_16 + adv_16),
           dem18 = group_frac(map_north, adv_18, arv_18 + adv_18),
           dem20 = group_frac(map_north, adv_20, arv_20 + adv_20))

summary(plans_north)

# Merge north and south

plans_north <- plans_north %>% filter(draw != "cd_2010")
plans_south <- plans_south %>% filter(draw != "cd_2010")

plans_south$dist_keep <- ifelse(plans_south$district == 0, FALSE, TRUE)
plans_north$dist_keep <- ifelse(plans_north$district == 6, FALSE, TRUE)

fl_plan_list <- list(list(map = map_south, plans = plans_south),
                     list(map = map_north, plans = plans_north))

rm(plans_south)
rm(plans_north)

prep_mat <- prep_particles(map = map, map_plan_list = fl_plan_list,
                           uid = row_num, dist_keep = dist_keep, nsims = nsims)

rm(fl_plan_list)

# Central Florida

constraints <- redist_constr(map) %>%
    # encourage Hispanic VAP above 40%
    add_constr_grp_hinge(
        5,
        vap_hisp,
        total_pop = vap,
        tgts_group = c(0.40)
    ) %>%
    # encourage Black VAP above 40%
    add_constr_grp_hinge(
        5,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.40))

plans_one_run <- redist_smc(map, nsims = nsims, runs = 1L, ncores = 3L,
                    counties = pseudo_county,
                    constraints = constraints,
                    init_particles = prep_mat,
                    pop_temper = 0.01, verbose = T)  %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_2020)

# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!
plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2010/FL_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2010/FL_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
