###############################################################################
# Simulate plans for `NH_cd_2010`
# © ALARM Project, September 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg NH_cd_2010}")

# Run simulations, replacing state FIPS with abbreviation (for ease in generating validation graphic)
## Merging by MCDs
set.seed(2010)
plans <- redist_smc(map %>% mutate(state = "NH") %>% merge_by(mcd),
    nsims = 5e3,
    runs = 2L,
    counties = county) %>%
    pullback() %>%
    structure(prec_pop = map$pop) %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 2500) %>% # thin samples
    ungroup() %>%
    match_numbers("cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/NH_2010/NH_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg NH_cd_2010}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/NH_2010/NH_cd_2010_stats.csv")

cli_process_done()
