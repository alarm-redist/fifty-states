###############################################################################
# Set up redistricting simulation for `FL_cd_2020`
# © ALARM Project, March 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg FL_cd_2020}")

# TODO any pre-computation (usually not necessary)

map <- redist_map(fl_shp, pop_tol = 0.005,
    existing_plan = cd_2020, adj = fl_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
                                            pop_muni = get_target(map)))

# Add an analysis name attribute
attr(map, "analysis_name") <- "FL_2020"

# Designate the south, centra, and north region county clusters
clust_south <- sort(c("Miami-Dade County", "Broward County", "Palm Beach County", "Monroe County", "Collier County", "Hendry County",
                      "Glades County", "Martin County", "Lee County", "Charlotte County", "St. Lucie County", "Okeechobee County",
                      "Hardee County", "Sarasota County", "Manatee County", "DeSoto County", "Highlands County"))

clust_central <- sort(c("Orange County", "Seminole County", "Osceola County", "Lake County", "Polk County", "Hillsborough County", "Pinellas County",
                        "Pasco County", "Hernando County", "Citrus County", "Sumter County", "Lake County", "Volusia County",
                        "Flagler County", "Brevard County", "Indian River County"))

clust_north <- sort(unique(map$county[-which(map$county %in% c(clust_south, clust_central))]))

map <- map %>%
    mutate(region = ifelse(county %in% clust_south, "South",
                           ifelse(county %in% clust_central, "Central",
                                  ifelse(county %in% clust_north, "North", NA)
                                 )
                           )
           )

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/FL_2020/FL_cd_2020_map.rds", compress = "xz")
cli_process_done()
