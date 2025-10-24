###############################################################################
# Set up redistricting simulation for `MD_cd_2010`
# © ALARM Project, August 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_2010}")

map <- redist_map(md_land, pop_tol = 0.005, 
                  existing_plan = cd_2010, adj = md_land$adj)

# Normalize enacted labels
nd <- attr(map, "ndists")
u  <- sort(unique(na.omit(map$cd_2010)))   
ref_norm <- match(map$cd_2010, u)   
stopifnot(identical(sort(unique(na.omit(ref_norm))), seq_len(nd)))
map$cd_2010 <- ref_norm
attr(map, "existing_plan") <- ref_norm

map <- map %>%
  mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                          pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "MD_2010"

# Compute and attach perimeters for compactness stats; save for reproducibility
perim_df <- redistmetrics::prep_perims(map)
attr(map, "perim_df") <- perim_df
dir.create(here("data-out/MD_2010"), recursive = TRUE, showWarnings = FALSE)
saveRDS(perim_df, here("data-out/MD_2010/perim.rds"))

map$state <- "MD"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/MD_2010/MD_cd_2010_map.rds", compress = "xz")
cli_process_done()
