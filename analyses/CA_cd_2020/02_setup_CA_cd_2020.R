###############################################################################
# Set up redistricting simulation for `CA_cd_2020`
# © ALARM Project, February 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg CA_cd_2020}")

map <- redist_map(ca_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = ca_shp$adj)

# make pseudo counties with default settings
map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

map <- map %>%
    mutate(uid = row_number())

map <- map %>%
    mutate(across(contains(c("_16", "_18", "_20")), \(x) coalesce(x, 0)))
map <- map %>%
    mutate(ndv = coalesce(ndv, 0),
        nrv = coalesce(nrv, 0))


map_south <- map %>%
    `attr<-`("existing_col", NULL) %>%
    filter(county %in% c("Los Angeles County", "San Bernardino County", "Orange County",
        "Riverside County", "San Diego County", "Imperial County")) %>%
    `attr<-`("ndists", 29) %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

map_bay <- map %>%
    `attr<-`("existing_col", NULL) %>%
    filter(county %in% c("Alameda County", "Contra Costa County", "Fresno County", "Kings County",
        "Madera County", "Madera County", "Merced County", "Monterey County",
        "Sacramento County", "San Benito County", "San Francisco County",
        "San Joaquin County", "San Mateo County", "Santa Clara County",
        "Santa Cruz County", "Solano County", "Stanislaus County", "Tulare County",
        "Yolo County")) %>%
    `attr<-`("ndists", 17) %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))



# Add an analysis name attribute
attr(map, "analysis_name") <- "CA_2020"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/CA_2020/CA_cd_2020_map.rds", compress = "xz")
cli_process_done()
