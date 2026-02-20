###############################################################################
# Set up redistricting simulation for `MD_cd_2000`
# © ALARM Project, October 2025
###############################################################################
cli_process_start("Creating {.cls redist_map} object for {.pkg MD_cd_2000}")

map <- redist_map(md_shp, pop_tol = 0.005,
    existing_plan = cd_2000, adj = md_shp$adj)

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

# Define helper function before it is called
check_valid <- function(pref_n, plans_matrix) {

    pref_sep <- data.frame(unit = 1, geometry = sf::st_cast(pref_n[1, ]$geometry, "POLYGON"))

    for (i in 2:nrow(pref_n))
    {
        pref_sep <- rbind(pref_sep, data.frame(unit = i, geometry = sf::st_cast(pref_n[i, ]$geometry, "POLYGON")))
    }

    pref_sep <- sf::st_as_sf(pref_sep)
    pref_sep_adj <- redist::redist.adjacency(pref_sep)

    mainland <- pref_sep[which(unlist(lapply(pref_sep_adj, length)) > 0), ]
    mainland_adj <- redist::redist.adjacency(mainland)
    mainland$component <- geomander::check_contiguity(adj = mainland_adj)$component

    checks <- vector(length = ncol(plans_matrix))
    mainland_plans <- plans_matrix[mainland$unit, ]

    for (k in 1:ncol(plans_matrix))
    {

        checks[k] <- max(check_contiguity(mainland_adj, mainland_plans[, k])$component) == 1
    }

    return(checks)

}
