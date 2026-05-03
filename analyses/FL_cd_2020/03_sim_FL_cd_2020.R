###############################################################################
# Simulate plans for `FL_cd_2020`
# © ALARM Project, March 2022
###############################################################################

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

constraints <- redist_constr(map) %>%
    # Keep the VRA hinge constraints from the prior South Florida stage.
    add_constr_grp_hinge(8, vap_black, vap, 0.4) %>%
    add_constr_grp_inv_hinge(-10, vap_black, vap, 0.1) %>%
    add_constr_grp_hinge(5, vap_hisp, vap, 0.7) %>%
    add_constr_grp_hinge(-8, vap_hisp, vap, 0.3) %>%
    # Keep the VRA hinge constraints from the prior North Florida stage.
    add_constr_grp_hinge(
        10,
        vap_hisp,
        total_pop = vap,
        tgts_group = c(0.45)
    ) %>%
    add_constr_grp_hinge(
        10,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.30)
    ) %>%
    add_constr_grp_hinge(-12, vap_black, vap, 0.15) %>%
    # Keep the VRA hinge constraints from the prior statewide remainder stage.
    add_constr_grp_hinge(
        5,
        vap_hisp,
        total_pop = vap,
        tgts_group = c(0.40)
    ) %>%
    add_constr_grp_hinge(
        5,
        vap_black,
        total_pop = vap,
        tgts_group = c(0.40)
    )

set.seed(2020)
plans <- redist_smc(
    map, nsims = 2000, runs = 5,
    counties = pseudo_county,
    constraints = constraints,
    pop_temper = 0.05, seq_alpha = 1,
    sampling_space = sampling_space_val,
    ms_params = list(frequency = 1L, mh_accept_per_smc = 65),
    split_params = list(splitting_schedule = "any_valid_sizes"),
    verbose = TRUE,
    ncores = max(1, parallel::detectCores() - 1)
) %>%
    filter(draw != "cd_2020") %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>%
    ungroup()

plans <- plans %>% add_reference(ref_plan = map$cd_2020)
plans <- match_numbers(plans, "cd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/FL_2020/FL_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg FL_cd_2020}")

plans <- add_summary_stats(plans, map) %>%
    mutate(total_cvap = tally_var(map, cvap), .after = total_vap)

summary(plans)

# cvap columns
cvap_cols <- names(map)[tidyselect::eval_select(starts_with("cvap_"), map)]
for (col in rev(cvap_cols)) {
    plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .after = vap_two)
}

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/FL_2020/FL_cd_2020_stats.csv")

cli_process_done()
