###############################################################################
# Set up redistricting simulation for `CA_cd_2010`
# © ALARM Project, February 2023
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CA_cd_2010}")

map <- redist_map(ca_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = ca_shp$adj)

# Make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

map <- map %>%
    mutate(
        uid = row_number(),
        across(contains(c("_16", "_18", "_20")) & !contains("cd"), \(x) coalesce(x, 0)),
        ndv = coalesce(ndv, 0),
        nrv = coalesce(nrv, 0)
    )

counties_south <- c("037", "071", "059",
    "065", "073", "025")
map_south <- map %>%
    `attr<-`("existing_col", NULL) %>%
    filter(county %in% counties_south) %>%
    `attr<-`("ndists", 31) %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

counties_bay <- c("001", "013", "039",
    "047", "053", "067",
    "069", "075", "077",
    "081", "085", "087",
    "095", "099", "113")
map_bay <- map %>%
    `attr<-`("existing_col", NULL) %>%
    filter(county %in% counties_bay) %>%
    `attr<-`("ndists", 17) %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

map <- map %>%
    mutate(cluster = case_when(county %in% counties_bay ~ "Bay",
        county %in% counties_south ~ "South",
        TRUE ~ "Remainder"))

# Add an analysis name attribute
attr(map, "analysis_name") <- "CA_2010"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CA_2010/CA_cd_2010_map.rds", compress = "xz")
cli_process_done()
