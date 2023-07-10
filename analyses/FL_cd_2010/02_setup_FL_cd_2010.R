###############################################################################
# Set up redistricting simulation for `FL_cd_2010`
# © ALARM Project, December 2022
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg FL_cd_2010}")

map <- redist_map(fl_shp, pop_tol = 0.005,
    existing_plan = cd_2010, adj = fl_shp$adj)

map <- map %>%
    mutate(pseudo_county = pick_county_muni(map, counties = county, munis = muni,
        pop_muni = get_target(map)))

clust_south <- sort(c("Miami-Dade County", "Broward County"))

clust_south <- stringr::str_sub(sapply(clust_south, function(x) {
    tigris::lookup_code("FL", x)
}), -5, -3)

clust_central <- sort(c("Orange County", "Seminole County", "Osceola County", "Lake County", "Polk County", "Hillsborough County", "Pinellas County",
    "Pasco County", "Hernando County", "Brevard County", "Indian River County", "Glades County", "Charlotte County", "Hendry County", "Lee County",
    "Okeechobee County", "Hardee County", "Sarasota County", "Manatee County", "DeSoto County", "Highlands County", "Collier County",
    "St. Lucie County", "Martin County", "Monroe County", "Palm Beach County"))

clust_central <- stringr::str_sub(sapply(clust_central, function(x) {
    tigris::lookup_code("FL", x)
}), -5, -3)

clust_north <- sort(unique(map$county[-which(map$county %in% c(clust_south, clust_central))]))

map <- map %>% mutate(
    section = ifelse(county %in% clust_south, "South", ifelse(county %in% clust_central, "Central", "North"))
)

# Add an analysis name attribute
attr(map, "analysis_name") <- "FL_2010"

map$state <- "FL"

# Output the redist_map object. Do not edit this path.
write_rds(map, "data-out/FL_2010/FL_cd_2010_map.rds", compress = "xz")
cli_process_done()
