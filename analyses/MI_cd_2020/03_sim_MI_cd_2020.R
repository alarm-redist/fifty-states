###############################################################################
# Simulate plans for `MI_cd_2020`
# © ALARM Project, October 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MI_cd_2020}")

constr <- redist_constr(map) %>%
    add_constr_grp_hinge(13, vap - vap_white, vap, 0.52) %>%
    add_constr_grp_hinge(-13, vap - vap_white, vap, 0.3) %>%
    add_constr_grp_inv_hinge(8, vap - vap_white, vap, 0.62)

set.seed(2020)

plans <- redist_smc(map, nsims = 48e3, runs = 4, counties = pseudo_county,
    constraints = constr, pop_temper = 0.02, seq_alpha = 0.9,
    ncores = as.integer(Sys.getenv("REDIST_NCORES", unset = "4"))) %>%
    group_by(chain) %>%
    # Thin to a 2500/chain pool (10k): the VRA filter below samples its 5000
    # final draws from the compliant subset, which under redist 5.x is no
    # longer nearly all of them.
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup()

plans <- match_numbers(plans, map$cd_2020)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# filter to ≥ 2 VRA districts
# (redist.group.percent was removed in redist 5.x)
grp_pop <- map$vap - map$vap_white
tot_pop <- map$vap
vra_ok <- apply(as.matrix(plans), 2, function(d) {
    shares <- tapply(grp_pop, d, sum)/tapply(tot_pop, d, sum)
    sort(shares)[12]
}) > 0.5
if (sum(vra_ok) < 5e3) {
    stop("Not enough VRA-compliant plans: ", sum(vra_ok), " of ", length(vra_ok))
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

if (FALSE) {
    library(ggplot2)

    redist.plot.distr_qtys(plans, 1 - vap_white/total_vap,
        color_thresh = NULL,
        color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
        size = 0.1) +
        scale_y_continuous("Percent Minority by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_2020 = "black"))
}
