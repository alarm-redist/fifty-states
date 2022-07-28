###############################################################################
# Simulate plans for `WA_cd_2010`
# © ALARM Project, July 2022
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg WA_cd_2010}")

constr <- redist_constr(map) %>%
  add_constr_grp_hinge(10.0, vap - vap_white, vap, c(0.52, 0.35, 0.25)) %>%
  add_constr_grp_hinge(-8.0, vap - vap_white, vap, c(0.35, 0.25))


#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Ask for help!
set.seed(2010)
plans <- redist_smc(map, nsims = 5e3, counties = pseudo_county, constraints = constr) %>% match_numbers("cd_2010")
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")


# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/WA_2010/WA_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg WA_cd_2010}")

#Team will change for us to use 2010 data
map$ndv <- map$adv_16
map$nrv <- map$arv_16

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/WA_2010/WA_cd_2010_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

}
