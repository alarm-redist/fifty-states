###############################################################################
# Simulate plans for `MD_cd_2010`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MD_cd_2010}")

set.seed(2010)

plans <- redist_smc(
  map,
  nsims = 2500, runs = 2L,
  counties = county
)

plans <- match_numbers(plans, "cd_2010")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MD_2010/MD_cd_2010_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MD_cd_2010}")

# Ensure geometry-only perimeters exist in an appropriate location and restore map attributes needed for the summary statistics.
dir.create(here("data-out/MD_2010"), recursive = TRUE, showWarnings = FALSE)                     
perim_df <- redistmetrics::prep_perims(map)                                                      
write_rds(perim_df, here("data-out/MD_2010/perim.rds"), compress = "xz")                         

if (is.null(attr(map, "analysis_name"))) attr(map, "analysis_name") <- "MD_cd_2010"              
if (is.null(attr(map, "pop_col")))       attr(map, "pop_col")       <- "pop"                     
if (is.null(attr(map, "ndists"))) {                                                                     
  fd <- unique(plans$draw)[1]
  attr(map, "ndists") <- length(unique(plans$district[plans$draw == fd]))
}                                                                                                   
if (is.null(attr(plans, "map"))) attr(plans, "map") <- map                                      

plans <- add_summary_stats(plans, map)                                                            

plans <- plans |> select(-ends_with('.y')) |> rename_with(.fn = \(x) str_sub(x, end = -3), .cols = ends_with('.x'))

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MD_2010/MD_cd_2010_stats.csv")

cli_process_done()