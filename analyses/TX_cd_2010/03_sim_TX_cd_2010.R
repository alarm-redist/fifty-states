###############################################################################
# Simulate plans for `TX_cd_2010`
# © ALARM Project, December 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg TX_cd_2010}")

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

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
    # BLACK
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

set.seed(2010)
plans <- redist_smc(
    map,
    nsims = 2500, runs = 5L,
    ncores = max(1, parallel::detectCores() - 1),
    counties = pseudo_county,
    constraints = constraints,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    pop_temper = 0.05,
    seq_alpha = 0.95
)

plans <- match_numbers(plans, "cd_2010")

plans <- plans %>% filter(draw != "cd_2010")

plans <- plans %>%
    mutate(district = as.numeric(district)) %>%
    add_reference(ref_plan = as.numeric(map$cd_2010), "cd_2010")

plans_5k <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
    ungroup()

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/TX_2010/TX_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg TX_cd_2010}")

plans_5k <- add_summary_stats(plans_5k, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

summary(plans_5k)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans_5k <- mutate(plans_5k, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/TX_2010/TX_cd_2010_stats.csv")

cli_process_done()

validate_analysis(plans_5k, map)
