###############################################################################
# Set up redistricting simulation for `MD_cd_2000`
# © ALARM Project, July 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_2000}")

map <- redist_map(md_land, pop_tol = 0.005,
                  existing_plan = cd_2000, adj = md_land$adj)

# Add an analysis name attribute
attr(map, "analysis_name") <- "MD_2000"

# Compute and attach perimeters for compactness stats; save for reproducibility
perim_df <- redistmetrics::prep_perims(map)
attr(map, "perim_df") <- perim_df
dir.create(here("data-out/MD_2000"), recursive = TRUE, showWarnings = FALSE)
saveRDS(perim_df, here("data-out/MD_2000/perim.rds"))

map$state <- "MD"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MD_2000/MD_cd_2000_map.rds", compress = "xz")
cli_process_done()
