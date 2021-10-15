###############################################################################
# Simulate plans for `MI_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MI_cd_2020}")

plans <- redist_smc(map, nsims = 8e3, counties = pseudocounty,
    constraints = list(hinge = list(strength = 50, tgts_min = 0.60,
        min_pop = vap - vap_white,
        tot_pop = vap)),
    seq_alpha = 0.4, verbose = FALSE)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# TODO add any reference plans that aren't already included

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

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MI_2020/MI_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MI_cd_2020}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MI_2020/MI_cd_2020_stats.csv")

cli_process_done()
