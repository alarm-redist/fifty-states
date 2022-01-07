###############################################################################
# Simulate plans for `MI_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MI_cd_2020}")

constr = redist_constr(map) %>%
    add_constr_grp_hinge(50, vap - vap_white, vap, 0.60)

plans <- redist_smc(map, nsims = 8e3, counties = pseudocounty,
    constraints = constr, seq_alpha = 0.4, verbose = FALSE) %>%
    subset_sampled()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# filter to ≥ 2 VRA districts
vra_ok <- redist.group.percent(as.matrix(plans), map$vap - map$vap_white, map$vap) %>%
    apply(2, function(x) sort(x)[12]) %>%
    `>`(0.5)
if (sum(vra_ok) < 5e3) {
    stop("Not enough VRA-compliant plans")
} else {
    vra_idx <- sample(which(vra_ok), 5e3, replace = FALSE)
    plans <- filter(plans, as.integer(draw) %in% vra_idx) %>%
        mutate(draw = as.factor(as.integer(draw)))
}

plans <- add_reference(plans, map$cd_2020)

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MI_2020/MI_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MI_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MI_2020/MI_cd_2020_stats.csv")

cli_process_done()
